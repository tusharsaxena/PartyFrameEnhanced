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
  MasterControls = 7,   -- settings/General.lua: the seven canonical rows -- six, plus the Minimap
                        -- button row the compose-minor-7 `minimapPath` seam emits (launcher-§3).
                        -- NOT eight: options-ui-§15 exempts this addon from Test mode, its unlocked
                        -- view being its preview.
  CastBarsBar    = 4,   -- settings/CastBars.lua: BarGroup (Fill)
  CastBarsBg     = 2,   --   ColorPair (Background)
  CastBarsBorder = 5,   --   BorderGroup, with Show border
  CastBarsFont   = 6,   --   FontGroup
  TargetFrames   = 17,  -- settings/TargetFrames.lua: BarGroup 4, ColorPair 2, BorderGroup 5, FontGroup 6
  PetFrames      = 17,  -- settings/PetFrames.lua: the same four blocks
}

test("optionssetup: the degraded load registers every host-declared row; the gap is the composers'", function()
  local NS2 = loadDegraded()
  local composed = 0
  for _, n in pairs(COMPOSED) do composed = composed + n end
  assertEqual(#NS.Schema, 121, "the fully loaded schema")
  assertEqual(#NS2.Schema, 63, "the library-absent schema")
  assertEqual(#NS.Schema - #NS2.Schema, composed, "the gap is exactly the hollow composers' rows")
end)

-- A row's dimming as the library evaluates it: `disabledIf(row)`, absent meaning never dimmed.
local function rowsByPath(page)
  local out = {}
  for _, row in ipairs(NS.SchemaForPage(page)) do
    if row.path then out[row.path] = row end
  end
  return out
end

local function dimmed(rows, path)
  local cond = rows[path].disabledIf
  return cond ~= nil and cond(rows[path]) == true
end

test("optionssetup: every feature page has a Size & Position tab that opens with Size", function()
  local L = NS.L
  for _, page in ipairs({ "castbar", "target", "pet" }) do
    local tab = {}
    for _, row in ipairs(NS.SchemaForPage(page)) do
      assertTrue(row.group ~= L["Position"], page .. ": no tab is still called Position")
      if row.group == L["Size & Position"] then tab[#tab + 1] = row end
    end
    assertEqual(tab[1].path, page .. ".width", page .. ": Width opens the tab")
    assertEqual(tab[1].subgroup, L["Size"])
    assertEqual(tab[2].path, page .. ".height")
    assertEqual(tab[3].subgroup, L["Placement"], page .. ": placement follows the size")
  end
end)

test("optionssetup: the placement block the anchor mode does not use is dimmed, and Width with Match width", function()
  local rows = rowsByPath("castbar")
  NS.SetByPath("castbar.anchorMode", "attached")
  NS.SetByPath("castbar.matchWidth", false)
  for _, path in ipairs({ "castbar.matchWidth", "castbar.point", "castbar.relativePoint",
                          "castbar.offsetX", "castbar.offsetY", "castbar.width", "castbar.height" }) do
    T.assertFalse(dimmed(rows, path), "attached: " .. path .. " is live")
  end
  T.assertTrue(dimmed(rows, "castbar.growth"), "attached: the free stack is dimmed")
  T.assertTrue(dimmed(rows, "castbar.spacing"))
  NS.SetByPath("castbar.matchWidth", true)
  T.assertTrue(dimmed(rows, "castbar.width"), "the party frame sets the width, so Width is dimmed")

  NS.SetByPath("castbar.anchorMode", "free")
  for _, path in ipairs({ "castbar.matchWidth", "castbar.point", "castbar.relativePoint",
                          "castbar.offsetX", "castbar.offsetY" }) do
    T.assertTrue(dimmed(rows, path), "free: " .. path .. " is dimmed")
  end
  T.assertFalse(dimmed(rows, "castbar.growth"), "free: the stack is live")
  T.assertFalse(dimmed(rows, "castbar.spacing"))
  T.assertFalse(dimmed(rows, "castbar.width"), "free placement always uses Width")
  NS.ApplyDefault(rows["castbar.anchorMode"])
  NS.ApplyDefault(rows["castbar.matchWidth"])
  T.mocks.__fireTimers()
end)

test("optionssetup: one Health updates tab drives both features; health rows dim with it, marker rows with the marker", function()
  local L = NS.L
  local general, target, pet = rowsByPath("general"), rowsByPath("target"), rowsByPath("pet")
  T.assertEqual(general["general.updateHealth"].group, L["Health updates"], "on the General page's own tab")
  T.assertEqual(general["general.tickInterval"].group, L["Health updates"])
  for _, path in ipairs({ "target.updateHealth", "target.tickInterval", "pet.updateHealth" }) do
    T.assertTrue(NS.FindSchemaRow(path) == nil, path .. " is gone: one shared setting, not one per page")
  end
  NS.SetByPath("general.updateHealth", false)
  T.assertTrue(dimmed(general, "general.tickInterval"))
  T.assertTrue(dimmed(target, "target.showPercent"))
  T.assertTrue(dimmed(pet, "pet.showPercent"))
  NS.SetByPath("general.updateHealth", true)
  T.assertFalse(dimmed(general, "general.tickInterval"))
  T.assertFalse(dimmed(pet, "pet.showPercent"))

  NS.SetByPath("target.showMarker", false)
  for _, path in ipairs({ "target.markerPoint", "target.markerOffsetX", "target.markerOffsetY" }) do
    T.assertTrue(dimmed(target, path), path .. " dims with the marker off")
  end
  NS.SetByPath("target.showMarker", true)
  T.assertFalse(dimmed(target, "target.markerPoint"))
  T.mocks.__fireTimers()
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

test("optionssetup: Reset All resets the active profile only — the list and the active profile stay", function()
  -- options-ui-§12 Testing: prove the blast radius, not the mechanism.
  local db = NS.db
  local current = db:GetCurrentProfile()
  db:SetProfile("SecondProfile")
  db:SetProfile(current)
  local function profileList()
    local list = {}
    for _, name in ipairs(db:GetProfiles()) do list[#list + 1] = name end
    table.sort(list)
    return table.concat(list, ",")
  end
  local listBefore = profileList()
  NS.SetByPath("general.provider", "blizzard")
  NS.SetByPath("castbar.height", 30)
  NS.SetByPath("state.debugConsole", true)
  local profiles = 0
  local target = NS.NewBusTarget()
  target:RegisterMessage(NS.MSG.PROFILE, function() profiles = profiles + 1 end)

  NS.Helpers.RestoreAllDefaults()

  target:UnregisterMessage(NS.MSG.PROFILE)
  assertEqual(NS.GetSetting("general.provider"), "auto", "profile rows are back at their defaults")
  assertEqual(NS.GetSetting("castbar.height"), 16)
  -- The console row carries no default (a session window, not a setting), so the walk leaves it.
  assertTrue(NS.GetSetting("state.debugConsole"), "an open console stays open")
  NS.SetByPath("state.debugConsole", false)
  assertEqual(db:GetCurrentProfile(), current, "still on the same profile")
  assertEqual(profileList(), listBefore, "the profile list is unchanged")
  assertTrue(profiles >= 1, "every element rebuilds off the PROFILE message")
  T.mocks.__fireTimers()
end)

test("optionssetup: without the library, opening the panel prints one honest line", function()
  local NS2, mocks2 = loadDegraded()
  NS2.OpenOptionsPanel()
  assertTrue(mocks2.__chat[#mocks2.__chat]:find("settings panel is unavailable", 1, true) ~= nil)
  assertFalse(pcall(error, "sentinel"), "sanity")
end)
