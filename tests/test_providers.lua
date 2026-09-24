-- tests/test_providers.lua — modules/Providers.lua: which frame system is used, how each member
-- frame's unit is read, when LAYOUT is sent, and that requests coalesce.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local NS, mocks = T.NS, T.mocks
local Providers = NS.Providers

local function member(unit, opts)
  opts = opts or {}
  local f = mocks.CreateFrame("Button")
  if opts.attr then
    f.GetAttribute = function(_, k) return k == "unit" and unit or nil end
  else
    rawset(f, "unit", unit)
  end
  -- The client starts a frame shown (kit revision 26, LK-05), so a hidden member is hidden here.
  if opts.shown == false then f:Hide() else f:Show() end
  return f
end

-- Each fixture installs one frame system on the mock and returns its member frames by unit.
local function installEllesmere(units)
  local header = mocks.CreateFrame("Frame", "ERFPartyHeader")
  header:Show()
  local byUnit = {}
  for i, unit in ipairs(units) do
    header[i] = member(unit, { attr = true })
    byUnit[unit] = header[i]
  end
  mocks.ERFPartyHeader = header
  mocks.C_AddOns = { IsAddOnLoaded = function(name) return name == "EllesmereUIRaidFrames" end }
  return byUnit
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

local function installClassic(units)
  local pf = mocks.CreateFrame("Frame", "PartyFrame")
  pf:Show()
  local byUnit = {}
  for i, unit in ipairs(units) do
    local f = member(unit)
    rawset(f, "unit", nil)
    rawset(f, "unitToken", unit)
    pf["MemberFrame" .. i] = f
    byUnit[unit] = f
  end
  mocks.PartyFrame = pf
  return byUnit
end

local function reset()
  mocks.__context.inGroup = true
  mocks.ERFPartyHeader, mocks.ERFPartySelfButton = nil, nil
  mocks.CompactPartyFrame, mocks.PartyFrame, mocks.EditModeManagerFrame = nil, nil, nil
  mocks.C_AddOns, mocks.UnitIsUnit = nil, nil
  mocks.__context.inRaid = false
  NS.db.profile.general.provider = "auto"
  Providers.Resolve()
end

local function layouts(fn)
  local n = 0
  local target = NS.NewBusTarget()
  target:RegisterMessage(NS.MSG.LAYOUT, function() n = n + 1 end)
  local ok, err = pcall(fn)
  target:UnregisterMessage(NS.MSG.LAYOUT)
  if not ok then error(err, 0) end
  return n
end

test("providers: Blizzard classic maps party1..4 by unitToken and never the player", function()
  local frames = installClassic({ "party1", "party2", "party3", "party4" })
  Providers.Resolve()
  assertEqual(Providers.ActiveId(), "blizzard-party")
  assertEqual(Providers.FrameFor("party2"), frames.party2)
  assertNil(Providers.FrameFor("player"), "the classic layout never shows the player")
  reset()
end)

test("providers: Blizzard raid-style maps the player too, and follows a re-sort", function()
  local frames = installRaidStyle({ "player", "party1", "party2" })
  Providers.Resolve()
  assertEqual(Providers.ActiveId(), "blizzard-raid")
  assertEqual(Providers.FrameFor("player"), frames.player)
  -- A re-sort swaps which frame shows which unit. The map follows the frames, and says so once.
  rawset(frames.player, "unit", "party1")
  rawset(frames.party1, "unit", "player")
  assertEqual(layouts(function() Providers.Resolve() end), 1)
  assertEqual(Providers.FrameFor("party1"), frames.player)
  assertEqual(Providers.FrameFor("player"), frames.party1)
  reset()
end)

test("providers: EllesmereUI outranks Blizzard in Automatic, and reads the secure unit attribute", function()
  installRaidStyle({ "player", "party1" })
  local erf = installEllesmere({ "party1", "player" })
  Providers.Resolve()
  assertEqual(Providers.ActiveId(), "ellesmere")
  assertEqual(Providers.FrameFor("player"), erf.player)
  reset()
end)

test("providers: the General page can pin Blizzard even with EllesmereUI on screen", function()
  local blizz = installRaidStyle({ "player", "party1" })
  installEllesmere({ "party1", "player" })
  NS.db.profile.general.provider = "blizzard"
  Providers.Resolve()
  assertEqual(Providers.ActiveId(), "blizzard-raid")
  assertEqual(Providers.FrameFor("party1"), blizz.party1)
  reset()
end)

test("providers: EllesmereUI's frames are ignored unless the addon is loaded", function()
  -- The presence guard (library-stack-§6): a stray global is not an integration.
  installEllesmere({ "party1" })
  mocks.C_AddOns = nil
  Providers.Resolve()
  assertNil(Providers.ActiveId())
  reset()
end)

test("providers: hidden member frames and raid tokens are skipped", function()
  local container = mocks.CreateFrame("Frame")
  container:Show()
  container.memberUnitFrames = { member("party1", { shown = false }), member("raid3") }
  mocks.CompactPartyFrame = container
  mocks.EditModeManagerFrame = { UseRaidStylePartyFrames = function() return true end }
  -- red under: the old raidN → partyN normalization, which mapped raid3 once it was comparable.
  mocks.UnitIsUnit = function(a, b) return a == "raid3" and b == "party2" end
  Providers.Resolve()
  assertNil(Providers.FrameFor("party1"), "a hidden frame shows nobody")
  assertNil(Providers.FrameFor("party2"), "a raid token maps to no unit: the addon is party-only")
  reset()
end)

test("providers: a raid group puts the map to sleep", function()
  installClassic({ "party1" })
  mocks.__context.inRaid = true
  Providers.Resolve()
  assertNil(Providers.FrameFor("party1"))
  reset()
end)

test("providers: solo puts the map to sleep", function()
  installClassic({ "party1" })
  mocks.__context.inGroup = false
  Providers.Resolve()
  assertNil(Providers.FrameFor("party1"))
  reset()
end)

test("providers: a resolve that finds what it already had sends no LAYOUT", function()
  installClassic({ "party1" })
  Providers.Resolve()
  assertEqual(layouts(function() Providers.Resolve() end), 0)
  reset()
end)

test("providers: any number of requests before the next frame cost one resolve", function()
  -- red under: Request resolving synchronously, or scheduling one timer per call.
  -- Drain first: an earlier suite's resume left a burst's follow-ups queued, and a follow-up that
  -- fires re-queues a resolve.
  while mocks.__fireTimers() > 0 do end
  local before = #mocks.__timers
  for _ = 1, 40 do Providers.Request() end
  assertEqual(#mocks.__timers - before, 1)
  mocks.__fireTimers()
end)

test("providers: a hooked member frame's unit change requests a resolve", function()
  local frames = installRaidStyle({ "player", "party1" })
  Providers.Resolve()
  mocks.__fireTimers()
  local before = #mocks.__timers
  frames.party1:__fire("OnAttributeChanged", "unit", "party2")
  assertEqual(#mocks.__timers - before, 1)
  frames.party1:__fire("OnAttributeChanged", "alpha", 1)
  assertEqual(#mocks.__timers - before, 1, "other attributes are ignored")
  mocks.__fireTimers()
  reset()
end)

test("providers: suspended, requests do nothing and events come off", function()
  Providers:Suspend()
  local before = #mocks.__timers
  Providers.Request()
  assertEqual(#mocks.__timers, before)
  Providers:Resume()
  assertTrue(#mocks.__timers > before, "resume resolves again from current state")
  mocks.__fireTimers()
end)
