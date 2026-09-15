local _, NS = ...

-- modules/CastBars.lua — one cast bar per tracked unit (spec §6.2).
--
-- SECRET-SAFE BY CONSTRUCTION (spec §7). A party member's cast name, icon, interruptibility and
-- times can all be secret. The bar never reads a time: the client's duration object goes straight
-- into StatusBar:SetTimerDuration and animates engine-side. The name and icon go straight to
-- SetText/SetTexture. `notInterruptible` never meets an `if`: it picks colors through
-- Compat.BoolValue and the shield's alpha through Compat.AlphaFromBool. The end of a cast comes from
-- the stop/interrupt events, never from comparing a remaining time.
--
-- EVENTS are registered per unit on the bar's own frame with RegisterUnitEvent, only while the
-- feature is on and the unit included, so the client filters by unit in C (a documented deviation
-- from events-frames-taint-§1, docs/ARCHITECTURE.md). Nothing here registers a global
-- UNIT_SPELLCAST_* event.
--
-- A stop, a failure or an interrupt RE-DERIVES the unit's cast before acting on it, instead of
-- matching cast ids (which can be secret): a new cast that started before the old one's stop arrived
-- keeps its bar.

local Perf    = NS.Perf
local Compat  = NS.Compat
local Units   = NS.Units
local Element = NS.Element
local L       = NS.L

local CastBars = NS.RegisterModule({ name = "CastBars" })
NS.CastBars = CastBars

local EVENTS = {
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_DELAYED",
    "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_CHANNEL_UPDATE",
    "UNIT_SPELLCAST_EMPOWER_START", "UNIT_SPELLCAST_EMPOWER_STOP", "UNIT_SPELLCAST_EMPOWER_UPDATE",
    "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
}
CastBars.EVENTS = EVENTS

-- Which events (re)start a bar, and the kind each implies.
local STARTS = {
    UNIT_SPELLCAST_START = "cast", UNIT_SPELLCAST_DELAYED = "cast",
    UNIT_SPELLCAST_CHANNEL_START = "channel", UNIT_SPELLCAST_CHANNEL_UPDATE = "channel",
    UNIT_SPELLCAST_EMPOWER_START = "empower", UNIT_SPELLCAST_EMPOWER_UPDATE = "empower",
}
local FAILS = { UNIT_SPELLCAST_INTERRUPTED = "interrupted", UNIT_SPELLCAST_FAILED = "failed" }

local TICK      = 0.1    -- time text and stale check, seconds
local HOLD_TIME = 0.5    -- an interrupted/failed bar stays up this long
local FADE_TIME = 0.3
local FALLBACK_ICON = 136243

-- Placeholder content for preview mode (preview-mode): a plain cast, mid-way.
local PREVIEW_ICON = 135907

local bars = {}          -- unit → element
CastBars.__bars = bars
local cfg                -- NS.db.profile.castbar, re-read on PROFILE
local suspended = false

-- ── the show decision (spec §6.7) ─────────────────────────────────────────────────────────────

local function shouldShow(el)
    if not Element.MasterShows() or not cfg.enabled then return false end
    if NS.State.preview then return true end
    if not Element.VisibilityAllows() then return false end
    if not Units.IsIncluded(el.unit) then return false end
    if cfg.anchorMode ~= "free" and not NS.Providers.FrameFor(el.unit) then return false end
    return el.state ~= "idle"
end

local function refreshShown(el)
    if shouldShow(el) then el:Show() else el:Hide() end
end

-- ── painting ──────────────────────────────────────────────────────────────────────────────────

-- The fill: the kind's color, or the uninterruptible color, chosen by a flag that may be secret.
-- Every channel is computed from plain inputs first (a secret cannot be multiplied), then chosen.
local function applyFill(el)
    local r, g, b, a
    if el.kind == "channel" then
        local c = cfg.channelColor
        r, g, b, a = c.r, c.g, c.b, c.a or 1
    elseif el.kind == "empower" then
        local c = cfg.empowerColor
        r, g, b, a = c.r, c.g, c.b, c.a or 1
    else
        r, g, b, a = NS.ResolveColor(cfg.barColor, cfg.useClassColorBar, el.unit)
    end
    local u, fill = cfg.uninterruptibleColor, cfg.barAlpha or 1
    local flag = el.notInterruptible
    el.bar:SetStatusBarColor(
        Compat.BoolValue(flag, u.r, r), Compat.BoolValue(flag, u.g, g),
        Compat.BoolValue(flag, u.b, b), Compat.BoolValue(flag, (u.a or 1) * fill, (a or 1) * fill))
    if cfg.showShield then
        Compat.AlphaFromBool(el.shield, flag, 1, 0)
    else
        el.shield:SetAlpha(0)
    end
end

-- ── the per-bar clock (only while something is showing) ──────────────────────────────────────

local onUpdate

local function setTicking(el, on)
    if on and not el.__ticking then
        el.__ticking, el.tick = true, 0
        el:SetScript("OnUpdate", onUpdate)
    elseif not on and el.__ticking then
        el.__ticking = false
        el:SetScript("OnUpdate", nil)
    end
end

local function idle(el)
    el.state, el.kind, el.duration, el.notInterruptible = "idle", nil, nil, nil
    setTicking(el, false)
    el:SetAlpha(el.__alpha or 1)
    refreshShown(el)
end

--- Show what `el.unit` is casting now, or go idle when it is casting nothing.
local function start(el, hint)
    local kind, name, texture, notInterruptible = Compat.CastInfo(el.unit, hint)
    if not kind then
        idle(el)
        return
    end
    el.kind, el.state, el.notInterruptible = kind, "casting", notInterruptible
    el.duration = Compat.CastDuration(el.unit, kind)
    el.__manualFill = not Compat.ApplyTimer(el.bar, el.duration, kind)
    if el.__manualFill then
        if el.duration then
            el.bar:SetMinMaxValues(0, el.duration:GetTotalDuration())
        else
            el.bar:SetMinMaxValues(0, 1)
            el.bar:SetValue(0)
        end
    end
    el.text:SetText(cfg.showName and name or "")
    el.text2:SetText("")
    if el.icon then el.icon:SetTexture(texture or FALLBACK_ICON) end
    if cfg.showSpark then el.spark:Show() else el.spark:Hide() end
    applyFill(el)
    el:SetAlpha(el.__alpha or 1)
    setTicking(el, true)
    refreshShown(el)
end

--- End the current cast: plainly (hide or fade), or as interrupted/failed (hold in the failed
--- color with the client's own localized word, then fade).
local function stop(el, reason)
    if el.state ~= "casting" then return end
    el.kind, el.duration, el.notInterruptible = nil, nil, nil
    el.spark:Hide()
    el.shield:SetAlpha(0)
    if reason then
        el.state, el.hold = "holding", HOLD_TIME
        local c = cfg.failedColor
        el.bar:SetMinMaxValues(0, 1)
        el.bar:SetValue(1)
        el.bar:SetStatusBarColor(c.r, c.g, c.b, (c.a or 1) * (cfg.barAlpha or 1))
        local word = reason == "failed" and (FAILED or L["Failed"]) or (INTERRUPTED or L["Interrupted"])
        el.text:SetText(word)
        el.text2:SetText("")
        NS.CombatStats.castsInterrupted = (NS.CombatStats.castsInterrupted or 0) + 1
        return
    end
    if cfg.fadeOut then
        el.state, el.fade = "fading", FADE_TIME
        return
    end
    idle(el)
end

function onUpdate(el, elapsed)
    local t0 = Perf.on and debugprofilestop()
    if el.state == "casting" then
        local d = el.duration
        if el.__manualFill and d then
            el.bar:SetValue(el.kind == "channel" and d:GetRemainingDuration() or d:GetElapsedDuration())
        end
        el.tick = el.tick + elapsed
        if el.tick >= TICK then
            el.tick = 0
            -- A stop the client never sent (CC, a zone change): nil-ness is never secret.
            if not UnitCastingInfo(el.unit) and not UnitChannelInfo(el.unit) then
                stop(el, nil)
            elseif cfg.showTime and d then
                el.text2:SetFormattedText("%.1f", d:GetRemainingDuration())
            end
        end
    elseif el.state == "holding" then
        el.hold = el.hold - elapsed
        if el.hold <= 0 then
            if cfg.fadeOut then el.state, el.fade = "fading", FADE_TIME else idle(el) end
        end
    elseif el.state == "fading" then
        el.fade = el.fade - elapsed
        if el.fade <= 0 then
            idle(el)
        else
            el:SetAlpha((el.__alpha or 1) * el.fade / FADE_TIME)
        end
    end
    if t0 then Perf.Note("castTick", debugprofilestop() - t0) end
end

-- ── events ────────────────────────────────────────────────────────────────────────────────────

local function render(el, hint)
    local t1 = Perf.on and debugprofilestop()
    start(el, hint)
    if el.state == "casting" then
        NS.CombatStats.castsStarted = (NS.CombatStats.castsStarted or 0) + 1
    end
    if t1 then Perf.Note("castRender", debugprofilestop() - t1, "castEvent") end
end

local function onEvent(el, event)
    if el.__previewing then return end
    local t0 = Perf.on and debugprofilestop()
    local hint = STARTS[event]
    if hint then
        render(el, hint)
    elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        if el.state == "casting" then
            -- A plain flag from the event's own name replaces the possibly secret one.
            el.notInterruptible = event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE"
            applyFill(el)
        end
    elseif Compat.CastInfo(el.unit) then
        -- A stop or failure, but the unit is already casting again: keep the bar on the new cast.
        render(el, el.kind)
    else
        stop(el, FAILS[event])
    end
    if t0 then Perf.Note("castEvent", debugprofilestop() - t0) end
end

-- ── preview (preview-mode: placeholder data through the real render path) ────────────────────

local function renderPreview(el)
    el.__previewing = true
    el.kind, el.state, el.notInterruptible = "cast", "casting", false
    el.duration = nil
    setTicking(el, false)
    el.bar:SetMinMaxValues(0, 1)
    el.bar:SetValue(0.6)
    el.text:SetText(cfg.showName and L["Preview cast"] or "")
    el.text2:SetText(cfg.showTime and "1.2" or "")
    if el.icon then el.icon:SetTexture(PREVIEW_ICON) end
    if cfg.showSpark then el.spark:Show() else el.spark:Hide() end
    applyFill(el)
    el:SetAlpha(el.__alpha or 1)
end

local function refresh(el)
    if NS.State.preview then
        renderPreview(el)
    elseif el.__previewing then
        el.__previewing = nil
        start(el)
        return
    end
    refreshShown(el)
end

local function refreshAll()
    for _, unit in ipairs(Units.LIST) do refresh(bars[unit]) end
end

-- ── configuration ─────────────────────────────────────────────────────────────────────────────

local function reskinAll()
    local t0 = Perf.on and debugprofilestop()
    for _, unit in ipairs(Units.LIST) do
        local el = bars[unit]
        Element.Reskin(el, cfg, cfg)
        -- A party member's own class is never secret, so the library resolver is safe here.
        Element.ApplyColors(el, cfg, function(stored, on) return NS.ResolveColor(stored, on, unit) end)
        if el.state == "casting" then applyFill(el) end
    end
    if t0 then Perf.Note("reskin", debugprofilestop() - t0) end
end

-- Registered only while the feature is on and the unit included: a disabled unit costs no dispatch.
local function syncEvents()
    local on = not suspended and NS.GetSetting("enabled") == true and cfg.enabled
    for _, unit in ipairs(Units.LIST) do
        local el = bars[unit]
        if on and Units.IsIncluded(unit) then
            if not el.__registered then
                for i = 1, #EVENTS do el:RegisterUnitEvent(EVENTS[i], unit) end
                el.__registered = true
                start(el)
            end
        elseif el.__registered then
            el:UnregisterAllEvents()
            el.__registered = false
            idle(el)
        end
    end
end

-- ── lifecycle ─────────────────────────────────────────────────────────────────────────────────

local function slotSize()
    local scale = NS.GetSetting("scale") or 1
    return (cfg.width or 140) * scale, (cfg.height or 16) * scale
end

function CastBars:OnEnable()
    cfg = NS.db.profile.castbar
    for _, unit in ipairs(Units.LIST) do
        local el = CreateFrame("Frame", "PartyFrameEnhancedCastBar_" .. unit, UIParent)
        Element.Build(el, { icon = true, spark = true, shield = true })
        el.unit, el.state = unit, "idle"
        el:SetScript("OnEvent", onEvent)
        el:Hide()
        bars[unit] = el
    end
    NS.Anchor.Register({
        key = "castbar", label = L["Cast bars"], secure = false, elements = bars,
        config = function() return cfg end,
        slotSize = slotSize,
        defaultPosition = { "CENTER", 0, -180 },
    })
    reskinAll()
    syncEvents()
    NS.Anchor.Apply("castbar")
end

function CastBars:Suspend()
    suspended = true
    syncEvents()
end

function CastBars:Resume()
    suspended = false
    syncEvents()
    refreshAll()
end

local ev = NS.NewBusTarget()
CastBars.__ev = ev

ev:RegisterMessage(NS.MSG.CONFIG, function(_, section)
    if not cfg then return end
    if section == "castbar" or section == "master" then
        reskinAll()
        syncEvents()
        refreshAll()
    elseif section == "general" then
        syncEvents()
        refreshAll()
    end
end)
ev:RegisterMessage(NS.MSG.PROFILE, function()
    if not cfg then return end
    cfg = NS.db.profile.castbar
    reskinAll()
    syncEvents()
    refreshAll()
end)
ev:RegisterMessage(NS.MSG.VISIBILITY, function() if cfg then refreshAll() end end)
ev:RegisterMessage(NS.MSG.LAYOUT, function() if cfg then refreshAll() end end)
