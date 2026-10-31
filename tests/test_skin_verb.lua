-- tests/test_skin_verb.lua — the reserved `skin` verb (LibKa0s v1.82.0, OptionsSkinPicker minor 3's
-- O.SkinVerb; PF-01 of Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK, ruling D-16):
-- a `skin` row after `config` runs NS.RunSkinVerb, which hands O.SkinVerb the first-run spec, so
-- `/pfe skin` shows the picker a new profile shows whatever skin.pickerSeen says. Refused while the
-- addon is disabled (the dispatcher's gate), a gray line on every call in combat (the library's),
-- and the library-absent line without LibKa0s. The shape is LibKa0sSkinTester's test_skin_verb.lua.
--
-- Leaves the harness on Ka0s Default, the picker down and marked unseen, the elements locked.

local T = _G.PFE_TEST
local NS, mocks = T.NS, T.mocks
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local loadDegraded = dofile("tests/degraded_env.lua")
local O = NS.Helpers
local Skin = mocks.LibStub("LibKa0s-Skin-1.0")
local OWNER = "PartyFrameEnhanced"
local PATH = "skin.pickerSeen"

local function settle()
  while mocks.__fireTimers() > 0 do end
end

local function strings() return mocks.LibStub("LibKa0s-Options-1.0").SKIN_PICKER_STRINGS end

--- `/pfe <msg>`, answering the chat lines it printed.
local function slash(msg, chat)
  chat = chat or mocks.__chat
  local before = #chat
  NS.Slash:OnSlash(msg)
  local out = {}
  for i = before + 1, #chat do out[#out + 1] = chat[i] end
  return out
end

local function anyLine(lines, fragment)
  for _, l in ipairs(lines) do
    if tostring(l):find(fragment, 1, true) then return true end
  end
  return false
end

--- The first-run picker closed on this profile, so only the verb can bring it back; puts back the
--- picker down, the key unseen, Ka0s Default, enabled and locked, whatever `fn` raised.
local function seen(fn)
  return function()
    local ok, err = pcall(function()
      NS.HideSkinPicker()
      NS.SetByPath(PATH, true)
      fn()
    end)
    NS.HideSkinPicker()
    NS.SetByPath("enabled", true)
    NS.SetByPath(PATH, false)
    NS.WriteSkinChoice("ka0s", "ka0s")
    Skin:SetChoice(OWNER, "ka0s", "ka0s")
    if NS.GetSetting("locked") ~= true then NS.SetByPath("locked", true) end
    settle()
    if not ok then error(err, 0) end
  end
end

test("skin verb: the row sits right after config, with the library's help words", function()
  local at
  for i, c in ipairs(NS.COMMANDS) do
    if c[1] == "skin" then at = i end
  end
  assertTrue(at ~= nil, "a skin row")
  assertEqual(NS.COMMANDS[at - 1][1], "config", "after config")
  assertEqual(NS.COMMANDS[at][2], strings().VERB_HELP, "one wording for every host")
end)

--- Run `fn` with O.SkinPicker recording each spec it is handed and passing it on.
local function recording(fn)
  local real, specs = O.SkinPicker, {}
  O.SkinPicker = function(spec)
    specs[#specs + 1] = spec
    local f, why = real(spec)
    specs.frame = f or specs.frame
    return f, why
  end
  local ok, err = pcall(fn, specs)
  O.SkinPicker = real
  if not ok then error(err, 0) end
end

test("skin verb: /pfe skin shows the picker on a profile that has closed it", seen(function()
  -- red under: no skin row (the dispatcher answers "unknown command").
  recording(function(specs)
    local out = slash("skin")
    assertFalse(anyLine(out, "unknown command"), "a known verb")
    assertEqual(#specs, 1, "one picker asked for, pickerSeen true or not")
    assertTrue(specs.frame ~= nil and specs.frame:IsShown(), "the picker is up")
  end)
end))

test("skin verb: NS.RunSkinVerb hands O.SkinVerb this addon's first-run spec", seen(function()
  local live, got = O.SkinVerb, nil
  O.SkinVerb = function(spec) got = spec; return nil, "queued" end
  local ok, win, why = pcall(NS.RunSkinVerb)
  O.SkinVerb = live
  assertTrue(ok, tostring(win))
  assertTrue(win == nil, "nothing shown")
  assertEqual(why, "queued", "the library's reason, passed on")
  assertEqual(got.owner, OWNER)
  assertTrue(rawequal(got.get, NS.SkinChoice), "the read seam")
  assertTrue(rawequal(got.set, NS.WriteSkinChoice), "the write seam")
  assertEqual(got.tab, "Appearance", "the gear opens the Skin tab")
end))

test("skin verb: in combat every call prints the library's gray line and shows nothing", seen(function()
  local real = mocks.InCombatLockdown
  mocks.InCombatLockdown = function() return true end
  local first, second, win, why
  local ok, err = pcall(function()
    first = slash("skin")
    second = slash("skin")
    win, why = NS.RunSkinVerb()
  end)
  mocks.InCombatLockdown = real
  if not ok then error(err, 0) end
  assertTrue(win == nil, "no picker mid-combat")
  assertEqual(why, "combat")
  assertTrue(anyLine(first, strings().VERB_COMBAT), "the first call says why")
  assertTrue(anyLine(second, strings().VERB_COMBAT), "and so does every later one")
end))

test("skin verb: refused while the addon is disabled, and no picker shows", seen(function()
  local calls = 0
  local live = O.SkinVerb
  O.SkinVerb = function(...) calls = calls + 1; return live(...) end
  local out
  local ok, err = pcall(function()
    NS.SetByPath("enabled", false)
    out = slash("skin")
  end)
  O.SkinVerb = live
  if not ok then error(err, 0) end
  assertEqual(#out, 1, "one refusal line")
  assertTrue(out[1]:find(NS.DisabledLine(), 1, true) ~= nil, "the collection's disabled line")
  assertEqual(calls, 0, "the picker was never asked for")
end))

test("skin verb: without LibKa0s the verb prints the library-absent line", function()
  local NS2, mocks2 = loadDegraded()
  local before = #mocks2.__chat
  NS2.Slash:OnSlash("skin")
  local out = {}
  for i = before + 1, #mocks2.__chat do out[#out + 1] = mocks2.__chat[i] end
  assertTrue(anyLine(out, "/pfe skin is unavailable: the LibKa0s library did not load."), "names the verb")
  local win, why = NS2.RunSkinVerb()
  assertTrue(win == nil, "no picker")
  assertEqual(why, "absent")
end)
