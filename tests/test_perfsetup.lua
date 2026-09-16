-- tests/test_perfsetup.lua — the LibKa0s-Perf-1.0 seam: the declared buckets, the suspend/resume
-- contract through the module registry, and the degraded arm.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local NS = T.NS

local loadDegraded = dofile("tests/degraded_env.lua")

local DECLARED = {
  "resolve", "anchor", "castEvent", "castRender", "castTick",
  "targetEvent", "targetTick", "targetRender", "petEvent", "reskin",
}

test("perfsetup: every bucket is declared, in report order", function()
  assertEqual(table.concat(NS.Perf.BUCKET_ORDER, ","), table.concat(DECLARED, ","))
end)

test("perfsetup: suspend and resume reach every registered module and republish visibility", function()
  local calls = {}
  local probe = {
    Suspend = function() calls[#calls + 1] = "suspend" end,
    Resume  = function() calls[#calls + 1] = "resume" end,
  }
  NS.RegisterModule(probe)
  local visibility = 0
  local target = NS.NewBusTarget()
  target:RegisterMessage(NS.MSG.VISIBILITY, function() visibility = visibility + 1 end)

  NS.lifecycle:Hold("perf")
  NS.lifecycle:Release("perf")

  target:UnregisterMessage(NS.MSG.VISIBILITY)
  table.remove(NS.Modules)
  assertEqual(table.concat(calls, ","), "suspend,resume")
  assertEqual(visibility, 2, "each half republishes VISIBILITY so ladders re-read Perf.suspended")
end)

test("perfsetup: `/pfe perf` answers lines to print", function()
  local lines = NS.Perf.OnCommand("")
  assertTrue(type(lines) == "table" and #lines > 0)
end)

test("perfsetup: live and stub both carry every Perf member the addon's source reads", function()
  -- Derived, not typed: every `Perf.<member>` (and `NS.Perf.<member>`) in the files the TOC loads,
  --   grep -ohE "Perf\.[A-Za-z_]+" $(files in PartyFrameEnhanced.toc)
  -- so a member a module starts reading joins this case in the commit that reads it.
  local Loader = dofile("tests/_kit/loader.lua")
  local used, n = {}, 0
  for _, path in ipairs(Loader.tocFiles("PartyFrameEnhanced.toc")) do
    local f = io.open(path, "r")
    local src = f:read("*a")
    f:close()
    for member in src:gmatch("Perf%.([%a_]+)") do
      if not used[member] then used[member] = true; n = n + 1 end
    end
  end
  assertTrue(n >= 3, "the derivation found only " .. n .. " members")
  local NS2 = loadDegraded()
  for member in pairs(used) do
    assertTrue(NS.Perf[member] ~= nil, "the live instance lacks Perf." .. member)
    assertTrue(NS2.Perf[member] ~= nil, "the degradation stub lacks Perf." .. member)
  end
end)

test("perfsetup: without LibKa0s the stub carries every member the addon calls", function()
  local NS2 = loadDegraded()
  assertEqual(NS2.Perf.on, false)
  assertEqual(NS2.Perf.suspended, false)
  NS2.Perf.Note("resolve", 1)
  local lines = NS2.Perf.OnCommand("")
  assertTrue(lines[1]:find("performance measurement is unavailable", 1, true) ~= nil)
end)
