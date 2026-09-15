-- tests/test_schema.lua — the schema registry, the dotted-path walkers, and the single write seam.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local NS = T.NS

-- Collect every CONFIG section published while `fn` runs, on a receiver of our own.
local function configSections(fn)
  local seen = {}
  local target = NS.NewBusTarget()
  target:RegisterMessage(NS.MSG.CONFIG, function(_, section) seen[#seen + 1] = section end)
  local ok, err = pcall(fn)
  target:UnregisterMessage(NS.MSG.CONFIG)
  if not ok then error(err, 0) end
  return seen
end

test("schema: validates with no shape errors and no unresolved paths", function()
  local errors, resolved, missing = NS.ValidateSchema()
  assertEqual(errors, 0, "shape errors")
  assertEqual(missing, 0, "paths that do not resolve against defaults.profile")
  assertTrue(resolved > 0, "at least one path resolved")
end)

test("schema: the General page opens on the Master controls tab, in the canonical order", function()
  local rows = NS.SchemaForPage("general")
  assertEqual(rows[1].group, "Master controls", "the first tab is Master controls (options-ui-§15)")
  local paths = {}
  for _, row in ipairs(rows) do
    if row.group == "Master controls" then paths[#paths + 1] = row.path end
  end
  assertEqual(table.concat(paths, ","), "enabled,visibility,scale,alpha,locked,state.debugConsole,state.testMode",
    "the canonical Master controls rows, in order, with nothing omitted")
end)

test("schema: General visibility is the four-value dropdown, not a boolean", function()
  local row = NS.FindSchemaRow("visibility")
  assertEqual(row.type, "string")
  local values = type(row.values) == "function" and row.values() or row.values
  for _, key in ipairs({ "always", "inCombat", "outOfCombat", "never" }) do
    assertTrue(values[key] ~= nil, "visibility offers " .. key)
  end
end)

test("schema: a write through the seam stores the value and publishes CONFIG once, by section", function()
  local before = NS.GetSetting("general.includePlayer")
  local sections = configSections(function() NS.SetByPath("general.includePlayer", not before) end)
  assertEqual(NS.GetSetting("general.includePlayer"), not before, "the value was stored")
  assertEqual(table.concat(sections, ","), "general", "one CONFIG, for the general section")
  NS.SetByPath("general.includePlayer", before)
end)

test("schema: a flat Master controls row publishes the master section", function()
  local sections = configSections(function() NS.SetByPath("scale", 1.25) end)
  assertEqual(table.concat(sections, ","), "master")
  NS.SetByPath("scale", 1.0)
end)

test("schema: the session-only debug console row publishes nothing and stores nothing", function()
  local sections = configSections(function() NS.SetByPath("state.debugConsole", false) end)
  assertEqual(#sections, 0, "no element renders from the console toggle")
  assertTrue(NS.db.profile.state == nil, "the console toggle never reaches the profile")
end)

test("schema: GetSetting falls back to the shipped default when the profile lacks the key", function()
  local saved = NS.db.profile.general.provider
  NS.db.profile.general.provider = nil
  assertEqual(NS.GetSetting("general.provider"), "auto")
  NS.db.profile.general.provider = saved
end)

test("schema: ApplyDefault writes a COPY of a table default", function()
  -- red under: ApplyDefault storing row.default itself, which would let one profile's edit reach the
  -- defaults table and every profile after it.
  local default = { r = 1, g = 0, b = 0, a = 1 }
  local row = { path = "general.__probeColor", page = "general", group = "Party frames",
                type = "color", default = default }
  NS.RegisterSchemaRows({ row })
  NS.ApplyDefault(row)
  local stored = NS.db.profile.general.__probeColor
  assertEqual(stored.r, 1, "the default was written")
  assertFalse(stored == default, "the stored table must not be the default table")
  NS.db.profile.general.__probeColor = nil
  table.remove(NS.Schema)
end)

test("schema: ResolvePath and SetPath walk dotted paths and leave flat keys flat", function()
  local t = {}
  NS.SetPath(t, "a.b.c", 3)
  NS.SetPath(t, "flat", 1)
  assertEqual(NS.ResolvePath(t, "a.b.c"), 3)
  assertEqual(NS.ResolvePath(t, "flat"), 1)
  assertEqual(NS.ResolvePath(t, "a.missing.c"), nil)
end)
