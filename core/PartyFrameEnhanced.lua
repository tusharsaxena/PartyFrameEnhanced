local addonName, NS = ...

-- core/PartyFrameEnhanced.lua — AceAddon registration, the lifecycle, the combat flag, the deferred
-- secure-write queue, the module registry, and the sender of VISIBILITY and PROFILE.

-- AceAddon promotion (architecture-§2): NS itself becomes the addon object.
local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon:NewAddon(NS, addonName, "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
NS.addon = addon

-- Reclaim NS.Print. NewAddon embeds AceConsole onto NS, and its :Print overwrites the tagged,
-- secret-safe printer core/CoreSetup.lua built. NS.Util.print is that same function object, so
-- restoring from it restores what every settings file already captured (architecture-§2).
if NS.Util and NS.Util.print then NS.Print = NS.Util.print end

-- ── the module registry ───────────────────────────────────────────────────────────────────────
--
-- Feature modules register themselves at file load. The lifecycle below calls each one's hooks in
-- registration (= TOC) order, so suspend/resume and enable stay one loop rather than a hand-kept
-- list that drifts from the modules that exist.
--   m:OnEnable()   build frames (secure ones included, out of combat) and register events
--   m:Suspend()    unregister every event frame, cancel every timer (performance-§6)
--   m:Resume()     re-register from CURRENT settings
NS.Modules = NS.Modules or {}

function NS.RegisterModule(m)
    NS.Modules[#NS.Modules + 1] = m
    return m
end

local function each(method)
    for _, m in ipairs(NS.Modules) do
        local fn = m[method]
        if fn then fn(m) end
    end
end

-- ── the two messages this file sends ──────────────────────────────────────────────────────────

--- The one sender of VISIBILITY. Anything that changes what a show-decision ladder reads calls
--- this rather than sending the message itself (architecture-§4: one sender per message).
function NS.PublishVisibility()
    NS.bus:SendMessage(NS.MSG.VISIBILITY)
end

local function publishProfile()
    NS.bus:SendMessage(NS.MSG.PROFILE)
end

-- ── the deferred secure-write queue (events-frames-taint-§2) ─────────────────────────────────
--
-- Secure writes (SetAttribute, a state driver, SetPoint on a secure button) are refused under
-- combat lockdown. Callers hand the write here under a KEY: out of combat it runs now; in combat it
-- is queued, and a later write under the same key replaces the earlier one, so a slider dragged
-- through combat flushes one write rather than forty. PLAYER_REGEN_ENABLED flushes in queue order.
local pending, pendingOrder = {}, {}

-- Forward: a write queued while the addon is already stood down still has to be completed, and the
-- listener that completes it is the one registration slash-commands-§7 permits a disabled addon.
local armPendingRegen, disarmPendingRegen

function NS.RunSecure(key, fn)
    if InCombatLockdown() then
        if not pending[key] then pendingOrder[#pendingOrder + 1] = key end
        pending[key] = fn
        NS.Debug("Secure", "queued %s", key)
        if NS.IsStoodDown and NS.IsStoodDown() then armPendingRegen() end
        return false
    end
    fn()
    return true
end

function NS.PendingSecureCount()
    return #pendingOrder
end

local function flushSecure()
    if #pendingOrder == 0 then return end
    local order = pendingOrder
    pendingOrder = {}
    local n = 0
    for _, key in ipairs(order) do
        local fn = pending[key]
        pending[key] = nil
        if fn then
            fn()
            n = n + 1
        end
    end
    NS.Debug("Secure", "flushed %d deferred write(s)", n)
end

-- ── the pending-secure listener, and it is the ONLY thing a stood-down addon watches ─────────
--
-- Secure work — SetAttribute, a state driver, SetPoint on a secure button — is refused under combat
-- lockdown, so a stand-down that lands in combat cannot finish. It holds the write pending and
-- completes it on PLAYER_REGEN_ENABLED, which slash-commands-§7 names as the one event registration
-- a disabled addon is permitted to keep — and MUSTs that it is released the moment it fires.
--
-- On its OWN frame rather than on the addon object, because the addon object's PLAYER_REGEN_ENABLED
-- is OnLeaveCombat and AceEvent keys a callback by (event, target): registering the same event on
-- the same target for a second reason silently replaces the first. Armed only when there is
-- something queued, so a stood-down addon with an empty queue watches nothing at all.
local regenWatch

function armPendingRegen()
    if #pendingOrder == 0 then return end
    if not regenWatch then
        regenWatch = CreateFrame("Frame")
        regenWatch:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            flushSecure()
        end)
    end
    regenWatch:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function disarmPendingRegen()
    if regenWatch then regenWatch:UnregisterAllEvents() end
end

-- ── the stand-down, reached from the latch in core/LifecycleSetup.lua ────────────────────────
--
-- ONE TEARDOWN, TWO REASONS TO REACH IT (slash-commands-§7). `perf` and `disabled` are two named
-- holds on one latch, and both land here. There is deliberately no second, disable-only path: two
-- mechanisms that both mean "be inert" diverge on the first module added after the second was
-- written, which is anti-pattern #85.

local LIFECYCLE_EVENTS = {
    PLAYER_ENTERING_WORLD = "OnEnterWorld",
    PLAYER_REGEN_DISABLED = "OnEnterCombat",
    PLAYER_REGEN_ENABLED  = "OnLeaveCombat",
    GROUP_ROSTER_UPDATE   = "OnRosterUpdate",
    ADDON_ACTION_BLOCKED  = "OnActionBlocked",
    ADDON_ACTION_FORBIDDEN = "OnActionBlocked",
}

function addon:RegisterLifecycleEvents()
    for event, method in pairs(LIFECYCLE_EVENTS) do self:RegisterEvent(event, method) end
end

--- Every registration this addon owns, actually unregistered; every timer canceled; every element
--- refused at the source. Not a draw gate: an early-returning handler is still a handler the client
--- pays to dispatch, and what a player switching the addon off is trying to stop paying for is
--- exactly that dispatch.
---
--- ORDER IS LOAD-BEARING. The modules stand their own event frames and tickers down first and the
--- VISIBILITY publish gets the elements hidden — both of which need the bus — and only then does the
--- bus itself come down. Reversed, the publish would reach nobody and the frames would stay up.
function NS.StandDown()
    for event in pairs(LIFECYCLE_EVENTS) do addon:UnregisterEvent(event) end
    each("Suspend")
    NS.PublishVisibility()
    NS.BusStandDown()
    -- THE ONE REGISTRATION A STOOD-DOWN ADDON KEEPS (slash-commands-§7). A secure write refused
    -- under combat lockdown cannot be completed now and must not be abandoned, so the queue holds
    -- it and PLAYER_REGEN_ENABLED finishes it — and that listener is released the moment it fires.
    armPendingRegen()
end

--- Back up, and rebuilt from CURRENT state rather than from a snapshot taken on the way down: a
--- setting changed while the addon was off comes back correctly (performance-§6).
function NS.StandUp()
    disarmPendingRegen()
    NS.BusStandUp()
    addon:RegisterLifecycleEvents()
    -- The combat state may have moved while the regen events were unregistered.
    NS.State.inCombat = UnitAffectingCombat("player") and true or false
    NS.State.inParty = NS.Units.InParty()
    if not InCombatLockdown() then flushSecure() end
    each("Resume")
    NS.PublishVisibility()
end

-- ── lifecycle ─────────────────────────────────────────────────────────────────────────────────

function addon:OnInitialize()
    NS:InitDB()
    if NS.Slash and NS.Slash.Register then NS.Slash:Register() end
end

function addon:OnEnable()
    NS.ClearLSMCache()
    NS.State.inParty = NS.Units.InParty()
    NS.State.inCombat = UnitAffectingCombat("player") and true or false
    self:RegisterLifecycleEvents()
    -- Modules build their frames here, at PLAYER_LOGIN, which is out of combat on every login and
    -- every /reload — the only safe moment to create secure buttons (design spec §6.4).
    each("OnEnable")
    -- EAGER settings-category registration (options-ui-§1); the page bodies stay lazy.
    if NS.CreateOptionsPanel then NS.CreateOptionsPanel() end
    -- The launcher registers HERE rather than in its own setup file (launcher-§1): the library
    -- resolves `db.global.minimap` at Register time, and the table it must hand LibDBIcon is the one
    -- AceDB built in OnInitialize, not the one that did not exist at file load. Idempotent by the
    -- library's own design, so a second call from a later login handler builds no second button.
    if NS.Launcher then NS.Launcher:Register() end
    -- THE `disabled` HOLD, RE-TAKEN FROM THE STORED PATH (slash-commands-§7). Last, because
    -- everything above it is SETUP — the frames, the settings category, the launcher — and setup
    -- comes up in either state; what the hold stands down is the FEATURES. A profile saved disabled
    -- therefore builds its secure buttons at PLAYER_LOGIN, out of combat, and then stands down,
    -- rather than having no buttons to build when the player switches it back on in combat.
    NS.ApplyEnabled(NS.GetSetting("enabled"))
end

function addon:OnEnterWorld()
    NS.State.inParty = NS.Units.InParty()
    NS.PublishVisibility()
end

-- The party-only rule (NS.Units.InParty) can flip on a roster change: republish, so every element
-- re-decides and every feature re-syncs its unit events. The same answer sends nothing.
function addon:OnRosterUpdate()
    local now = NS.Units.InParty()
    if now == NS.State.inParty then return end
    NS.State.inParty = now
    NS.Debug("Party", "%s", now and "in a party \226\128\148 active" or "not in a party \226\128\148 nothing shows")
    NS.PublishVisibility()
end

-- Combat bookkeeping for the [Combat] rollup (debug-logging-§9): counters any module may bump,
-- reset at combat start and flushed as one line at combat end. Two assignments when debug is off.
NS.CombatStats = NS.CombatStats or {}

function addon:OnEnterCombat()
    NS.State.inCombat = true
    for k in pairs(NS.CombatStats) do NS.CombatStats[k] = 0 end
    NS.PublishVisibility()
end

function addon:OnLeaveCombat()
    NS.State.inCombat = false
    flushSecure()
    NS.PublishVisibility()
    if NS.State.debug then
        local parts = {}
        for k, v in pairs(NS.CombatStats) do parts[#parts + 1] = k .. "=" .. v end
        table.sort(parts)
        NS.Debug("Combat", "left: %s", #parts > 0 and table.concat(parts, " ") or "no activity")
    end
end

-- A blocked or forbidden action is always a bug in this addon's secure handling. The client names
-- the addon it blames; only ours is logged, and ungated, because it must be seen to be fixed.
function addon:OnActionBlocked(event, blamed, func)
    if blamed ~= addonName then return end
    if NS.DebugLog and NS.DebugLog.Add then
        NS.DebugLog:Add("Secure", ("%s: %s"):format(event, NS.SafeToString(func)))
    end
end

-- ── profile callbacks (registered in core/Database.lua) ──────────────────────────────────────
--
-- AceDB replacing the profile whole is logged once, here, worded by the event (debug-logging-§10),
-- then every module rebuilds from the new profile off the one PROFILE message.

local function currentProfile()
    return (NS.db and NS.db.GetCurrentProfile and NS.db:GetCurrentProfile()) or "?"
end

local function adoptProfile(tag, fmt, ...)
    NS.Debug(tag, fmt, ...)
    -- A profile switch can flip `enabled` with no verb and no checkbox touched, so the latch is
    -- re-evaluated BEFORE anything is published: a profile that enables the addon has to be back up
    -- to hear the messages below, and one that disables it has nothing that should hear them.
    NS.ReevaluateEnabled()
    publishProfile()
    NS.PublishVisibility()
    if NS.RefreshOptionsPanel then NS.RefreshOptionsPanel() end
end

function NS.OnProfileChanged()
    adoptProfile("Profile", "changed \226\134\146 %s", currentProfile())
end

function NS.OnProfileReset()
    local n = NS.ConsumeResetCount and NS.ConsumeResetCount()
    if n then
        adoptProfile("Set", "reset profile '%s' to defaults (%d rows)", currentProfile(), n)
    else
        adoptProfile("Set", "reset profile '%s' to defaults", currentProfile())
    end
end

-- AceDB hands a copy's callback the SOURCE profile's name as its third argument.
function NS.OnProfileCopied(_, _, source)
    adoptProfile("Set", "copied profile '%s' \226\134\146 '%s'", tostring(source or "?"),
        currentProfile())
end
