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

test("parity: a bare /pfe runs `config` in the library-absent build too", function()
  local NS2 = loadDegraded()
  local opens = 0
  NS2.OpenOptionsPanel = function() opens = opens + 1 end
  NS2.Slash.__cli:OnSlash("  ")
  assertTrue(opens == 1, "the stub dispatcher sent bare input to `config`")
end)

test("parity: the Slash stub dispatches verbs, aliases, typos and the disabled gate as the library does", function()
  local NS2, mocks2 = loadDegraded()
  local cli = NS2.Slash.__cli
  local function dispatch(msg)
    local before = #mocks2.__chat
    cli:OnSlash(msg)
    local out = {}
    for i = before + 1, #mocks2.__chat do out[#out + 1] = mocks2.__chat[i] end
    return out
  end
  local opens = 0
  NS2.OpenOptionsPanel = function() opens = opens + 1 end
  -- The first print of a library-less build carries the once-per-session missing-library notice;
  -- spend it here so the line counts below are the dispatcher's alone.
  dispatch("version")

  -- Running: the verb is lowercased, an alias resolves, a typo gets `unknown command` then help.
  local out = dispatch("  VERSION  ")
  assertTrue(#out == 1 and out[1]:find("v" .. NS2.Version(), 1, true) ~= nil, "`VERSION` ran the version verb")
  dispatch("options")
  assertTrue(opens == 1, "the `options` alias reached `config`")
  out = dispatch("wibble")
  assertTrue(#out > 1 and out[1]:find("unknown command 'wibble'", 1, true) ~= nil,
    "a typo got unknown command and then the help index")

  -- Disabled: a feature verb refuses on one line; a live verb and the bare form still answer; a typo
  -- is still a typo, not a refusal.
  -- This environment never runs InitDB, so there is no stored tree to write. The dispatcher asks the
  -- getter at dispatch time (settings/Slash.lua `isEnabled`), which is the seam to answer through.
  local getSetting = NS2.GetSetting
  NS2.GetSetting = function(path)
    if path == "enabled" then return false end
    return getSetting(path)
  end
  local line = cli:DisabledLine()
  out = dispatch("unlock")
  assertTrue(#out == 1 and out[1]:find(line, 1, true) ~= nil, "`unlock` refused on one line")
  out = dispatch("version")
  assertTrue(#out == 1 and out[1]:find(line, 1, true) == nil, "`version` answered while disabled")
  dispatch("")
  assertTrue(opens == 2, "the bare form opened the panel while disabled")
  out = dispatch("wibble")
  assertTrue(out[1]:find("unknown command 'wibble'", 1, true) ~= nil, "a typo while disabled is unknown")
end)
