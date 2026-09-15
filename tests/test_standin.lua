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

test("standin: shows the player's name and a Test tag, and drags", function()
  local f = StandIn.Place("ellesmere", nil)
  assertEqual(f.name.__text, "Testchar")
  assertEqual(f.tag.__text, "Test")
  assertTrue(f:GetScript("OnDragStart") ~= nil and f:GetScript("OnDragStop") ~= nil)
  StandIn.Show()
  assertTrue(StandIn.IsShown())
  StandIn.Hide()
  assertTrue(not StandIn.IsShown())
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
