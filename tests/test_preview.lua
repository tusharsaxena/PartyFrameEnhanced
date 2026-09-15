-- tests/test_preview.lua — modules/Preview.lua and the two verbs that arrive with it: unlock ↔
-- preview, the combat refusal, `/pfe preview`, the holders' grab state, and `/pfe status`.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local NS, mocks = T.NS, T.mocks

local function slash(msg)
  local before = #mocks.__chat
  NS.Slash:OnSlash(msg)
  local out = {}
  for i = before + 1, #mocks.__chat do out[#out + 1] = mocks.__chat[i] end
  return table.concat(out, "\n")
end

local function holder(key) return NS.Anchor.__features[key].holder end

test("preview: unlocking turns preview on and makes free-placement holders grabbable", function()
  NS.db.profile.castbar.anchorMode = "free"
  NS.db.profile.target.anchorMode = "attached"
  slash("unlock")
  assertTrue(NS.State.preview)
  assertTrue(NS.Anchor.IsUnlocked())
  assertEqual(holder("castbar").__mouse ~= false, true)
  assertTrue(holder("castbar").plate.__shown, "a free holder shows its plate")
  assertFalse(holder("target").plate.__shown, "an attached feature has nothing to grab")
  slash("lock")
  assertFalse(NS.State.preview)
  assertFalse(holder("castbar").plate.__shown)
end)

test("preview: unlocking in combat is refused, the stored lock stays, and the player is told why", function()
  -- red under: an unlock that half-happens in combat (placeholders on, secure frames stuck).
  mocks.InCombatLockdown = function() return true end
  local out = slash("unlock")
  mocks.InCombatLockdown = function() return false end
  assertEqual(NS.GetSetting("locked"), true)
  assertFalse(NS.State.preview)
  assertTrue(out:find("cannot unlock during combat", 1, true) ~= nil)
  assertFalse(out:find("Elements unlocked", 1, true) ~= nil, "no false acknowledgment")
end)

test("preview: `/pfe preview` toggles the placeholders and leaves the lock alone", function()
  assertTrue(slash("preview"):find("Preview on", 1, true) ~= nil)
  assertTrue(NS.State.preview)
  assertEqual(NS.GetSetting("locked"), true)
  slash("preview")
  assertFalse(NS.State.preview)
end)

test("preview: a profile saved unlocked comes back in preview", function()
  NS.db.profile.locked = false
  NS.bus:SendMessage(NS.MSG.PROFILE)
  assertTrue(NS.State.preview)
  NS.db.profile.locked = true
  NS.bus:SendMessage(NS.MSG.PROFILE)
  assertFalse(NS.State.preview)
end)

test("status: names the frame system, each unit, each feature, and anything switched off", function()
  NS.db.profile.visibility = "never"
  local out = slash("status")
  NS.db.profile.visibility = "always"
  assertTrue(out:find("Frame system: none found", 1, true) ~= nil)
  assertTrue(out:find("Party 1", 1, true) ~= nil)
  assertTrue(out:find("Cast bars: on", 1, true) ~= nil)
  assertTrue(out:find("visibility never", 1, true) ~= nil)
end)
