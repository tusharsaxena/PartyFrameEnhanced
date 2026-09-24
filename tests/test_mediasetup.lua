-- tests/test_mediasetup.lua — the LibKa0s-Media-1.0 seam: paths are built from THIS addon's folder,
-- and a missing library answers nil and a real client font, never a guessed path.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local NS = T.NS

local loadDegraded = dofile("tests/degraded_env.lua")

test("mediasetup: the console's monospace face is the library's, under this addon's folder", function()
  local path = NS.Constants.FONT_MONO
  assertTrue(path:find("PartyFrameEnhanced", 1, true) ~= nil, "built from our folder: " .. path)
  assertTrue(path:find("LibKa0s", 1, true) ~= nil, "inside the vendored payload: " .. path)
end)

test("mediasetup: NS.Icon builds catalog paths from this addon's folder", function()
  local path = NS.Icon("close")
  assertTrue(path ~= nil, "the catalog ships a close mark")
  assertTrue(path:find("PartyFrameEnhanced", 1, true) ~= nil, "built from our folder: " .. path)
end)

test("mediasetup: without LibKa0s the face falls back to a real client font and icons answer nil", function()
  local NS2 = loadDegraded()
  assertEqual(NS2.Constants.FONT_MONO, NS2.Constants.FALLBACK_FONT)
  assertEqual(NS2.Icon("close"), nil)
end)

test("mediasetup: LOGO_PATH is the shipped logo, derived from the folder name", function()
  assertEqual(NS.Constants.LOGO_PATH,
    "Interface\\AddOns\\PartyFrameEnhanced\\media\\logos\\partyframeenhanced.logo.tga")
  -- red under: a hand-typed folder name, which a rename of the addon folder would leave stale.
  local NS3 = {}
  assert(loadfile("core/Constants.lua"))("SomeAddon", NS3)
  assertEqual(NS3.Constants.LOGO_PATH, "Interface\\AddOns\\SomeAddon\\media\\logos\\someaddon.logo.tga")
end)
