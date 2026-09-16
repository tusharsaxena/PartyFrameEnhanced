-- tests/test_castbars.lua — modules/CastBars.lua: per-unit event registration, the cast lifecycle
-- (start, channel, stop, interrupt, stale), the secret-safe fill, the show decision, and suspend.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local NS, mocks = T.NS, T.mocks
local CastBars = NS.CastBars
local bars = CastBars.__bars

-- Free placement and no fade, set per case: the show decision then does not depend on party frames
-- (tests/test_anchor.lua and tests/test_providers.lua cover those), and a stop lands on idle at once.
-- Per case rather than at file load, because every suite file loads before any case runs and an
-- earlier suite's profile reset would undo a file-level write. One case below switches back.
local function prep()
  local cfg = NS.db.profile.castbar
  cfg.anchorMode, cfg.fadeOut = "free", false
end

local function fire(unit, event)
  prep()
  bars[unit]:__fire("OnEvent", event, unit)
end

local function tick(unit, seconds)
  local fn = bars[unit]:GetScript("OnUpdate")
  if fn then fn(bars[unit], seconds) end
end

local function cast(unit, c)
  mocks.__casts[unit] = c
end

local function clear(unit)
  mocks.__casts[unit] = nil
  fire(unit, "UNIT_SPELLCAST_STOP")
end

test("castbars: each included unit's bar registers exactly the cast events, for its own unit", function()
  -- red under: a missing event (a stuck bar) or a global registration (every unit's casts in Lua).
  for _, unit in ipairs(NS.Units.LIST) do
    local registered = bars[unit].__unitEvents
    for _, event in ipairs(CastBars.EVENTS) do
      assertTrue(registered[event] ~= nil and registered[event][1] == unit, unit .. " " .. event)
    end
  end
end)

test("castbars: nothing in the addon registers a UNIT_SPELLCAST event globally", function()
  local f = io.open("modules/CastBars.lua", "r")
  local src = f:read("*a")
  f:close()
  assertFalse(src:find(':RegisterEvent%("UNIT_SPELLCAST') ~= nil)
end)

test("castbars: turning the feature off unregisters every unit; on registers them again", function()
  NS.SetByPath("castbar.enabled", false)
  assertTrue(next(bars.party1.__unitEvents) == nil)
  NS.SetByPath("castbar.enabled", true)
  assertTrue(bars.party1.__unitEvents.UNIT_SPELLCAST_START ~= nil)
end)

test("castbars: a cast start shows the bar with the name, icon and an engine-driven fill timer", function()
  mocks.Enum = { StatusBarTimerDirection = { ElapsedTime = 0, RemainingTime = 1 },
                 StatusBarInterpolation = { Immediate = 0 } }
  cast("party1", { kind = "cast", name = "Flash Heal", texture = 135907, notInterruptible = false })
  fire("party1", "UNIT_SPELLCAST_START")
  local el = bars.party1
  assertTrue(el:IsShown())
  assertEqual(el.state, "casting")
  assertEqual(el.text.__text, "Flash Heal")
  assertEqual(el.icon.__texture, 135907)
  assertEqual(el.bar.__timer.direction, 0, "a cast fills (ElapsedTime)")
  clear("party1")
  assertFalse(el:IsShown())
  mocks.Enum = nil
end)

test("castbars: a channel drains, and without the engine timer the bar is driven from the same object", function()
  mocks.Enum = { StatusBarTimerDirection = { ElapsedTime = 0, RemainingTime = 1 } }
  cast("party2", { kind = "channel", name = "Penance", remaining = 1.25, total = 2 })
  fire("party2", "UNIT_SPELLCAST_CHANNEL_START")
  assertEqual(bars.party2.bar.__timer.direction, 1, "a channel drains (RemainingTime)")
  clear("party2")
  mocks.Enum = nil
  -- No Enum: the manual path sets the range from the object and the value on every frame.
  cast("party2", { kind = "channel", name = "Penance", remaining = 1.25, total = 2 })
  fire("party2", "UNIT_SPELLCAST_CHANNEL_START")
  assertEqual(bars.party2.bar.__max, 2)
  tick("party2", 0.01)
  assertEqual(bars.party2.bar.__value, 1.25, "a channel's manual fill is the time remaining")
  clear("party2")
end)

test("castbars: the time text shows seconds left, refreshed at most ten times a second", function()
  cast("party3", { kind = "cast", name = "Smite", remaining = 1.5, total = 2 })
  fire("party3", "UNIT_SPELLCAST_START")
  tick("party3", 0.05)
  assertEqual(bars.party3.text2.__text, "", "not before the first tick")
  tick("party3", 0.06)
  assertEqual(bars.party3.text2.__text, "1.5")
  clear("party3")
end)

test("castbars: an interrupt holds the bar in the failed color with the client's word, then hides", function()
  cast("party1", { kind = "cast", name = "Greater Heal" })
  fire("party1", "UNIT_SPELLCAST_START")
  mocks.__casts.party1 = nil
  fire("party1", "UNIT_SPELLCAST_INTERRUPTED")
  local el = bars.party1
  assertEqual(el.state, "holding")
  assertEqual(el.text.__text, "Interrupted")
  assertEqual(el.bar.__value, 1, "the fill is frozen full")
  local c = NS.db.profile.castbar.failedColor
  assertEqual(el.bar.__color[1], c.r)
  tick("party1", 0.6)
  assertEqual(el.state, "idle")
  assertFalse(el:IsShown())
end)

test("castbars: a stop that arrives after the next cast began keeps the bar on the new cast", function()
  -- Re-derive on stop instead of matching cast ids, which can be secret.
  cast("party4", { kind = "cast", name = "First" })
  fire("party4", "UNIT_SPELLCAST_START")
  cast("party4", { kind = "cast", name = "Second" })
  fire("party4", "UNIT_SPELLCAST_STOP")
  assertEqual(bars.party4.state, "casting")
  assertEqual(bars.party4.text.__text, "Second")
  clear("party4")
end)

test("castbars: a stop the client never sent is caught by the tick", function()
  cast("party1", { kind = "cast", name = "Mind Blast" })
  fire("party1", "UNIT_SPELLCAST_START")
  mocks.__casts.party1 = nil
  tick("party1", 0.2)
  assertEqual(bars.party1.state, "idle")
end)

test("castbars: a secret notInterruptible picks the fill and the shield on the C side", function()
  -- red under: an `if notInterruptible` anywhere on the paint path, which raises in the client.
  local SECRET = {}
  mocks.issecretvalue = function(v) return v == SECRET end
  local evaluated, alphaFromBool = 0, 0
  mocks.C_CurveUtil = { EvaluateColorValueFromBoolean = function(flag, _, b)
    assertTrue(flag == SECRET, "the secret flag reaches the curve evaluator untouched")
    evaluated = evaluated + 1
    return b
  end }
  local el = bars.party2
  rawset(el.shield, "SetAlphaFromBoolean", function() alphaFromBool = alphaFromBool + 1 end)
  cast("party2", { kind = "cast", name = "Holy Fire", notInterruptible = SECRET })
  fire("party2", "UNIT_SPELLCAST_START")
  assertEqual(evaluated, 4, "all four fill channels chosen by the curve")
  assertEqual(alphaFromBool, 1, "the shield's alpha set from the secret flag")
  -- The interruptibility events replace it with a plain flag derived from the event's name.
  fire("party2", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
  assertEqual(el.notInterruptible, true)
  assertEqual(el.shield.__alpha, 1)
  fire("party2", "UNIT_SPELLCAST_INTERRUPTIBLE")
  assertEqual(el.shield.__alpha, 0)
  mocks.issecretvalue, mocks.C_CurveUtil = nil, nil
  rawset(el.shield, "SetAlphaFromBoolean", nil)
  clear("party2")
end)

test("castbars: the show decision hides a casting bar for master off, Never, and a missing frame", function()
  cast("party1", { kind = "cast", name = "Heal" })
  fire("party1", "UNIT_SPELLCAST_START")
  local el = bars.party1
  assertTrue(el:IsShown())
  NS.SetByPath("enabled", false)
  assertFalse(el:IsShown(), "master switch")
  NS.SetByPath("enabled", true)
  NS.SetByPath("visibility", "never")
  assertFalse(el:IsShown(), "General visibility: Never")
  NS.SetByPath("visibility", "always")
  assertTrue(el:IsShown())
  NS.SetByPath("castbar.anchorMode", "attached")
  assertFalse(el:IsShown(), "attached with no party frame on screen")
  NS.SetByPath("castbar.anchorMode", "free")
  clear("party1")
end)

test("castbars: preview shows every included bar with placeholder content, and clears on exit", function()
  prep()
  NS.State.preview = true
  NS.PublishVisibility()
  for _, unit in ipairs(NS.Units.LIST) do
    assertTrue(bars[unit]:IsShown(), unit .. " previews")
  end
  assertEqual(bars.party3.text.__text, "Preview cast")
  NS.State.preview = false
  NS.PublishVisibility()
  assertFalse(bars.party3:IsShown(), "back to live data: nothing is casting")
end)

test("castbars: suspended, every bar unregisters and hides; resumed, they come back", function()
  cast("party1", { kind = "cast", name = "Heal" })
  fire("party1", "UNIT_SPELLCAST_START")
  NS.lifecycle:Hold("perf")
  assertTrue(next(bars.party1.__unitEvents) == nil)
  assertFalse(bars.party1:IsShown())
  NS.lifecycle:Release("perf")
  assertTrue(bars.party1.__unitEvents.UNIT_SPELLCAST_START ~= nil)
  assertTrue(bars.party1:IsShown(), "a cast still running is picked up again from current state")
  clear("party1")
end)
