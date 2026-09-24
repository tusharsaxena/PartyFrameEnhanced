-- tests/test_preview_standin.lua — preview end to end, with the LOCK as its only switch
-- (options-ui-§15): the two shapes preview takes, the live switch between them, the refusals, every
-- exit, the secure anchoring, and status.
--
-- This suite is tests/test_testmode.lua rehomed. That file drove `/pfe test`; the verb and the
-- Master controls Test mode row are gone, because §15 exempts an addon whose unlocked view already
-- IS its preview and anti-pattern #80 makes the duplicate switch the finding. Every case here is the
-- same behavior reached through `/pfe unlock` — except "unlock creates no stand-in", which INVERTED
-- and is now the central claim: unlocking out of a party is what raises the stand-in at all.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local NS, mocks = T.NS, T.mocks
local StandIn, Providers = NS.StandIn, NS.Providers

--- Everything the addon printed while `fn` ran, joined.
local function capture(fn)
  local before = #mocks.__chat
  fn()
  local out = {}
  for i = before + 1, #mocks.__chat do out[#out + 1] = mocks.__chat[i] end
  return table.concat(out, "\n")
end

local function slash(msg) return capture(function() NS.Slash:OnSlash(msg) end) end

-- The roster changes: the client fires GROUP_ROSTER_UPDATE to every listener. Bounded, because a
-- running health ticker re-queues itself.
local function world(inGroup, inRaid)
  mocks.__context.inGroup, mocks.__context.inRaid = inGroup, inRaid
  mocks.__fireEvent("GROUP_ROSTER_UPDATE")
  for _ = 1, 10 do if mocks.__fireTimers() == 0 then break end end
end

-- Every feature on and attached, and LOCKED — which is now the same statement as "preview off".
local function prep()
  local p = NS.db.profile
  p.enabled, p.visibility, p.locked = true, "always", true
  for _, key in ipairs({ "castbar", "target", "pet" }) do
    p[key].enabled, p[key].anchorMode = true, "attached"
  end
  NS.bus:SendMessage(NS.MSG.PROFILE)
end

local function off()
  NS.SetByPath("locked", true)
  world(true, false)
end

local function isOff()
  assertFalse(NS.State.preview, "preview is off")
  assertTrue(NS.GetSetting("locked"), "because the elements are locked")
  assertFalse(StandIn.IsShown(), "the stand-in is hidden")
  assertNil(Providers.FrameFor("party1"), "party1 is unmapped")
end

test("preview: solo, unlocking raises the stand-in in party1's place; locking ends it", function()
  prep()
  world(false, false)
  slash("unlock")
  assertTrue(NS.State.preview)
  assertTrue(StandIn.IsShown())
  assertEqual(Providers.FrameFor("party1"), StandIn.Frame())
  local bars = NS.CastBars.__bars
  assertEqual(bars.party1.__aTarget, StandIn.Frame(), "party1's cast bar is pinned to the stand-in")
  assertTrue(bars.party1:IsShown(), "and shows its placeholder")
  slash("lock")
  isOff()
  off()
end)

test("preview: in a party, unlocking is placeholders on the real frames and no stand-in", function()
  prep()
  world(true, false)
  slash("unlock")
  assertTrue(NS.State.preview)
  assertFalse(StandIn.IsShown(), "the real party frames carry the placeholders")
  off()
end)

test("preview: in a raid it is the stand-in too", function()
  prep()
  world(true, true)
  slash("unlock")
  assertTrue(StandIn.IsShown())
  assertEqual(Providers.FrameFor("party1"), StandIn.Frame())
  off()
end)

test("preview: it switches live — joining hides the stand-in, leaving brings it back, it stays on",
    function()
  prep()
  world(false, false)
  slash("unlock")
  world(true, false)
  assertFalse(StandIn.IsShown())
  assertNil(Providers.FrameFor("party1"))
  assertTrue(NS.State.preview, "the placeholders stay; only their target moved")
  world(false, false)
  assertTrue(StandIn.IsShown())
  assertEqual(Providers.FrameFor("party1"), StandIn.Frame())
  off()
end)

-- The three refusals came off the removed Test mode row, which would not start under any of them.
-- They live on the `locked` row's validate now, so they reach every writer of it.
test("preview: unlocking is refused in combat, disabled or suspended — one line each", function()
  prep()
  world(false, false)
  mocks.InCombatLockdown = function() return true end
  local out = slash("unlock")
  mocks.InCombatLockdown = function() return false end
  assertTrue(out:find("cannot unlock during combat", 1, true) ~= nil, out)
  assertTrue(out:find("|cff808080", 1, true) ~= nil, "gray")
  isOff()
  -- The disabled arm arrives at the SEAM rather than through `/pfe unlock`. Since slash-commands-§2's
  -- gate landed, the dispatcher refuses a feature verb before the seam is entered at all — that
  -- refusal is its own claim and is pinned in tests/test_slash.lua. The Lock frame checkbox still
  -- reaches here, and what NS.AcceptLock does with it is what this case is about.
  NS.db.profile.enabled = false
  local refusal = capture(function() NS.SetByPath("locked", false) end)
  -- The collection's one refusal line (slash-commands-§7), byte for byte what the slash gate prints
  -- for a refused verb: the Lock frame row MUST NOT re-spell it in its own gray wording.
  assertEqual(refusal, slash("unlock"), "the disabled refusal is the gate's line")
  assertTrue(refusal:find(NS.Slash.__cli:DisabledLine(), 1, true) ~= nil, refusal)
  assertTrue(refusal:find("|cff808080", 1, true) == nil, "not gray")
  NS.db.profile.enabled = true
  isOff()
  NS.lifecycle:Hold("perf")
  assertTrue(slash("unlock"):find("suspended", 1, true) ~= nil)
  NS.lifecycle:Release("perf")
  isOff()
  off()
end)

test("preview: locking is never refused, so a refusal cannot strand the elements unlocked", function()
  prep()
  world(false, false)
  slash("unlock")
  mocks.InCombatLockdown = function() return true end
  NS.SetByPath("locked", true)
  mocks.InCombatLockdown = function() return false end
  assertTrue(NS.GetSetting("locked"), "locking in combat must always be allowed")
  assertFalse(NS.State.preview)
  off()
end)

for _, solo in ipairs({ true, false }) do
  test(("preview: combat re-locks at PLAYER_REGEN_DISABLED (%s)"):format(solo and "stand-in" or "party"),
      function()
    prep()
    world(not solo, false)
    slash("unlock")
    local before = #mocks.__chat
    mocks.__fireEvent("PLAYER_REGEN_DISABLED")
    local said = table.concat(mocks.__chat, "\n", before + 1)
    mocks.__fireEvent("PLAYER_REGEN_ENABLED")
    assertTrue(said:find("combat started", 1, true) ~= nil, said)
    assertTrue(NS.GetSetting("locked"), "the fight starts locked, on live data")
    assertFalse(NS.State.preview)
    assertFalse(StandIn.IsShown())
    off()
  end)
end

test("preview: the master switch going off re-locks", function()
  prep()
  world(false, false)
  slash("unlock")
  local before = #mocks.__chat
  NS.SetByPath("enabled", false)
  local said = table.concat(mocks.__chat, "\n", before + 1)
  NS.SetByPath("enabled", true)
  assertTrue(said:find("the addon was disabled", 1, true) ~= nil, said)
  isOff()
  off()
end)

test("preview: a perf-run suspend re-locks, and the stand-in leaves the map at once", function()
  prep()
  world(false, false)
  slash("unlock")
  NS.lifecycle:Hold("perf")
  isOff()
  NS.lifecycle:Release("perf")
  off()
end)

test("preview: party1's target button pins to the stand-in, and after the lock its driver hides it",
    function()
  prep()
  world(false, false)
  local btn = NS.TargetFrames.__buttons.party1
  slash("unlock")
  assertEqual(btn.__aTarget, StandIn.Frame())
  assertEqual(btn.__drivers.visibility, "show")
  slash("lock")
  assertEqual(btn.__drivers.visibility, "hide")
  mocks.__runStateDrivers()
  assertFalse(btn:IsShown())
  off()
end)

-- THE INVERSION. This case read "unlock creates no stand-in" while test mode existed, and moving
-- that capability onto the lock is the whole of what made removing the row free.
test("preview: unlocking out of a party is what creates the stand-in", function()
  prep()
  world(false, false)
  assertFalse(StandIn.IsShown(), "locked, there is nothing up")
  slash("unlock")
  assertTrue(StandIn.IsShown(), "unlocked out of a party, the stand-in is how there is anything to place")
  assertEqual(Providers.FrameFor("party1"), StandIn.Frame())
  slash("lock")
  assertFalse(StandIn.IsShown())
  off()
end)

test("preview: a Frame system change re-dresses the stand-in", function()
  prep()
  world(false, false)
  mocks.EditModeManagerFrame = { UseRaidStylePartyFrames = function() return false end }
  slash("unlock")
  assertEqual(StandIn.Frame().__placed.id, "blizzard-party")
  NS.SetByPath("general.provider", "ellesmere")
  assertEqual(StandIn.Frame().__placed.id, "ellesmere")
  NS.SetByPath("general.provider", "auto")
  mocks.EditModeManagerFrame = nil
  off()
end)

test("preview: with Match party frame width, party1's cast bar pins both edges to the stand-in",
    function()
  -- Evidence for the in-game report that the preview bar looked narrower than the frame: the width
  -- comes from the two edge anchors, so the whole bar spans the stand-in.
  prep()
  NS.db.profile.castbar.matchWidth = true
  NS.bus:SendMessage(NS.MSG.PROFILE)
  world(false, false)
  slash("unlock")
  local bar = NS.CastBars.__bars.party1
  assertEqual(bar.__aTarget, StandIn.Frame())
  assertTrue(bar.__aMatch, "both edges pinned: the width is the stand-in's")
  off()
  NS.db.profile.castbar.matchWidth = nil
end)

test("preview: the placeholder cast is drawn full, so the whole bar shows", function()
  -- red under: a part-filled placeholder, whose dark remainder reads as "not the bar".
  prep()
  world(false, false)
  slash("unlock")
  assertEqual(NS.CastBars.__bars.party1.bar.__value, 1)
  off()
end)

test("preview: Lock frame is the switch, and no Test mode row survives beside it", function()
  -- options-ui-§15: the exemption is the absence of the row, so it is asserted rather than inferred
  -- from a count. red under: the composed row creeping back with a `testModePath`.
  prep()
  world(false, false)
  assertNil(NS.FindSchemaRow("state.testMode"), "the Test mode row must not come back")
  local row = NS.FindSchemaRow("locked")
  assertTrue(row ~= nil, "Lock frame is the row that does the job")
  assertEqual(row.group, "Master controls")
  NS.SetByPath("locked", false)
  assertTrue(NS.State.preview, "and writing it is what turns preview on")
  assertTrue(StandIn.IsShown())
  off()
end)

test("preview: status names what preview is showing, and neither verb survives in NS.COMMANDS",
    function()
  prep()
  world(false, false)
  slash("unlock")
  local out = slash("status")
  assertTrue(out:find("unlocked (stand-in)", 1, true) ~= nil, out)
  assertFalse(out:find("not in a party", 1, true) ~= nil, "preview replaces the hint")
  off()
  world(true, false)
  slash("unlock")
  assertTrue(slash("status"):find("unlocked (your party frames)", 1, true) ~= nil)
  off()
  for _, e in ipairs(NS.COMMANDS) do
    assertTrue(e[1] ~= "test", "/pfe test went with the Test mode row")
    assertTrue(e[1] ~= "preview", "/pfe preview was removed before it")
  end
end)
