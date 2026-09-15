-- tests/test_targetframes.lua — modules/TargetFrames.lua and modules/UnitButtons.lua: the secure
-- buttons, their state drivers and click attributes, combat deferral, painting (name, health, color,
-- marker) under plain and secret values, and the health ticker's lifecycle.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local NS, mocks = T.NS, T.mocks
local TargetFrames = NS.TargetFrames
local buttons = TargetFrames.__buttons

-- Free placement, feature and addon on — written straight into the profile (an earlier suite's
-- profile reset may have undone them), then republished so every button re-decides.
local function prep()
  local cfg = NS.db.profile.target
  cfg.anchorMode, cfg.enabled = "free", true
  NS.db.profile.enabled, NS.db.profile.visibility = true, "always"
  NS.PublishVisibility()
end

local function drain()
  -- The ticker re-queues itself; cancel it first so the drain ends.
  NS.db.profile.target.enabled = false
  TargetFrames.UpdateTicker()
  NS.db.profile.target.enabled = true
  while mocks.__fireTimers() > 0 do end
end

local function target(owner, data)
  mocks.__units[NS.Units.TARGET[owner]] = data
  buttons[owner]:__fire("OnEvent", "UNIT_TARGET", owner)
end

test("targetframes: every button is a secure unit button acting on its owner's target", function()
  for _, unit in ipairs(NS.Units.LIST) do
    local btn = buttons[unit]
    assertEqual(btn.__template, "SecureUnitButtonTemplate")
    assertEqual(btn:GetAttribute("unit"), NS.Units.TARGET[unit])
  end
  assertEqual(buttons.party2:GetAttribute("unit"), "party2target")
  assertEqual(buttons.player:GetAttribute("unit"), "target")
end)

test("targetframes: the state driver folds General visibility in, and hides what is not allowed", function()
  prep()
  NS.SetByPath("visibility", "always")
  assertEqual(buttons.party1.__drivers.visibility, "[@party1target,exists] show; hide")
  NS.SetByPath("visibility", "inCombat")
  assertEqual(buttons.party1.__drivers.visibility, "[nocombat] hide; [@party1target,exists] show; hide")
  NS.SetByPath("visibility", "outOfCombat")
  assertEqual(buttons.party1.__drivers.visibility, "[combat] hide; [@party1target,exists] show; hide")
  NS.SetByPath("visibility", "never")
  assertEqual(buttons.party1.__drivers.visibility, "hide")
  NS.SetByPath("visibility", "always")
  NS.SetByPath("target.enabled", false)
  assertEqual(buttons.party1.__drivers.visibility, "hide", "feature off")
  NS.SetByPath("target.enabled", true)
end)

test("targetframes: attached with no party frame on screen, the driver is hide", function()
  prep()
  NS.SetByPath("target.anchorMode", "attached")
  assertEqual(buttons.party3.__drivers.visibility, "hide")
  NS.SetByPath("target.anchorMode", "free")
  assertEqual(buttons.party3.__drivers.visibility, "[@party3target,exists] show; hide")
end)

test("targetframes: in combat a driver change is queued, never written, and lands at regen", function()
  -- red under: RegisterStateDriver in lockdown, which the client blocks and blames on the addon.
  prep()
  mocks.InCombatLockdown = function() return true end
  NS.SetByPath("visibility", "never")
  assertEqual(buttons.party1.__drivers.visibility, "[@party1target,exists] show; hide",
    "the installed driver did not change in combat")
  mocks.InCombatLockdown = function() return false end
  NS.addon:OnLeaveCombat()
  assertEqual(buttons.party1.__drivers.visibility, "hide")
  NS.SetByPath("visibility", "always")
end)

test("targetframes: click to target sets the attribute and the mouse, both ways", function()
  prep()
  assertEqual(buttons.party1:GetAttribute("*type1"), "target")
  assertEqual(buttons.party1.__mouse, true)
  NS.SetByPath("target.clickToTarget", false)
  assertEqual(buttons.party1:GetAttribute("*type1"), nil)
  assertEqual(buttons.party1.__mouse, false)
  NS.SetByPath("target.clickToTarget", true)
end)

test("targetframes: UNIT_TARGET paints the name, health, percent and marker", function()
  prep()
  target("party1", { name = "Hogger", health = 30, healthMax = 120, pct = 25, reaction = 2, marker = 7 })
  local btn = buttons.party1
  assertEqual(btn.text.__text, "Hogger")
  assertEqual(btn.bar.__max, 120)
  assertEqual(btn.bar.__value, 30)
  assertEqual(btn.text2.__text, "25%")
  assertEqual(btn.marker.__marker, 7)
  mocks.__units.party1target = nil
  drain()
end)

test("targetframes: NPCs color by reaction, players by class when asked, the swatch otherwise", function()
  prep()
  local cfg = NS.db.profile.target
  target("party1", { name = "Wolf", reaction = 2 })
  assertEqual(buttons.party1.bar.__color[1], cfg.hostileColor.r, "hostile NPC")
  target("party1", { name = "Guard", reaction = 5 })
  assertEqual(buttons.party1.bar.__color[1], cfg.friendlyColor.r, "friendly NPC")
  NS.SetByPath("target.useClassColorBar", true)
  target("party1", { name = "Jaina", isPlayer = true, class = "MAGE" })
  assertEqual(buttons.party1.bar.__color[1], mocks.RAID_CLASS_COLORS.MAGE.r, "player in class color")
  NS.SetByPath("target.useClassColorBar", false)
  target("party1", { name = "Jaina", isPlayer = true, class = "MAGE" })
  assertEqual(buttons.party1.bar.__color[1], cfg.barColor.r, "companion off: the stored swatch")
  mocks.__units.party1target = nil
  drain()
end)

test("targetframes: a secret class and a secret reaction never reach a table lookup", function()
  -- red under: RAID_CLASS_COLORS[secret] or reactionColor(secret) — the client raises on both.
  prep()
  local SECRET = setmetatable({}, { __index = function() error("a secret was indexed") end })
  mocks.issecretvalue = function(v) return v == SECRET end
  mocks.UnitIsPlayer = function() return SECRET end
  NS.SetByPath("target.useClassColorBar", true)
  target("party2", { name = SECRET, class = SECRET, reaction = SECRET, health = SECRET, healthMax = SECRET })
  local cfg = NS.db.profile.target
  assertEqual(buttons.party2.bar.__color[1], cfg.hostileColor.r, "unknown reaction reads as hostile")
  assertTrue(buttons.party2.text.__text == SECRET, "a secret name goes to SetText untouched")
  assertTrue(buttons.party2.bar.__value == SECRET, "a secret health goes to SetValue untouched")
  NS.SetByPath("target.useClassColorBar", false)
  mocks.issecretvalue = nil
  mocks.UnitIsPlayer = function(u) local d = mocks.__units[u]; return d and d.isPlayer or false end
  mocks.__units.party2target = nil
  drain()
end)

test("targetframes: the ticker runs only while someone has a target, and repaints health", function()
  prep()
  drain()
  assertFalse(TargetFrames.TickerRunning(), "no targets, no ticker")
  target("party3", { name = "Boar", health = 50, healthMax = 100, reaction = 2 })
  assertTrue(TargetFrames.TickerRunning())
  mocks.__units.party3target.health = 20
  mocks.__fireTimers()
  assertEqual(buttons.party3.bar.__value, 20, "the tick repainted health")
  mocks.__units.party3target = nil
  mocks.__fireTimers()
  assertFalse(TargetFrames.TickerRunning(), "the last target gone, the ticker cancels itself")
end)

test("targetframes: an unchanged plain health is not repainted by the tick", function()
  prep()
  target("party4", { name = "Rat", health = 5, healthMax = 10, reaction = 2 })
  local btn = buttons.party4
  local writes = 0
  local orig = btn.bar.SetValue
  rawset(btn.bar, "SetValue", function(self, v) writes = writes + 1; orig(self, v) end)
  mocks.__fireTimers()
  mocks.__fireTimers()
  assertEqual(writes, 0, "same health, no SetValue")
  rawset(btn.bar, "SetValue", orig)
  mocks.__units.party4target = nil
  drain()
end)

test("targetframes: Update health off draws the bar full with no percent, and the ticker never runs", function()
  prep()
  drain()
  NS.SetByPath("target.updateHealth", false)
  target("party3", { name = "Boar", health = 50, healthMax = 100, pct = 50, reaction = 2 })
  local btn = buttons.party3
  assertEqual(btn.bar.__max, 1)
  assertEqual(btn.bar.__value, 1, "a full bar")
  assertEqual(btn.text2.__text, "", "no percent")
  assertFalse(TargetFrames.TickerRunning(), "nothing to refresh, so no ticker")
  NS.SetByPath("target.updateHealth", true)
  assertTrue(TargetFrames.TickerRunning(), "back on, the ticker resumes")
  assertEqual(btn.bar.__value, 50, "and the real health is painted again")
  assertEqual(btn.text2.__text, "50%")
  mocks.__units.party3target = nil
  drain()
end)

test("targetframes: the marker sits on its configured point of the bar, nudged by its offsets", function()
  prep()
  local btn = buttons.party1
  local orig, got = btn.marker.SetPoint, nil
  rawset(btn.marker, "SetPoint", function(_, ...) got = { ... } end)
  NS.SetByPath("target.markerPoint", "TOPRIGHT")
  NS.SetByPath("target.markerOffsetX", 5)
  NS.SetByPath("target.markerOffsetY", -3)
  assertEqual(got[1], "CENTER")
  assertTrue(got[2] == btn.bar, "relative to the bar")
  assertEqual(got[3], "TOPRIGHT")
  assertEqual(got[4], 5 * (NS.GetSetting("scale") or 1))
  assertEqual(got[5], -3 * (NS.GetSetting("scale") or 1))
  rawset(btn.marker, "SetPoint", orig)
  for _, key in ipairs({ "markerPoint", "markerOffsetX", "markerOffsetY" }) do
    NS.SetByPath("target." .. key, NS.defaults.profile.target[key])
  end
end)

test("targetframes: preview shows every allowed button with placeholder content", function()
  prep()
  NS.State.preview = true
  NS.PublishVisibility()
  assertEqual(buttons.party1.__drivers.visibility, "show")
  assertEqual(buttons.party1.text.__text, "Preview target")
  assertEqual(buttons.party1.text2.__text, "65%")
  NS.State.preview = false
  NS.PublishVisibility()
  assertEqual(buttons.party1.__drivers.visibility, "[@party1target,exists] show; hide")
end)

test("targetframes: suspended, no events, no ticker, every driver hide", function()
  prep()
  target("party1", { name = "Boar", reaction = 2 })
  NS.SuspendAll()
  assertTrue(next(buttons.party1.__unitEvents) == nil)
  assertFalse(TargetFrames.TickerRunning())
  assertEqual(buttons.party1.__drivers.visibility, "hide")
  NS.ResumeAll()
  assertEqual(buttons.party1.__unitEvents.UNIT_TARGET[1], "party1")
  mocks.__units.party1target = nil
  drain()
end)
