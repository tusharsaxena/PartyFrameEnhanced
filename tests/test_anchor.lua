-- tests/test_anchor.lua — modules/Anchor.lua against a probe feature: the attached pin and its memo,
-- the free stack, the secure-in-combat fade and defer, and the position owner.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local NS, mocks = T.NS, T.mocks
local Anchor = NS.Anchor

-- A recording element: every SetPoint and ClearAllPoints is kept, in order.
local function element()
  local el = mocks.CreateFrame("Frame")
  el.__points, el.__cleared = {}, 0
  rawset(el, "SetPoint", function(self, ...) self.__points[#self.__points + 1] = { ... } end)
  rawset(el, "ClearAllPoints", function(self) self.__cleared = self.__cleared + 1; self.__points = {} end)
  rawset(el, "SetAlpha", function(self, a) self.__alphaSet = a end)
  return el
end

local function setPointCalls(els)
  local n = 0
  for _, el in pairs(els) do n = n + #el.__points end
  return n
end

local cfg
local function probe(secure)
  cfg = {
    anchorMode = "attached", point = "TOP", relativePoint = "BOTTOM",
    offsetX = 0, offsetY = -2, matchWidth = false, growth = "DOWN", spacing = 4,
  }
  local els = {}
  for _, unit in ipairs(NS.Units.LIST) do els[unit] = element() end
  local key = "probe" .. #Anchor.__order
  Anchor.Register({
    key = key, secure = secure, elements = els,
    config = function() return cfg end,
    slotSize = function() return 100, 20 end,
    defaultPosition = { "CENTER", 0, -150 },
  })
  return key, els
end

local function unregister(key)
  Anchor.__features[key] = nil
  for i, k in ipairs(Anchor.__order) do
    if k == key then table.remove(Anchor.__order, i) break end
  end
end

-- Give the providers a fixed frame per party unit for the duration.
local function withFrames(fn)
  local frames = {}
  for _, unit in ipairs({ "party1", "party2" }) do frames[unit] = mocks.CreateFrame("Frame") end
  local orig = NS.Providers.FrameFor
  NS.Providers.FrameFor = function(unit) return frames[unit] end
  local ok, err = pcall(fn, frames)
  NS.Providers.FrameFor = orig
  if not ok then error(err, 0) end
end

test("anchor: attached pins each element to its unit's frame by the configured points", function()
  withFrames(function(frames)
    local key, els = probe(false)
    Anchor.Apply(key)
    local p = els.party1.__points[1]
    assertEqual(p[1], "TOP")
    assertTrue(p[2] == frames.party1, "pinned to party1's own frame")
    assertEqual(p[3], "BOTTOM")
    assertEqual(p[5], -2)
    assertEqual(#els.player.__points, 0, "no frame for the player: unpinned")
    assertEqual(els.player.__cleared, 1)
    unregister(key)
  end)
end)

test("anchor: a pass that changes nothing makes no SetPoint call", function()
  -- red under: dropping the memo in pin(), which re-anchors every element on every LAYOUT.
  withFrames(function()
    local key, els = probe(false)
    Anchor.Apply(key)
    for _, el in pairs(els) do el.__points = {} end
    Anchor.Apply(key)
    assertEqual(setPointCalls(els), 0)
    cfg.offsetY = -6
    Anchor.Apply(key)
    assertEqual(setPointCalls(els), 2, "an offset change re-pins the two units that have frames")
    unregister(key)
  end)
end)

test("anchor: match width pins both edges instead of one point", function()
  withFrames(function()
    local key, els = probe(false)
    cfg.matchWidth = true
    Anchor.Apply(key)
    local pts = els.party1.__points
    assertEqual(#pts, 2)
    assertEqual(pts[1][1] .. ">" .. pts[1][3], "TOPLEFT>BOTTOMLEFT")
    assertEqual(pts[2][1] .. ">" .. pts[2][3], "TOPRIGHT>BOTTOMRIGHT")
    unregister(key)
  end)
end)

test("anchor: free placement stacks included units down from the holder", function()
  local key, els = probe(false)
  cfg.anchorMode = "free"
  Anchor.Apply(key)
  local holder = Anchor.__features[key].holder
  assertTrue(els.player.__points[1][2] == holder, "stacked in the holder")
  assertEqual(els.player.__points[1][5], 0, "first slot at the top")
  assertEqual(els.party1.__points[1][5], -24, "second slot one height plus spacing lower")
  -- Leaving the player out closes the gap: party1 takes the first slot.
  NS.db.profile.general.includePlayer = false
  Anchor.Apply(key)
  assertEqual(els.party1.__points[1][5], 0)
  assertEqual(#els.player.__points, 0)
  NS.db.profile.general.includePlayer = true
  unregister(key)
end)

test("anchor: a secure feature in combat fades what would move and defers the pass to regen", function()
  -- red under: calling SetPoint in lockdown, which the client blocks and blames on the addon.
  withFrames(function()
    local key, els = probe(true)
    mocks.InCombatLockdown = function() return true end
    Anchor.Apply(key)
    assertEqual(setPointCalls(els), 0, "nothing moved in combat")
    assertEqual(els.party1.__alphaSet, 0, "an element whose anchor changed is faded")
    assertTrue(NS.PendingSecureCount() >= 1, "the real pass is queued")
    mocks.InCombatLockdown = function() return false end
    NS.addon:OnLeaveCombat()
    assertEqual(#els.party1.__points, 1, "regen placed it")
    assertEqual(els.party1.__alphaSet, 1, "and restored its alpha")
    unregister(key)
  end)
end)

test("anchor: a drag saves the holder's position and ResetPositions clears it", function()
  local key = probe(false)
  cfg.anchorMode = "free"
  local holder = Anchor.__features[key].holder
  rawset(holder, "GetPoint", function() return "TOPLEFT", nil, "TOPLEFT", 120.4, -80.6 end)
  holder:__fire("OnDragStop")
  assertEqual(cfg.position.point, "TOPLEFT")
  assertEqual(cfg.position.x, 120)
  assertEqual(cfg.position.y, -81)
  Anchor.ResetPositions()
  assertNil(cfg.position)
  unregister(key)
end)

test("anchor: LAYOUT re-applies every registered feature", function()
  withFrames(function()
    local key, els = probe(false)
    NS.bus:SendMessage(NS.MSG.LAYOUT)
    assertEqual(#els.party1.__points, 1)
    unregister(key)
  end)
end)
