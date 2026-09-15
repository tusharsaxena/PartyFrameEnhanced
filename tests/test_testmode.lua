-- tests/test_testmode.lua — `/pfe test` end to end (docs/superpowers/specs/2026-09-15-test-mode-design.md
-- §2): the two modes, the live switch, the refusals, every exit, the secure anchoring, and status.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local NS, mocks = T.NS, T.mocks
local StandIn, Providers = NS.StandIn, NS.Providers

local function slash(msg)
  local before = #mocks.__chat
  NS.Slash:OnSlash(msg)
  local out = {}
  for i = before + 1, #mocks.__chat do out[#out + 1] = mocks.__chat[i] end
  return table.concat(out, "\n")
end

-- The roster changes: the client fires GROUP_ROSTER_UPDATE to every listener. Bounded, because a
-- running health ticker re-queues itself.
local function world(inGroup, inRaid)
  mocks.__context.inGroup, mocks.__context.inRaid = inGroup, inRaid
  mocks.__fireEvent("GROUP_ROSTER_UPDATE")
  for _ = 1, 10 do if mocks.__fireTimers() == 0 then break end end
end

-- Every feature on and attached, locked, test mode off.
local function prep()
  if NS.State.test then NS.TestMode.Toggle() end
  local p = NS.db.profile
  p.enabled, p.visibility, p.locked = true, "always", true
  for _, key in ipairs({ "castbar", "target", "pet" }) do
    p[key].enabled, p[key].anchorMode = true, "attached"
  end
  NS.bus:SendMessage(NS.MSG.PROFILE)
end

local function off()
  if NS.State.test then NS.TestMode.Toggle() end
  world(true, false)
end

local function isOff()
  assertNil(NS.State.test)
  assertFalse(NS.State.preview, "the test hold is released")
  assertFalse(StandIn.IsShown(), "the stand-in is hidden")
  assertNil(Providers.FrameFor("party1"), "party1 is unmapped")
end

test("testmode: solo, /pfe test raises the stand-in in party1's place with placeholders; again ends it", function()
  prep()
  world(false, false)
  local out = slash("test")
  assertEqual(NS.State.test, "standin")
  assertTrue(NS.State.preview)
  assertTrue(StandIn.IsShown())
  assertEqual(Providers.FrameFor("party1"), StandIn.Frame())
  assertTrue(out:find("stand-in", 1, true) ~= nil)
  local bars = NS.CastBars.__bars
  assertEqual(bars.party1.__aTarget, StandIn.Frame(), "party1's cast bar is pinned to the stand-in")
  assertTrue(bars.party1:IsShown(), "and shows its placeholder")
  assertTrue(slash("test"):find("Test mode off", 1, true) ~= nil)
  isOff()
  off()
end)

test("testmode: in a party, /pfe test is placeholders on the real frames and no stand-in", function()
  prep()
  world(true, false)
  local out = slash("test")
  assertEqual(NS.State.test, "party")
  assertTrue(NS.State.preview)
  assertFalse(StandIn.IsShown())
  assertTrue(out:find("your party frames", 1, true) ~= nil)
  off()
end)

test("testmode: in a raid it is the stand-in too", function()
  prep()
  world(true, true)
  slash("test")
  assertEqual(NS.State.test, "standin")
  assertEqual(Providers.FrameFor("party1"), StandIn.Frame())
  off()
end)

test("testmode: it switches live — joining hides the stand-in, leaving brings it back, it stays on", function()
  prep()
  world(false, false)
  slash("test")
  world(true, false)
  assertEqual(NS.State.test, "party")
  assertFalse(StandIn.IsShown())
  assertNil(Providers.FrameFor("party1"))
  assertTrue(NS.State.preview, "the placeholders stay")
  world(false, false)
  assertEqual(NS.State.test, "standin")
  assertTrue(StandIn.IsShown())
  assertEqual(Providers.FrameFor("party1"), StandIn.Frame())
  off()
end)

test("testmode: refused in combat, disabled or suspended — one gray line each, nothing changes", function()
  prep()
  world(false, false)
  mocks.InCombatLockdown = function() return true end
  local out = slash("test")
  mocks.InCombatLockdown = function() return false end
  assertTrue(out:find("cannot start test mode during combat", 1, true) ~= nil)
  assertTrue(out:find("|cff808080", 1, true) ~= nil, "gray")
  isOff()
  NS.db.profile.enabled = false
  assertTrue(slash("test"):find("the addon is disabled", 1, true) ~= nil)
  NS.db.profile.enabled = true
  isOff()
  NS.Perf.suspended = true
  assertTrue(slash("test"):find("suspended", 1, true) ~= nil)
  NS.Perf.suspended = false
  isOff()
  off()
end)

for _, solo in ipairs({ true, false }) do
  test(("testmode: combat ends it at PLAYER_REGEN_DISABLED (%s)"):format(solo and "stand-in" or "party"),
      function()
    prep()
    world(not solo, false)
    slash("test")
    local before = #mocks.__chat
    mocks.__fireEvent("PLAYER_REGEN_DISABLED")
    local said = table.concat(mocks.__chat, "\n", before + 1)
    mocks.__fireEvent("PLAYER_REGEN_ENABLED")
    assertTrue(said:find("combat started", 1, true) ~= nil)
    assertNil(NS.State.test)
    assertFalse(NS.State.preview)
    assertFalse(StandIn.IsShown())
    off()
  end)
end

test("testmode: the master switch going off ends it", function()
  prep()
  world(false, false)
  slash("test")
  local before = #mocks.__chat
  NS.SetByPath("enabled", false)
  local said = table.concat(mocks.__chat, "\n", before + 1)
  NS.SetByPath("enabled", true)
  assertTrue(said:find("the addon was disabled", 1, true) ~= nil)
  isOff()
  off()
end)

test("testmode: a perf-run suspend ends it, and the stand-in leaves the map at once", function()
  prep()
  world(false, false)
  slash("test")
  NS.SuspendAll()
  isOff()
  NS.ResumeAll()
  off()
end)

test("testmode: party1's target button pins to the stand-in, and after the stop its driver hides it", function()
  prep()
  world(false, false)
  local btn = NS.TargetFrames.__buttons.party1
  slash("test")
  assertEqual(btn.__aTarget, StandIn.Frame())
  assertEqual(btn.__drivers.visibility, "show")
  slash("test")
  assertEqual(btn.__drivers.visibility, "hide")
  mocks.__runStateDrivers()
  assertFalse(btn:IsShown())
  off()
end)

test("testmode: unlock creates no stand-in", function()
  prep()
  world(false, false)
  slash("unlock")
  assertFalse(StandIn.IsShown())
  assertNil(Providers.FrameFor("party1"))
  slash("lock")
  off()
end)

test("testmode: a Frame system change re-dresses the stand-in", function()
  prep()
  world(false, false)
  mocks.EditModeManagerFrame = { UseRaidStylePartyFrames = function() return false end }
  slash("test")
  assertEqual(StandIn.Frame().__placed.id, "blizzard-party")
  NS.SetByPath("general.provider", "ellesmere")
  assertEqual(StandIn.Frame().__placed.id, "ellesmere")
  NS.SetByPath("general.provider", "auto")
  mocks.EditModeManagerFrame = nil
  off()
end)

test("testmode: status names the mode, and the verb is in NS.COMMANDS", function()
  prep()
  world(false, false)
  slash("test")
  local out = slash("status")
  assertTrue(out:find("test mode on (stand-in)", 1, true) ~= nil)
  assertFalse(out:find("not in a party", 1, true) ~= nil, "test mode replaces the hint")
  off()
  slash("test")
  assertTrue(slash("status"):find("test mode on (your party frames)", 1, true) ~= nil)
  off()
  local have = false
  for _, e in ipairs(NS.COMMANDS) do if e[1] == "test" then have = true end end
  assertTrue(have)
end)
