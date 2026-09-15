-- tests/test_database.lua — AceDB init, the migration runner, and the profile callbacks.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local NS = T.NS

local function received(msg, fn)
  local n = 0
  local target = NS.NewBusTarget()
  target:RegisterMessage(msg, function() n = n + 1 end)
  local ok, err = pcall(fn)
  target:UnregisterMessage(msg)
  if not ok then error(err, 0) end
  return n
end

test("database: InitDB opens the store with the shipped defaults and schema v1", function()
  assertTrue(NS.db ~= nil and NS.db.profile ~= nil, "NS.db.profile exists")
  assertEqual(NS.db.global.schemaVersion, 1)
  assertEqual(NS.GetSetting("general.provider"), "auto")
  assertEqual(NS.GetSetting("locked"), true, "a first login starts locked, out of preview mode")
end)

test("database: RunMigrations is idempotent", function()
  NS:RunMigrations()
  NS:RunMigrations()
  assertEqual(NS.db.global.schemaVersion, 1)
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
