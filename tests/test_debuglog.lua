-- tests/test_debuglog.lua — the LibKa0s-DebugLog-1.0 seam: the flag is ours and session-only, and
-- the degraded arm still flips it and says so.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local NS = T.NS

local loadDegraded = dofile("tests/degraded_env.lua")

test("debuglog: NS.Debug is the instance's gated sink, bound bare", function()
  assertTrue(NS.Debug == NS.DebugLog.Debug)
end)

test("debuglog: enabling logging flips NS.State.debug and writes nothing to the profile", function()
  -- debug-logging-§5: session-only, never in SV.
  NS.DebugLog:SetEnabled(true)
  assertTrue(NS.State.debug, "the addon's own flag is on")
  NS.DebugLog:SetEnabled(false)
  assertFalse(NS.State.debug)
  for key in pairs(NS.db.profile) do
    assertFalse(key:lower():find("debug", 1, true), "no debug key in the profile: " .. key)
  end
end)

test("debuglog: without LibKa0s, `debug on` still sets the flag and acknowledges it", function()
  local NS2, mocks2 = loadDegraded()
  NS2.DebugLog:SetEnabled(true)
  assertTrue(NS2.State.debug)
  local acked = false
  for _, line in ipairs(mocks2.__chat) do
    if line:find("debug logging", 1, true) then acked = true end
  end
  assertTrue(acked, "the player is told the flag changed")
  assertEqual(NS2.Debug("Tag", "fmt"), nil, "the sink is a harmless no-op")
end)
