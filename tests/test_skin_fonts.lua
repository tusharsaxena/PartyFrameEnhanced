-- tests/test_skin_fonts.lua — the HUD text's font settings under LibKa0s v1.82.0 (PF-01 of
-- Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK).
--
-- D-07: every HUD section's Font block is the minimum set (face, size, color with class color, flags,
-- shadow), and its Font flags lead with From skin ("@skin"), the default, which modules/Element.lua
-- draws through S.FontFlags: the Skin tab's Font outline decides (OUTLINE under All text and HUD
-- text only, none under Off), and a flag the player picked wins. The v3 migration moves a stored
-- flag equal to the previous default (OUTLINE) onto From skin once, on every stored profile
-- (Addendum 01); any other stored flag stays.
--
-- D-09: an element that uses the skin's face (its "Use the skin's font" companion on) draws at
-- S.HudFontSize(stored size), so its text is as wide in every skin as in Ka0s Default; its own face,
-- or Ignore fonts, draws the stored size. The stored size is never rewritten.

local T = _G.PFE_TEST
local NS, mocks = T.NS, T.mocks
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local Element = NS.Element
local Skin = mocks.LibStub("LibKa0s-Skin-1.0")
local OWNER = "PartyFrameEnhanced"
local SECTIONS = { "castbar", "target", "pet" }
local FROM_SKIN = "@skin"

local function settle()
  while mocks.__fireTimers() > 0 do end
end

--- Run `fn` on Ka0s Default with the outline on the default, HUD text only, fonts not ignored, and the same after,
--- whatever `fn` raised.
local function clean(fn)
  local function home()
    Skin:SetChoice(OWNER, "ka0s", "ka0s")
    Skin:SetOutline(OWNER, "hud")
    Skin:SetIgnore(OWNER, nil, false)
    settle()
  end
  return function()
    home()
    local ok, err = pcall(fn)
    home()
    if not ok then error(err, 0) end
  end
end

--- A fresh probe element and a copy of `section`'s defaults to draw it with.
local function probe(section)
  local el = Element.Build(mocks.CreateFrame("Frame", nil, mocks.UIParent), { icon = section == "castbar" })
  local cfg = {}
  for k, v in pairs(NS.defaults.profile[section]) do cfg[k] = v end
  return el, cfg
end

--- The size and flags the element's name line was drawn with.
local function drawn(el)
  local _, size, flags = el.text:GetFont()
  return size, flags
end

-- ── the rows and the defaults (D-07) ─────────────────────────────────────────────────────────

test("skin fonts: every HUD section's Font flags default to From skin", function()
  for _, section in ipairs(SECTIONS) do
    assertEqual(NS.defaults.profile[section].fontFlags, FROM_SKIN, section)
    local row = NS.FindSchemaRow(section .. ".fontFlags")
    assertTrue(row ~= nil, section .. ".fontFlags has a row")
    assertEqual(row.default, FROM_SKIN, section .. ": the row's default")
    assertEqual(row.sorting[1], FROM_SKIN, section .. ": From skin leads the list")
    assertEqual(row.values[FROM_SKIN], "From skin", section .. ": its label")
  end
end)

test("skin fonts: every HUD Font block is the minimum set, class color included", function()
  for _, section in ipairs(SECTIONS) do
    for _, key in ipairs({ "font", "fontFromSkin", "fontSize", "fontColor", "useClassColorFont",
                           "fontFlags", "fontShadow" }) do
      assertTrue(NS.FindSchemaRow(section .. "." .. key) ~= nil, section .. "." .. key)
    end
  end
end)

test("skin fonts: /pfe set takes From skin and every picked flag", function()
  NS.Slash:OnSlash("set target.fontFlags THICKOUTLINE")
  assertEqual(NS.GetSetting("target.fontFlags"), "THICKOUTLINE")
  NS.Slash:OnSlash("set target.fontFlags @skin")
  assertEqual(NS.GetSetting("target.fontFlags"), FROM_SKIN)
end)

-- ── the drawing: flags ───────────────────────────────────────────────────────────────────────

test("skin fonts: From skin draws through the Font outline", clean(function()
  -- red under: the stored value handed to SetFont as is ("@skin" is no flag the client knows).
  local el, cfg = probe("castbar")
  Skin:SetOutline(OWNER, "all")
  Element.Reskin(el, cfg, cfg, true)
  assertEqual(select(2, drawn(el)), "OUTLINE", "All text: outlined")
  Skin:SetOutline(OWNER, "hud")
  Element.Reskin(el, cfg, cfg, true)
  assertEqual(select(2, drawn(el)), "OUTLINE", "HUD text only: the HUD is outlined")
  Skin:SetOutline(OWNER, "off")
  Element.Reskin(el, cfg, cfg, true)
  assertEqual(select(2, drawn(el)), "", "Off: none")
  assertEqual(select(3, el.text2:GetFont()), "", "both lines")
end))

test("skin fonts: a flag the player picked wins over the Font outline", clean(function()
  local el, cfg = probe("target")
  Skin:SetOutline(OWNER, "off")
  cfg.fontFlags = "THICKOUTLINE"
  Element.Reskin(el, cfg, nil, true)
  assertEqual(select(2, drawn(el)), "THICKOUTLINE")
  cfg.fontFlags = ""
  Skin:SetOutline(OWNER, "all")
  Element.Reskin(el, cfg, nil, true)
  assertEqual(select(2, drawn(el)), "", "None stays none under All text")
end))

test("skin fonts: a Font outline change restyles the live elements", clean(function()
  -- red under: the memo built from the stored flag, which an outline change never moves.
  Skin:SetOutline(OWNER, "off")
  settle()
  for _, unit in ipairs(NS.Units.LIST) do
    local bar = NS.CastBars.__bars[unit]
    assertEqual(select(3, bar.text:GetFont()), "", unit .. "'s cast bar lost its outline")
  end
  Skin:SetOutline(OWNER, "all")
  settle()
  for _, unit in ipairs(NS.Units.LIST) do
    assertEqual(select(3, NS.CastBars.__bars[unit].text:GetFont()), "OUTLINE", unit .. " outlined again")
  end
end))

-- ── the drawing: sizes (D-09) ────────────────────────────────────────────────────────────────

test("skin fonts: on the skin's face the HUD size scales with the skin; its own face keeps it", clean(function()
  -- red under: SetFont handed the stored size whatever the skin (Obsidian's face would read wider).
  local el, cfg = probe("pet")
  cfg.fontSize = 12
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  settle()
  Element.Reskin(el, cfg, nil, true)
  assertEqual((drawn(el)), 13, "Obsidian draws a stored 12 at 13")
  assertEqual(cfg.fontSize, 12, "the stored size is never rewritten")
  cfg.fontFromSkin = false
  Element.Reskin(el, cfg, nil, true)
  assertEqual((drawn(el)), 12, "its own face: the stored size")
  cfg.fontFromSkin = true
  Skin:SetIgnore(OWNER, nil, true)
  settle()
  Element.Reskin(el, cfg, nil, true)
  assertEqual((drawn(el)), 12, "Ignore fonts: the stored size")
end))

test("skin fonts: Ka0s Default keeps the stored size, and Master scale still multiplies", clean(function()
  local el, cfg = probe("castbar")
  cfg.fontSize = 11
  Element.Reskin(el, cfg, cfg, true)
  assertEqual((drawn(el)), 11, "Ka0s Default is the baseline")
  local scale = NS.GetSetting("scale")
  local ok, err = pcall(function()
    NS.db.profile.scale = 2
    Element.Reskin(el, cfg, cfg, true)
    assertEqual((drawn(el)), 22)
  end)
  NS.db.profile.scale = scale
  if not ok then error(err, 0) end
end))

test("skin fonts: a skin switch moves the drawn size on the live elements", clean(function()
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  settle()
  local stored = NS.GetSetting("target.fontSize")
  local want = NS.Skin.HudFontSize(stored, true) * (NS.GetSetting("scale") or 1)
  assertTrue(want ~= stored, "Obsidian scales the target frames' size")
  for _, unit in ipairs(NS.Units.LIST) do
    local btn = NS.TargetFrames.__buttons[unit]
    assertEqual(select(2, btn.text:GetFont()), want, unit .. "'s target frame")
  end
end))

-- ── the v3 migration (Addendum 01) ────────────────────────────────────────────────────────────

--- Run `fn(stored)` from a stamp of 2 with `profiles` added to the stored profiles, then put the
--- stamp and the stored set back.
local function fromV2(profiles, fn)
  local g, stored = NS.db.global, NS.db.sv.profiles
  local stamp = g.schemaVersion
  for name, p in pairs(profiles) do stored[name] = p end
  g.schemaVersion = 2
  local ok, err = pcall(fn, stored)
  for name in pairs(profiles) do stored[name] = nil end
  g.schemaVersion = stamp
  if not ok then error(err, 0) end
end

test("skin fonts: v3 moves a stored OUTLINE onto From skin, on every stored profile", function()
  local a = { castbar = { fontFlags = "OUTLINE" }, target = { fontFlags = "THICKOUTLINE" } }
  local b = { pet = { fontFlags = "OUTLINE" }, target = { fontFlags = "" } }
  fromV2({ A = a, B = b }, function()
    NS:RunMigrations()
    assertEqual(NS.db.global.schemaVersion, 3)
    assertEqual(a.castbar.fontFlags, FROM_SKIN, "the old default follows the skin")
    assertEqual(a.target.fontFlags, "THICKOUTLINE", "a picked flag stays")
    assertEqual(b.pet.fontFlags, FROM_SKIN, "every profile")
    assertEqual(b.target.fontFlags, "", "None stays")
    assertEqual(a.pet, nil, "a section never stored is not created")
  end)
end)

test("skin fonts: v3 runs once; an OUTLINE the player picks after it is kept", function()
  local p = { castbar = { fontFlags = "OUTLINE" } }
  fromV2({ P = p }, function()
    NS:RunMigrations()
    assertEqual(p.castbar.fontFlags, FROM_SKIN)
    p.castbar.fontFlags = "OUTLINE"
    NS:RunMigrations()
    -- red under: the step re-applied on every load (no stamp, or the stamp ignored).
    assertEqual(p.castbar.fontFlags, "OUTLINE", "the player's pick survives a reload")
  end)
end)
