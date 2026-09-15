local _, NS = ...

-- modules/TargetFrames.lua — what each party member is targeting (design spec §6.3). One secure button per
-- tracked unit acting on its target token (`target` for the player, `partyNtarget` otherwise);
-- clicking it targets that unit.
--
-- UPDATES: UNIT_TARGET per owner (RegisterUnitEvent on the button's own frame — the documented
-- deviation in docs/ARCHITECTURE.md) repaints name, color, marker and health; RAID_TARGET_UPDATE
-- repaints markers. A compound token gets no UNIT_HEALTH, so health comes from ONE repeating timer
-- that runs only while at least one tracked unit has a target, and cancels itself when none do.
-- With "Update health" off the bar is drawn full and the ticker never starts.
--
-- COLOR: a player target in its class color when "Use class color" is on; an NPC by its reaction
-- when "Color NPCs by reaction" is on; the stored bar color otherwise. The target's class, player-ness
-- and reaction can each be secret: an unknown class falls through to the stored swatch, an unknown
-- reaction reads as hostile.

local Perf        = NS.Perf
local Compat      = NS.Compat
local Units       = NS.Units
local Element     = NS.Element
local UnitButtons = NS.UnitButtons
local L           = NS.L

local TargetFrames = NS.RegisterModule({ name = "TargetFrames" })
NS.TargetFrames = TargetFrames

local buttons = {}
TargetFrames.__buttons = buttons
local cfg
local suspended = false
local ticker

local PREVIEW_MARKER = 8   -- skull

-- ── color ─────────────────────────────────────────────────────────────────────────────────────

local function reactionColor(reaction)
    if reaction and reaction >= 5 then return cfg.friendlyColor end
    if reaction == 4 then return cfg.neutralColor end
    return cfg.hostileColor
end

local function paintColors(btn, token)
    local classToken = Compat.ClassToken(token)
    local isPlayer = Compat.IsPlayer(token)
    local resolve = Element.ClassResolver(isPlayer and classToken or nil)
    local r, g, b, a
    if isPlayer == false and cfg.colorReaction then
        r, g, b, a = Element.Stored(reactionColor(Compat.Reaction(token)))
    elseif isPlayer == nil and cfg.colorReaction then
        -- Player-ness itself unknown: reaction if it is plain, else the hostile swatch.
        r, g, b, a = Element.Stored(reactionColor(Compat.Reaction(token)))
    else
        r, g, b, a = resolve(cfg.barColor, cfg.useClassColorBar)
    end
    btn.bar:SetStatusBarColor(r, g, b, (a or 1) * (cfg.barAlpha or 1))
    Element.ApplyColors(btn, cfg, resolve)
end

-- ── painting ──────────────────────────────────────────────────────────────────────────────────

local function paintAll(btn)
    local token = btn.token
    UnitButtons.Invalidate(btn)
    UnitButtons.RenderName(btn, token, cfg.showName)
    if cfg.updateHealth then
        UnitButtons.RenderHealth(btn, token, cfg.showPercent)
    else
        UnitButtons.RenderFull(btn)
    end
    paintColors(btn, token)
    if cfg.showMarker then Compat.RaidMarker(btn.marker, token) else btn.marker:Hide() end
end

local function paintPreview(btn)
    local health = cfg.updateHealth
    UnitButtons.RenderPreview(btn, L["Preview target"], health and 65 or 100, cfg.showName,
        health and cfg.showPercent)
    local r, g, b, a = Element.Stored(cfg.colorReaction and cfg.hostileColor or cfg.barColor)
    btn.bar:SetStatusBarColor(r, g, b, (a or 1) * (cfg.barAlpha or 1))
    Element.ApplyColors(btn, cfg, Element.ClassResolver(nil))
    if cfg.showMarker and SetRaidTargetIconTexture then
        SetRaidTargetIconTexture(btn.marker, PREVIEW_MARKER)
        btn.marker:Show()
    else
        btn.marker:Hide()
    end
end

-- ── the health ticker ─────────────────────────────────────────────────────────────────────────

local function featureOn()
    return not suspended and cfg.enabled and Element.MasterShows()
end

local function tick()
    local t0 = Perf.on and debugprofilestop()
    local any, painted = false, 0
    for _, unit in ipairs(Units.LIST) do
        local btn = buttons[unit]
        if btn.__allowed and Compat.UnitExists(btn.token) then
            any = true
            local t1 = Perf.on and debugprofilestop()
            if UnitButtons.RenderHealth(btn, btn.token, cfg.showPercent) then painted = painted + 1 end
            if t1 then Perf.Note("targetRender", debugprofilestop() - t1, "targetTick") end
        end
    end
    NS.CombatStats.targetTicks = (NS.CombatStats.targetTicks or 0) + 1
    if t0 then Perf.Note("targetTick", debugprofilestop() - t0) end
    if not any then TargetFrames.UpdateTicker() end
end

--- Run the ticker exactly while it has something to do: the feature on, health updates on, not
--- previewing, and at least one allowed unit with a target.
function TargetFrames.UpdateTicker()
    local want = false
    if featureOn() and cfg.updateHealth and not NS.State.preview then
        for _, unit in ipairs(Units.LIST) do
            local btn = buttons[unit]
            if btn.__allowed and Compat.UnitExists(btn.token) then want = true; break end
        end
    end
    if want and not ticker then
        ticker = NS.addon:ScheduleRepeatingTimer(tick, cfg.tickInterval or 0.2)
        NS.Debug("Target", "health ticker started (every %ss)", cfg.tickInterval or 0.2)
    elseif not want and ticker then
        NS.addon:CancelTimer(ticker)
        ticker = nil
        NS.Debug("Target", "health ticker stopped")
    end
end

function TargetFrames.TickerRunning()
    return ticker ~= nil
end

-- One pass of the ticker, for tests/perf.lua to measure without the timer library around it.
TargetFrames.__tick = tick

-- ── show decision, content, events ────────────────────────────────────────────────────────────

local function refresh(btn)
    local allowed = not suspended and UnitButtons.Allowed(cfg, btn.unit)
    btn.__allowed = allowed
    UnitButtons.ApplyDriver(btn, UnitButtons.Driver(btn.token, allowed, NS.State.preview))
    if not allowed then return end
    if NS.State.preview then paintPreview(btn) else paintAll(btn) end
end

local function refreshAll()
    for _, unit in ipairs(Units.LIST) do refresh(buttons[unit]) end
    TargetFrames.UpdateTicker()
end

local function onEvent(btn)
    if not btn.__allowed or NS.State.preview then return end
    local t0 = Perf.on and debugprofilestop()
    paintAll(btn)
    TargetFrames.UpdateTicker()
    if t0 then Perf.Note("targetEvent", debugprofilestop() - t0) end
    -- The name may be secret; the sink's stringifier renders it as <secret>.
    NS.Debug("Target", "%s targets %s", btn.unit, UnitName(btn.token) or "nothing")
end

local function syncEvents()
    local on = featureOn()
    for _, unit in ipairs(Units.LIST) do
        local btn = buttons[unit]
        if on and Units.IsIncluded(unit) then
            if not btn.__registered then
                btn:RegisterUnitEvent("UNIT_TARGET", unit)
                btn.__registered = true
            end
        elseif btn.__registered then
            btn:UnregisterAllEvents()
            btn.__registered = false
        end
    end
end

local function reskinAll()
    -- Size and anchors on a secure button are protected: the whole restyle is one secure write.
    NS.RunSecure("target:reskin", function()
        local t0 = Perf.on and debugprofilestop()
        for _, unit in ipairs(Units.LIST) do Element.Reskin(buttons[unit], cfg, nil) end
        if t0 then Perf.Note("reskin", debugprofilestop() - t0) end
    end)
    for _, unit in ipairs(Units.LIST) do UnitButtons.ApplyClicks(buttons[unit], cfg.clickToTarget) end
end

local function reconfigure()
    reskinAll()
    syncEvents()
    refreshAll()
end

-- ── lifecycle ─────────────────────────────────────────────────────────────────────────────────

function TargetFrames:OnEnable()
    cfg = NS.db.profile.target
    for _, unit in ipairs(Units.LIST) do
        local btn = UnitButtons.Create("Target", unit, Units.TARGET[unit])
        btn:SetScript("OnEvent", onEvent)
        buttons[unit] = btn
    end
    NS.Anchor.Register({
        key = "target", label = L["Target frames"], secure = true, elements = buttons,
        config = function() return cfg end,
        slotSize = function()
            local scale = NS.GetSetting("scale") or 1
            return (cfg.width or 110) * scale, (cfg.height or 20) * scale
        end,
        defaultPosition = { "CENTER", 220, -180 },
    })
    reconfigure()
    NS.Anchor.Apply("target")
end

function TargetFrames:Suspend()
    suspended = true
    syncEvents()
    refreshAll()
end

function TargetFrames:Resume()
    suspended = false
    syncEvents()
    refreshAll()
end

local ev = NS.NewBusTarget()
TargetFrames.__ev = ev

local function whenReady(fn)
    return function(...) if cfg then fn(...) end end
end

ev:RegisterMessage(NS.MSG.CONFIG, whenReady(function(_, section)
    if section == "target" or section == "master" then
        reconfigure()
    elseif section == "general" then
        syncEvents()
        refreshAll()
    end
end))
ev:RegisterMessage(NS.MSG.PROFILE, whenReady(function()
    cfg = NS.db.profile.target
    reconfigure()
end))
ev:RegisterMessage(NS.MSG.VISIBILITY, whenReady(refreshAll))
ev:RegisterMessage(NS.MSG.LAYOUT, whenReady(refreshAll))

-- Markers change for every unit at once; one repaint pass over the shown frames.
ev:RegisterEvent("RAID_TARGET_UPDATE", whenReady(function()
    if NS.State.preview or not cfg.showMarker then return end
    for _, unit in ipairs(Units.LIST) do
        local btn = buttons[unit]
        if btn.__allowed then Compat.RaidMarker(btn.marker, btn.token) end
    end
end))
