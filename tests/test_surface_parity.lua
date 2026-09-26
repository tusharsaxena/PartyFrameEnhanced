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

test("parity: the Core stub's SafeRegister* pcall a raising target, answer false and append once", function()
  -- red under: a stub body that calls the target bare (the raise escapes) or appends on every call.
  local NS2 = loadDegraded()
  assertTrue(NS2.SafeRegisterEvent ~= NS.SafeRegisterEvent, "the degraded load took the stub")
  local target = {
    RegisterEvent = function(_, event) if event == "BAD_EVENT" then error("unknown event") end end,
    RegisterUnitEvent = function(_, event) if event == "BAD_EVENT" then error("unknown event") end end,
  }
  local rejected = {}
  assertTrue(NS2.SafeRegisterEvent(target, "BAD_EVENT", nil, rejected) == false, "a raise answers false")
  assertTrue(NS2.SafeRegisterEvent(target, "BAD_EVENT", nil, rejected) == false, "and again")
  assertTrue(NS2.SafeRegisterUnitEvent(target, "BAD_EVENT", rejected, "party1") == false, "unit form too")
  assertTrue(#rejected == 1 and rejected[1] == "BAD_EVENT", "appended exactly once")
  assertTrue(NS2.SafeRegisterEvent(target, "GOOD_EVENT", nil, rejected) == true, "a known name answers true")
  assertTrue(NS2.SafeRegisterEvents(target, { "GOOD_EVENT", "BAD_EVENT", "OTHER" }, nil, rejected) == 2,
    "the array form counts what registered")
  assertTrue(#rejected == 1, "still once")
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

test("parity: the DebugLog stub's RunDiagnostics prints the library-absent line and writes nothing", function()
  -- red under: a stub RunDiagnostics that is a silent no-op (a player gets no answer), or one that
  -- appends to the stub buffer (debug-logging-§14, LibKa0s DebugLog 14.1's stub contract).
  local NS2, mocks2 = loadDegraded()
  local D = NS2.DebugLog
  NS2.Print("spend") -- the once-per-session missing-library notice rides the first printed line
  local before = #mocks2.__chat
  local n = D:RunDiagnostics()
  local want = NS2.L["%s is unavailable: the LibKa0s library did not load."]:format("/pfe diagnostics")
  assertTrue(n == 0, "counts 0 lines, got " .. tostring(n))
  assertTrue(#mocks2.__chat == before + 1, "exactly one chat line")
  assertTrue(mocks2.__chat[#mocks2.__chat]:sub(-#want) == want, "the library-absent line")
  assertTrue(#D.buffer == 0, "nothing written to the buffer")
  assertTrue(#D:BuildDiagnostics().lines == 0, "BuildDiagnostics is an empty report")

  before = #mocks2.__chat
  assertTrue(D:DebugVerb("DIAGNOSTICS") == true, "DebugVerb routes diagnostics in any case")
  assertTrue(#mocks2.__chat == before + 1, "to the same one line")
  assertTrue(D:DebugVerb("status") == false, "anything else stays the host's")
end)

test("parity: the Bus stub carries the whole LibKa0s-Bus-1.0 surface", function()
  local NS2 = loadDegraded()
  assertTrue(NS2.__busLib ~= nil and NS2.__busLib ~= NS.__busLib, "the degraded load took the stub")
  T.assertSurfaceParity(NS2.__busLib, "LibKa0s-Bus-1.0")
end)

test("parity: the Schema stub instance carries every member of the live instance", function()
  -- The instance surface is not in the library's member manifest, so the two-table form pins it
  -- (LibKa0s docs/api/Schema/version-2-docs.md, "Pinning it").
  local NS2 = loadDegraded()
  assertTrue(NS2.__schema ~= nil and NS2.__schemaLib ~= NS.__schemaLib, "the degraded load took the stub")
  T.assertSurfaceParity(NS.__schema, NS2.__schema, "schema instance vs host stub")
end)

test("parity: the Schema stub library carries the lib-level primitives", function()
  local NS2 = loadDegraded()
  T.assertSurfaceParity(NS2.__schemaLib, "LibKa0s-Schema-1.0", {
    -- The stub's refusals are the host's own words, not a copy of the library's constants.
    "STRINGS",
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
    -- Live-only, no call site here. The stub renders plain `cmd  desc` rows, never a copy of the
    -- library's row formatter, header or list builder (LibKa0s docs/api/Slash/version-16-docs.md,
    -- "The degradation stub"): a degraded help index is allowed to look degraded.
    "HelpHeader", "HelpRows", "BuildListLines", "CliVersion", "Text",
  })
end)

test("parity: the Slash stub's refusal format is the library's DISABLED_LINE_FORMAT, byte for byte", function()
  -- red under: a stub that re-spells the refusal line, or does not publish the copy it carries.
  -- The runner maps "LibKa0s-Slash-1.0" to the Slash INSTANCE; assertLibraryConstant falls back to
  -- the mock's LibStub for this lib-level member (test kit revision 26).
  local NS2 = loadDegraded()
  assertTrue(NS.Slash.__disabledLineFormat == nil, "the live load publishes no copy")
  T.assertLibraryConstant(NS2.Slash.__disabledLineFormat, "LibKa0s-Slash-1.0", "DISABLED_LINE_FORMAT")
end)

test("parity: the Slash stub prints plain rows and the one library-absent line", function()
  -- red under: keep the FormatRow copy (its em-dash separator), or the old `missing` concatenation.
  local NS2, mocks2 = loadDegraded()
  local cli = NS2.Slash.__cli
  local function dispatch(msg)
    local before = #mocks2.__chat
    cli:OnSlash(msg)
    local out = {}
    for i = before + 1, #mocks2.__chat do out[#out + 1] = mocks2.__chat[i] end
    return out
  end
  dispatch("version") -- spend the once-per-session missing-library notice

  local out = dispatch("help")
  assertTrue(#out == 1 + #NS2.COMMANDS, "the header and one row per verb")
  for i = 2, #out do
    assertTrue(out[i]:find("/pfe ", 1, true) ~= nil, "a command row: " .. out[i])
    assertTrue(out[i]:find("/pfe %S+  ") ~= nil, "two spaces after the verb: " .. out[i])
    assertTrue(out[i]:find("/pfe %S+ \226\128\148 ") == nil, "no em-dash row separator: " .. out[i])
  end
  for _, row in ipairs(cli:LandingRows()) do
    assertTrue(row:find("^/pfe %S+ \226\128\148 ") == nil, "landing row is plain: " .. row)
  end

  out = dispatch("list")
  local want = NS2.L["%s is unavailable: the LibKa0s library did not load."]:format("/pfe list")
  assertTrue(#out == 1, "exactly one line, got " .. #out)
  assertTrue(out[1]:sub(-#want) == want, "the library-absent line: " .. tostring(out[1]))

  -- No AceDB behind the degraded load: one honest line, no raise.
  out = dispatch("profile")
  assertTrue(#out == 1 and out[1]:find("Profile system requires AceDB-3.0", 1, true) ~= nil,
    "profile with no AceDB answers on one line")
  -- With a profile store, the sub-verb help renders plain rows through the stub's row shape.
  NS2.db = { SetProfile = function() end }
  out = dispatch("profile")
  assertTrue(#out == 8, "the header and seven sub-verb rows, got " .. #out)
  for i = 2, #out do
    assertTrue(out[i]:find("/pfe profile %S+.-  %S") ~= nil, "plain profile row: " .. out[i])
    assertTrue(out[i]:find("\226\128\148", 1, true) == nil, "no em dash: " .. out[i])
  end
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
