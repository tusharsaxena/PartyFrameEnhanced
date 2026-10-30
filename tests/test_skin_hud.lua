-- tests/test_skin_hud.lua — the HUD through the skin (PF-03 of the 2026-10-29 skinning rollout;
-- skinning-§6, owner ruling R3 / O2).
--
-- The cast bars, target frames and pet frames draw three media picks: the bar texture, the border
-- style and the text face. Each composer group takes its `fromSkin` companion ("Use the skin's
-- texture / border / font"), defaulting to true (X3), and modules/Element.lua resolves the pick
-- through S.Resolve while it is on. Only those three follow the skin: colors, sizes, flags and
-- the shadow stay the player's (X4). A skin switch restyles every element live, and the v2
-- migration step sets the companions once on every stored profile (O2), the border only where no
-- border is drawn (D2), and never again after the player changes one.

local T = _G.PFE_TEST
local NS, mocks = T.NS, T.mocks
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local Element = NS.Element
local Skin = mocks.LibStub("LibKa0s-Skin-1.0")
local OWNER = "PartyFrameEnhanced"
local SECTIONS = { "castbar", "target", "pet" }
local COMPANIONS = { "barTextureFromSkin", "borderStyleFromSkin", "fontFromSkin" }

local function settle()
  while mocks.__fireTimers() > 0 do end
end

local function choose(skin)
  Skin:SetChoice(OWNER, "ka0s", skin)
  settle()
end

--- Run `fn` with NS.FetchMedia recording every (kind, key) it is asked for, on Ka0s Default before
--- and after, whatever `fn` raised.
local function withFetches(fn)
  return function()
    choose("ka0s")
    local orig = NS.FetchMedia
    local fetched = {}
    NS.FetchMedia = function(kind, key, fallback)
      fetched[#fetched + 1] = { kind = kind, key = key }
      return orig(kind, key, fallback)
    end
    local ok, err = pcall(fn, fetched)
    NS.FetchMedia = orig
    choose("ka0s")
    if not ok then error(err, 0) end
  end
end

--- The last key `fetched` asked for of `kind`.
local function lastKey(fetched, kind)
  for i = #fetched, 1, -1 do
    if fetched[i].kind == kind then return fetched[i].key end
  end
end

--- A fresh probe element and a copy of `section`'s defaults to draw it with.
local function probe(section)
  local el = Element.Build(mocks.CreateFrame("Frame", nil, mocks.UIParent), { icon = section == "castbar" })
  local cfg = {}
  for k, v in pairs(NS.defaults.profile[section]) do cfg[k] = v end
  cfg.borderShow = true
  return el, cfg
end

-- ── the defaults and the rows ──────────────────────────────────────────────────────────────────

test("skin hud: every HUD section's three companions default to true (X3)", function()
  for _, section in ipairs(SECTIONS) do
    for _, key in ipairs(COMPANIONS) do
      assertEqual(NS.defaults.profile[section][key], true, section .. "." .. key)
    end
  end
end)

test("skin hud: each companion is a composed bool row defaulting to true, written through the seam", function()
  for _, section in ipairs(SECTIONS) do
    for _, key in ipairs(COMPANIONS) do
      local path = section .. "." .. key
      local row = NS.FindSchemaRow(path)
      assertTrue(row ~= nil, path .. " has a schema row")
      assertEqual(row.type, "bool", path)
      assertEqual(row.default, true, path .. " row default")
    end
    NS.SetByPath(section .. ".fontFromSkin", false)
    assertEqual(NS.GetSetting(section .. ".fontFromSkin"), false, section .. ": the seam writes it")
    NS.SetByPath(section .. ".fontFromSkin", true)
  end
end)

-- ── the drawing ────────────────────────────────────────────────────────────────────────────────

test("skin hud: following the skin, an element draws Ka0s Default's bar, border and HUD face",
  withFetches(function(fetched)
    local el, cfg = probe("castbar")
    Element.Reskin(el, cfg, cfg, true)
    assertEqual(lastKey(fetched, "statusbar"), NS.Skin.Token("bar.texture"), "the bar texture")
    assertEqual(lastKey(fetched, "border"), NS.Skin.Token("bar.borderStyle"), "the border style")
    assertEqual(lastKey(fetched, "font"), NS.Skin.Token("hud.font"), "the HUD face")
    assertEqual(lastKey(fetched, "font"), "Ka0s Prototype", "Ka0s Default's face (X5)")
  end))

test("skin hud: a companion turned off draws the player's own pick again", withFetches(function(fetched)
  local el, cfg = probe("target")
  cfg.barTextureFromSkin, cfg.borderStyleFromSkin, cfg.fontFromSkin = false, false, false
  Element.Reskin(el, cfg, nil, true)
  assertEqual(lastKey(fetched, "statusbar"), "Blizzard", "the stored texture")
  assertEqual(lastKey(fetched, "border"), "Blizzard Tooltip", "the stored border")
  assertEqual(lastKey(fetched, "font"), "Friz Quadrata TT", "the stored face")
end))

test("skin hud: a skin that leaves a token alone falls back to the player's pick", withFetches(function(fetched)
  local orig = NS.Skin.Resolve
  NS.Skin.Resolve = function(kind, value, fromSkin)
    if kind == "hud.font" then return nil end
    return orig(kind, value, fromSkin)
  end
  local ok, err = pcall(function()
    local el, cfg = probe("pet")
    Element.Reskin(el, cfg, nil, true)
  end)
  NS.Skin.Resolve = orig
  if not ok then error(err, 0) end
  assertEqual(lastKey(fetched, "font"), "Friz Quadrata TT", "no token: the stored face")
end))

test("skin hud: the structure memo holds the RESOLVED keys, so a skin switch restyles", withFetches(function()
  local el, cfg = probe("pet")
  assertTrue(Element.Reskin(el, cfg, nil), "the first restyle runs")
  assertTrue(not Element.Reskin(el, cfg, nil), "nothing moved: the structural half is skipped")
  choose("obsidian")
  -- red under: the signature built from the stored picks, which a skin switch never moves.
  assertTrue(NS.Skin.Token("hud.font") ~= "Ka0s Prototype", "Obsidian has its own HUD face")
  assertTrue(Element.Reskin(el, cfg, nil), "a new skin's keys move the memo")
  choose("ka0s")
  assertTrue(Element.Reskin(el, cfg, nil), "and back")
  cfg.fontFromSkin = false   -- Friz, the stored pick, against Ka0s Default's Prototype
  assertTrue(Element.Reskin(el, cfg, nil), "a companion toggle moves the memo")
end))

test("skin hud: Ignore fonts gives the HUD the player's own face back, live", withFetches(function(fetched)
  -- Ka0s Default, whose HUD face (Prototype) differs from the stored pick (Friz). The library's own
  -- S.Resolve answers the stored pick for hud.font while the owner ignores fonts (LibKa0s v1.81.0,
  -- Skin minor 8), so the addon composes nothing on its side: no seam of its own is left.
  assertEqual(NS.SkinIgnoresFonts, nil, "the addon's own Ignore fonts seam is gone")
  local el, cfg = probe("castbar")
  Element.Reskin(el, cfg, cfg, true)
  assertEqual(lastKey(fetched, "font"), "Ka0s Prototype", "following: the skin's face")
  local ok, err = pcall(function()
    Skin:SetIgnore(OWNER, nil, true)
    settle()
    -- red under: S.Resolve ignoring the owner's ignoreFonts for hud.font.
    assertTrue(Element.Reskin(el, cfg, cfg), "toggling Ignore fonts moves the memo")
    assertEqual(lastKey(fetched, "font"), "Friz Quadrata TT", "ignoring fonts: the stored face")
    assertEqual(lastKey(fetched, "statusbar"), NS.Skin.Token("bar.texture"), "the texture still follows")
    -- The live cast bars restyled on the exception's own OnLooksChanged.
    for _, unit in ipairs(NS.Units.LIST) do
      assertTrue(NS.CastBars.__bars[unit].__structure:find("Friz Quadrata TT", 1, true) ~= nil,
        unit .. "'s cast bar went back to its own face")
    end
  end)
  Skin:SetIgnore(OWNER, nil, false)
  settle()
  if not ok then error(err, 0) end
  assertEqual(select(2, Skin:GetIgnore(OWNER)), false, "the exception off again")
  Element.Reskin(el, cfg, cfg)
  assertEqual(lastKey(fetched, "font"), "Ka0s Prototype", "the skin's face back, live")
end))

test("skin hud: the HUD colors stay the player's under every skin (X4)", withFetches(function()
  local el, cfg = probe("castbar")
  choose("ember")
  Element.Reskin(el, cfg, cfg, true)
  local seen
  rawset(el.text, "SetTextColor", function(_, r, g, b, a) seen = { r, g, b, a } end)
  Element.ApplyColors(el, cfg, Element.ClassResolver(nil))
  local c = cfg.fontColor
  assertEqual(seen[1], c.r)
  assertEqual(seen[2], c.g)
  assertEqual(seen[3], c.b)
  assertEqual(seen[4], c.a)
end))

test("skin hud: a skin switch restyles the live cast bars, target and pet frames", withFetches(function(fetched)
  choose("obsidian")
  local want = NS.Skin.Token("hud.font")
  local fonts = 0
  for _, f in ipairs(fetched) do
    if f.kind == "font" and f.key == want then fonts = fonts + 1 end
  end
  -- Five units each: the cast bars, then the target and pet frames through RunSecure.
  assertTrue(fonts >= 15, ("every element took the new face (%d fetches)"):format(fonts))
  for _, unit in ipairs(NS.Units.LIST) do
    local sig = NS.CastBars.__bars[unit].__structure
    assertTrue(sig:find(want, 1, true) ~= nil, unit .. "'s cast bar memo holds the new face")
    assertTrue(NS.TargetFrames.__buttons[unit].__structure:find(want, 1, true) ~= nil, unit .. " target")
    assertTrue(NS.PetFrames.__buttons[unit].__structure:find(want, 1, true) ~= nil, unit .. " pet")
  end
end))

-- ── the one-time reset (O2) ────────────────────────────────────────────────────────────────────

--- Run `fn(stored)` from a stamp of 1 with `profiles` added to the stored profiles, then put the
--- stamp and the stored set back.
local function fromV1(profiles, fn)
  local g, stored = NS.db.global, NS.db.sv.profiles
  local stamp = g.schemaVersion
  for name, p in pairs(profiles) do stored[name] = p end
  g.schemaVersion = 1
  local ok, err = pcall(fn, stored)
  for name in pairs(profiles) do stored[name] = nil end
  g.schemaVersion = stamp
  if not ok then error(err, 0) end
end

test("skin hud: v2 sets every stored profile's HUD companions to follow the skin", function()
  local old = {
    castbar = { barTexture = "Smooth", font = "Arial Narrow", barTextureFromSkin = false, fontFromSkin = false },
    target = { borderStyle = "Blizzard Dialog" },
  }
  fromV1({ Old = old }, function()
    NS:RunMigrations()
    assertEqual(NS.db.global.schemaVersion, 2)
    assertEqual(old.castbar.barTextureFromSkin, true, "texture follows")
    assertEqual(old.castbar.fontFromSkin, true, "font follows")
    assertEqual(old.castbar.borderStyleFromSkin, true, "no border drawn: the style follows")
    assertEqual(old.target.borderStyleFromSkin, true)
    assertEqual(old.castbar.barTexture, "Smooth", "the pick itself is kept, never the sentinel")
    assertEqual(old.castbar.font, "Arial Narrow")
    assertEqual(old.target.borderStyle, "Blizzard Dialog")
    assertEqual(old.pet, nil, "a section never stored is not created: its defaults follow already")
  end)
end)

test("skin hud: v2 keeps a drawn border the player's own (D2)", function()
  local shown = { target = { borderShow = true, borderStyle = "Blizzard Dialog" }, pet = { borderShow = false } }
  fromV1({ Shown = shown }, function()
    NS:RunMigrations()
    -- red under: borderStyleFromSkin = true everywhere, which hands a shown border to Ka0s
    -- Default's "None" and removes it.
    assertEqual(shown.target.borderStyleFromSkin, false, "a shown border keeps its style")
    assertEqual(shown.target.fontFromSkin, true, "its font still follows")
    assertEqual(shown.pet.borderStyleFromSkin, true, "a hidden border follows")
  end)
end)

test("skin hud: the reset runs once; a pick the player makes after it is kept", function()
  fromV1({}, function()
    NS:RunMigrations()
    assertEqual(NS.GetSetting("castbar.fontFromSkin"), true, "the active profile follows")
    NS.SetByPath("castbar.fontFromSkin", false)
    NS.SetByPath("castbar.font", "Arial Narrow")
    NS:RunMigrations()
    NS:RunMigrations()
    -- red under: the step re-applied on every load (no stamp, or the stamp ignored).
    assertEqual(NS.GetSetting("castbar.fontFromSkin"), false, "the player's choice survives a reload")
    assertEqual(NS.GetSetting("castbar.font"), "Arial Narrow")
    NS.SetByPath("castbar.fontFromSkin", true)
    NS.SetByPath("castbar.font", "Friz Quadrata TT")
  end)
end)
