-- tests/test_optionssetup.lua — settings/OptionsSetup.lua as a FILE: the global reset's veto on both
-- builds, and the degraded stub's load-completing member set with its measured schema counts.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local NS = T.NS

local loadDegraded = dofile("tests/degraded_env.lua")

-- Which rows a build's Reset All leaves untouched, as sorted paths. Probe rows make the case
-- non-vacuous: no shipping row is on the profiles page, and only the console row is session-only.
local function vetoedByResetAll(ns, restoreAll)
  local n = #ns.Schema
  table.insert(ns.Schema, { page = "profiles", path = "__probe.onProfilesPage", type = "bool" })
  table.insert(ns.Schema, { page = "general", path = "__probe.onGeneralPage", type = "bool" })
  table.insert(ns.Schema, { page = "general", path = "__probe.sessionOnly", type = "bool",
                            sessionOnly = true })
  local touched = {}
  local orig = ns.ApplyDefault
  ns.ApplyDefault = function(row) touched[row.path] = true end
  local ok, err = pcall(restoreAll)
  ns.ApplyDefault = orig
  local vetoed = {}
  for _, row in ipairs(ns.Schema) do
    if row.path:find("^__probe") and not touched[row.path] then vetoed[#vetoed + 1] = row.path end
  end
  for i = #ns.Schema, n + 1, -1 do ns.Schema[i] = nil end
  if not ok then error(err, 0) end
  table.sort(vetoed)
  return table.concat(vetoed, ",")
end

test("optionssetup: the live and degraded builds veto the same rows from Reset All", function()
  -- red under: a veto that spares only the profiles page, or one that vetoes the session rows too.
  local NS2 = loadDegraded()
  local live = vetoedByResetAll(NS, NS.Helpers.RestoreAllDefaults)
  local degraded = vetoedByResetAll(NS2, NS2.Helpers.RestoreAllDefaults)
  assertEqual(live, "__probe.onGeneralPage,__probe.onProfilesPage",
    "profile-backed rows are vetoed (the profile reset covers them); the session row is swept")
  assertEqual(degraded, live)
  T.mocks.__fireTimers()
end)

-- The degraded load's schema, measured. The composers are HOLLOW in the stub (options-ui-§1: the
-- no-copy MUST wins), so the gap between the two counts is exactly the composed rows, attributed here
-- composer by composer. A page file that raised at load would show up as a larger gap.
local COMPOSED = {
  MasterControls = 6,   -- settings/General.lua
}

test("optionssetup: the degraded load registers every host-declared row; the gap is the composers'", function()
  local NS2 = loadDegraded()
  local composed = 0
  for _, n in pairs(COMPOSED) do composed = composed + n end
  assertEqual(#NS.Schema, 8, "the fully loaded schema")
  assertEqual(#NS2.Schema, 2, "the library-absent schema")
  assertEqual(#NS.Schema - #NS2.Schema, composed, "the gap is exactly the hollow composers' rows")
end)

test("optionssetup: the stub publishes every member a page file touches at load", function()
  local NS2 = loadDegraded()
  for _, name in ipairs({ "LSMValues", "ColorPair", "FontGroup", "BorderGroup", "BarGroup",
                          "MasterControls", "RestoreAllDefaults" }) do
    assertTrue(type(NS2.Helpers[name]) == "function", "stub member missing: " .. name)
  end
  assertEqual(NS2.Helpers.MASTER_GROUP, "Master controls")
  assertTrue(type(NS2.Helpers.LSMValues("statusbar")) == "function",
    "LSMValues answers a function, never a table frozen at load")
end)

test("optionssetup: without the library, opening the panel prints one honest line", function()
  local NS2, mocks2 = loadDegraded()
  NS2.OpenOptionsPanel()
  assertTrue(mocks2.__chat[#mocks2.__chat]:find("settings panel is unavailable", 1, true) ~= nil)
  assertFalse(pcall(error, "sentinel"), "sanity")
end)
