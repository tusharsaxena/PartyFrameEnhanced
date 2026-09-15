-- tests/test_party.lua — the party-only rule (docs/superpowers/specs/2026-09-15-test-mode-design.md §1):
-- NS.Units.InParty, and what solo, a raid and a party each show and register.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local NS, mocks = T.NS, T.mocks

test("party: InParty is a party of 2-5 — not solo, not a raid", function()
  local ctx = mocks.__context
  ctx.inGroup, ctx.inRaid = false, false
  assertFalse(NS.Units.InParty(), "solo")
  ctx.inGroup, ctx.inRaid = true, true
  assertFalse(NS.Units.InParty(), "a raid")
  ctx.inGroup, ctx.inRaid = true, false
  assertTrue(NS.Units.InParty(), "a party")
  assertEqual(type(NS.Units.InParty()), "boolean")
end)

local function slash(msg)
  local before = #mocks.__chat
  NS.Slash:OnSlash(msg)
  local out = {}
  for i = before + 1, #mocks.__chat do out[#out + 1] = mocks.__chat[i] end
  return table.concat(out, "\n")
end

-- The roster changes: the client fires GROUP_ROSTER_UPDATE to every listener.
local function world(inGroup, inRaid)
  mocks.__context.inGroup, mocks.__context.inRaid = inGroup, inRaid
  mocks.__fireEvent("GROUP_ROSTER_UPDATE")
end

-- Every feature on and in free placement, locked: the show decision then needs no party frame.
local function prepFree()
  local p = NS.db.profile
  p.enabled, p.visibility, p.locked = true, "always", true
  for _, key in ipairs({ "castbar", "target", "pet" }) do
    p[key].enabled, p[key].anchorMode, p[key].fadeOut = true, "free", false
  end
  NS.bus:SendMessage(NS.MSG.PROFILE)
end

local function nothingRegistered(el) return next(el.__unitEvents) == nil end

for _, where in ipairs({ { "solo", false, false }, { "in a raid", true, true } }) do
  test(("party: %s, nothing shows — free placement included — and no unit events are registered")
      :format(where[1]), function()
    prepFree()
    mocks.__casts.party1 = { kind = "cast", name = "Heal" }
    world(where[2], where[3])
    local bar = NS.CastBars.__bars.party1
    local tgt, pet = NS.TargetFrames.__buttons.party1, NS.PetFrames.__buttons.party1
    assertFalse(bar:IsShown(), "the cast bar")
    assertEqual(tgt.__drivers.visibility, "hide")
    assertEqual(pet.__drivers.visibility, "hide")
    assertTrue(nothingRegistered(bar) and nothingRegistered(tgt) and nothingRegistered(pet))
    assertFalse(NS.TargetFrames.TickerRunning())
    -- Back in a party, the same setup shows and listens.
    world(true, false)
    assertEqual(bar.__unitEvents.UNIT_SPELLCAST_START[1], "party1")
    assertTrue(bar:IsShown(), "casting, in free placement")
    assertEqual(tgt.__drivers.visibility, "[@party1target,exists] show; hide")
    mocks.__casts.party1 = nil
    bar:__fire("OnEvent", "UNIT_SPELLCAST_STOP", "party1")
  end)
end

test("party: a roster change republishes VISIBILITY only when the party answer flips", function()
  world(true, false)
  local n = 0
  local t = NS.NewBusTarget()
  t:RegisterMessage(NS.MSG.VISIBILITY, function() n = n + 1 end)
  NS.addon:OnRosterUpdate()
  assertEqual(n, 0, "the same answer sends nothing")
  world(false, false)
  assertEqual(n, 1)
  t:UnregisterMessage(NS.MSG.VISIBILITY)
  world(true, false)
end)

test("party: preview skips the rule — unlocked solo, the free-placement placeholders show", function()
  prepFree()
  world(false, false)
  NS.SetByPath("locked", false)
  assertTrue(NS.CastBars.__bars.party1:IsShown())
  assertEqual(NS.TargetFrames.__buttons.party1.__drivers.visibility, "show")
  NS.SetByPath("locked", true)
  world(true, false)
end)

test("party: /pfe status says so when you're not in a party", function()
  world(false, false)
  local out = slash("status")
  world(true, false)
  assertTrue(out:find("not in a party", 1, true) ~= nil)
  assertFalse(slash("status"):find("not in a party", 1, true) ~= nil, "in a party it is quiet")
end)
