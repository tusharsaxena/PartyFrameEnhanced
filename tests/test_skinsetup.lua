-- tests/test_skinsetup.lua — the LibKa0s-Skin-1.0 seam (core/SkinSetup.lua, skinning-§1, §2, §3).
--
-- What this addon owes the skin engine, and nothing the library pins itself (LootHistory's
-- tests/test_skinsetup.lua is the shape): the owner is registered under the folder name with this
-- addon's read and write seams and its own tokens; the skin.* keys default to Ka0s Default and are
-- skip-render schema rows on General's Appearance group; the Skin tab is General's last tab; the
-- profile's skin is applied when the store exists and FIRST on every profile event; and one pick,
-- from the tab, a bare `/pfe set` or another addon's copy, is ONE effective SetChoice (one
-- OnLooksChanged), however many store writes follow it.

local T = _G.PFE_TEST
local NS, mocks = T.NS, T.mocks
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local Skin = mocks.LibStub("LibKa0s-Skin-1.0")
local OWNER = "PartyFrameEnhanced"
local PATHS = { "skin.source", "skin.skin", "skin.ignorePanel", "skin.ignoreFonts", "skin.font",
  "skin.texture", "skin.pickerSeen" }

-- ONE listener for the whole file: the library keeps a listener for the session, so each case
-- resets the counter instead of registering again.
local looks = 0
NS.Skin.OnLooksChanged(function() looks = looks + 1 end)

local function settle()
  while mocks.__fireTimers() > 0 do end
end

--- Back on Ka0s Default, stored and applied, the Scope and the overrides at their defaults.
local function reset()
  NS.WriteSkinChoice("ka0s", "ka0s", { panel = true, fonts = false }, { font = false, texture = false })
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  Skin:SetIgnore(OWNER, true, false)
  Skin:SetOverride(OWNER, false, false)
  settle()
  looks = 0
end

--- Run `fn` with the skin reset before and after, whatever `fn` raised.
local function clean(fn)
  return function()
    reset()
    local ok, err = pcall(fn)
    reset()
    if not ok then error(err, 0) end
  end
end

--- `/pfe <msg>`, its chat lines discarded.
local function slash(msg)
  NS.Slash:OnSlash(msg)
end

local function rowFor(path)
  for _, row in ipairs(NS.Schema) do
    if row.path == path then return row end
  end
end

-- ── the owner ────────────────────────────────────────────────────────────────────────────────

test("Skin seam: the owner is the folder name, and NS.Skin is its facade", function()
  -- red under: registering under the brand or a typo (the library keys every frame and every
  -- listener by owner), or publishing a facade of some other owner.
  assertTrue(Skin:IsOwner(OWNER), "core/SkinSetup.lua did not register the owner")
  assertTrue(rawequal(NS.Skin, Skin:For(OWNER)), "NS.Skin is not Skin:For(\"PartyFrameEnhanced\")")
  assertEqual(NS.Skin.owner, OWNER)
  assertEqual(Skin:OwnerLabel(OWNER), "Ka0s Party Frame Enhanced", "the copy confirmation names the brand")
end)

test("Skin seam: the read answers Ka0s Default before the profile store exists", function()
  -- RegisterOwner calls `get` at FILE LOAD, before NS:InitDB; a getter that raised there would be a
  -- visible Lua error on every login.
  local db = NS.db
  NS.db = nil
  local ok, source, skin = pcall(NS.SkinChoice)
  local wok = pcall(NS.WriteSkinChoice, "ka0s", "obsidian")
  NS.db = db
  assertTrue(ok, "NS.SkinChoice raised without a store: " .. tostring(source))
  assertEqual(source, "ka0s")
  assertEqual(skin, "ka0s")
  assertTrue(wok, "NS.WriteSkinChoice raised without a store")
end)

test("Skin seam: the owner's own token keeps Ka0s Default's pixels and follows its role elsewhere", clean(function()
  -- X1, X2, X12: pf.mover is the free-placement plate's exact color today, and follows list.sel.
  -- red under: the token refused (a library family name), or a default that moved Ka0s Default.
  local c = NS.Skin.Token("pf.mover")
  assertTrue(type(c) == "table", "pf.mover is not a token of this owner")
  local want = NS.SKIN_TOKENS["pf.mover"].default
  for i = 1, 4 do assertTrue(math.abs(c[i] - want[i]) < 1e-6, "pf.mover[" .. i .. "] on Ka0s Default") end
  assertEqual(table.concat(want, ","), "0,0.6,1,0.25", "the plate's literal, byte for byte")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  local o, sel = NS.Skin.Token("pf.mover"), NS.Skin.Token("list.sel")
  for i = 1, 4 do assertEqual(o[i], sel[i], "under Obsidian pf.mover follows list.sel [" .. i .. "]") end
end))

-- ── the keys and the rows ────────────────────────────────────────────────────────────────────

test("Skin seam: the skin keys default to Ka0s Default, and the picker unseen on every profile", function()
  -- red under: a default other than today's look; the Scope moved off LootHistory's (panel left the
  -- client's, fonts skinned); or pickerSeen true, which would skip O3's one-time picker.
  local d = NS.defaults.profile.skin
  assertEqual(d.source, "ka0s")
  assertEqual(d.skin, "ka0s")
  assertEqual(d.ignorePanel, true)
  assertEqual(d.ignoreFonts, false)
  assertEqual(d.font, "")
  assertEqual(d.texture, "")
  assertEqual(d.pickerSeen, false)
end)

test("Skin seam: every skin key is a skip-render row in General's Appearance group", function()
  -- The library's tab draws them; a row that rendered itself would draw a second control on top.
  for _, path in ipairs(PATHS) do
    local row = rowFor(path)
    assertTrue(row ~= nil, path .. " is not a schema row")
    assertEqual(row.page, "general", path .. ": page")
    assertEqual(row.group, "Appearance", path .. ": group (the library tab's key)")
    assertTrue(row.skipRender == true, path .. ": the tab draws it, so it must be skipRender")
  end
end)

test("Skin seam: the skin row's values are every registered skin, in the library's order", function()
  local row = rowFor("skin.skin")
  local skins = Skin:Skins()
  assertEqual(#row.sorting, #skins, "one value per registered skin")
  for i, def in ipairs(skins) do
    assertEqual(row.sorting[i], def.key, "value " .. i)
    assertTrue(row.values[def.key] ~= nil, def.key .. " has no label")
  end
  assertEqual(row.sorting[1], "ka0s", "Ka0s Default first")
end)

-- ── the write seam ───────────────────────────────────────────────────────────────────────────

test("Skin seam: /pfe set refuses a skin that is not registered and applies one that is", clean(function()
  slash("set skin.skin no-such-skin")
  assertEqual(NS.GetSetting("skin.skin"), "ka0s", "an unknown skin was stored")
  assertEqual(looks, 0, "a refused set repainted")
  slash("set skin.skin obsidian")
  assertEqual(NS.GetSetting("skin.skin"), "obsidian", "a registered skin was refused")
  local _, applied = Skin:GetChoice(OWNER)
  assertEqual(applied, "obsidian", "a bare set must move the applied skin (the row's onChange)")
  assertEqual(looks, 1, "one set, one repaint")
end))

test("Skin seam: the write seam lands every half through NS.SetByPath", clean(function()
  -- red under: a seam that writes the profile around NS.SetByPath (no validation, no [Set] line,
  -- no onChange), or one that drops the Scope or the overrides.
  local seen = {}
  local set = NS.SetByPath
  NS.SetByPath = function(path, v, ...) seen[#seen + 1] = path; return set(path, v, ...) end
  local ok, err = pcall(NS.WriteSkinChoice, "ka0s", "ember", { panel = false, fonts = true },
    { font = "Ka0s Expressway", texture = false })
  NS.SetByPath = set
  if not ok then error(err, 0) end
  assertEqual(table.concat(seen, ","), "skin.source,skin.skin,skin.ignorePanel,skin.ignoreFonts,skin.font,skin.texture")
  assertEqual(NS.GetSetting("skin.ignorePanel"), false)
  assertEqual(NS.GetSetting("skin.ignoreFonts"), true)
  assertEqual(NS.GetSetting("skin.font"), "Ka0s Expressway")
  assertEqual(NS.GetSetting("skin.texture"), "", "false is stored as \"\", the skin's own")
  local font, texture = NS.SkinOverride()
  assertEqual(font, "Ka0s Expressway")
  assertEqual(texture, false)
end))

test("Skin seam: another addon's copy to every Ka0s addon repaints this addon once", clean(function()
  -- The library's copy calls SetChoice for each owner, then WriteChoice, which reaches this addon's
  -- registered setter; each row's onChange then finds its half applied already.
  local source, skin = "ka0s", "ember"
  Skin:SetChoice(OWNER, source, skin)
  assertTrue(Skin:WriteChoice(OWNER, source, skin), "the copy's write did not reach this addon's setter")
  assertEqual(looks, 1, "a copy must repaint this addon exactly once")
  assertEqual(NS.GetSetting("skin.skin"), "ember", "the copy did not land in the profile")
end))

test("Skin seam: /pfe set reaches an exception and an override, and only its own half", clean(function()
  slash("set skin.ignoreFonts true")
  local panel, fonts = Skin:GetIgnore(OWNER)
  assertEqual(fonts, true, "the set applied")
  assertEqual(panel, true, "the other half untouched")
  slash("set skin.texture Solid")
  local font, texture = Skin:GetOverride(OWNER)
  assertEqual(texture, "Solid", "the texture override applied")
  assertTrue(not font, "the font override untouched")
end))

-- ── the profile ──────────────────────────────────────────────────────────────────────────────

test("Skin seam: applying the stored profile carries its exceptions and overrides", clean(function()
  -- NS:InitDB and the profile events call NS.ApplySkinChoice() with no argument.
  -- red under: applying the stored pair and not the Scope or the overrides.
  local p = NS.db.profile.skin
  p.skin, p.ignorePanel, p.ignoreFonts, p.font = "glass", false, true, "Ka0s Expressway"
  NS.ApplySkinChoice()
  assertEqual(select(2, Skin:GetChoice(OWNER)), "glass", "the stored skin")
  local panel, fonts = Skin:GetIgnore(OWNER)
  assertEqual(panel, false, "the stored panel exception")
  assertEqual(fonts, true, "the stored fonts exception")
  assertEqual((Skin:GetOverride(OWNER)), "Ka0s Expressway", "the stored font override")
end))

test("Skin seam: a profile switch applies the new profile's skin before anything is published", clean(function()
  -- red under: applying the skin after the PROFILE message (a handler would read the old skin), or
  -- not at all on a switch. The spy stands where adoptProfile's first publication-side step runs.
  local db = NS.db
  local start = db:GetCurrentProfile()
  local reeval, seen = NS.ReevaluateEnabled, nil
  local ok, err = pcall(function()
    db:SetProfile("PFE-SkinProbe")
    db.profile.skin.skin = "glass"
    db:SetProfile(start)
    settle()
    assertEqual(select(2, Skin:GetChoice(OWNER)), "ka0s", "back on the start profile, its skin")
    looks = 0
    NS.ReevaluateEnabled = function(...) seen = select(2, Skin:GetChoice(OWNER)); return reeval(...) end
    db:SetProfile("PFE-SkinProbe")
    NS.ReevaluateEnabled = reeval
    settle()
    assertEqual(seen, "glass", "the skin was not applied before the profile was published")
    assertEqual(select(2, Skin:GetChoice(OWNER)), "glass", "the switch did not move the applied skin")
    assertEqual(looks, 1, "one switch, one repaint")
  end)
  NS.ReevaluateEnabled = reeval
  if db:GetCurrentProfile() ~= start then db:SetProfile(start) end
  pcall(db.DeleteProfile, db, "PFE-SkinProbe", true)
  settle()
  if not ok then error(err, 0) end
end))

-- ── the tab ──────────────────────────────────────────────────────────────────────────────────

--- Show the General page and answer its render context and the widgets the render built. The page
--- builds on first show, so a render spy catches the context; a page shown before is re-rendered.
local function showGeneral()
  local H = NS.Helpers
  local ace = mocks.LibStub("AceGUI-3.0")
  local render, ctx = H.RenderTabbedSchema, nil
  H.RenderTabbedSchema = function(c, page, ...)
    if page == "general" then ctx = c end
    return render(c, page, ...)
  end
  local panel = mocks.__subcategories["General"]
  local ok, err = pcall(function()
    assertTrue(panel ~= nil, "the General page is not registered")
    panel:Show()
    panel:__fire("OnShow")
    if not ctx then panel:Hide(); panel:__fire("OnHide"); NS.RefreshOptionsPanel(); panel:Show(); panel:__fire("OnShow") end
  end)
  H.RenderTabbedSchema = render
  if not ok then error(err, 0) end
  return ctx, ace
end

test("Skin seam: Skin is General's last tab, and one pick there is one repaint", clean(function()
  -- skinning-§3: the library's tab, after every group tab (General has no Keybindings tab).
  -- red under: the host tab not handed to RenderTabbedSchema, or a row onChange that re-applies the
  -- whole stored pair (two repaints, the first to a half-written skin).
  local ctx, ace = showGeneral()
  assertTrue(ctx ~= nil, "the General page never rendered")
  local layout = ctx.__tabLayout
  assertTrue(layout ~= nil and layout.buttons ~= nil, "the General page drew no tab strip")
  assertEqual(#layout.buttons, 3, "Master controls, All elements, Skin")
  local mark = #ace.__created
  layout.buttons[3]:__fire("OnClick")
  assertEqual(ctx.activeTab, "Appearance", "the last tab is the library's Appearance (Skin) tab")
  local cb
  for i = mark + 1, #ace.__created do
    local w = ace.__created[i]
    local label = tostring(w.labelText or "")
    if w.type == "CheckBox" and label:sub(-#"Obsidian") == "Obsidian" then cb = w end
  end
  assertTrue(cb ~= nil, "the Skin tab drew no Obsidian choice")
  cb:SetValue(true); cb:__fire("OnValueChanged", true)
  settle()
  assertEqual(looks, 1, "one pick must repaint exactly once")
  assertEqual(select(2, Skin:GetChoice(OWNER)), "obsidian", "the pick did not move the applied skin")
  assertEqual(NS.GetSetting("skin.skin"), "obsidian", "the pick did not reach the profile")
  layout.buttons[1]:__fire("OnClick")
end))
