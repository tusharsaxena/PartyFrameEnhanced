local _, NS = ...

-- modules/PetFrames.lua — each party member's pet (design spec §6.5). One secure button per tracked unit
-- acting on its pet token (`pet` for the player, `partypetN` otherwise); clicking it targets the pet.
--
-- UPDATES are all events, no ticker: UNIT_PET on the owner (a pet summoned, dismissed or swapped)
-- repaints everything; UNIT_HEALTH / UNIT_MAXHEALTH / UNIT_NAME_UPDATE on the pet token repaint what
-- they name. Both are RegisterUnitEvent on the button's own frame (the documented deviation in
-- docs/ARCHITECTURE.md). RAID_TARGET_UPDATE repaints the markers, one pass on the module's own target.
--
-- COLOR: the stored bar color, or the OWNER's class color with "Use class color" on — the pet frame
-- describes a party member's pet, and the owner's class is what identifies whose it is. An owner is
-- a party member, whose class is never secret.

local Perf        = NS.Perf
local Compat      = NS.Compat
local Units       = NS.Units
local Element     = NS.Element
local UnitButtons = NS.UnitButtons
local L           = NS.L

local PetFrames = NS.RegisterModule({ name = "PetFrames" })
NS.PetFrames = PetFrames

local buttons = {}
PetFrames.__buttons = buttons
local cfg, gen        -- the pet section, and the general one (shared health updates)
local suspended = false

local HEALTH_EVENTS = { UNIT_HEALTH = true, UNIT_MAXHEALTH = true }
local PREVIEW_MARKER = 8   -- skull

local function paintAll(btn)
    UnitButtons.Invalidate(btn)
    UnitButtons.RenderName(btn, btn.token, cfg.showName)
    if gen.updateHealth then
        UnitButtons.RenderHealth(btn, btn.token, cfg.showPercent)
    else
        UnitButtons.RenderFull(btn)
    end
    local r, g, b, a = NS.ResolveColor(cfg.barColor, cfg.useClassColorBar, btn.unit)
    btn.bar:SetStatusBarColor(r, g, b, (a or 1) * (cfg.barAlpha or 1))
    Element.ApplyColors(btn, cfg, Element.UnitResolver(btn, btn.unit))
    if cfg.showMarker then Compat.RaidMarker(btn.marker, btn.token) else btn.marker:Hide() end
end

local function paintPreview(btn)
    local health = gen.updateHealth
    UnitButtons.RenderPreview(btn, L["Preview pet"], health and 80 or 100, cfg.showName,
        health and cfg.showPercent)
    local r, g, b, a = NS.ResolveColor(cfg.barColor, cfg.useClassColorBar, btn.unit)
    btn.bar:SetStatusBarColor(r, g, b, (a or 1) * (cfg.barAlpha or 1))
    Element.ApplyColors(btn, cfg, Element.UnitResolver(btn, btn.unit))
    if cfg.showMarker and SetRaidTargetIconTexture then
        SetRaidTargetIconTexture(btn.marker, PREVIEW_MARKER)
        btn.marker:Show()
    else
        btn.marker:Hide()
    end
end

local function refresh(btn)
    local allowed = not suspended and UnitButtons.Allowed(cfg, btn.unit)
    btn.__allowed = allowed
    UnitButtons.ApplyDriver(btn, UnitButtons.Driver(btn.token, allowed, NS.State.preview))
    if not allowed then return end
    if NS.State.preview then paintPreview(btn) else paintAll(btn) end
end

local function refreshAll()
    for _, unit in ipairs(Units.LIST) do refresh(buttons[unit]) end
end

local function onEvent(btn, event)
    if not btn.__allowed or NS.State.preview then return end
    local t0 = Perf.on and debugprofilestop()
    if HEALTH_EVENTS[event] then
        UnitButtons.RenderHealth(btn, btn.token, cfg.showPercent)
    elseif event == "UNIT_NAME_UPDATE" then
        UnitButtons.RenderName(btn, btn.token, cfg.showName)
    else
        paintAll(btn)   -- UNIT_PET: a different pet (or none) behind the token
        NS.Debug("Pet", "%s pet: %s", btn.unit, UnitName(btn.token) or "none")
    end
    if t0 then Perf.Note("petEvent", debugprofilestop() - t0) end
end

-- What a button listens for: nothing (false), its owner and name ("name"), or those plus the pet's
-- health ("health"). Re-registered only when that answer changes.
local function wantedEvents(on, unit)
    if not (on and Units.IsIncluded(unit)) then return false end
    return gen.updateHealth and "health" or "name"
end

local function syncEvents()
    local on = not suspended and cfg.enabled and Element.MasterShows() and Units.InParty()
    for _, unit in ipairs(Units.LIST) do
        local btn = buttons[unit]
        local want = wantedEvents(on, unit)
        if (btn.__registered or false) ~= want then
            btn:UnregisterAllEvents()
            if want then
                btn:RegisterUnitEvent("UNIT_PET", unit)
                btn:RegisterUnitEvent("UNIT_NAME_UPDATE", btn.token)
                if want == "health" then
                    btn:RegisterUnitEvent("UNIT_HEALTH", btn.token)
                    btn:RegisterUnitEvent("UNIT_MAXHEALTH", btn.token)
                end
            end
            btn.__registered = want
        end
    end
end

local function reskinAll()
    NS.RunSecure("pet:reskin", function()
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

function PetFrames:OnEnable()
    cfg, gen = NS.db.profile.pet, NS.db.profile.general
    for _, unit in ipairs(Units.LIST) do
        local btn = UnitButtons.Create("Pet", unit, Units.PET[unit])
        btn:SetScript("OnEvent", onEvent)
        buttons[unit] = btn
    end
    NS.Anchor.Register({
        key = "pet", label = L["Pet frames"], secure = true, elements = buttons,
        config = function() return cfg end,
        slotSize = function()
            local scale = NS.GetSetting("scale") or 1
            return (cfg.width or 80) * scale, (cfg.height or 14) * scale
        end,
        defaultPosition = { "CENTER", -220, -180 },
    })
    reconfigure()
    NS.Anchor.Apply("pet")
end

function PetFrames:Suspend()
    suspended = true
    syncEvents()
    refreshAll()
end

function PetFrames:Resume()
    suspended = false
    syncEvents()
    refreshAll()
end

local ev = NS.NewBusTarget()
PetFrames.__ev = ev

local function whenReady(fn)
    return function(...) if cfg then fn(...) end end
end

ev:RegisterMessage(NS.MSG.CONFIG, whenReady(function(_, section)
    if section == "pet" or section == "master" then
        reconfigure()
    elseif section == "general" then
        syncEvents()
        refreshAll()
    end
end))
ev:RegisterMessage(NS.MSG.PROFILE, whenReady(function()
    cfg, gen = NS.db.profile.pet, NS.db.profile.general
    reconfigure()
end))
-- VISIBILITY also carries the party flip (core/PartyFrameEnhanced.lua), so events follow it.
ev:RegisterMessage(NS.MSG.VISIBILITY, whenReady(function()
    syncEvents()
    refreshAll()
end))
ev:RegisterMessage(NS.MSG.LAYOUT, whenReady(refreshAll))

-- Markers change for every unit at once; one repaint pass over the allowed buttons.
ev:RegisterEvent("RAID_TARGET_UPDATE", whenReady(function()
    if NS.State.preview or not cfg.showMarker then return end
    for _, unit in ipairs(Units.LIST) do
        local btn = buttons[unit]
        if btn.__allowed then Compat.RaidMarker(btn.marker, btn.token) end
    end
end))
