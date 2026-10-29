-- tests/test_skin_picker.lua — the first-run skin picker on this addon's seam (core/SkinSetup.lua;
-- LibKa0s OptionsSkinPicker 1, LibKa0s#64), and the Profiles page's AceGUI tree painted for this
-- owner (settings/Profiles.lua, NS.SkinPaintAceTree).
--
-- What this addon owes the picker, and nothing the library pins itself (LootHistory's
-- tests/test_skin_picker.lua is the shape): the spec it hands O.SkinPicker (its owner, its two
-- seams, the Skin tab's page and key, the eye, the close); WHEN it shows (a profile whose
-- `skin.pickerSeen` is false, once after the login or reload entry and after every profile event,
-- never while the addon stands down, held through combat); that only the player's close marks it
-- seen; and that the eye is this addon's preview, the unlock. The trigger cases spy on
-- O.SkinPicker; the window cases drive the library's real one.
--
-- Leaves the harness on Ka0s Default, the picker down and marked unseen, the elements locked.

local T = _G.PFE_TEST
local NS, mocks = T.NS, T.mocks
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local O = NS.Helpers
local Skin = mocks.LibStub("LibKa0s-Skin-1.0")
local OWNER = "PartyFrameEnhanced"
local PATH = "skin.pickerSeen"

local function settle()
  while mocks.__fireTimers() > 0 do end
end

local function quietly(fn)
  local cf = mocks.DEFAULT_CHAT_FRAME
  local add = cf.AddMessage
  cf.AddMessage = function() end
  local ok, err = pcall(fn)
  cf.AddMessage = add
  if not ok then error(err, 0) end
end

--- Run `fn(calls)` with O.SkinPicker replaced by a recorder: each call's spec, in order.
local function spying(fn)
  local real = O.SkinPicker
  local calls = {}
  O.SkinPicker = function(spec)
    calls[#calls + 1] = spec
    return { spy = true }
  end
  local ok, err = pcall(fn, calls)
  O.SkinPicker = real
  if not ok then error(err, 0) end
end

--- The picker down (quietly), this profile's key back to false and Ka0s Default worn, whatever
--- `fn` raised.
local function clean(fn)
  return function()
    local ok, err = pcall(function()
      quietly(function()
        NS.HideSkinPicker()
        NS.SetByPath(PATH, false)
        fn()
      end)
    end)
    quietly(function()
      NS.HideSkinPicker()
      if NS.db:GetCurrentProfile() ~= "Default" then NS.db:SetProfile("Default") end
      NS.HideSkinPicker()
      NS.SetByPath(PATH, false)
      NS.WriteSkinChoice("ka0s", "ka0s")
      Skin:SetChoice(OWNER, "ka0s", "ka0s")
      if NS.GetSetting("locked") ~= true then NS.SetByPath("locked", true) end
      settle()
    end)
    if not ok then error(err, 0) end
  end
end

-- ── the key and the spec ─────────────────────────────────────────────────────────────────────

test("Skin picker: the spec names this owner, its seams, the Skin tab and the eye", function()
  -- red under: a set that is not the write seam (a pick would never reach the profile), or a page
  -- or tab key O.SelectTab does not know (the gear would open the panel on the wrong tab).
  local spec = NS.SkinPickerSpec()
  assertEqual(spec.owner, OWNER)
  assertTrue(rawequal(spec.get, NS.SkinChoice), "get is the read seam")
  assertTrue(rawequal(spec.set, NS.WriteSkinChoice), "set is the write seam")
  assertEqual(spec.page, "general")
  assertEqual(spec.tab, "Appearance", "the Skin tab's key")
  assertTrue(O.__panelFor("general") ~= nil, "\"general\" is a page O.SelectTab finds")
  assertEqual(type(spec.onPreview), "function")
  assertEqual(type(spec.onClose), "function")
end)

-- ── when it shows ────────────────────────────────────────────────────────────────────────────

test("Skin picker: an unseen profile shows it; a seen one does not", clean(function()
  spying(function(calls)
    NS.MaybeShowSkinPicker()
    assertEqual(#calls, 1, "pickerSeen false: the picker shows")
    assertEqual(calls[1].owner, OWNER)
    NS.SetByPath(PATH, true)
    NS.MaybeShowSkinPicker()
    assertEqual(#calls, 1, "pickerSeen true: it does not show again")
  end)
end))

test("Skin picker: the login or reload entry lights a two-second fuse; a zone change does not", clean(function()
  -- red under: dropping the call from addon:OnEnterWorld, or calling it on every zone change.
  spying(function(calls)
    NS.addon:OnEnterWorld("PLAYER_ENTERING_WORLD", false, false)
    settle()
    assertEqual(#calls, 0, "a zone change shows nothing")
    NS.addon:OnEnterWorld("PLAYER_ENTERING_WORLD", true, false)
    NS.addon:OnEnterWorld("PLAYER_ENTERING_WORLD", false, true)
    assertEqual(#calls, 0, "nothing before the fuse burns")
    settle()
    assertEqual(#calls, 1, "the login fuse shows the picker, once for two entries")
  end)
end))

test("Skin picker: the stand-down puts out a lit fuse", clean(function()
  spying(function(calls)
    NS.addon:OnEnterWorld("PLAYER_ENTERING_WORLD", true, false)
    NS.SetByPath("enabled", false)
    local ok, err = pcall(function()
      assertTrue(NS.IsStoodDown(), "the switch stood the addon down")
      settle()
      assertEqual(#calls, 0, "a stood-down addon's fuse shows nothing")
    end)
    NS.SetByPath("enabled", true)
    settle()
    if not ok then error(err, 0) end
  end)
end))

test("Skin picker: in combat a start waits for PLAYER_REGEN_ENABLED, once", clean(function()
  local real = mocks.InCombatLockdown
  mocks.InCombatLockdown = function() return true end
  local ok, err = pcall(function()
    spying(function(calls)
      assertEqual(NS.MaybeShowSkinPicker(), nil)
      NS.MaybeShowSkinPicker()
      assertEqual(#calls, 0, "nothing shows in combat")
      mocks.InCombatLockdown = function() return false end
      mocks.__fireEvent("PLAYER_REGEN_ENABLED")
      assertEqual(#calls, 1, "the combat edge shows it, once for two held starts")
      mocks.__fireEvent("PLAYER_REGEN_ENABLED")
      assertEqual(#calls, 1, "the one-shot target is gone")
    end)
  end)
  mocks.InCombatLockdown = real
  if not ok then error(err, 0) end
end))

test("Skin picker: a held start is dropped by the stand-down's HideSkinPicker", clean(function()
  local real = mocks.InCombatLockdown
  mocks.InCombatLockdown = function() return true end
  local ok, err = pcall(function()
    spying(function(calls)
      NS.MaybeShowSkinPicker()
      NS.HideSkinPicker()
      mocks.InCombatLockdown = function() return false end
      mocks.__fireEvent("PLAYER_REGEN_ENABLED")
      assertEqual(#calls, 0, "a dropped start must not fire on the combat edge")
    end)
  end)
  mocks.InCombatLockdown = real
  if not ok then error(err, 0) end
end))

test("Skin picker: never while the addon is switched off", clean(function()
  spying(function(calls)
    NS.SetByPath("enabled", false)
    local ok, err = pcall(function()
      assertTrue(NS.IsStoodDown(), "the switch stood the addon down")
      NS.MaybeShowSkinPicker()
      assertEqual(#calls, 0, "a disabled addon shows no picker")
    end)
    NS.SetByPath("enabled", true)
    settle()
    if not ok then error(err, 0) end
  end)
end))

test("Skin picker: a new profile and a reset profile show it again", clean(function()
  -- Both start from the defaults, pickerSeen false (O3). red under: no call on the profile adopt
  -- path, or one before the latch re-reads the new profile's switch.
  local db = NS.db
  NS.SetByPath(PATH, true)
  spying(function(calls)
    db:SetProfile("PickerProbe")
    settle()
    assertEqual(#calls, 1, "a new profile shows the picker")
    NS.SetByPath(PATH, true)
    db:ResetProfile()
    settle()
    assertEqual(#calls, 2, "a reset profile shows it again")
    NS.SetByPath(PATH, true)
    db:SetProfile("Default")
    settle()
    assertEqual(#calls, 2, "back on a profile that has seen it: no picker")
  end)
  if db.DeleteProfile then pcall(db.DeleteProfile, db, "PickerProbe", true) end
end))

-- ── the real window ──────────────────────────────────────────────────────────────────────────

test("Skin picker: the player's close marks it seen; this addon's own hide does not", clean(function()
  local f = NS.MaybeShowSkinPicker()
  assertTrue(f ~= nil and f:IsShown(), "the library's picker did not show")
  NS.HideSkinPicker()
  assertEqual(NS.GetSetting(PATH), false, "a stand-down hide is not the player's close")
  f = NS.MaybeShowSkinPicker()
  assertTrue(f ~= nil and f:IsShown(), "it shows again while unseen")
  O.HideSkinPicker()
  assertEqual(NS.GetSetting(PATH), true, "the player's close sets pickerSeen")
  assertEqual(NS.MaybeShowSkinPicker(), nil, "and it does not show again")
end))

test("Skin picker: a profile that has seen it takes a shown picker down, unmarked", clean(function()
  local f = NS.MaybeShowSkinPicker()
  assertTrue(f ~= nil and f:IsShown())
  NS.db.profile.skin.pickerSeen = true
  NS.MaybeShowSkinPicker()
  assertFalse(f:IsShown(), "the picker stayed up on a profile that has seen it")
end))

test("Skin picker: a profile switch takes a shown picker down before the new skin", clean(function()
  -- red under: the hide after NS.ApplySkinChoice (the put-back would undo the new profile's skin).
  local f = NS.MaybeShowSkinPicker()
  assertTrue(f ~= nil and f:IsShown())
  local order = {}
  local hide, apply = NS.HideSkinPicker, NS.ApplySkinChoice
  NS.HideSkinPicker = function(...) order[#order + 1] = "hide"; return hide(...) end
  NS.ApplySkinChoice = function(...) order[#order + 1] = "apply"; return apply(...) end
  local downAfter
  local ok, err = pcall(function()
    spying(function()
      NS.db:SetProfile("PickerProbe2")
      settle()
      downAfter = not f:IsShown()
    end)
  end)
  NS.HideSkinPicker, NS.ApplySkinChoice = hide, apply
  if NS.db.DeleteProfile then
    NS.db:SetProfile("Default")
    pcall(NS.db.DeleteProfile, NS.db, "PickerProbe2", true)
  end
  if not ok then error(err, 0) end
  assertEqual(order[1], "hide", "the picker goes down first")
  assertEqual(order[2], "apply", "then the new profile's skin")
  assertTrue(downAfter, "the old profile's showing is down")
end))

test("Skin picker: the eye unlocks through the write seam, this addon's preview", clean(function()
  -- red under: an eye that writes the lock around the seam (no Preview refusals, no [Set] line), or
  -- one that does nothing (the picker would show no eye a player can use).
  assertEqual(NS.GetSetting("locked"), true)
  NS.SkinPickerSpec().onPreview()
  settle()
  assertEqual(NS.GetSetting("locked"), false, "the eye unlocks")
  assertTrue(NS.State.preview == true, "and preview is on")
end))

test("Skin picker: the eye in combat is the unlock's own refusal", clean(function()
  local real = mocks.InCombatLockdown
  mocks.InCombatLockdown = function() return true end
  local ok, err = pcall(function() NS.SkinPickerSpec().onPreview() end)
  mocks.InCombatLockdown = real
  if not ok then error(err, 0) end
  assertEqual(NS.GetSetting("locked"), true, "no unlock in combat")
end))

test("Skin picker: Apply with no pick saves nothing and marks the picker seen", clean(function()
  -- The window's own controls are the library's; this addon owns the seams they reach.
  local f = NS.MaybeShowSkinPicker()
  assertTrue(f ~= nil and f:IsShown())
  assertTrue(f.apply ~= nil, "the window has Apply")
  f.apply:__fire("OnClick")
  settle()
  assertFalse(f:IsShown(), "Apply closes the window")
  assertEqual(select(2, NS.SkinChoice()), "ka0s", "nothing picked, nothing saved")
  assertEqual(NS.GetSetting(PATH), true, "Apply marks the picker seen")
end))

test("Skin picker: the write seam a saved pick reaches stores both halves", clean(function()
  -- Apply, the gear and Apply to all call spec.set(source, key); a pick itself never does.
  NS.SkinPickerSpec().set("ka0s", "obsidian")
  assertEqual(select(2, NS.SkinChoice()), "obsidian")
  assertEqual(NS.GetSetting("skin.source"), "ka0s")
end))

-- ── the Profiles page's AceGUI tree ──────────────────────────────────────────────────────────

--- Build the Profiles page over stub AceConfig libraries and show it once; answers the containers
--- NS.SkinPaintAceTree was handed, in order, with the owner each paint named.
local function profilesPaints()
  local libs = mocks.__libs
  local saved = {}
  for _, n in ipairs({ "AceDBOptions-3.0", "AceConfig-3.0", "AceConfigDialog-3.0", "AceGUI-3.0" }) do
    saved[n] = libs[n]
  end
  local opened = 0
  libs["AceDBOptions-3.0"] = { GetOptionsTable = function() return { type = "group" } end }
  libs["AceConfig-3.0"] = { RegisterOptionsTable = function() end }
  libs["AceConfigDialog-3.0"] = { Open = function() opened = opened + 1 end }
  libs["AceGUI-3.0"] = {
    Create = function()
      return { frame = mocks.CreateFrame("Frame"), SetLayout = function() end }
    end,
  }
  local H = NS.Helpers
  local builder, ctx
  local register, createPanel = NS.RegisterOptionsPage, H.CreatePanel
  local paintTree = Skin.PaintAceTree
  local paints = {}
  Skin.PaintAceTree = function(_, owner, container)
    paints[#paints + 1] = { owner = owner, container = container, opened = opened }
    return 1
  end
  NS.RegisterOptionsPage = function(_, _, b) builder = b end
  H.CreatePanel = function(...) ctx = createPanel(...); return ctx end
  local ok, err = pcall(function()
    local Loader = dofile("tests/_kit/loader.lua")
    Loader.addonName = OWNER
    Loader.load("settings/Profiles.lua", NS, mocks)
    assertTrue(builder ~= nil, "settings/Profiles.lua registered no page")
    builder({})
    assertTrue(ctx ~= nil, "the page built no panel")
    ctx.panel:Show()
    ctx.panel:__fire("OnShow")
  end)
  NS.RegisterOptionsPage, H.CreatePanel, Skin.PaintAceTree = register, createPanel, paintTree
  for n, v in pairs(saved) do libs[n] = v end
  for _, n in ipairs({ "AceDBOptions-3.0", "AceConfig-3.0", "AceConfigDialog-3.0", "AceGUI-3.0" }) do
    if saved[n] == nil then libs[n] = nil end
  end
  mocks.__subcategories["Profiles"] = nil
  if ctx then
    ctx.panel:Hide()
    ctx.panel:__fire("OnHide")
  end
  if not ok then error(err, 0) end
  return paints
end

test("Profiles page: the tree AceConfigDialog drew is painted for this owner, after the Open", function()
  -- red under: no paint (AceConfigDialog acquires past the owner proxy, so its rows stay stock
  -- under every skin), or a paint before the Open (the rows it draws would miss it).
  local paints = profilesPaints()
  assertTrue(#paints >= 1, "the Profiles renderer painted nothing")
  assertEqual(paints[1].owner, OWNER)
  assertTrue(paints[1].container ~= nil and paints[1].container.frame ~= nil, "the container is painted")
  assertTrue(paints[1].opened >= 1, "painted after AceConfigDialog:Open")
end)

test("Profiles page: the seam binds the owner and degrades to nothing painted", function()
  local real = Skin.PaintAceTree
  local seen
  Skin.PaintAceTree = function(_, owner) seen = owner; return 3 end
  local n = NS.SkinPaintAceTree({})
  Skin.PaintAceTree = real
  assertEqual(seen, OWNER)
  assertEqual(n, 3)
  Skin.PaintAceTree = nil
  local ok, got = pcall(NS.SkinPaintAceTree, {})
  Skin.PaintAceTree = real
  assertTrue(ok, "a copy without SkinAce must not raise")
  assertEqual(got, 0)
end)
