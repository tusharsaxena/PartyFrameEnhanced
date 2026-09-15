-- tests/degraded_env.lua — builds a SECOND addon environment with LibKa0s absent.
--
-- The only honest way to exercise the setup files' degradation stubs is a real load without the
-- library (testing-§8): nothing from libs/LibKa0s is loaded, so every major is unregistered and the
-- mock's LibStub answers nil exactly as the client would. The list is the TOC's whole list, in its
-- order — a list that stopped before the page files would stay green through a total load failure.
-- Not a suite; callers dofile it like tests/wow_mock.lua.
return function()
  local Loader     = dofile("tests/_kit/loader.lua")
  local buildMocks = dofile("tests/wow_mock.lua")
  Loader.addonName = "PartyFrameEnhanced"
  local mocks2, NS2 = buildMocks(), {}
  Loader.loadAll(Loader.tocFiles("PartyFrameEnhanced.toc"), NS2, mocks2)
  return NS2, mocks2
end
