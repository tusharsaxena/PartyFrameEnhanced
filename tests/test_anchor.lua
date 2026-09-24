-- tests/test_anchor.lua — modules/Anchor.lua against a probe feature: the attached pin and its memo,
-- the free stack, the secure-in-combat fade and defer, and the position owner.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertNil, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertNil, T.assertFalse
local NS, mocks = T.NS, T.mocks
local Anchor = NS.Anchor

-- A recording element: every SetPoint and ClearAllPoints is kept, in order.
local function element()
  local el = mocks.CreateFrame("Frame")
  el.__points, el.__cleared = {}, 0
  -- STRICTER THAN THE MOCK, on purpose. The live client raises "bad argument #2 to '?'
  -- (Usage: self:RegisterForDrag(buttons))" when handed nil -- clearing is the NO-ARGUMENT call --
  -- but tests/_kit's frame stub accepts anything, so `RegisterForDrag(grab and "LeftButton" or nil)`
  -- passed here and raised in game on the first `/pfe unlock`. Until the kit models it, this suite
  -- models it locally. (Upstream finding for LibKa0s testkit; do not "fix" it by editing libs/.)
  rawset(el, "RegisterForDrag", function(_, ...)
    local n = select("#", ...)
    for i = 1, n do
      assertTrue(type((select(i, ...))) == "string",
        "RegisterForDrag takes button names or NOTHING; nil raises on a real client")
    end
    el.__dragButtons = n > 0 and select(1, ...) or nil
  end)
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
    -- A probe key has no row in defaults/Profile.lua, so it declares the fallback a real feature
    -- reads out of NS.defaults.profile[key]. Same seam, reachable from a synthetic key.
    defaults = { point = "TOP", relativePoint = "BOTTOM" },
    config = function() return cfg end,
    slotSize = function() return 100, 20 end,
    defaultPosition = { "CENTER", 0, -150 },
  })
  return key, els
end

-- Hide the probe's holder as well as dropping its rows. Kit 26 creates frames shown, and a probe
-- that is out of `order` is out of Anchor:Suspend's reach, so a holder left shown here would sit in
-- test_disabled's frame census until the garbage collector happened to take it: green or red by
-- allocation timing, not by anything the addon does.
local function unregister(key)
  local spec = Anchor.__features[key]
  if spec and spec.holder then spec.holder:Hide() end
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

-- THE PROFILE-SWITCH CRASH (in-game report, 2026-09-16). AceDB's SetProfile calls removeDefaults()
-- on the OUTGOING profile table, stripping every key whose value still equals its default -- and
-- `point` / `relativePoint` are exactly that for any player who never moved them. MSG.PROFILE
-- handlers run in CallbackHandler's next() order, which is undefined, so the features' config()
-- reads the live section (tests/test_profile_switch.lua pins that); this case pins the fallback
-- for a section that still arrives stripped.
-- red under: `local point, rel = cfg.point, cfg.relativePoint`, which sent nil into SetPoint and
-- raised "Usage: SetPoint(point, ...)" mid-profile-change, taking the whole ApplyAll down with it.
test("anchor: a section stripped of its defaulted point still pins, from the shipped default", function()
  withFrames(function()
    local key, els = probe(false)
    -- Exactly what removeDefaults leaves behind: the keys the player moved, and nothing else.
    cfg.point, cfg.relativePoint = nil, nil
    Anchor.Apply(key)
    local d = NS.defaults.profile[key]
    for _, unit in ipairs({ "party1", "party2" }) do
      local pt = els[unit].__points[1]
      assertTrue(pt ~= nil, unit .. " was never pinned")
      assertTrue(pt[1] ~= nil, "SetPoint got a nil point, which is the raise itself")
      if d then
        assertEqual(pt[1], d.point, "the shipped default is what the absent key meant")
        assertEqual(pt[3], d.relativePoint)
      end
    end
    unregister(key)
  end)
end)

-- The unlocked handles (in-game report): at a small gap the holder's plate is covered by the
-- elements, so the only thing left to grab was a strip of blue that is not there any more. The
-- label got a body and the elements forward their drag, so both are handles.
test("anchor: unlocking gives the name plate a grabbable body and arms every element's drag", function()
  local key, els = probe(false)
  cfg.anchorMode = "free"
  Anchor.SetUnlocked(true)
  local holder = Anchor.__features[key].holder
  assertTrue(holder.grip ~= nil, "the label needs a frame behind it; a FontString takes no mouse")
  assertTrue(holder.grip:IsShown(), "the handle shows with the plate")
  for _, unit in ipairs(NS.Units.LIST) do
    assertTrue(els[unit]:GetScript("OnDragStart") ~= nil, unit .. " is not grabbable while unlocked")
    assertEqual(els[unit].__dragButtons, "LeftButton", unit .. " took no drag button")
  end
  Anchor.SetUnlocked(false)
  assertFalse(holder.grip:IsShown(), "and goes with it when locked")
  for _, unit in ipairs(NS.Units.LIST) do
    assertNil(els[unit]:GetScript("OnDragStart"), "a locked element must not be draggable")
    assertNil(els[unit].__dragButtons, "locking must CLEAR the drag, not register nil")
  end
  unregister(key)
end)

-- Every NAMED frame built inside `fn` gets a recording SetDontSavePosition (or, with `present`
-- false, a falsy one: a client without the method). Answers the name -> { args } record.
local function withNamedFrames(present, fn)
  local calls, orig = {}, mocks.CreateFrame
  mocks.CreateFrame = function(frameType, name, ...)
    local f = orig(frameType, name, ...)
    if name then
      rawset(f, "SetDontSavePosition", present and function(_, v) calls[name] = { v } end or false)
    end
    return f
  end
  local ok, err = pcall(fn)
  mocks.CreateFrame = orig
  if not ok then error(err, 0) end
  return calls
end

test("anchor: a holder opts out of the client's layout cache; the addon owns its position", function()
  -- red under: no SetDontSavePosition after SetMovable, which lets layout-local.txt restore a
  -- dragged holder over the position the addon re-anchors it to.
  local key
  local calls = withNamedFrames(true, function() key = probe(false) end)
  local rec = calls["PartyFrameEnhanced_" .. key .. "_Holder"]
  assertTrue(rec ~= nil, "the holder never called SetDontSavePosition")
  assertEqual(rec[1], true)
  unregister(key)
end)

test("anchor: a holder still builds on a client without SetDontSavePosition", function()
  local key
  withNamedFrames(false, function() key = probe(false) end)
  assertTrue(Anchor.__features[key].holder ~= nil)
  unregister(key)
end)
