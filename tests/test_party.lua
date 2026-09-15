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
