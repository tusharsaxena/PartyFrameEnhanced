-- tests/test_rangefade.lua — modules/RangeFade.lua: every element under its unit's fade frame; the
-- fade copied from EllesmereUI's and Blizzard raid-style's own alpha calls, secret flags included;
-- Blizzard classic's own UnitInRange check; and full alpha whenever the fade does not apply.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local NS, mocks = T.NS, T.mocks
local Providers, RangeFade = NS.Providers, NS.RangeFade

local function fade(unit) return RangeFade.Parent(unit) end

-- A post-hook that behaves like the client's: the original runs, then the hook with the same
-- arguments. The kit's hooksecurefunc is a no-op, so without this no hook would ever fire.
local function realHooks()
  mocks.hooksecurefunc = function(obj, method, fn)
    local orig = obj[method]
    rawset(obj, method, function(self, ...)
      local r = orig(self, ...)
      fn(self, ...)
      return r
    end)
  end
end

local function member(unit, field)
  local f = mocks.CreateFrame("Button")
  rawset(f, field or "unit", unit)
  f:Show()
  return f
end

local function installRaidStyle(units)
  local container = mocks.CreateFrame("Frame", "CompactPartyFrame")
  container:Show()
  container.memberUnitFrames = {}
  local byUnit = {}
  for i, unit in ipairs(units) do
    container.memberUnitFrames[i] = member(unit)
    byUnit[unit] = container.memberUnitFrames[i]
  end
  mocks.CompactPartyFrame = container
  mocks.EditModeManagerFrame = { UseRaidStylePartyFrames = function() return true end }
  return byUnit
end

local function installEllesmere(units)
  local header = mocks.CreateFrame("Frame", "ERFPartyHeader")
  header:Show()
  local byUnit = {}
  for i, unit in ipairs(units) do
    header[i] = member(unit)
    rawset(header[i], "GetAttribute", function(_, k) return k == "unit" and unit or nil end)
    byUnit[unit] = header[i]
  end
  mocks.ERFPartyHeader = header
  mocks.C_AddOns = { IsAddOnLoaded = function(name) return name == "EllesmereUIRaidFrames" end }
  return byUnit
end

local function installClassic(units)
  local pf = mocks.CreateFrame("Frame", "PartyFrame")
  pf:Show()
  local byUnit = {}
  for i, unit in ipairs(units) do
    local f = member(unit, "unitToken")
    pf["MemberFrame" .. i] = f
    byUnit[unit] = f
  end
  mocks.PartyFrame = pf
  return byUnit
end

local function reset()
  if NS.State.preview then
    NS.State.preview = false
    NS.PublishVisibility()
  end
  mocks.hooksecurefunc = function() end
  mocks.issecretvalue = nil
  mocks.ERFPartyHeader, mocks.ERFPartySelfButton = nil, nil
  mocks.CompactPartyFrame, mocks.PartyFrame, mocks.EditModeManagerFrame = nil, nil, nil
  mocks.C_AddOns = nil
  for _, unit in ipairs(NS.Units.LIST) do mocks.__units[unit] = nil end
  NS.db.profile.general.provider = "auto"
  NS.db.profile.general.rangeFade = true
  NS.db.profile.general.strata = "auto"
  Providers.Resolve()
end

-- Each case below runs between two resets, the second one whether or not the case passed: a case
-- that fails half-way must not leave its frame system, a hook or preview behind for later suites.
local function case(name, fn)
  test(name, function()
    reset()
    local ok, err = pcall(fn)
    reset()
    if not ok then error(err, 0) end
  end)
end

test("rangefade: every cast bar, target frame and pet frame sits under its unit's fade frame", function()
  for _, unit in ipairs(NS.Units.LIST) do
    local f = fade(unit)
    assertTrue(NS.CastBars.__bars[unit].__parent == f, unit .. "'s cast bar")
    assertTrue(NS.TargetFrames.__buttons[unit].__parent == f, unit .. "'s target frame")
    assertTrue(NS.PetFrames.__buttons[unit].__parent == f, unit .. "'s pet frame")
  end
  assertTrue(fade("party1") ~= fade("party2"), "one fade frame per unit")
end)

case("rangefade: Blizzard raid-style — the member frame's SetAlpha is copied to its unit", function()
  realHooks()
  local frames = installRaidStyle({ "player", "party1", "party2" })
  Providers.Resolve()
  assertEqual(Providers.ActiveId(), "blizzard-raid")
  frames.party2:SetAlpha(0.5)
  assertEqual(fade("party2").__alphaSet, 0.5, "party2 went out of range; so do its elements")
  assertEqual(fade("party1").__alphaSet, 1, "and nobody else's")
  frames.party2:SetAlpha(1)
  assertEqual(fade("party2").__alphaSet, 1, "back in range")
end)

case("rangefade: EllesmereUI — a secret range flag is replayed through SetAlphaFromBoolean", function()
  -- red under: comparing or branching on the flag, which the client raises on in combat.
  realHooks()
  local SECRET = setmetatable({}, { __eq = function() error("a secret was compared") end })
  mocks.issecretvalue = function(v) return v == SECRET end
  local frames = installEllesmere({ "player", "party1" })
  Providers.Resolve()
  assertEqual(Providers.ActiveId(), "ellesmere")
  frames.party1:SetAlphaFromBoolean(SECRET, 1, 0.4)
  local call = fade("party1").__alphaFromBool
  assertTrue(call ~= nil and rawequal(call[1], SECRET), "the secret flag went to the C method untouched")
  assertEqual(call[2], 1)
  assertEqual(call[3], 0.4, "EllesmereUI's own out-of-range alpha, not ours")
  mocks.issecretvalue = nil
end)

case("rangefade: a secret alpha the client refuses falls back to the frame's own outOfRange", function()
  realHooks()
  local SECRET = {}
  mocks.issecretvalue = function(v) return v == SECRET end
  local frames = installRaidStyle({ "party1" })
  Providers.Resolve()
  local f = fade("party1")
  local orig = f.SetAlpha
  rawset(f, "SetAlpha", function(self, a)
    if a == SECRET then error("secret refused") end
    return orig(self, a)
  end)
  rawset(frames.party1, "outOfRange", true)
  frames.party1:SetAlpha(SECRET)
  assertEqual(f.__alphaSet, 0.5, "outOfRange true reads as the raid-style frames' 0.5")
  rawset(f, "SetAlpha", orig)
  mocks.issecretvalue = nil
end)

case("rangefade: Blizzard classic has no fade to copy — UnitInRange drives it instead", function()
  installClassic({ "party1", "party2" })
  mocks.__units.party2 = { inRange = false }
  Providers.Resolve()
  assertEqual(Providers.ActiveId(), "blizzard-party")
  assertTrue(RangeFade.Listening(), "UNIT_IN_RANGE_UPDATE is registered on the classic frames")
  assertEqual(fade("party2").__alphaSet, 0.5, "out of range at the resolve")
  assertEqual(fade("party1").__alphaSet, 1)
  mocks.__units.party2 = { inRange = true }
  mocks.__fireEvent("UNIT_IN_RANGE_UPDATE", "party2")
  assertEqual(fade("party2").__alphaSet, 1, "the range event brought it back")
  reset()
  assertFalse(RangeFade.Listening(), "and off the classic frames the event is not registered")
end)

case("rangefade: off, in preview, or with no party frame, every fade is full alpha", function()
  realHooks()
  local frames = installRaidStyle({ "party1" })
  Providers.Resolve()
  frames.party1:SetAlpha(0.5)
  assertEqual(fade("party1").__alphaSet, 0.5)

  NS.SetByPath("general.rangeFade", false)
  assertEqual(fade("party1").__alphaSet, 1, "the setting off restores full alpha")
  frames.party1:SetAlpha(0.5)
  assertEqual(fade("party1").__alphaSet, 1, "and the hook no longer copies")
  NS.SetByPath("general.rangeFade", true)
  assertEqual(fade("party1").__alphaSet, 0.5, "back on, it re-reads the frame's alpha")

  NS.State.preview = true
  NS.PublishVisibility()
  assertEqual(fade("party1").__alphaSet, 1, "preview draws at full alpha")
  NS.State.preview = false
  NS.PublishVisibility()

  assertEqual(fade("party3").__alphaSet, 1, "a unit with no party frame is never faded")
end)

case("rangefade: status names which way the fade is running", function()
  local function status()
    local before = #mocks.__chat
    NS.Slash:OnSlash("status")
    local out = {}
    for i = before + 1, #mocks.__chat do out[#out + 1] = mocks.__chat[i] end
    return table.concat(out, "\n")
  end
  assertEqual(RangeFade.Mode(), "idle", "no frame system on screen")
  assertTrue(status():find("Range fade: waiting for party frames", 1, true) ~= nil)
  installRaidStyle({ "party1" })
  Providers.Resolve()
  assertEqual(RangeFade.Mode(), "copy")
  assertTrue(status():find("Range fade: copied from Blizzard (raid-style)", 1, true) ~= nil)
  mocks.CompactPartyFrame, mocks.EditModeManagerFrame = nil, nil
  installClassic({ "party1" })
  Providers.Resolve()
  assertEqual(RangeFade.Mode(), "range")
  assertTrue(status():find("Range fade: own range check (classic frames)", 1, true) ~= nil)
  NS.SetByPath("general.rangeFade", false)
  assertEqual(RangeFade.Mode(), "off")
  assertTrue(status():find("Range fade: off", 1, true) ~= nil)
end)

case("rangefade: a perf run's suspend drops the range event and restores full alpha", function()
  installClassic({ "party1" })
  mocks.__units.party1 = { inRange = false }
  Providers.Resolve()
  assertEqual(fade("party1").__alphaSet, 0.5)
  NS.lifecycle:Hold("perf")
  -- Checked before the release, which always runs: a hold left behind would stand the addon down
  -- for every suite after this one.
  local listening, alpha = RangeFade.Listening(), fade("party1").__alphaSet
  NS.lifecycle:Release("perf")
  assertFalse(listening, "suspended, the range event is dropped")
  assertEqual(alpha, 1, "and every fade is full alpha")
  assertTrue(RangeFade.Listening(), "resumed from current settings")
  assertEqual(fade("party1").__alphaSet, 0.5)
end)

case("rangefade: UnitMap and HookedCount report the frame map and the hooks, read-only", function()
  -- red under: handing out the live map (a reader could unmap a frame), or a count that ignores
  -- the hooks this resolve added.
  realHooks()
  -- The hook set is weak-keyed, so member frames earlier suites dropped leave it whenever the
  -- collector runs. Collected first, so a cycle that lands mid-case cannot shrink the count under
  -- the assertion (it went red at random once tests/test_securefollow.lua added garbage before it).
  collectgarbage("collect")
  local hookedBefore = RangeFade.HookedCount()
  local frames = installRaidStyle({ "player", "party1" })
  Providers.Resolve()
  local map = RangeFade.UnitMap()
  assertTrue(map.party1 == frames.party1, "party1's frame")
  assertTrue(map.player == frames.player, "the player's frame")
  assertTrue(map.party2 == nil, "a unit with no frame is absent")
  assertEqual(RangeFade.HookedCount(), hookedBefore + 2, "both member frames were hooked")
  map.party1 = nil
  assertTrue(RangeFade.UnitMap().party1 == frames.party1, "mutating the copy changes nothing")
  frames.party1:SetAlpha(0.5)
  assertEqual(fade("party1").__alphaSet, 0.5, "and the copy still reaches party1's fade")
end)

-- Strata: the fade frames stack with the party frames, one level over the highest frame in them.
local function recordStrata(unit)
  local f = fade(unit)
  rawset(f, "SetFrameStrata", function(self, s) self.__strata = s end)
  return f
end

local function dress(frame, strata, level, childLevel)
  rawset(frame, "GetFrameStrata", function() return strata end)
  frame:SetFrameLevel(level)
  local child = mocks.CreateFrame("Frame")
  child:SetFrameLevel(childLevel)
  rawset(child, "GetChildren", function() end)
  rawset(frame, "GetChildren", function() return child end)
end

case("rangefade: Match party frames copies the party frame's strata, a level over its children", function()
  -- red under: the elements left on UIParent's MEDIUM over a LOW party frame (they covered other
  -- addons' LOW windows), or a level from the party frame alone, which its own health bar outranks.
  local frames = installRaidStyle({ "player", "party1" })
  dress(frames.party1, "LOW", 5, 12)
  dress(frames.player, "LOW", 3, 4)
  local f1, fp, f2 = recordStrata("party1"), recordStrata("player"), recordStrata("party2")
  Providers.Resolve()
  NS.bus:SendMessage(NS.MSG.LAYOUT)
  assertEqual(f1.__strata, "LOW", "party1's elements share its party frame's strata")
  assertEqual(f1:GetFrameLevel(), 13, "one above the party frame's highest child")
  assertEqual(fp.__strata, "LOW", "the player's too")
  assertEqual(fp:GetFrameLevel(), 5, "each unit over its own frame")
  local s2 = RangeFade.StackFor("party2")
  assertEqual(s2, "LOW", "a unit with no frame stacks with the party it would join")
  assertTrue(f2.__strata == "LOW", "and its fade frame is written")
end)

case("rangefade: a fixed strata overrides the party frame's, and nothing to copy lands on LOW", function()
  local frames = installRaidStyle({ "player", "party1" })
  dress(frames.party1, "LOW", 5, 6)
  local f1 = recordStrata("party1")
  Providers.Resolve()
  NS.SetByPath("general.strata", "high")
  assertEqual(f1.__strata, "HIGH", "the chosen strata, as the client spells it")
  assertEqual(f1:GetFrameLevel(), 7, "still above the party frame")
  NS.SetByPath("general.strata", "auto")
  assertEqual(f1.__strata, "LOW", "back to the party frame's")
  mocks.CompactPartyFrame, mocks.EditModeManagerFrame = nil, nil
  Providers.Resolve()
  assertEqual(RangeFade.StackFor("party1"), "LOW", "no frame system on screen: LOW")
end)

case("rangefade: a strata change in combat waits for the secure queue", function()
  local frames = installRaidStyle({ "player", "party1" })
  dress(frames.party1, "LOW", 5, 6)
  local f1 = recordStrata("party1")
  Providers.Resolve()
  NS.bus:SendMessage(NS.MSG.LAYOUT)
  mocks.InCombatLockdown = function() return true end
  local ok, err = pcall(function()
    NS.SetByPath("general.strata", "dialog")
    assertEqual(f1.__strata, "LOW", "a fade frame parents secure buttons: not written in combat")
  end)
  mocks.InCombatLockdown = function() return false end
  mocks.__fireEvent("PLAYER_REGEN_ENABLED")
  if not ok then error(err, 0) end
  assertEqual(f1.__strata, "DIALOG", "written once combat ends")
end)
