-- tests/test_petframes.lua — modules/PetFrames.lua: the secure pet buttons, their events on owner and
-- pet tokens, painting, the owner's class color, and suspend.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local NS, mocks = T.NS, T.mocks
local buttons = NS.PetFrames.__buttons

-- Free placement, feature and addon on — written straight into the profile (an earlier suite's
-- profile reset may have undone them), then republished so every button re-decides.
local function prep()
  local cfg = NS.db.profile.pet
  cfg.anchorMode, cfg.enabled = "free", true
  NS.db.profile.enabled, NS.db.profile.visibility = true, "always"
  NS.PublishVisibility()
end

test("petframes: each button acts on its owner's pet token", function()
  prep()
  assertEqual(buttons.player:GetAttribute("unit"), "pet")
  assertEqual(buttons.party3:GetAttribute("unit"), "partypet3")
  assertEqual(buttons.party3.__drivers.visibility, "[@partypet3,exists] show; hide")
end)

test("petframes: UNIT_PET listens on the owner, the health events on the pet token", function()
  local ev = buttons.party2.__unitEvents
  assertEqual(ev.UNIT_PET[1], "party2")
  assertEqual(ev.UNIT_HEALTH[1], "partypet2")
  assertEqual(ev.UNIT_MAXHEALTH[1], "partypet2")
  assertEqual(ev.UNIT_NAME_UPDATE[1], "partypet2")
end)

test("petframes: a new pet paints fully; a health event repaints health only", function()
  prep()
  mocks.__units.partypet1 = { name = "Wolf", health = 40, healthMax = 80 }
  local btn = buttons.party1
  btn:__fire("OnEvent", "UNIT_PET", "party1")
  assertEqual(btn.text.__text, "Wolf")
  assertEqual(btn.bar.__value, 40)
  mocks.__units.partypet1.health = 10
  mocks.__units.partypet1.name = "Renamed"
  btn:__fire("OnEvent", "UNIT_HEALTH", "partypet1")
  assertEqual(btn.bar.__value, 10)
  assertEqual(btn.text.__text, "Wolf", "a health event does not repaint the name")
  btn:__fire("OnEvent", "UNIT_NAME_UPDATE", "partypet1")
  assertEqual(btn.text.__text, "Renamed")
  mocks.__units.partypet1 = nil
end)

test("petframes: Use class color takes the OWNER's class", function()
  prep()
  mocks.__classByUnit.party1 = "WARRIOR"
  NS.SetByPath("pet.useClassColorBar", true)
  mocks.__units.partypet1 = { name = "Wolf", class = "MAGE" }
  buttons.party1:__fire("OnEvent", "UNIT_PET", "party1")
  assertEqual(buttons.party1.bar.__color[1], mocks.RAID_CLASS_COLORS.WARRIOR.r,
    "the owner's class, not the pet's")
  NS.SetByPath("pet.useClassColorBar", false)
  mocks.__classByUnit.party1 = nil
  mocks.__units.partypet1 = nil
end)

test("petframes: Update health off drops the health events and draws the bar full", function()
  prep()
  local btn = buttons.party2
  NS.SetByPath("general.updateHealth", false)
  assertTrue(btn.__unitEvents.UNIT_HEALTH == nil, "no UNIT_HEALTH")
  assertTrue(btn.__unitEvents.UNIT_MAXHEALTH == nil, "no UNIT_MAXHEALTH")
  assertEqual(btn.__unitEvents.UNIT_PET[1], "party2", "the owner event stays")
  assertEqual(btn.__unitEvents.UNIT_NAME_UPDATE[1], "partypet2", "and the name event")
  mocks.__units.partypet2 = { name = "Cat", health = 10, healthMax = 80 }
  btn:__fire("OnEvent", "UNIT_PET", "party2")
  assertEqual(btn.bar.__max, 1)
  assertEqual(btn.bar.__value, 1, "a full bar")
  NS.SetByPath("general.updateHealth", true)
  assertEqual(btn.__unitEvents.UNIT_HEALTH[1], "partypet2", "back on, re-registered")
  assertEqual(btn.bar.__value, 10, "and the real health is painted")
  mocks.__units.partypet2 = nil
end)

test("petframes: suspended, events come off and every driver is hide", function()
  prep()
  NS.SuspendAll()
  assertTrue(next(buttons.party1.__unitEvents) == nil)
  assertEqual(buttons.party1.__drivers.visibility, "hide")
  NS.ResumeAll()
  assertEqual(buttons.party1.__unitEvents.UNIT_PET[1], "party1")
end)
