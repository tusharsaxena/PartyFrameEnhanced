-- tests/test_skin_outline.lua — the Font outline (LibKa0s v1.82.0, Skin minor 9; PF-01 of
-- Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK, ruling D-06): stored as skin.outline
-- ("all", "hud", the default since LibKa0s v1.83.0, ruling D-10 of the font pickers and skin faces
-- run, "off"), written only through the skin write seam (NS.WriteSkinChoice's
-- `media.outline`), and applied with Skin:SetOutline at load, on every profile event and on the row's
-- own write. The shape is LibKa0sSkinTester's tests/test_skin_outline.lua.

local T = _G.PFE_TEST
local NS, mocks = T.NS, T.mocks
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local loadDegraded = dofile("tests/degraded_env.lua")
local Skin = mocks.LibStub("LibKa0s-Skin-1.0")
local OWNER = "PartyFrameEnhanced"

local function settle()
  while mocks.__fireTimers() > 0 do end
end

--- Run `fn` with the outline back on the default, HUD text only, before and after, whatever `fn` raised.
local function clean(fn)
  return function()
    NS.SetByPath("skin.outline", "hud")
    settle()
    local ok, err = pcall(fn)
    NS.SetByPath("skin.outline", "hud")
    settle()
    if not ok then error(err, 0) end
  end
end

test("outline: a fresh profile stores HUD text only, the library's default", function()
  assertEqual(NS.defaults.profile.skin.outline, "hud")
  assertEqual(NS.defaults.profile.skin.outline, Skin.OUTLINE_DEFAULT)
  assertEqual(Skin:GetOutline(OWNER), "hud")
end)

test("outline: the schema row is the Skin tab's, with the library's three modes in its order", function()
  local row = NS.FindSchemaRow("skin.outline")
  assertTrue(row ~= nil, "a skin.outline row")
  assertTrue(row.skipRender == true, "the Skin tab draws it")
  assertEqual(row.group, "Appearance")
  assertEqual(table.concat(row.sorting, ","), table.concat(Skin.OUTLINE_MODES, ","))
  for _, mode in ipairs(Skin.OUTLINE_MODES) do
    assertTrue(row.values[mode] ~= nil, mode .. " has a label")
  end
end)

test("outline: the write seam stores media.outline, and leaves it alone when it is nil", clean(function()
  -- red under: WriteSkinChoice dropping media.outline (the Skin tab's Font outline and another
  -- addon's copy would move the look and never store it).
  NS.WriteSkinChoice(nil, nil, nil, { font = false, texture = false, outline = "hud" })
  assertEqual(NS.GetSetting("skin.outline"), "hud")
  NS.WriteSkinChoice(nil, nil, nil, { font = false, texture = false })
  assertEqual(NS.GetSetting("skin.outline"), "hud", "a media without outline leaves it")
  NS.WriteSkinChoice(nil, nil, nil, { font = false, texture = false, outline = "off" })
  assertEqual(NS.GetSetting("skin.outline"), "off")
end))

test("outline: another addon's copy reaches the store through WriteChoice", clean(function()
  local source, skin = NS.SkinChoice()
  Skin:WriteChoice(OWNER, source, skin, nil, { font = false, texture = false, outline = "off" })
  assertEqual(NS.GetSetting("skin.outline"), "off")
end))

test("outline: /pfe set applies the mode live, and refuses one the library does not know", clean(function()
  NS.SetByPath("skin.outline", "all")
  settle()
  NS.Slash:OnSlash("set skin.outline hud")
  settle()
  assertEqual(Skin:GetOutline(OWNER), "hud")
  assertEqual(NS.Skin.FontFlags(NS.Skin.FROM_SKIN), "OUTLINE", "the HUD keeps it")
  assertEqual(NS.Skin.FontFlags(NS.Skin.FROM_SKIN, "window"), "", "window text loses it")
  NS.Slash:OnSlash("set skin.outline off")
  settle()
  assertEqual(NS.Skin.FontFlags(NS.Skin.FROM_SKIN), "", "Off takes both")
  NS.Slash:OnSlash("set skin.outline thick")
  assertEqual(NS.GetSetting("skin.outline"), "off", "an unknown mode is refused")
end))

test("outline: applying the stored profile carries its Font outline", clean(function()
  -- red under: ApplySkinChoice's whole-pair path not applying the stored outline (NS:InitDB and
  -- every profile event call it with no argument).
  NS.db.profile.skin.outline = "off"
  NS.ApplySkinChoice()
  assertEqual(Skin:GetOutline(OWNER), "off")
end))

test("outline: a profile switch applies the incoming profile's mode, and back", clean(function()
  local db = NS.db
  local start = db:GetCurrentProfile()
  local ok, err = pcall(function()
    NS.SetByPath("skin.outline", "off")
    db:SetProfile("PFE-OutlineProbe")
    settle()
    assertEqual(Skin:GetOutline(OWNER), "hud", "the new profile keeps the default")
    db:SetProfile(start)
    settle()
    assertEqual(Skin:GetOutline(OWNER), "off", "the start profile's is back")
  end)
  if db:GetCurrentProfile() ~= start then db:SetProfile(start) end
  pcall(db.DeleteProfile, db, "PFE-OutlineProbe", true)
  settle()
  if not ok then error(err, 0) end
end))

test("outline: without the skin engine the apply is a quiet no-op", function()
  local NS2 = loadDegraded()
  assertEqual(NS2.ApplySkinOutline(), false)
  assertEqual(NS2.ApplySkinOutline("off"), false)
end)
