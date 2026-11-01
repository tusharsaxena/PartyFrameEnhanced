-- tests/test_skin_flip.lua — the HUD's colors and shadow follow the skin (FS-PF-FLIP, causes D2, D3,
-- D4 and D6 of Ka0sAddonsCommonTasks docs/2026-11-01-FULL_SKINNING).
--
-- What this addon owes (LibKa0s Options doc, "Moving to this version"): each color and the shadow
-- have a "Use the skin's ..." companion, default on, drawn after the class color and every meaning
-- color and before the stored swatch; Ka0s Default keeps this addon's pixels through its owner
-- tokens; and the one per-profile step moves existing profiles onto the skin, naming companions and
-- the From skin flags only, so every stored pick and color survives for a player who turns a
-- companion off.
--
-- After test_skin_hud; every case leaves the skin on Ka0s Default.

local T = _G.PFE_TEST
local NS, mocks = T.NS, T.mocks
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local Element = NS.Element
local Skin = mocks.LibStub("LibKa0s-Skin-1.0")
local OWNER = "PartyFrameEnhanced"
local S = NS.Skin
local SECTIONS = { "castbar", "target", "pet" }
local COMPANIONS = { "barColorFromSkin", "bgColorFromSkin", "borderColorFromSkin", "fontColorFromSkin",
  "fontShadowFromSkin" }
local LISTED = { "barTextureFromSkin", "borderStyleFromSkin", "fontFromSkin", "barColorFromSkin",
  "bgColorFromSkin", "borderColorFromSkin", "fontColorFromSkin", "fontShadowFromSkin" }
local FILL_TOKEN = { castbar = "pf.castFill", target = "pf.targetFill", pet = "pf.petFill" }

local function rgba(...) return table.concat({ ... }, ",") end

local function swatch(c) return rgba(c.r, c.g, c.b, c.a) end

--- A deep, order-free print of `v`, so "byte-identical" means every leaf.
local function dump(v)
  if type(v) ~= "table" then return tostring(v) end
  local keys, out = {}, {}
  for k in pairs(v) do keys[#keys + 1] = tostring(k) end
  table.sort(keys)
  for _, k in ipairs(keys) do out[#out + 1] = k .. "=" .. dump(v[k]) end
  return "{" .. table.concat(out, ";") .. "}"
end

local function deep(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, x in pairs(v) do out[k] = deep(x) end
  return out
end

local function choose(skin)
  Skin:SetChoice(OWNER, "ka0s", skin)
  while mocks.__fireTimers() > 0 do end
end

local function onSkin(key, fn)
  return function()
    choose(key)
    local ok, err = pcall(fn)
    choose("ka0s")
    if not ok then error(err, 0) end
  end
end

--- A fresh probe element, a copy of `section`'s defaults to draw it with, and a spy on the setters
--- each flipped surface draws through. `drawn` holds the last values each setter took.
local function probe(section)
  local el = Element.Build(mocks.CreateFrame("Frame", nil, mocks.UIParent), { icon = section == "castbar" })
  local cfg, drawn = deep(NS.defaults.profile[section]), {}
  local function spy(frame, method, key)
    frame[method] = function(_, ...) drawn[key] = rgba(...) end
  end
  spy(el.bg, "SetVertexColor", "bg")
  spy(el.border, "SetBackdropBorderColor", "border")
  spy(el.text, "SetTextColor", "text")
  spy(el.text2, "SetTextColor", "text2")
  spy(el.text, "SetShadowColor", "shadowColor")
  spy(el.text, "SetShadowOffset", "shadowOffset")
  el.border.SetBackdrop = function(_, b) drawn.backdrop = b end
  el.border.ClearBackdrop = function() drawn.backdrop = false end
  return el, cfg, drawn
end

--- `fn` with the skin answering a real border: no shipped skin does (SkinDefs bar.borderStyle None).
local function withSkinBorder(fn)
  local orig = NS.Skin.Resolve
  NS.Skin.Resolve = function(kind, value, fromSkin)
    if fromSkin and kind == "bar.borderStyle" then return "Blizzard Dialog" end
    if fromSkin and kind == "bar.borderSize" then return 3 end
    return orig(kind, value, fromSkin)
  end
  local ok, err = pcall(fn)
  NS.Skin.Resolve = orig
  if not ok then error(err, 0) end
end

-- ── the rows and the defaults ───────────────────────────────────────────────────────────────────

test("skin flip: every section's color and shadow companions are bool rows defaulting on, in both places", function()
  local groups = { barColorFromSkin = NS.L["Fill"], bgColorFromSkin = NS.L["Background"],
    borderColorFromSkin = NS.L["Border"], fontColorFromSkin = NS.L["Font"], fontShadowFromSkin = NS.L["Font"] }
  for _, section in ipairs(SECTIONS) do
    for _, key in ipairs(COMPANIONS) do
      local path = section .. "." .. key
      local row = NS.FindSchemaRow(path)
      assertTrue(row ~= nil, "no row " .. path)
      assertEqual(row.type, "bool", path)
      assertEqual(row.default, true, path .. " defaults on on the row")
      assertEqual(NS.defaults.profile[section][key], true, path .. " defaults on in AceDB")
      assertEqual(row.subgroup, groups[key], path)
      assertTrue(type(row.desc) == "string" and row.desc:find("not read while this is on", 1, true) ~= nil,
        path .. "'s tooltip says the row it governs is not read")
    end
    assertEqual(NS.FindSchemaRow(section .. ".fontColorFromSkin").label, NS.L["Use the skin's color"])
    assertEqual(NS.FindSchemaRow(section .. ".fontShadowFromSkin").label, NS.L["Use the skin's shadow"])
  end
end)

test("skin flip: no swatch carries disabledIf, and no class or meaning color has a companion", function()
  -- red under: a composed swatch grayed by its companion (options-ui-§17).
  for _, section in ipairs(SECTIONS) do
    for _, key in ipairs({ "barColor", "bgColor", "borderColor", "fontColor", "fontShadow" }) do
      assertEqual(NS.FindSchemaRow(section .. "." .. key).disabledIf, nil, key)
    end
    for _, key in ipairs({ "useClassColorBar", "useClassColorBg", "useClassColorBorder", "useClassColorFont" }) do
      assertEqual(NS.FindSchemaRow(section .. "." .. key .. "FromSkin"), nil, key)
    end
  end
  for _, path in ipairs({ "castbar.channelColorFromSkin", "castbar.empowerColorFromSkin",
    "castbar.uninterruptibleColorFromSkin", "castbar.failedColorFromSkin", "target.hostileColorFromSkin",
    "target.neutralColorFromSkin", "target.friendlyColorFromSkin" }) do
    assertEqual(NS.FindSchemaRow(path), nil, path)
  end
end)

test("skin flip: the picks' defaults moved to the Ka0s picks, in both places", function()
  for _, section in ipairs(SECTIONS) do
    local d = NS.defaults.profile[section]
    assertEqual(d.barTexture, "Ka0s Default", section)
    assertEqual(d.font, "Ka0s Prototype", section)
    assertEqual(NS.FindSchemaRow(section .. ".barTexture").default, "Ka0s Default", section)
    assertEqual(NS.FindSchemaRow(section .. ".font").default, "Ka0s Prototype", section)
    assertEqual(d.fontFlags, "@skin", section)
    assertEqual(NS.FindSchemaRow(section .. ".fontFlags").default, "@skin", section)
  end
end)

test("skin flip: the border is on, and its thickness is the skin's through the composer", function()
  for _, section in ipairs(SECTIONS) do
    assertEqual(NS.defaults.profile[section].borderShow, true, section)
    local size = NS.FindSchemaRow(section .. ".borderSize")
    assertEqual(size.disabledIf, section .. ".borderStyleFromSkin", section)
    assertEqual(size.skinValue(size), S.Token("bar.borderSize"), section)
  end
end)

-- ── what the elements draw ──────────────────────────────────────────────────────────────────────

test("skin flip: Ka0s Default keeps this addon's pixels: fill, background, text, no edge, no shadow", function()
  for _, section in ipairs(SECTIONS) do
    local el, cfg, drawn = probe(section)
    Element.Reskin(el, cfg, cfg, true)
    local resolve = Element.ClassResolver(nil)
    Element.ApplyColors(el, cfg, resolve)
    assertEqual(rgba(Element.FillColor(cfg, resolve, FILL_TOKEN[section])), swatch(cfg.barColor), section .. " fill")
    assertEqual(drawn.bg, swatch(cfg.bgColor), section .. " background")
    assertEqual(drawn.text, swatch(cfg.fontColor), section .. " text")
    assertEqual(drawn.text2, swatch(cfg.fontColor), section .. " second text")
    assertEqual(drawn.backdrop, false, section .. ": Ka0s Default's style is None, so no edge is drawn")
    assertEqual(drawn.border, nil, section .. ": no color on an edge that is not there")
    assertEqual(drawn.shadowColor, rgba(0, 0, 0, 0), section .. " no shadow")
  end
end)

test("skin flip: a shown border draws the skin's style, thickness and color", function()
  withSkinBorder(function()
    local el, cfg, drawn = probe("target")
    Element.Reskin(el, cfg, nil, true)
    Element.ApplyColors(el, cfg, Element.ClassResolver(nil))
    assertTrue(type(drawn.backdrop) == "table", "the edge is drawn")
    assertEqual(drawn.backdrop.edgeSize, 3, "bar.borderSize, not the stored 8")
    assertEqual(drawn.border, rgba(S.Color("bar.border")), "bar.border")
    cfg.borderStyleFromSkin, cfg.borderColorFromSkin = false, false
    cfg.borderColor = { r = 1, g = 0, b = 0, a = 1 }
    Element.Reskin(el, cfg, nil)
    Element.ApplyColors(el, cfg, Element.ClassResolver(nil))
    assertEqual(drawn.backdrop.edgeSize, cfg.borderSize, "companion off: the stored thickness")
    assertEqual(drawn.border, rgba(1, 0, 0, 1), "and the stored color")
  end)
end)

test("skin flip: Show border off still draws no edge under a skin that has one", function()
  withSkinBorder(function()
    local el, cfg, drawn = probe("pet")
    cfg.borderShow = false
    Element.Reskin(el, cfg, nil, true)
    Element.ApplyColors(el, cfg, Element.ClassResolver(nil))
    assertEqual(drawn.backdrop, false)
    assertEqual(drawn.border, nil)
  end)
end)

test("skin flip: a skin switch changes what every element's fill, background and text draw", function()
  -- The setters themselves, on the live elements through the switch: comparing getters proves nothing.
  local p = NS.db.profile
  local reaction = p.target.colorReaction
  p.target.colorReaction, p.target.enabled, p.pet.enabled, p.castbar.enabled = false, true, true, true
  p.target.anchorMode, p.pet.anchorMode, p.castbar.anchorMode = "free", "free", "free"
  p.enabled, p.visibility = true, "always"
  NS.PublishVisibility()
  NS.Slash:OnSlash("unlock")
  local live = { castbar = NS.CastBars.__bars.party1, target = NS.TargetFrames.__buttons.party1,
    pet = NS.PetFrames.__buttons.party1 }
  local drawn = {}
  for section, el in pairs(live) do
    local d = {}
    drawn[section] = d
    el.bar.SetStatusBarColor = function(_, ...) d.fill = rgba(...) end
    el.bg.SetVertexColor = function(_, ...) d.bg = rgba(...) end
    el.text.SetTextColor = function(_, ...) d.text = rgba(...) end
  end
  local ok, err = pcall(function()
    choose("obsidian")
    for section in pairs(live) do
      local d = drawn[section]
      assertEqual(d.fill, rgba(S.BarFillColor()), section .. " fill: the skin's bar.fill")
      assertEqual(d.bg, rgba(S.Color("bar.bg")), section .. " background: bar.bg")
      assertEqual(d.text, rgba(S.HudTextColor()), section .. " text: hud.text")
      d.fill, d.bg, d.text = nil, nil, nil
    end
    choose("ka0s")
    for section in pairs(live) do
      local d, c = drawn[section], p[section]
      assertEqual(d.fill, swatch(c.barColor), section .. " fill back on Ka0s Default's pixels")
      assertEqual(d.bg, swatch(c.bgColor), section .. " background back")
      assertEqual(d.text, swatch(c.fontColor), section .. " text back")
    end
  end)
  for _, el in pairs(live) do
    el.bar.SetStatusBarColor, el.bg.SetVertexColor, el.text.SetTextColor = nil, nil, nil
  end
  NS.Slash:OnSlash("lock")
  p.target.colorReaction = reaction
  choose("ka0s")
  if not ok then error(err, 0) end
end)

test("skin flip: a companion off draws the stored color", onSkin("obsidian", function()
  for _, section in ipairs(SECTIONS) do
    local el, cfg, drawn = probe(section)
    cfg.barColorFromSkin, cfg.bgColorFromSkin, cfg.fontColorFromSkin = false, false, false
    cfg.barColor = { r = 0.1, g = 0.2, b = 0.3, a = 0.4 }
    cfg.bgColor = { r = 0.5, g = 0.6, b = 0.7, a = 0.8 }
    cfg.fontColor = { r = 0.9, g = 0.1, b = 0.2, a = 1 }
    local resolve = Element.ClassResolver(nil)
    Element.ApplyColors(el, cfg, resolve)
    assertEqual(rgba(Element.FillColor(cfg, resolve, FILL_TOKEN[section])), swatch(cfg.barColor), section)
    assertEqual(drawn.bg, swatch(cfg.bgColor), section)
    assertEqual(drawn.text, swatch(cfg.fontColor), section)
  end
end))

test("skin flip: a class color comes first, whatever the companion says", onSkin("obsidian", function()
  local c = mocks.RAID_CLASS_COLORS.MAGE
  local resolve = Element.ClassResolver("MAGE")
  local el, cfg, drawn = probe("target")
  cfg.useClassColorBar, cfg.useClassColorBg, cfg.useClassColorFont = true, true, true
  local r, g, b = Element.FillColor(cfg, resolve, "pf.targetFill")
  assertEqual(rgba(r, g, b), rgba(c.r, c.g, c.b), "the fill")
  Element.ApplyColors(el, cfg, resolve)
  assertEqual(drawn.bg, rgba(c.r, c.g, c.b, cfg.bgColor.a), "the background, at its stored alpha")
  assertEqual(drawn.text, rgba(c.r, c.g, c.b, cfg.fontColor.a), "the text")
end))

test("skin flip: every meaning color stays under a skin", onSkin("obsidian", function()
  local p = NS.db.profile
  local el = NS.TargetFrames.__buttons.party1
  local filled
  p.target.enabled, p.target.anchorMode, p.enabled, p.visibility = true, "free", true, "always"
  NS.PublishVisibility()
  el.bar.SetStatusBarColor = function(_, ...) filled = rgba(...) end
  mocks.__units.party1target = { name = "Boar", health = 50, healthMax = 100, pct = 50, reaction = 2 }
  local ok, err = pcall(function()
    el:__fire("OnEvent", "UNIT_TARGET", "party1")
    assertEqual(filled, swatch(p.target.hostileColor), "a hostile NPC keeps the hostile color")
  end)
  el.bar.SetStatusBarColor = nil
  mocks.__units.party1target = nil
  if not ok then error(err, 0) end
end))

test("skin flip: without the library the stored color draws, not a token's default", function()
  local NS2 = dofile("tests/degraded_env.lua")()
  local stored = { r = 0.1, g = 0.2, b = 0.3, a = 0.4 }
  local cfg = { barColor = stored, barColorFromSkin = true }
  assertEqual(rgba(NS2.Element.FillColor(cfg, NS2.Element.ClassResolver(nil), "pf.castFill")), swatch(stored))
end)

-- ── the shadow ──────────────────────────────────────────────────────────────────────────────────

test("skin flip: a skin's shadow draws, and a skin that says none draws none over a stored shadow", function()
  local el, cfg, drawn = probe("castbar")
  cfg.fontShadow = true
  assertEqual(S.HudShadow(), false, "Ka0s Default's hud.shadow")
  Element.Reskin(el, cfg, cfg, true)
  assertEqual(drawn.shadowColor, rgba(0, 0, 0, 0), "no shadow, whatever the stored row says")
  choose("obsidian")
  local ok, err = pcall(function()
    local x, y, r, g, b, a = S.HudShadow()
    assertTrue(Element.Reskin(el, cfg, cfg), "the skin's shadow moves the memo")
    assertEqual(drawn.shadowOffset, rgba(x, y), "the skin's offset")
    assertEqual(drawn.shadowColor, rgba(r, g, b, a), "the skin's color")
  end)
  choose("ka0s")
  if not ok then error(err, 0) end
end)

test("skin flip: two skins alike but for the shadow still redraw a string that has drawn", function()
  -- LibKa0s Options doc, Moving to, section 5. red under: a signature that signs only the stored
  -- fontShadow, which leaves the old skin's shadow up. Same face, size and flags on both sides.
  local el, cfg, drawn = probe("pet")
  Element.Reskin(el, cfg, nil, true)
  local prim, saved = Skin.prim, Skin.prim.HudShadow
  prim.HudShadow = function() return 2, -2, 0.1, 0.2, 0.3, 1 end
  local ok, err = pcall(function()
    assertTrue(Element.Reskin(el, cfg, nil), "the resolved shadow moved the memo")
    assertEqual(drawn.shadowOffset, rgba(2, -2))
    assertEqual(drawn.shadowColor, rgba(0.1, 0.2, 0.3, 1))
    assertTrue(not Element.Reskin(el, cfg, nil), "and nothing else moved")
  end)
  prim.HudShadow = saved
  if not ok then error(err, 0) end
end)

test("skin flip: the companion off draws the stored shadow under every skin", onSkin("obsidian", function()
  local el, cfg, drawn = probe("target")
  cfg.fontShadowFromSkin, cfg.fontShadow = false, true
  Element.Reskin(el, cfg, nil, true)
  assertEqual(drawn.shadowOffset, rgba(1, -1), "the stored row's stock offset")
  assertEqual(drawn.shadowColor, rgba(0, 0, 0, 1), "in black")
  cfg.fontShadow = false
  assertTrue(Element.Reskin(el, cfg, nil), "the stored row moves the memo")
  assertEqual(drawn.shadowColor, rgba(0, 0, 0, 0), "off clears it")
end))

test("skin flip: Ignore fonts leaves the stored shadow standing", onSkin("obsidian", function()
  local el, cfg, drawn = probe("target")
  cfg.fontShadow = true
  Skin:SetIgnore(OWNER, nil, true)
  local ok, err = pcall(function()
    assertEqual(S.HudShadow(), nil, "the library's nil")
    Element.Reskin(el, cfg, nil, true)
    assertEqual(drawn.shadowOffset, rgba(1, -1), "the stored row stands")
  end)
  Skin:SetIgnore(OWNER, nil, false)
  if not ok then error(err, 0) end
end))

test("skin flip: the shadow lands on a font object where the client has CreateFont", onSkin("obsidian", function()
  -- A 12.0.7 client draws only a font object's shadow. red under: the shadow set on the FontString.
  local el, cfg = probe("castbar")
  local handed
  local function object(name)
    local o = { name = name, calls = {} }
    for _, m in ipairs({ "SetFont", "SetShadowColor", "SetShadowOffset" }) do
      o[m] = function(_, ...) o.calls[m] = { ... } end
    end
    return o
  end
  local saved = rawget(_G, "CreateFont")
  rawset(_G, "CreateFont", object)
  el.text.SetFontObject = function(_, o) handed = o end
  local ok, err = pcall(function()
    Element.Reskin(el, cfg, cfg, true)
    assertTrue(handed ~= nil, "the name took a font object")
    local x, y, r, g, b, a = S.HudShadow()
    assertEqual(rgba(unpack(handed.calls.SetShadowOffset)), rgba(x, y))
    assertEqual(rgba(unpack(handed.calls.SetShadowColor)), rgba(r, g, b, a))
  end)
  rawset(_G, "CreateFont", saved)
  Skin.__hudFonts[el.text] = nil
  Skin.__hudFonts[el.text2] = nil
  if not ok then error(err, 0) end
end))

-- ── the one step ────────────────────────────────────────────────────────────────────────────────

--- A stored partial profile: some companions stored false, some absent, a color with one key, a
--- section missing whole.
local function partial()
  return {
    skin = { source = "ka0s", skin = "obsidian", ignorePanel = false, ignoreFonts = true },
    castbar = {
      font = "My Font", barTexture = "My Bar", borderStyle = "My Border", borderSize = 7, fontSize = 15,
      fontShadow = true, fontFlags = "THICKOUTLINE", borderShow = true,
      barColor = { r = 0.9 }, bgColor = { r = 0.1, g = 0.2, b = 0.3, a = 0.4 }, borderColor = { g = 0.5 },
      fontColor = { b = 0.6, a = 1 }, channelColor = { r = 0.3 },
      useClassColorBar = true, useClassColorFont = false,
      barTextureFromSkin = false, fontFromSkin = false, borderStyleFromSkin = false, fontShadowFromSkin = false,
    },
    target = { barColor = { a = 0.5 }, colorReaction = false, hostileColor = { r = 1 } },
  }
end

test("skin flip: the step moves every listed key and leaves every pick and color byte-identical", function()
  local p = partial()
  local before = deep(p)
  assertEqual(NS.ResetProfileToSkin(p), true, "it ran")
  for _, section in ipairs({ "castbar", "target" }) do
    for _, key in ipairs(LISTED) do
      assertEqual(p[section][key], true, section .. "." .. key)
    end
    assertEqual(p[section].fontFlags, "@skin", section .. ": the flags' own name")
  end
  assertEqual(p.pet, nil, "a section never stored is not created")
  for _, key in ipairs({ "font", "barTexture", "borderStyle", "borderSize", "fontSize", "fontShadow", "barColor",
    "bgColor", "borderColor", "fontColor", "channelColor", "useClassColorBar", "useClassColorFont", "borderShow" }) do
    assertEqual(dump(p.castbar[key]), dump(before.castbar[key]), "castbar." .. key)
  end
  assertEqual(dump(p.target.barColor), dump(before.target.barColor), "a one-key color")
  assertEqual(dump(p.target.hostileColor), dump(before.target.hostileColor), "a meaning color")
  assertEqual(p.target.colorReaction, false, "its toggle")
  assertEqual(p.skin.ignorePanel, false, "the Scope's panel")
  assertEqual(p.skin.ignoreFonts, true, "the Scope's fonts")
  assertEqual(p.skin.skin, "obsidian", "the skin itself")
  assertEqual(p.skin.fullSkinReset, true, "the record")
  for section, sec in pairs({ castbar = p.castbar, target = p.target }) do
    assertEqual(sec.skin, nil, section .. " grew no stray skin table")
    for key, value in pairs(sec) do
      if key ~= "fontFlags" then assertTrue(value ~= "@skin", section .. "." .. key .. " holds the sentinel") end
    end
  end
end)

test("skin flip: the list names no size, class toggle, meaning color, Scope key, pick or swatch", function()
  for _, path in ipairs(NS.SKIN_RESET_PATHS) do
    local leaf = path:match("%.([^.]+)$")
    assertTrue(leaf == "fontFlags" or leaf:match("FromSkin$") ~= nil, path)
    assertTrue(not leaf:find("useClassColor", 1, true), path)
    assertTrue(path:match("^castbar%.") or path:match("^target%.") or path:match("^pet%."), path)
  end
  assertEqual(#NS.SKIN_RESET_PATHS, 27, "nine keys on three sections")
end)

test("skin flip: a second run writes nothing, and a companion turned off afterwards stays off", function()
  local p = partial()
  NS.ResetProfileToSkin(p)
  p.castbar.barColorFromSkin, p.castbar.fontFlags = false, "OUTLINE"
  local after = dump(p)
  assertEqual(NS.ResetProfileToSkin(p), false, "the record gates it")
  assertEqual(dump(p), after, "nothing moved")
end)

test("skin flip: the step creates the record's table on a raw profile with none", function()
  local p = {}
  assertEqual(NS.ResetProfileToSkin(p), true)
  assertEqual(dump(p), "{skin={fullSkinReset=true}}", "the one table it may create")
end)

test("skin flip: the step is the same write with the library absent", function()
  local NS2 = dofile("tests/degraded_env.lua")()
  local live, hand = partial(), partial()
  NS.ResetProfileToSkin(live)
  assertEqual(NS2.ResetProfileToSkin(hand), true, "it ran")
  assertEqual(dump(hand), dump(live), "byte for byte")
  assertEqual(NS2.ResetProfileToSkin(hand), false, "and the record gates it")
  local raw = {}
  NS2.ResetProfileToSkin(raw)
  assertEqual(dump(raw), "{skin={fullSkinReset=true}}", "a path through a missing table is skipped")
end)

test("skin flip: the record outlives every Defaults button, so a turned-off companion stays off", function()
  -- No schema row (KickCD's convention): no Defaults path can walk it. red under: a row of its own
  -- with no exemption, which a Defaults press puts back to false, and the next migration or profile
  -- event then forces every companion on.
  assertEqual(NS.FindSchemaRow("skin.fullSkinReset"), nil, "no row to reset")
  local p = NS.db.profile
  local saved = deep(p)
  local ok, err = pcall(function()
    p.skin.fullSkinReset = true
    p.pet.barColorFromSkin = false
    p.target.fontFlags = "OUTLINE"
    NS.Helpers.RestoreDefaults("general", {})
    NS.Helpers.RestoreDefaults("castbar", {})
    assertEqual(p.skin.fullSkinReset, true, "the record survives the press")
    NS:RunMigrations()
    assertEqual(p.pet.barColorFromSkin, false, "the migration")
    assertEqual(p.target.fontFlags, "OUTLINE", "the flag the player picked")
    NS.OnProfileChanged()
    assertEqual(p.pet.barColorFromSkin, false, "a profile event")
  end)
  for key, value in pairs(saved) do p[key] = value end
  NS.OnProfileChanged()
  if not ok then error(err, 0) end
end)

test("skin flip: the ladder walks every stored profile, and a profile event runs the step", function()
  local g, stored = NS.db.global, NS.db.sv.profiles
  local stamp = g.schemaVersion
  local old = partial()
  stored.Old = old
  g.schemaVersion = 3
  local ok, err = pcall(function()
    NS:RunMigrations()
    assertEqual(old.castbar.barColorFromSkin, true, "a stored, inactive profile moved")
    assertEqual(g.schemaVersion, NS.SCHEMA_VERSION)
    local p = NS.db.profile
    local record, off = p.skin.fullSkinReset, p.castbar.bgColorFromSkin
    p.skin.fullSkinReset, p.castbar.bgColorFromSkin = false, false
    NS.OnProfileChanged()
    assertEqual(p.castbar.bgColorFromSkin, true, "the profile event ran it")
    p.skin.fullSkinReset, p.castbar.bgColorFromSkin = record, off
  end)
  stored.Old = nil
  g.schemaVersion = stamp
  if not ok then error(err, 0) end
end)

test("skin flip: past the stamp the runner still moves an active profile with no record", function()
  local p = NS.db.profile
  local off = p.castbar.bgColorFromSkin
  p.skin.fullSkinReset, p.castbar.bgColorFromSkin = false, false
  NS:RunMigrations()
  assertEqual(p.skin.fullSkinReset, true)
  assertEqual(p.castbar.bgColorFromSkin, true, "a profile restored from a backup, say")
  p.castbar.bgColorFromSkin = off
end)

-- ── gloss and the icon's edge (FS-PF-FIX, causes A3 and A1) ─────────────────────────────────────

--- `body(el, cfg, gloss)` on a fresh element on the kit's paint recorder: the base mock's bars are no
--- StatusBar, and the library leaves those alone. `gloss()` is the layer.
local function withGlossBar(body)
  local restorePaint = dofile("tests/_kit/mock_paint.lua")(mocks)
  local savedCreate = rawget(_G, "CreateFrame")
  rawset(_G, "CreateFrame", mocks.CreateFrame)
  local el = Element.Build(mocks.CreateFrame("Frame", nil, mocks.UIParent), {})
  rawset(_G, "CreateFrame", savedCreate)
  local cfg = deep(NS.defaults.profile.pet)
  local ok, err = pcall(body, el, cfg, function()
    local rec = Skin.painted[el.bar]
    return rec and rec.regions.gloss
  end)
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  Skin:Untrack(el.bar)
  restorePaint()
  if not ok then error(err, 0) end
end

test("skin flip: a glossy skin glosses the fill; Ka0s Default and the player's own texture do not", function()
  -- red under: a bar that never reads bar.gloss, or a gloss left on after the skin moved on.
  withGlossBar(function(el, cfg, gloss)
    Element.Reskin(el, cfg, nil, true)
    assertEqual(gloss(), nil, "Ka0s Default has none")
    Skin:SetChoice(OWNER, "ka0s", "glass")
    Element.Reskin(el, cfg, nil)
    assertTrue(gloss() ~= nil, "Glass has it")
    assertEqual(gloss():IsShown(), true, "the layer shows")
    cfg.barTextureFromSkin = false
    assertTrue(Element.Reskin(el, cfg, nil), "the companion moves the memo")
    assertEqual(gloss():IsShown(), false, "the player's own texture stays plain")
    -- red under: a call that omits the companion, which a replay would shine again.
    Skin:SetChoice(OWNER, "ka0s", "obsidian")
    Skin:SetChoice(OWNER, "ka0s", "glass")
    assertEqual(gloss():IsShown(), false, "and through a skin switch's replay")
    cfg.barTextureFromSkin = true
    Element.Reskin(el, cfg, nil)
    assertEqual(gloss():IsShown(), true, "the companion back on")
    Skin:SetChoice(OWNER, "ka0s", "ka0s")
    assertEqual(gloss():IsShown(), false, "a switch away takes it off")
  end)
end)

test("skin flip: the memo signs the texture's companion when the pick equals the skin's key", function()
  -- The resolved key does not move here, so the gloss would keep the companion it last saw.
  local el, cfg = probe("pet")
  cfg.barTexture = NS.Skin.Token("bar.texture")
  Element.Reskin(el, cfg, nil, true)
  cfg.barTextureFromSkin = false
  assertTrue(Element.Reskin(el, cfg, nil), "a companion toggle restyles")
end)

test("skin flip: the cast bar's spell icon wears the skin's icon edge, recorded for a replay", function()
  local el, cfg = probe("castbar")
  cfg.showIcon = true
  local edge = el.iconEdge
  assertTrue(edge ~= nil, "a frame to carry it: the icon is a Texture")
  local rec = Skin.painted[edge]
  assertTrue(rec ~= nil, "S.IconBorder recorded it, so a skin change replays it")
  local top = rec.regions.edgeTop
  assertTrue(top ~= nil, "Ka0s Default's Solid 2 px edge")
  Element.Reskin(el, cfg, cfg, true)
  assertTrue(edge:IsShown(), "shown with the icon")
  cfg.showIcon = false
  Element.Reskin(el, cfg, cfg)
  assertTrue(not edge:IsShown(), "hidden with the icon")
  assertEqual(probe("target").iconEdge, nil, "no icon, no edge")
  Skin:Untrack(edge)
end)
