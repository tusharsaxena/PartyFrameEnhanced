-- tests/test_envsetup.lua — the LibKa0s-Env-1.0 seam: NS.Meta and NS.Version, live and with the
-- library absent (a real library-absent load, testing-§8).

local T = _G.PFE_TEST
local test, assertEqual, assertNil = T.test, T.assertEqual, T.assertNil
local NS = T.NS

local loadDegraded = dofile("tests/degraded_env.lua")

test("envsetup: NS.Version never answers nil — the fallback constant when no reader answers", function()
  -- The harness has no metadata reader, which is exactly a client the library cannot read from.
  assertEqual(NS.Version(), NS.version)
end)

test("envsetup: without LibKa0s, Meta and Version read C_AddOns, then fall back to NS.version", function()
  local NS2, mocks2 = loadDegraded()
  assertNil(NS2.Meta("Version"), "no reader at all answers nil")
  assertEqual(NS2.Version(), "1.0.0", "and Version falls back to the constant")
  mocks2.C_AddOns = { GetAddOnMetadata = function(name, field)
    if name == "PartyFrameEnhanced" and field == "Version" then return "9.9.9" end
  end }
  assertEqual(NS2.Meta("Version"), "9.9.9", "the degraded ladder reads C_AddOns with our folder name")
  assertEqual(NS2.Version(), "9.9.9")
  mocks2.C_AddOns = nil
end)
