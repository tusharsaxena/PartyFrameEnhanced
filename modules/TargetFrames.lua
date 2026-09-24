local _, NS = ...

-- modules/TargetFrames.lua — what each party member is targeting (design spec §6.3). One secure button per
-- tracked unit acting on its target token (`target` for the player, `partyNtarget` otherwise);
-- clicking it targets that unit.
--
-- UPDATES: UNIT_TARGET per owner (RegisterUnitEvent on the button's own frame — the documented
-- deviation in docs/ARCHITECTURE.md) repaints name, color, marker and health, PLUS
-- PLAYER_TARGET_CHANGED on the module's own target -- UNIT_TARGET does not fire for the player's
-- own target change -- which repaints the player's button alone; RAID_TARGET_UPDATE repaints
-- markers. A compound token gets no UNIT_HEALTH, so health comes from ONE repeating timer
-- that runs only while at least one button is SHOWN, and repaints only the shown ones. "Shown" is
-- the state driver's `[@partyNtarget,exists]`, which the client resolves securely; Lua's own
-- UnitExists on a compound token can come back secret in combat, and reading that as "exists"
-- repainted every hidden button five times a second (docs/perf-analysis/20260915-161824). The
-- buttons' OnShow/OnHide post-hooks start and stop the timer; they make no protected call.
-- With "Update health" off the bar is drawn full and the ticker runs only for the case below.
--
-- THE UNIT THAT HAS NOT RESOLVED. A button can be painted while its unit exists but the client has
-- not streamed it yet -- routine when someone joins the party, since the layout repaint lands
-- before the new member's target is known: a nil name, and an unknown reaction that reads as
-- hostile, so a blank red frame (owner-reported). No event follows -- UNIT_TARGET waits for the
-- owner to change target, and unit events such as UNIT_NAME_UPDATE are not dispatched for compound
-- tokens -- so such a button is marked pending and the ticker repaints it whole until it resolves.
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
local cfg, gen        -- the target section, and the general one (shared health updates)
local suspended = false
local ticker, tickerInterval

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
    -- Unresolved: the unit exists but the client has not streamed it yet -- a plain nil name, and
    -- with it an unknown reaction that reads as hostile. The ticker repaints until it resolves. A
    -- secret name IS resolved (the secret test comes first: a secret is never compared).
    local name = UnitName(token)
    btn.__pending = not Compat.IsSecret(name) and name == nil
    UnitButtons.Invalidate(btn)
    UnitButtons.RenderName(btn, token, cfg.showName)
    if gen.updateHealth then
        UnitButtons.RenderHealth(btn, token, cfg.showPercent)
    else
        UnitButtons.RenderFull(btn)
    end
    paintColors(btn, token)
    if cfg.showMarker then Compat.RaidMarker(btn.marker, token) else btn.marker:Hide() end
end

local function paintPreview(btn)
    local health = gen.updateHealth
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

-- One shown button's share of a tick: a pending one repainted whole, otherwise its health. Answers
-- whether it is still pending.
local function tickButton(btn)
    local t1 = Perf.on and debugprofilestop()
    if btn.__pending then
        paintAll(btn)
    elseif gen.updateHealth then
        UnitButtons.RenderHealth(btn, btn.token, cfg.showPercent)
    end
    if t1 then Perf.Note("targetRender", debugprofilestop() - t1, "targetTick") end
    return btn.__pending
end

local function tick()
    local t0 = Perf.on and debugprofilestop()
    local any, pending = false, false
    for _, unit in ipairs(Units.LIST) do
        local btn = buttons[unit]
        if btn.__allowed and btn:IsVisible() then
            any = true
            if tickButton(btn) then pending = true end
        end
    end
    NS.CombatStats.targetTicks = (NS.CombatStats.targetTicks or 0) + 1
    if t0 then Perf.Note("targetTick", debugprofilestop() - t0) end
    if not any or (not pending and not gen.updateHealth) then TargetFrames.UpdateTicker() end
end

-- Whether the ticker has something to do: the feature on, not previewing, and at least one allowed
-- button shown by its state driver that needs it -- for its health, or because its unit had not
-- resolved when it was painted (see paintAll).
local function tickerWanted()
    if not (featureOn() and not NS.State.preview) then return false end
    for _, unit in ipairs(Units.LIST) do
        local btn = buttons[unit]
        if btn.__allowed and btn:IsVisible() and (gen.updateHealth or btn.__pending) then return true end
    end
    return false
end

--- Run the ticker exactly while it has something to do, at the shared Health refresh pace. A new
--- pace restarts a running ticker at it; before, it only took effect on the next start.
function TargetFrames.UpdateTicker()
    local want = tickerWanted()
    local interval = gen.tickInterval or 0.2
    if ticker and (not want or tickerInterval ~= interval) then
        NS.addon:CancelTimer(ticker)
        ticker, tickerInterval = nil, nil
        if not want then NS.Debug("Target", "health ticker stopped") end
    end
    if want and not ticker then
        ticker, tickerInterval = NS.addon:ScheduleRepeatingTimer(tick, interval), interval
        NS.Debug("Target", "health ticker started (every %ss)", interval)
    end
end

function TargetFrames.TickerRunning()
    return ticker ~= nil
end

--- The running ticker's pace in seconds, or nil when it is not running.
function TargetFrames.TickerInterval()
    return tickerInterval
end

-- One pass of the ticker, for tests/perf.lua to measure without the timer library around it.
TargetFrames.__tick = tick

-- ── show decision, content, events ────────────────────────────────────────────────────────────

local function refresh(btn)
    -- Stood down, the driver is unregistered, not replaced with "hide" (slash-commands-§7); a
    -- feature that is merely off keeps its "hide" driver. Resume's refreshAll re-installs it.
    if suspended then
        btn.__allowed = false
        UnitButtons.Release(btn)
        return
    end
    local allowed = UnitButtons.Allowed(cfg, btn.unit)
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
    local on = featureOn() and Units.InParty()
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

-- A button the state driver shows or hides may start or stop the ticker. Resolved at call time.
local function onVisibility()
    if cfg then TargetFrames.UpdateTicker() end
end

function TargetFrames:OnEnable()
    cfg, gen = NS.db.profile.target, NS.db.profile.general
    for _, unit in ipairs(Units.LIST) do
        local btn = UnitButtons.Create("Target", unit, Units.TARGET[unit])
        btn:SetScript("OnEvent", onEvent)
        btn:HookScript("OnShow", onVisibility)
        btn:HookScript("OnHide", onVisibility)
        buttons[unit] = btn
    end
    NS.Anchor.Register({
        key = "target", label = L["Target frames"], secure = true, elements = buttons,
        -- LIVE reads, never the `cfg` upvalue: this feature's PROFILE handler may run after
        -- Anchor's (modules/Anchor.lua, placementOf).
        config = function() return NS.db.profile.target end,
        slotSize = function()
            local scale = NS.GetSetting("scale") or 1
            local c = NS.db.profile.target
            return (c.width or 110) * scale, (c.height or 20) * scale
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
    cfg, gen = NS.db.profile.target, NS.db.profile.general
    reconfigure()
end))
-- VISIBILITY also carries the party flip (core/PartyFrameEnhanced.lua), so events follow it.
ev:RegisterMessage(NS.MSG.VISIBILITY, whenReady(function()
    syncEvents()
    refreshAll()
end))
ev:RegisterMessage(NS.MSG.LAYOUT, whenReady(refreshAll))

-- THE PLAYER'S OWN TARGET. `UNIT_TARGET` fires when a PARTY member's target changes and NOT when
-- the player's does -- that is `PLAYER_TARGET_CHANGED`, which carries no unit argument. The
-- per-owner registration above therefore covered four of the five tracked units, and the player's
-- own button sat on whatever it last painted: every other frame tracked correctly while the
-- player's showed a stale name, or a red bar with no name at all, since an unknown reaction reads
-- as hostile (the color note at the top of this file). Reported from a live party.
--
-- ON THE MODULE'S OWN TARGET, not on the button, and that is the difference between this and the
-- registrations above. An unfiltered event has no unit to filter by, so `RegisterUnitEvent` cannot
-- carry it; putting a bare `RegisterEvent` on all five buttons would repaint all five on every
-- target change, four of them for a change that is none of their business. One registration here
-- repaints exactly the one button whose owner moved -- the same shape RAID_TARGET_UPDATE below
-- already uses for an event that genuinely concerns everyone.
ev:RegisterEvent("PLAYER_TARGET_CHANGED", whenReady(function()
    local btn = buttons.player
    if btn then onEvent(btn) end
end))

-- Markers change for every unit at once; one repaint pass over the shown frames.
ev:RegisterEvent("RAID_TARGET_UPDATE", whenReady(function()
    if NS.State.preview or not cfg.showMarker then return end
    for _, unit in ipairs(Units.LIST) do
        local btn = buttons[unit]
        if btn.__allowed then Compat.RaidMarker(btn.marker, btn.token) end
    end
end))
