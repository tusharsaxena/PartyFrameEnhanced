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
  assertEqual(table.concat(paths, ","),
    "enabled,visibility,scale,alpha,locked,state.debugConsole,global.minimap.hide",
    "the canonical Master controls rows, in order, with nothing omitted but Test mode")
  -- Minimap button opens the fourth line and Test mode would have paired beside it (launcher-§3,
  -- compose minor 7). With no Test mode row the line is the minimap row alone, which is the shape
  -- the composer computes rather than declares.
  -- Test mode is the one legitimate omission (options-ui-§15): this addon's unlocked view already IS
  -- its preview -- unlocking raises the stand-in out of a party and paints placeholders in one --
  -- so a Test mode box beside Lock frame would be two switches for one state (anti-pattern #80).
  assertEqual(NS.FindSchemaRow("state.testMode"), nil, "the Test mode row must not come back")
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

-- ── the write seam, characterized (written before the seam moved to LibKa0s-Schema-1.0) ─────────

-- A throwaway row on the General page, taken out again afterwards. `trace` records, in order, the
-- [Set] lines, the row's reactions and the CONFIG sections.
local function withProbe(fields, fn)
  local trace = {}
  local row = { path = "general.__probe", page = "general", group = "Party frames", type = "bool",
                default = false }
  for k, v in pairs(fields or {}) do row[k] = v end
  if row.onChange == true then
    row.onChange = function(v)
      trace[#trace + 1] = "onChange " .. tostring(v) .. " stored=" .. tostring(NS.db.profile.general.__probe)
    end
  end
  NS.RegisterSchemaRows({ row })
  local savedDebug, savedFlag = NS.Debug, NS.State.debug
  NS.State.debug = true
  NS.Debug = function(tag, fmt, ...) trace[#trace + 1] = tag .. " " .. fmt:format(...) end
  local target = NS.NewBusTarget()
  target:RegisterMessage(NS.MSG.CONFIG, function(_, section) trace[#trace + 1] = "CONFIG " .. section end)
  local ok, err = pcall(fn, trace, row)
  target:UnregisterAllMessages()
  NS.Debug, NS.State.debug = savedDebug, savedFlag
  for i = #NS.Schema, 1, -1 do
    if NS.Schema[i] == row then table.remove(NS.Schema, i) end
  end
  if NS.SchemaRuntime then NS.SchemaRuntime.Reindex() end
  NS.db.profile.general.__probe = nil
  if not ok then error(err, 0) end
end

test("schema: a write stores, logs one [Set] line, reacts, then publishes CONFIG, once each", function()
  withProbe({ onChange = true }, function(trace)
    local ok = NS.SetByPath("general.__probe", true)
    assertTrue(ok, "the seam answered true")
    assertEqual(table.concat(trace, " | "),
      "Set general.__probe = true | onChange true stored=true | CONFIG general")
  end)
end)

test("schema: a refused write stores nothing, reacts to nothing and publishes nothing", function()
  withProbe({ onChange = true, validate = function(v) return v ~= true end }, function(trace)
    local ok = NS.SetByPath("general.__probe", true)
    assertFalse(ok, "the seam answered false")
    assertEqual(NS.db.profile.general.__probe, nil, "nothing was stored")
    for _, line in ipairs(trace) do
      assertTrue(line:find("^onChange") == nil and line:find("^CONFIG") == nil, "ran: " .. line)
    end
  end)
end)

test("schema: a bulk act is ONE [Set] line counting only the rows it changed", function()
  withProbe({}, function(trace)
    local scale = NS.GetSetting("scale")
    NS.Bulk.Run("reset", "probe", function()
      NS.SetByPath("general.__probe", true)   -- changed
      NS.SetByPath("scale", scale)            -- already at that value: not counted
    end)
    local lines = {}
    for _, line in ipairs(trace) do
      if line:find("^Set ") then lines[#lines + 1] = line end
    end
    assertEqual(table.concat(lines, " | "), "Set reset probe: 1 rows")
  end)
end)

test("schema: a bracket that raises still closes, says so, and re-raises the same error", function()
  withProbe({}, function(trace)
    local boom = {}
    local ok, err = pcall(NS.Bulk.Run, "reset", "probe", function()
      NS.SetByPath("general.__probe", true)
      error(boom)
    end)
    assertFalse(ok)
    assertTrue(err == boom, "the error came back by identity")
    assertEqual(trace[#trace], "Set reset probe: 1 rows (stopped by an error)")
  end)
end)

test("schema: the counted profile reset counts rows off default, and never the global minimap row", function()
  local base = NS.ProfileRowsOffDefault()
  NS.SetByPath("global.minimap.hide", false)
  assertEqual(NS.ProfileRowsOffDefault(), base, "a hidden minimap button is not a profile row")
  NS.SetByPath("general.provider", "blizzard")
  assertEqual(NS.ProfileRowsOffDefault(), base + 1, "one profile row moved")
  NS.SetByPath("general.provider", "auto")
  NS.SetByPath("global.minimap.hide", true)
end)

test("schema: before the db opens, GetSetting answers the shipped default", function()
  local db = NS.db
  NS.db = nil
  local ok, v = pcall(NS.GetSetting, "general.provider")
  NS.db = db
  assertTrue(ok, tostring(v))
  assertEqual(v, "auto")
end)

-- ── the library-absent build's host verbs ──────────────────────────────────────────────────────
--
-- On a load without LibKa0s the Master controls composer is hollow (options-ui-§1), so `enabled`
-- and `locked` have no row there. The host verbs still write them through the seam, and the write
-- has to land (settings/Slash.lua, runEnabled): a player who cannot read the acknowledgment must
-- still be able to turn the addon off and back on, and the stored path is what the next load reads.

test("schema: without the library, /pfe disable and /pfe enable still write the stored path", function()
  local NS2 = dofile("tests/degraded_env.lua")()
  NS2:InitDB()
  assertEqual(NS2.FindSchemaRow("enabled"), nil, "the composed row is absent on this build")
  NS2.Slash.__cli:OnSlash("disable")
  assertEqual(NS2.db.profile.enabled, false, "/pfe disable landed in the profile")
  NS2.Slash.__cli:OnSlash("enable")
  assertEqual(NS2.db.profile.enabled, true, "/pfe enable landed in the profile")
end)
