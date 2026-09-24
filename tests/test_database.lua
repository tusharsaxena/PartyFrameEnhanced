-- tests/test_database.lua — AceDB init, the migration runner, and the profile callbacks.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local NS, mocks = T.NS, T.mocks

local function received(msg, fn)
  local n = 0
  local target = NS.NewBusTarget()
  target:RegisterMessage(msg, function() n = n + 1 end)
  local ok, err = pcall(fn)
  target:UnregisterMessage(msg)
  if not ok then error(err, 0) end
  return n
end

test("database: InitDB stamps NS.SCHEMA_VERSION over a default of 0", function()
  assertTrue(NS.db ~= nil and NS.db.profile ~= nil, "NS.db.profile exists")
  -- 0, not the current version: AceDB strips a value equal to its default at logout, so a
  -- current-version default would never persist (savedvariables-§1, WS-03).
  assertEqual(NS.defaults.global.schemaVersion, 0)
  assertEqual(NS.db.global.schemaVersion, NS.SCHEMA_VERSION)
  assertEqual(NS.SCHEMA_VERSION, 1, "v1 is the shape v0.1.0 ships")
  assertEqual(NS.GetSetting("general.provider"), "auto")
  assertEqual(NS.GetSetting("locked"), true, "a first login starts locked, out of preview mode")
end)

test("database: RunMigrations is idempotent", function()
  NS:RunMigrations()
  NS:RunMigrations()
  assertEqual(NS.db.global.schemaVersion, NS.SCHEMA_VERSION)
end)

-- Runs `fn` with `step` injected into the ladder and the target raised to its `to`, from a stamp of
-- 1, over a second, never-activated stored profile 'Second'. Everything is put back afterwards.
local function withInjectedStep(step, fn)
  local steps, target, g = NS.__schemaSteps, NS.SCHEMA_VERSION, NS.db.global
  local stamp, stored = g.schemaVersion, NS.db.sv.profiles
  local chatBefore = #mocks.__chat
  stored.Second = {}
  steps[#steps + 1] = step
  NS.SCHEMA_VERSION, g.schemaVersion = step.to, 1
  local ok, err = pcall(fn, stored, function() return #mocks.__chat - chatBefore end)
  steps[#steps] = nil
  NS.SCHEMA_VERSION, g.schemaVersion, stored.Second = target, stamp, nil
  if not ok then error(err, 0) end
end

test("database: a profile step runs over every stored profile, then stamps", function()
  withInjectedStep({ to = 2, scope = "profile", apply = function(p) p.__migrated = true end },
    function(stored)
      NS:RunMigrations()
      -- red under: step.apply(NS.db.profile) only
      assertEqual(stored.Default.__migrated, true, "the active profile migrated")
      assertEqual(stored.Second.__migrated, true, "the stored, inactive profile migrated too")
      assertEqual(NS.db.global.schemaVersion, 2)
      stored.Default.__migrated = nil
    end)
end)

test("database: a raising step leaves the stamp and prints one line; a rerun is a no-op", function()
  local calls = 0
  withInjectedStep({ to = 2, scope = "profile", apply = function() calls = calls + 1; error("boom") end },
    function(_, printedSince)
      NS:RunMigrations()
      assertEqual(NS.db.global.schemaVersion, 1, "not stamped past a failed step")
      assertEqual(printedSince(), 1, "one line to the player")
      assertTrue(mocks.__chat[#mocks.__chat]:find("Settings migration to v2 failed", 1, true) ~= nil,
        "the line names the version")
    end)
  withInjectedStep({ to = 2, scope = "profile", apply = function() calls = calls + 1 end },
    function(_, printedSince)
      NS:RunMigrations()
      local after = calls
      NS:RunMigrations()
      assertEqual(calls, after, "a second run applies nothing")
      assertEqual(NS.db.global.schemaVersion, 2)
      assertEqual(printedSince(), 0, "a clean run prints nothing")
    end)
end)

test("database: a counted profile reset restores defaults and publishes PROFILE once", function()
  NS.SetByPath("general.provider", "blizzard")
  local n = received(NS.MSG.PROFILE, function() NS.ResetProfileCounted(NS.db) end)
  assertEqual(NS.GetSetting("general.provider"), "auto", "the profile is back at its defaults")
  assertEqual(n, 1, "every module rebuilds off one PROFILE message")
  assertEqual(NS.ConsumeResetCount(), nil, "the count was consumed by the handler, not left pending")
end)

test("database: a profile switch publishes PROFILE and VISIBILITY", function()
  local profiles = received(NS.MSG.PROFILE, function()
    assertEqual(received(NS.MSG.VISIBILITY, function() NS.OnProfileChanged() end), 1)
  end)
  assertEqual(profiles, 1)
end)
