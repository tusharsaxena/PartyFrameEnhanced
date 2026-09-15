-- tests/test_surface_parity.lua — every degradation stub carries the whole live surface it stands in
-- for (testing-§8). The degraded arm comes from a real library-absent load (tests/degraded_env.lua),
-- never from a hand-written stub; a member that is live-only on purpose is named with its reason.

local T = _G.PFE_TEST
local test, assertTrue = T.test, T.assertTrue
local NS = T.NS

local loadDegraded = dofile("tests/degraded_env.lua")

test("parity: the Core stub publishes everything core/CoreSetup.lua publishes live", function()
  -- Derived from the source, so a new publication joins this case in the commit that adds it.
  local f = io.open("core/CoreSetup.lua", "r")
  local src = f:read("*a")
  f:close()
  local live, n = {}, 0
  for name in src:gmatch("\nNS%.([A-Za-z_]+)%s*=") do
    if NS[name] ~= nil then live[name] = NS[name]; n = n + 1 end
  end
  assertTrue(n >= 5, "the derivation found only " .. n .. " publications")
  T.assertSurfaceParity(live, loadDegraded(), "Core stub")
end)

test("parity: the DebugLog stub carries the whole live surface", function()
  local NS2 = loadDegraded()
  T.assertSurfaceParity(NS2.DebugLog, "LibKa0s-DebugLog-1.0", {
    -- The formatters and text accessors: nothing outside the library calls them, and a stub copy is
    -- the line-format drift the extraction ended.
    "FormatPlain", "FormatColored", "CopyText", "Text",
    -- Test seams the library stamps when it BUILDS the console window.
    "_frameForTest", "_toggleClickForTest",
  })
end)

test("parity: the Options stub carries every helper the degraded build can reach", function()
  local NS2 = loadDegraded()
  T.assertSurfaceParity(NS2.Helpers, "LibKa0s-Options-1.0", {
    -- lib.LAYOUT's numbers: a host copy of a library constant is the copy that goes stale, and
    -- every reader sits behind an AceGUI a library-less build never gets.
    "ROW_VSPACER", "SECTION_HEADING_H", "BUTTON_PAIR_REL", "PADDING_X",
    "CHROME_GAP", "TAB_H", "BANNER_H",
    -- The panel machinery: the stub answers these on NS (one honest line), not on Helpers.
    "CreateOptionsPanel", "OpenOptionsPanel", "RegisterOptionsPage",
    "BuildLandingPage", "RefreshScalars", "TextRow",
    -- The AceGUI handle only a live panel stashes.
    "AceGUI",
    -- No caller in this addon; a stub member with no caller is a copy waiting to go stale.
    "RefreshPanel", "PageBanner", "SubTabStrip",
    -- Constants the composers stamp onto their rows; nothing here reads the tables themselves.
    "CLASS_COLOR_NOTE", "FONT_FLAGS", "FONT_FLAGS_SORT", "VISIBILITY_SORT", "VISIBILITY_VALUES",
  })
end)

test("parity: the Slash stub carries every dispatcher member the addon calls", function()
  local NS2 = loadDegraded()
  assertTrue(type(NS.Slash.__cli) == "table" and type(NS2.Slash.__cli) == "table")
  T.assertSurfaceParity(NS2.Slash.__cli, "LibKa0s-Slash-1.0", {
    -- Live-only, no call site here: the stub renders a plain help row instead.
    "HelpHeader", "HelpRows", "BuildListLines", "CliVersion", "Text",
  })
end)
