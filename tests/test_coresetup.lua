-- tests/test_coresetup.lua — the LibKa0s-Core-1.0 seam: the printer, its tag, the reclaim from
-- AceConsole, the close-button wrapper, and the degraded arm.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local NS, mocks = T.NS, T.mocks

local loadDegraded = dofile("tests/degraded_env.lua")

test("coresetup: NS.Print is the library printer, reclaimed from AceConsole's embed", function()
  -- red under: dropping the reclaim in core/PartyFrameEnhanced.lua, which leaves AceConsole's green,
  -- untagged :Print on NS (architecture-§2, anti-pattern #36).
  assertTrue(NS.Print == NS.Util.print, "NS.Print and NS.Util.print are one function object")
end)

test("coresetup: printed lines carry the cyan [PFE] tag", function()
  local before = #mocks.__chat
  NS.Print("hello")
  local line = mocks.__chat[before + 1]
  assertTrue(line ~= nil, "a line was printed")
  assertTrue(line:find("|cff00ffff[PFE]|r", 1, true) == 1, "the line opens with the cyan tag: " .. line)
end)

test("coresetup: NS.MakeCloseButton hands the library this addon's folder name", function()
  -- red under: a two-argument call, which silently draws the fallback glyph (anti-pattern #64).
  local Core = mocks.LibStub("LibKa0s-Core-1.0")
  local orig, seen = Core.MakeCloseButton, nil
  Core.MakeCloseButton = function(_, _, folder) seen = folder end
  NS.MakeCloseButton({}, function() end)
  Core.MakeCloseButton = orig
  assertEqual(seen, "PartyFrameEnhanced")
end)

test("coresetup: without LibKa0s the printer still prints, and says the library is missing once", function()
  local NS2, mocks2 = loadDegraded()
  NS2.Print("one")
  NS2.Print("two")
  local missing = 0
  for _, line in ipairs(mocks2.__chat) do
    if line:find("LibKa0s library is missing", 1, true) then missing = missing + 1 end
  end
  assertEqual(missing, 1, "the missing-library line is said once, not per line")
  assertTrue(mocks2.__chat[#mocks2.__chat]:find("two", 1, true) ~= nil, "and the lines still print")
end)
