-- tests/test_lifecycle.lua — the combat flag, the deferred secure-write queue, and the
-- blocked-action breadcrumb in core/PartyFrameEnhanced.lua.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local NS, mocks = T.NS, T.mocks

local function inCombat(on)
  mocks.InCombatLockdown = function() return on end
end

test("lifecycle: a secure write out of combat runs at once", function()
  inCombat(false)
  local ran = false
  assertTrue(NS.RunSecure("probe", function() ran = true end))
  assertTrue(ran)
end)

test("lifecycle: in combat a secure write queues, the same key replaces, and regen flushes in order", function()
  -- red under: running the write in lockdown (the client blocks it and blames the addon), or
  -- flushing each queued write per key instead of the latest one.
  inCombat(true)
  local log = {}
  assertFalse(NS.RunSecure("a", function() log[#log + 1] = "a1" end))
  NS.RunSecure("b", function() log[#log + 1] = "b" end)
  NS.RunSecure("a", function() log[#log + 1] = "a2" end)
  assertEqual(#log, 0, "nothing ran in lockdown")
  assertEqual(NS.PendingSecureCount(), 2, "two keys pending")
  inCombat(false)
  NS.addon:OnLeaveCombat()
  assertEqual(table.concat(log, ","), "a2,b", "the latest write per key, in first-queued order")
  assertEqual(NS.PendingSecureCount(), 0)
end)

test("lifecycle: the regen events drive NS.State.inCombat and republish visibility", function()
  local n = 0
  local target = NS.NewBusTarget()
  target:RegisterMessage(NS.MSG.VISIBILITY, function() n = n + 1 end)
  NS.addon:OnEnterCombat()
  assertTrue(NS.State.inCombat)
  NS.addon:OnLeaveCombat()
  assertFalse(NS.State.inCombat)
  target:UnregisterMessage(NS.MSG.VISIBILITY)
  assertEqual(n, 2)
end)

test("lifecycle: a blocked action blamed on this addon is logged, ungated", function()
  local before = NS.DebugLog:BufferSize()
  NS.addon:OnActionBlocked("ADDON_ACTION_BLOCKED", "PartyFrameEnhanced", "SetPoint")
  NS.addon:OnActionBlocked("ADDON_ACTION_BLOCKED", "SomeOtherAddon", "Show")
  assertEqual(NS.DebugLog:BufferSize(), before + 1, "ours logged, another addon's ignored")
end)
