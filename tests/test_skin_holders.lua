-- tests/test_skin_holders.lua — the free-placement drag holders through the skin (PF-02 of the
-- 2026-10-29 skinning rollout; modules/Anchor.lua, skinning-§1).
--
-- The holder is the one surface outside the HUD this addon draws itself: a translucent plate and
-- the feature's name above it, shown while unlocked in free placement. The plate is this addon's
-- own token `pf.mover` (gap PF-G1: Ka0s Default answers today's 0, 0.6, 1, 0.25 exactly; every
-- other skin draws its list.sel wash), the caption the library's `accent` text role (gold under Ka0s
-- Default, as GameFontNormalSmall drew it). A skin switch repaints both live.
--
-- The base mock hands back THE FRAME from CreateTexture and CreateFontString and records no paint,
-- so these cases build their probe holders under the kit's opt-in recorder (tests/_kit/mock_paint.lua).

local T = _G.PFE_TEST
local NS, mocks = T.NS, T.mocks
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local Anchor = NS.Anchor
local Skin = mocks.LibStub("LibKa0s-Skin-1.0")
local installPaint = dofile("tests/_kit/mock_paint.lua")
local OWNER = "PartyFrameEnhanced"

local function settle()
  while mocks.__fireTimers() > 0 do end
end

local function choose(skin)
  Skin:SetChoice(OWNER, "ka0s", skin)
  settle()
end

--- A probe feature registered under the recorder, so its plate and label are real regions.
local function probe()
  local restore = installPaint(mocks)
  local cfg = { anchorMode = "free", growth = "DOWN", spacing = 4 }
  local key = "skinprobe" .. #Anchor.__order
  local ok, err = pcall(Anchor.Register, {
    key = key, elements = {}, label = "Probe",
    defaults = { point = "TOP", relativePoint = "BOTTOM" },
    config = function() return cfg end,
    slotSize = function() return 100, 20 end,
    defaultPosition = { "CENTER", 0, -150 },
  })
  restore()
  if not ok then error(err, 0) end
  return key, Anchor.__features[key].holder
end

local function unregister(key)
  local spec = Anchor.__features[key]
  if spec and spec.holder then spec.holder:Hide() end
  Anchor.__features[key] = nil
  for i, k in ipairs(Anchor.__order) do
    if k == key then table.remove(Anchor.__order, i) break end
  end
end

--- Run `fn(holder)` on a fresh probe, on Ka0s Default before and after, whatever `fn` raised.
local function withHolder(fn)
  return function()
    choose("ka0s")
    local key, holder = probe()
    local ok, err = pcall(fn, holder)
    unregister(key)
    choose("ka0s")
    if not ok then error(err, 0) end
  end
end

local function same(got, want, what)
  assertTrue(type(got) == "table", what .. ": nothing was painted")
  for i = 1, 4 do
    assertTrue(math.abs((got[i] or 1) - (want[i] or 1)) < 1e-6,
      ("%s: component %d is %s, want %s"):format(what, i, tostring(got[i]), tostring(want[i])))
  end
end

local function tokenColor(name)
  local r, g, b, a = NS.Skin.Color(name)
  return { r, g, b, a or 1 }
end

test("skin holders: under Ka0s Default the plate and caption keep today's exact colors", withHolder(function(holder)
  same(holder.plate.__color, { 0, 0.6, 1, 0.25 }, "the plate (pf.mover's Ka0s Default)")
  same(holder.label.__textColor, { 1, 0.82, 0, 1 }, "the caption (text.accent, GameFontNormalSmall's gold)")
end))

test("skin holders: the plate reads pf.mover and the caption the accent role, never a literal", withHolder(function(holder)
  choose("obsidian")
  local want = tokenColor("pf.mover")
  assertTrue(want[1] ~= 0 or want[2] ~= 0.6 or want[3] ~= 1, "Obsidian draws its own mover wash")
  same(holder.plate.__color, want, "the plate after a switch to Obsidian")
  same(holder.label.__textColor, tokenColor("text.accent"), "the caption after a switch to Obsidian")
end))

test("skin holders: back on Ka0s Default both return to today's pixels", withHolder(function(holder)
  choose("ember")
  choose("ka0s")
  same(holder.plate.__color, { 0, 0.6, 1, 0.25 }, "the plate back on Ka0s Default")
  same(holder.label.__textColor, { 1, 0.82, 0, 1 }, "the caption back on Ka0s Default")
end))

test("skin holders: under High Contrast the plate is a translucent yellow wash, never opaque black", withHolder(function(holder)
  choose("contrast")
  -- red under: following list.sel, which High Contrast sets to an opaque #000000 (it marks a
  -- selection with rowSelOutline instead), so the plate became a solid black block.
  same(holder.plate.__color, { 1, 0.9, 0, 0.25 }, "the plate under High Contrast")
  assertTrue(holder.plate.__color[4] < 0.5, "the plate stays translucent")
end))

test("skin holders: a skin whose wash is none leaves the plate clear, never stale", withHolder(function(holder)
  local orig = NS.Skin.Color
  NS.Skin.Color = function(name) if name == "pf.mover" then return nil end return orig(name) end
  local ok, err = pcall(choose, "glass")
  NS.Skin.Color = orig
  if not ok then error(err, 0) end
  assertEqual(holder.plate.__color, nil, "a none plate draws nothing")
  assertEqual(holder.plate.__texture, nil, "and no texture either")
end))

