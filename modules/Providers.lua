local _, NS = ...

-- modules/Providers.lua — which party frame shows which party member (design spec §5).
--
-- Three providers, one per frame system: EllesmereUI's party header, Blizzard's raid-style
-- CompactPartyFrame, and Blizzard's classic PartyFrame. A resolve picks one (Automatic: the highest
-- priority that is on screen; or the one the General page pins), reads each visible member frame's
-- unit, and keeps a unit → frame map. When the map changes it sends LAYOUT — the only sender.
--
-- READ-ONLY by construction (library-stack-§6, events-frames-taint-§3): nothing here hides, moves,
-- reparents or calls into another addon's or Blizzard's frame. Change detection is hooksecurefunc and
-- HookScript only, and every hook just REQUESTS a resolve; the resolve itself runs on the next frame,
-- coalesced, so a burst of forty attribute changes during a re-sort costs one pass.

local Perf   = NS.Perf
local Compat = NS.Compat
local Units  = NS.Units

local Providers = NS.RegisterModule({ name = "Providers" })
NS.Providers = Providers

local UNITS = Units.LIST

-- Precomputed so a resolve concatenates nothing.
local ERF_CHILD, CPF_MEMBER, PF_MEMBER = {}, {}, {}
for i = 1, 5 do
    ERF_CHILD[i]  = "ERFPartyHeaderUnitButton" .. i
    CPF_MEMBER[i] = "CompactPartyFrameMember" .. i
    PF_MEMBER[i]  = "MemberFrame" .. i
end

-- ── state ─────────────────────────────────────────────────────────────────────────────────────

local map, scratch = {}, {}   -- unit → frame: the published map, and the one a resolve fills
local active                  -- the provider the last resolve used, or nil
local suspended = false
local scheduled = false       -- a next-frame resolve is already queued
local burstGen = 0            -- invalidates follow-ups from an older burst
local standIn                 -- test mode's stand-in party frame (modules/StandIn.lua), or nil
local stale = false           -- the map was edited while suspended; the next resolve re-sends LAYOUT

local hookedFrames = setmetatable({}, { __mode = "k" })
local hookedFns = {}

-- ── requests ──────────────────────────────────────────────────────────────────────────────────

local function runScheduled()
    scheduled = false
    Providers.Resolve()
end

--- Ask for a resolve on the next frame. Any number of requests before it runs cost one pass.
function Providers.Request()
    if suspended or scheduled then return end
    scheduled = true
    C_Timer.After(0, runScheduled)
end

-- A structural change (roster, Edit Mode, an addon loading): resolve now, and again once frames that
-- settle a frame or two late have settled. A newer burst supersedes an older one's follow-ups.
local function burst()
    Providers.Request()
    burstGen = burstGen + 1
    local gen = burstGen
    C_Timer.After(0.1, function() if gen == burstGen then Providers.Request() end end)
    C_Timer.After(0.5, function() if gen == burstGen then Providers.Request() end end)
end

local function onAttributeChanged(_, name)
    if name == "unit" then Providers.Request() end
end

local function hookFrame(frame)
    if type(frame) ~= "table" or hookedFrames[frame] or type(frame.HookScript) ~= "function" then
        return
    end
    hookedFrames[frame] = true
    frame:HookScript("OnShow", Providers.Request)
    frame:HookScript("OnHide", Providers.Request)
    frame:HookScript("OnAttributeChanged", onAttributeChanged)
end

local function hookMethod(key, owner, method)
    if hookedFns[key] or type(owner) ~= "table" or type(owner[method]) ~= "function" then return end
    hookedFns[key] = true
    hooksecurefunc(owner, method, Providers.Request)
end

-- ── the providers ─────────────────────────────────────────────────────────────────────────────

local function erfChild(header, i)
    return (header and header[i]) or _G[ERF_CHILD[i]]
end

local ELLESMERE = {
    id = "ellesmere", family = "ellesmere", label = "EllesmereUI", priority = 100,
    IsAvailable = function()
        return ERFPartyHeader ~= nil and Compat.IsAddOnLoaded("EllesmereUIRaidFrames")
    end,
    IsActive = function()
        return Compat.FrameVisible(ERFPartyHeader) or Compat.FrameVisible(ERFPartySelfButton)
    end,
    -- Five SecureGroupHeader children the header re-assigns units to as the roster sorts, plus the
    -- separate self button EllesmereUI uses for "show self first".
    ForEachFrame = function(cb)
        local header = ERFPartyHeader
        for i = 1, 5 do
            local f = erfChild(header, i)
            if f then cb(f) end
        end
        if ERFPartySelfButton then cb(ERFPartySelfButton) end
    end,
    InstallHooks = function()
        hookFrame(ERFPartyHeader)
    end,
}

local BLIZZARD_RAID = {
    id = "blizzard-raid", family = "blizzard", label = "Blizzard (raid-style)", priority = 50,
    IsAvailable = function() return CompactPartyFrame ~= nil end,
    IsActive = function()
        return Compat.UseRaidStyleParty() and Compat.FrameVisible(CompactPartyFrame)
    end,
    -- Includes the player, and re-sorts with flowSortFunc — in combat too.
    ForEachFrame = function(cb)
        local list = CompactPartyFrame and CompactPartyFrame.memberUnitFrames
        for i = 1, 5 do
            local f = (type(list) == "table" and list[i]) or _G[CPF_MEMBER[i]]
            if f then cb(f) end
        end
    end,
    InstallHooks = function()
        hookMethod("CompactPartyFrame.RefreshMembers", CompactPartyFrame, "RefreshMembers")
    end,
}

local BLIZZARD_PARTY = {
    id = "blizzard-party", family = "blizzard", label = "Blizzard (classic)", priority = 40,
    IsAvailable = function() return PartyFrame ~= nil end,
    IsActive = function()
        return not Compat.UseRaidStyleParty() and Compat.FrameVisible(PartyFrame)
    end,
    -- Four frames, fixed to party1..party4 by index; never the player, never re-sorted.
    ForEachFrame = function(cb)
        if not PartyFrame then return end
        for i = 1, 4 do
            local f = PartyFrame[PF_MEMBER[i]]
            if f then cb(f) end
        end
    end,
    InstallHooks = function()
        hookMethod("PartyFrame.UpdatePartyFrames", PartyFrame, "UpdatePartyFrames")
    end,
}

-- Highest priority first: Automatic takes the first one that is available and on screen.
local PROVIDERS = { ELLESMERE, BLIZZARD_RAID, BLIZZARD_PARTY }
Providers.__list = PROVIDERS

-- ── resolving ─────────────────────────────────────────────────────────────────────────────────

local function collect(frame)
    hookFrame(frame)
    if not Compat.FrameVisible(frame) then return end
    -- Only the five tracked tokens map. A raidN token means a raid-shaped group, which the
    -- party-only rule excludes.
    local unit = Compat.FrameUnit(frame)
    if unit and Units.INDEX[unit] and scratch[unit] == nil then scratch[unit] = frame end
end

local function pick()
    local choice = NS.GetSetting("general.provider")
    for _, p in ipairs(PROVIDERS) do
        if (choice == "auto" or choice == p.family) and p.IsAvailable() and p.IsActive() then
            return p
        end
    end
    return nil
end

-- Asleep out of a party (solo, or in a raid: the party-only rule, NS.Units.InParty) and while the
-- addon is switched off: the map empties and every attached element loses its frame.
local function asleep()
    return not Units.InParty() or NS.GetSetting("enabled") ~= true
end

local function logResolve(p)
    if not NS.State.debug then return end
    local found = {}
    for _, unit in ipairs(UNITS) do
        if map[unit] then found[#found + 1] = unit end
    end
    NS.Debug("Provider", "%s: %s", p and p.label or "none",
        #found > 0 and table.concat(found, ", ") or "no party frames")
end

--- Did this resolve turn up anything a consumer would see differently — a different provider, or a
--- different frame under any tracked unit? The `stale` flag counts as changed and is consumed here:
--- SetStandIn raises it when it edits the map behind a suspended resolve, and that edit has to be
--- published by the next live resolve even though nothing else moved. Must be asked BEFORE `active`
--- is reassigned, since the provider comparison is against the previous one. Lifted out of
--- Providers.Resolve rather than inlined, to keep that sequence under the complexity gate: the scan
--- is a run of comparisons the gate reads as branching, and what remains in Resolve is the
--- gather-then-publish shape it is actually about.
local function resolveChanged(p)
    if stale then stale = false; return true end
    if p ~= active then return true end
    for _, unit in ipairs(UNITS) do
        if scratch[unit] ~= map[unit] then return true end
    end
    return false
end

--- Rebuild the unit → frame map now. Sends LAYOUT only when the provider or any unit's frame
--- changed, so a resolve that finds what it already had costs its consumers nothing.
function Providers.Resolve()
    if suspended then return end
    local t0 = Perf.on and debugprofilestop()
    for unit in pairs(scratch) do scratch[unit] = nil end
    local p = nil
    if not asleep() then
        p = pick()
        if p then
            p.InstallHooks()
            p.ForEachFrame(collect)
        end
    end
    -- Test mode's stand-in fills party1 when no real frame does, asleep or not: a real frame wins.
    if standIn and scratch.party1 == nil then scratch.party1 = standIn end
    local changed = resolveChanged(p)
    active = p
    if changed then map, scratch = scratch, map end
    -- Noted BEFORE the send, so the consumers' anchor work is not billed to this bucket.
    if t0 then Perf.Note("resolve", debugprofilestop() - t0) end
    if changed then
        logResolve(p)
        NS.bus:SendMessage(NS.MSG.LAYOUT)
    end
end

-- ── what consumers read ───────────────────────────────────────────────────────────────────────

--- The party frame currently showing `unit`, or nil.
function Providers.FrameFor(unit)
    return map[unit]
end

--- The active frame system's label, or nil when none is on screen.
function Providers.ActiveLabel()
    return active and active.label or nil
end

function Providers.ActiveId()
    return active and active.id or nil
end

-- ── test mode's stand-in (docs/superpowers/specs/2026-09-15-test-mode-design.md §3) ─────────────

--- Put test mode's stand-in in party1's place (a real frame still wins), or remove it with nil.
--- Resolves NOW rather than next frame: a stop at PLAYER_REGEN_DISABLED must land its anchor writes
--- before lockdown begins.
function Providers.SetStandIn(frame)
    local old = standIn
    standIn = frame
    if suspended then
        -- A resolve while suspended does nothing, yet a removed stand-in must leave the map now.
        if frame == nil and old ~= nil and map.party1 == old then
            map.party1, stale = nil, true
        end
        return
    end
    Providers.Resolve()
end

-- The first member frame of a frame system, which exists (hidden) out of a party.
local function firstMember(id)
    if id == "ellesmere" then
        return (ERFPartyHeader and ERFPartyHeader[1]) or _G[ERF_CHILD[1]] or ERFPartySelfButton
    elseif id == "blizzard-raid" then
        local list = CompactPartyFrame and CompactPartyFrame.memberUnitFrames
        return (type(list) == "table" and list[1]) or _G[CPF_MEMBER[1]]
    end
    return PartyFrame and PartyFrame[PF_MEMBER[1]]
end

-- EllesmereUI's configured party frame size, from its saved settings. Its five party buttons exist
-- solo, but it styles them at the RAID frame size (_StyleButtonSecure) and gives them the party size
-- only in ReloadPartyFrames, so a hidden button measures the wrong frame (seen in game: a stand-in
-- the shape of 100 × 50 raid frames against 200 × 80 party frames). The size EllesmereUI applies is
-- partyFrameWidth × partyFrameHeight, or its own defaults of 125 × 60. Read-only; every step is
-- nil-guarded, and the keys are EllesmereUI's own. The header rides along for its effective scale.
local function ellesmereConfiguredSize()
    local db = EllesmereUIDB
    local profiles = type(db) == "table" and db.profiles
    local profile = type(profiles) == "table" and profiles[db.activeProfile]
    local addons = type(profile) == "table" and profile.addons
    local rf = type(addons) == "table" and addons.EllesmereUIRaidFrames
    if type(rf) ~= "table" then return nil end
    local w, h = rf.partyFrameWidth or 125, rf.partyFrameHeight or 60
    if type(w) ~= "number" or type(h) ~= "number" or w <= 0 or h <= 0 then return nil end
    return { w = w, h = h, scaleFrame = ERFPartyHeader }
end

--- Which frame system the stand-in imitates, that system's first member frame (or nil), and — for
--- EllesmereUI — its configured party frame size { w, h, scaleFrame } (or nil). The resolve can't
--- answer this out of a party, where no system is on screen: pinned to EllesmereUI it is EllesmereUI;
--- pinned to Blizzard, or Automatic without EllesmereUI's raid frames loaded, it is raid-style when
--- Edit Mode uses it and classic otherwise. Read-only, like everything here.
function Providers.StandInSource()
    local choice = NS.GetSetting("general.provider")
    local id
    if choice == "ellesmere" or (choice == "auto" and Compat.IsAddOnLoaded("EllesmereUIRaidFrames")) then
        id = "ellesmere"
    elseif Compat.UseRaidStyleParty() then
        id = "blizzard-raid"
    else
        id = "blizzard-party"
    end
    return id, firstMember(id), id == "ellesmere" and ellesmereConfiguredSize() or nil
end

-- ── lifecycle ─────────────────────────────────────────────────────────────────────────────────

local ev = NS.NewBusTarget()
Providers.__ev = ev

local ELLESMERE_ADDONS = { EllesmereUI = true, EllesmereUIRaidFrames = true }

local function registerEvents()
    ev:RegisterEvent("GROUP_ROSTER_UPDATE", burst)
    ev:RegisterEvent("PLAYER_ENTERING_WORLD", burst)
    ev:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", burst)
    ev:RegisterEvent("PLAYER_REGEN_ENABLED", Providers.Request)
    ev:RegisterEvent("ADDON_LOADED", function(_, name)
        if ELLESMERE_ADDONS[name] then burst() end
    end)
end

-- Edit Mode's exit is a callback rather than an event; guarded, since it is Blizzard-private. It is
-- a registration like any other, so the stand-down drops it and the stand-up takes it back
-- (slash-commands-§7): one callback per owner, so a second registration replaces the first.
local function editModeCallback(on)
    if not (EventRegistry and type(EventRegistry.RegisterCallback) == "function") then return end
    if on then
        pcall(EventRegistry.RegisterCallback, EventRegistry, "EditMode.Exit", burst, Providers)
    else
        pcall(EventRegistry.UnregisterCallback, EventRegistry, "EditMode.Exit", Providers)
    end
end

function Providers:OnEnable()
    registerEvents()
    editModeCallback(true)
    burst()
end

function Providers:Suspend()
    suspended = true
    scheduled = false
    burstGen = burstGen + 1
    ev:UnregisterAllEvents()
    editModeCallback(false)
end

function Providers:Resume()
    suspended = false
    registerEvents()
    editModeCallback(true)
    burst()
end

-- A frame-system choice, the master switch or a new profile can change the answer.
ev:RegisterMessage(NS.MSG.CONFIG, function(_, section)
    if section == "general" or section == "master" then Providers.Request() end
end)
ev:RegisterMessage(NS.MSG.PROFILE, function() burst() end)
