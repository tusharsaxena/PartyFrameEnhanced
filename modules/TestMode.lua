local _, NS = ...

-- modules/TestMode.lua — `/pfe test` (docs/superpowers/specs/2026-09-15-test-mode-design.md §2).
--
-- One state, NS.State.test: nil (off), "party" (placeholders on the real party frames) or "standin"
-- (out of a party, solo or in a raid: modules/StandIn.lua's frame in party1's place). Both hold
-- preview through Preview.Hold("test"); the stand-in mode also puts the stand-in into the provider map.
--
-- It switches live between the two on a roster change and stays on through joins and leaves. It is
-- refused in combat, disabled or suspended, and ends at PLAYER_REGEN_DISABLED — while secure writes
-- are still allowed, so no clickable placeholder or stand-in anchor survives into the fight — when the
-- master switch goes off, and on a perf-run suspend. Its two game events are registered only while it
-- is on, so off it costs nothing.

local L         = NS.L
local Preview   = NS.Preview
local StandIn   = NS.StandIn
local Providers = NS.Providers

local TestMode = NS.RegisterModule({ name = "TestMode" })
NS.TestMode = TestMode

local placedId   -- the frame system the stand-in was last dressed as

local function gray(s) return "|cff808080" .. s .. "|r" end

local function modeFor()
    return NS.Units.InParty() and "party" or "standin"
end

-- Dress the stand-in for the frame system it imitates, and say where its size came from: `frame`,
-- `settings` (the system's configured size) or `fallback` — the line a smoke step reads.
local function dress()
    local id, source, configured = Providers.StandInSource()
    local p = StandIn.Place(id, source, configured).__placed
    placedId = id
    NS.Debug("Test", "stand-in as %s, %.0f x %.0f from %s", id, p.w, p.h, p.from)
end

local function raiseStandIn()
    dress()
    StandIn.Show()
    Providers.SetStandIn(StandIn.Frame())
end

local function lowerStandIn()
    Providers.SetStandIn(nil)
    StandIn.Hide()
end

-- Put up what `mode` needs and take down what it doesn't.
local function enter(mode)
    if mode == "standin" then raiseStandIn() else lowerStandIn() end
    NS.State.test = mode
end

local ev = NS.NewBusTarget()
TestMode.__ev = ev

local listen

local function stop(why)
    if not NS.State.test then return false end
    listen(false)
    lowerStandIn()
    NS.State.test = nil
    Preview.Hold("test", false)
    NS.Debug("Test", "off (%s)", why)
    -- Master controls' Test mode checkbox reads NS.State.test (settings/General.lua).
    if NS.RefreshOptionsPanel then NS.RefreshOptionsPanel() end
    return true
end

local function exit(why, line)
    if stop(why) then NS.Print(line) end
end

local function onCombat()
    exit("combat", L["Test mode off \226\128\148 combat started"])
end

-- The live switch: a party gets placeholders on its real frames, anything else the stand-in.
local function onRoster()
    local mode = modeFor()
    if mode == NS.State.test then return end
    enter(mode)
    NS.Debug("Test", "switched to %s", mode)
end

function listen(on)
    if on then
        ev:RegisterEvent("PLAYER_REGEN_DISABLED", onCombat)
        ev:RegisterEvent("GROUP_ROSTER_UPDATE", onRoster)
    else
        ev:UnregisterEvent("PLAYER_REGEN_DISABLED")
        ev:UnregisterEvent("GROUP_ROSTER_UPDATE")
    end
end

local function start()
    Preview.Hold("test", true)
    enter(modeFor())
    listen(true)
    NS.Debug("Test", "on (%s)", NS.State.test)
    if NS.RefreshOptionsPanel then NS.RefreshOptionsPanel() end
end

--- `/pfe test`: on (refused in combat, with the addon disabled, or during a perf-run suspend) or off.
--- Returns the line for the verb to print.
function TestMode.Toggle()
    if NS.State.test then
        stop("command")
        return L["Test mode off"]
    end
    if InCombatLockdown() then return gray(L["cannot start test mode during combat"]) end
    if NS.GetSetting("enabled") ~= true then
        return gray(L["cannot start test mode \226\128\148 the addon is disabled"])
    end
    if NS.Perf.suspended then
        return gray(L["cannot start test mode \226\128\148 a perf run has the addon suspended"])
    end
    start()
    if NS.State.test == "standin" then
        return L["Test mode on \226\128\148 a stand-in party frame is up; drag it to move it"]
    end
    return L["Test mode on \226\128\148 placeholders on your party frames"]
end

function TestMode:Suspend()
    exit("suspended", L["Test mode off \226\128\148 a perf run suspended the addon"])
end

local DISABLED = L["Test mode off \226\128\148 the addon was disabled"]

ev:RegisterMessage(NS.MSG.CONFIG, function(_, section)
    if not NS.State.test then return end
    if section == "master" and NS.GetSetting("enabled") ~= true then
        exit("disabled", DISABLED)
    elseif section == "general" and NS.State.test == "standin" then
        -- A Frame system change: the stand-in takes the new system's look and size.
        if (Providers.StandInSource()) ~= placedId then dress() end
    end
end)

ev:RegisterMessage(NS.MSG.PROFILE, function()
    if NS.State.test and NS.GetSetting("enabled") ~= true then exit("disabled", DISABLED) end
end)
