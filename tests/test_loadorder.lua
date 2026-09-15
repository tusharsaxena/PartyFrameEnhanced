-- tests/test_loadorder.lua — the load lists cannot drift from the TOC, and the load-bearing TOC
-- positions stay where their comments say they must be.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse
local mocks = T.mocks
local NS = T.NS

local Loader = dofile("tests/_kit/loader.lua")
local TOC = "PartyFrameEnhanced.toc"

local function readFile(path)
  local f = io.open(path, "r")
  assertTrue(f ~= nil, "cannot open " .. path .. " (tests run from the repo root)")
  local body = f:read("*a")
  f:close()
  return body
end

local function tocIndex()
  local index = {}
  for i, p in ipairs(Loader.tocFiles(TOC)) do index[p:lower()] = i end
  return index
end

local function assertBefore(first, second, why)
  local index = tocIndex()
  assertTrue(index[first] ~= nil, first .. " is not in the TOC")
  assertTrue(index[second] ~= nil, second .. " is not in the TOC")
  assertTrue(index[first] < index[second], first .. " must load before " .. second .. ": " .. why)
end

test("loadorder: tocFiles returns the addon's files, locale first and settings last", function()
  local files = Loader.tocFiles(TOC)
  assertTrue(#files > 15, "the TOC lists more than fifteen lua files, got " .. #files)
  assertEqual(files[1], "locales/enUS.lua", "the locale table loads first")
  assertEqual(files[#files], "settings/Profiles.lua", "the Profiles page loads last")
end)

test("loadorder: core/MediaSetup.lua loads before core/Constants.lua, and the TOC says why", function()
  -- red under: moving MediaSetup below Constants (FONT_MONO would take the fallback silently).
  assertBefore("core/mediasetup.lua", "core/constants.lua", "Constants reads NS.MediaFont at load")
  assertTrue(readFile(TOC):find("Constants.FONT_MONO is resolved from", 1, true) ~= nil,
    "the TOC line must carry the note saying its position is load-bearing")
end)

test("loadorder: CoreSetup loads after Namespace and before PerfSetup and DebugLogSetup", function()
  assertBefore("core/namespace.lua", "core/coresetup.lua", "the printer's prefix is NS.PREFIX")
  assertBefore("core/coresetup.lua", "core/perfsetup.lua", "PerfSetup's sinks print")
  assertBefore("core/coresetup.lua", "core/debuglogsetup.lua", "the console's print forwarder")
  assertBefore("core/constants.lua", "core/debuglogsetup.lua", "the console reads FONT_MONO")
end)

test("loadorder: OptionsSetup loads before every settings page", function()
  local index = tocIndex()
  local setup = index["settings/optionssetup.lua"]
  assertTrue(setup ~= nil, "settings/OptionsSetup.lua is not in the TOC")
  for _, page in ipairs({ "settings/about.lua", "settings/general.lua", "settings/profiles.lua" }) do
    assertTrue(index[page] ~= nil and index[page] > setup,
      page .. " must load after settings/OptionsSetup.lua, which publishes NS.Helpers")
  end
end)

test("loadorder: Schema loads before every settings file, and the TOC says why", function()
  -- red under: a page file above settings/Schema.lua — its RegisterSchemaRows call raises at load.
  local index = tocIndex()
  local schema = index["settings/schema.lua"]
  assertTrue(schema ~= nil, "settings/Schema.lua is not in the TOC")
  for path, i in pairs(index) do
    if path:match("^settings/") and path ~= "settings/schema.lua" then
      assertTrue(i > schema, path .. " must load after settings/Schema.lua")
    end
  end
  assertTrue(readFile(TOC):find("publishes NS.RegisterSchemaRows", 1, true) ~= nil,
    "the TOC line must say Schema's position is load-bearing")
end)

test("loadorder: PerfSetup loads before every module", function()
  local index = tocIndex()
  local perf = index["core/perfsetup.lua"]
  for path, i in pairs(index) do
    if path:match("^modules/") then
      assertTrue(i > perf, path .. " takes NS.Perf at file scope and must load after PerfSetup")
    end
  end
end)

test("loadorder: StandIn and TestMode load after Preview, StandIn first, and the TOC says why", function()
  assertBefore("modules/preview.lua", "modules/testmode.lua", "TestMode captures NS.Preview at file scope")
  assertBefore("modules/standin.lua", "modules/testmode.lua", "TestMode captures NS.StandIn at file scope")
  assertTrue(readFile(TOC):find("TestMode captures NS.Preview and NS.StandIn", 1, true) ~= nil,
    "the TOC line must say TestMode's position is load-bearing")
end)

test("loadorder: tocFiles skips libs, directives and comments, and uses forward slashes", function()
  for _, p in ipairs(Loader.tocFiles(TOC)) do
    assertFalse(p:lower():match("^libs/"), "a libs/ path leaked into the derived list: " .. p)
    assertTrue(p:match("%.lua$") ~= nil, "a non-lua entry leaked into the derived list: " .. p)
    assertFalse(p:find("\\", 1, true), "a backslash survived into " .. p)
  end
end)

test("loadorder: every derived path exists on disk", function()
  for _, p in ipairs(Loader.tocFiles(TOC)) do
    local f = io.open(p, "r")
    assertTrue(f ~= nil, "the TOC names a file that does not exist: " .. p)
    if f then f:close() end
  end
end)

test("loadorder: the runner loaded exactly the TOC's files, in the TOC's order", function()
  assertEqual(table.concat(T.loadedAddonFiles, "\n"), table.concat(Loader.tocFiles(TOC), "\n"),
    "tests/run.lua's load list has drifted from the TOC")
end)

test("loadorder: the runner loaded exactly the vendored XML's library files, in its order", function()
  assertEqual(table.concat(T.loadedLibFiles, "\n"),
    table.concat(Loader.xmlFiles("libs/LibKa0s/LibKa0s.xml"), "\n"),
    "tests/run.lua's library load list has drifted from libs/LibKa0s/LibKa0s.xml")
end)

test("loadorder: tests/perf.lua derives both halves of its list too", function()
  -- Source-read, because tests/perf.lua is a separate process this suite does not run.
  local src = readFile("tests/perf.lua")
  assertTrue(src:find("Loader.tocFiles", 1, true) ~= nil, "tests/perf.lua must derive from the TOC")
  assertTrue(src:find("Loader.xmlFiles", 1, true) ~= nil, "tests/perf.lua must derive from the XML")
end)

test("loadorder: the loaded library registered — NS.Perf is the lib, not the stub", function()
  -- A short library list raises nothing: Perf would simply not register and NS.Perf would be the
  -- four-member stub, which every perf figure would then silently measure.
  local perf = mocks.LibStub("LibKa0s-Perf-1.0", true)
  assertTrue(perf ~= nil, "libs/LibKa0s/Perf.lua must have loaded and registered its major")
  assertTrue(type(NS.Perf.Start) == "function", "NS.Perf is the instance; the stub has no Start")
end)
