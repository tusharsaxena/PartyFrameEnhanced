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
