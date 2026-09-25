-- tests/test_standin.lua — modules/StandIn.lua and the provider half of the stand-in: which frame
-- system it imitates, its size and position copied from that system's hidden first member frame, its
-- look, and the party1 rule (a real frame always wins).

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local NS, mocks = T.NS, T.mocks
local Providers, StandIn = NS.Providers, NS.StandIn

-- A hidden member frame answering the four getters the stand-in reads.
local function source(w, h, left, top, scale)
  local f = mocks.CreateFrame("Frame")
  rawset(f, "GetSize", function() return w, h end)
  rawset(f, "GetLeft", function() return left end)
  rawset(f, "GetTop", function() return top end)
  rawset(f, "GetEffectiveScale", function() return scale or 1 end)
  return f
end

local function raidStyle(on)
  mocks.EditModeManagerFrame = { UseRaidStylePartyFrames = function() return on end }
end

local function reset()
  mocks.ERFPartyHeader, mocks.ERFPartySelfButton = nil, nil
  mocks.CompactPartyFrame, mocks.PartyFrame, mocks.EditModeManagerFrame = nil, nil, nil
  mocks.C_AddOns, mocks.issecretvalue = nil, nil
  mocks.__context.inGroup, mocks.__context.inRaid = true, false
  NS.db.profile.general.provider = "auto"
  Providers.SetStandIn(nil)
end

local function layouts(fn)
  local n = 0
  local t = NS.NewBusTarget()
  t:RegisterMessage(NS.MSG.LAYOUT, function() n = n + 1 end)
  fn()
  t:UnregisterMessage(NS.MSG.LAYOUT)
  return n
end

test("standin: Automatic imitates EllesmereUI when loaded, else raid-style or classic by Edit Mode", function()
  mocks.C_AddOns = { IsAddOnLoaded = function(name) return name == "EllesmereUIRaidFrames" end }
  assertEqual((Providers.StandInSource()), "ellesmere")
  mocks.C_AddOns = nil
  raidStyle(true)
  assertEqual((Providers.StandInSource()), "blizzard-raid")
  raidStyle(false)
  assertEqual((Providers.StandInSource()), "blizzard-party")
  reset()
end)

test("standin: a pinned Frame system wins — EllesmereUI even unloaded, Blizzard by Edit Mode", function()
  NS.db.profile.general.provider = "ellesmere"
  raidStyle(true)
  assertEqual((Providers.StandInSource()), "ellesmere")
  NS.db.profile.general.provider = "blizzard"
  mocks.C_AddOns = { IsAddOnLoaded = function() return true end }
  assertEqual((Providers.StandInSource()), "blizzard-raid")
  reset()
end)

test("standin: the source is the imitated system's first member frame", function()
  local header, first = mocks.CreateFrame("Frame"), mocks.CreateFrame("Frame")
  header[1] = first
  mocks.ERFPartyHeader = header
  mocks.C_AddOns = { IsAddOnLoaded = function(name) return name == "EllesmereUIRaidFrames" end }
  local id, src = Providers.StandInSource()
  assertEqual(id, "ellesmere")
  assertEqual(src, first)
  mocks.C_AddOns = nil
  local cpf = mocks.CreateFrame("Frame")
  cpf.memberUnitFrames = { mocks.CreateFrame("Frame") }
  mocks.CompactPartyFrame = cpf
  raidStyle(true)
  id, src = Providers.StandInSource()
  assertEqual(id, "blizzard-raid")
  assertEqual(src, cpf.memberUnitFrames[1])
  local pf = mocks.CreateFrame("Frame")
  pf.MemberFrame1 = mocks.CreateFrame("Frame")
  mocks.PartyFrame = pf
  raidStyle(false)
  id, src = Providers.StandInSource()
  assertEqual(id, "blizzard-party")
  assertEqual(src, pf.MemberFrame1)
  reset()
end)

test("standin: copies the source's size and top-left through the effective-scale ratio", function()
  rawset(StandIn.Frame(), "GetEffectiveScale", function() return 1 end)
  local p = StandIn.Place("blizzard-raid", source(80, 40, 100, 600, 2)).__placed
  rawset(StandIn.Frame(), "GetEffectiveScale", nil)
  assertEqual(p.id, "blizzard-raid")
  assertEqual(p.w, 160)
  assertEqual(p.h, 80)
  assertEqual(p.point, "TOPLEFT")
  assertEqual(p.left, 200)
  assertEqual(p.top, 1200)
end)

test("standin: a zero size takes the system's fallback, and no position goes to the center", function()
  local p = StandIn.Place("ellesmere", source(0, 0, nil, nil)).__placed
  assertEqual(p.w, 125)
  assertEqual(p.h, 60)
  assertEqual(p.point, "CENTER")
  p = StandIn.Place("blizzard-party", nil).__placed
  assertEqual(p.w, 120)
  assertEqual(p.h, 53)
  assertEqual(StandIn.Place("blizzard-raid", nil).__placed.w, 72)
end)

test("standin: a secret size or position is never compared — fallback and center", function()
  -- red under: comparing w > 0 on a secret, which raises in the client.
  mocks.issecretvalue = function(v) return v == 777 end
  local p = StandIn.Place("ellesmere", source(777, 777, 777, 777, 777)).__placed
  mocks.issecretvalue = nil
  assertEqual(p.w, 125)
  assertEqual(p.point, "CENTER")
end)

test("standin: draws beneath what attaches to it (LOW strata), as a real party frame does", function()
  -- red under: the stand-in on the elements' own strata, where its health bar covered the cast
  -- bar's icon and left a 1px rim of it showing.
  local f = StandIn.Frame()
  local strata
  rawset(f, "SetFrameStrata", function(_, s) strata = s end)
  StandIn.Place("ellesmere", nil)
  rawset(f, "SetFrameStrata", nil)
  assertEqual(strata, "LOW")
end)

test("standin: marks the player's name (test), with no corner tag for an element to cover, and drags", function()
  local f = StandIn.Place("ellesmere", nil)
  assertTrue(f.name.__text:find("Testchar", 1, true) ~= nil)
  assertTrue(f.name.__text:find("(test)", 1, true) ~= nil)
  assertNil(rawget(f, "tag"), "a top-right tag sat under the cast bar's time text")
  assertTrue(f:GetScript("OnDragStart") ~= nil and f:GetScript("OnDragStop") ~= nil)
  StandIn.Show()
  assertTrue(StandIn.IsShown())
  StandIn.Hide()
  assertTrue(not StandIn.IsShown())
end)

test("standin: imitating EllesmereUI, its configured party size beats what the hidden button measures", function()
  -- red under: copying the hidden first party button, which EllesmereUI styles at its RAID size
  -- (_StyleButtonSecure) until ReloadPartyFrames gives it the party size. Seen in game as a stand-in
  -- of the wrong shape against real 200 × 80 party frames.
  mocks.C_AddOns = { IsAddOnLoaded = function(name) return name == "EllesmereUIRaidFrames" end }
  local header = mocks.CreateFrame("Frame")
  header[1] = source(100, 46, 10, 500)   -- the raid size, as the hidden button carries it solo
  mocks.ERFPartyHeader = header
  mocks.EllesmereUIDB = { activeProfile = "Default", profiles = { Default = { addons = {
    EllesmereUIRaidFrames = { partyFrameWidth = 200, partyFrameHeight = 80 } } } } }
  local p = StandIn.Place(Providers.StandInSource()).__placed
  assertEqual(p.w, 200)
  assertEqual(p.h, 80)
  assertEqual(p.from, "settings")
  assertEqual(p.left, 10, "the position still comes from the button")
  -- Never changed in EllesmereUI: its own defaults, 125 × 60.
  mocks.EllesmereUIDB.profiles.Default.addons.EllesmereUIRaidFrames = {}
  p = StandIn.Place(Providers.StandInSource()).__placed
  assertEqual(p.w, 125)
  assertEqual(p.h, 60)
  assertEqual(p.from, "settings")
  -- EllesmereUI's settings unreadable: the button's measured size, then the fallback.
  mocks.EllesmereUIDB = nil
  assertEqual(StandIn.Place(Providers.StandInSource()).__placed.from, "frame")
  mocks.ERFPartyHeader = nil
  assertEqual(StandIn.Place(Providers.StandInSource()).__placed.from, "fallback")
  -- A size that is not a number is not trusted.
  mocks.EllesmereUIDB = { activeProfile = "Default", profiles = { Default = { addons = {
    EllesmereUIRaidFrames = { partyFrameWidth = "wide", partyFrameHeight = 80 } } } } }
  assertEqual(StandIn.Place(Providers.StandInSource()).__placed.from, "fallback")
  mocks.EllesmereUIDB = nil
  reset()
end)

test("standin: fills party1 only when no real frame holds it, and clearing it restores the real map", function()
  local standIn = StandIn.Frame()
  mocks.__context.inGroup = false
  Providers.SetStandIn(standIn)
  assertEqual(Providers.FrameFor("party1"), standIn, "asleep, the stand-in still fills party1")
  assertNil(Providers.FrameFor("party2"), "it never takes another unit")
  assertNil(Providers.FrameFor("player"))
  mocks.__context.inGroup = true
  local real = mocks.CreateFrame("Frame")
  rawset(real, "unit", "party1")
  real:Show()
  local cpf = mocks.CreateFrame("Frame")
  cpf:Show()
  cpf.memberUnitFrames = { real }
  mocks.CompactPartyFrame = cpf
  raidStyle(true)
  Providers.Resolve()
  assertEqual(Providers.FrameFor("party1"), real, "a real frame wins")
  Providers.SetStandIn(nil)
  assertEqual(Providers.FrameFor("party1"), real)
  reset()
end)

test("standin: setting and clearing it resolve at once, each sending LAYOUT", function()
  mocks.__context.inGroup = false
  local n = layouts(function()
    Providers.SetStandIn(StandIn.Frame())
    Providers.SetStandIn(nil)
  end)
  reset()
  assertEqual(n, 2)
  assertNil(Providers.FrameFor("party1"))
end)

test("standin: cleared while suspended, it leaves the map at once and the resume re-sends LAYOUT", function()
  mocks.__context.inGroup = false
  Providers.SetStandIn(StandIn.Frame())
  Providers:Suspend()
  Providers.SetStandIn(nil)
  assertNil(Providers.FrameFor("party1"))
  local n = layouts(function()
    Providers:Resume()
    for _ = 1, 10 do if mocks.__fireTimers() == 0 then break end end
  end)
  reset()
  assertTrue(n >= 1, "the anchors must hear the stand-in is gone")
end)

-- A FRESH StandIn module (the suite's own is built once and cached), loaded under a mock view whose
-- named frames carry a recording SetDontSavePosition, or a falsy one with `present` false.
local function freshStandIn(present)
  local calls = {}
  local view = setmetatable({
    CreateFrame = function(frameType, name, ...)
      local f = mocks.CreateFrame(frameType, name, ...)
      if name then
        rawset(f, "SetDontSavePosition", present and function(_, v) calls[name] = { v } end or false)
      end
      return f
    end,
  }, { __index = mocks })
  local ns2 = { Compat = NS.Compat, L = NS.L }
  local Loader = dofile("tests/_kit/loader.lua")
  Loader.addonName = "PartyFrameEnhanced"
  Loader.load("modules/StandIn.lua", ns2, view)
  return ns2.StandIn, calls
end

test("standin: opts out of the client's layout cache; the addon places it every time", function()
  -- red under: no SetDontSavePosition after SetMovable, which lets layout-local.txt restore a
  -- dragged stand-in over the position copied from the imitated frame.
  local fresh, calls = freshStandIn(true)
  local f = fresh.Frame()
  local rec = calls.PartyFrameEnhancedStandIn
  f:Hide()
  assertTrue(rec ~= nil, "the stand-in never called SetDontSavePosition")
  assertEqual(rec[1], true)
end)

test("standin: still builds on a client without SetDontSavePosition", function()
  local fresh = freshStandIn(false)
  local f = fresh.Frame()
  f:Hide()
  assertTrue(f ~= nil)
end)
