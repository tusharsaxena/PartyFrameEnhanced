-- tests/launcher_env.lua -- builds a SECOND addon environment in which the two BROKER libraries are
-- present, and a third in which they are not.
--
-- tests/run.lua's world is deliberately the broker-less one: LibDataBroker-1.1 and LibDBIcon-1.0 are
-- listed in the TOC's `# Libraries` block, and Loader.tocFiles skips every `libs\` line, so the main
-- suite already loads the addon against a host that has neither. That is the shipped degraded case
-- (launcher-§1: the library resolves both with LibStub(..., true) at Register time and a host with
-- neither must not raise), and it is worth keeping as the default rather than papering over.
--
-- What it cannot do is exercise the button. So this file loads the WHOLE tree again -- the vendored
-- library from its XML, then every file the TOC names, then InitDB and OnEnable, exactly as
-- tests/run.lua does -- against a LibStub that answers the two majors with fakes a suite can read.
-- Not the real libraries: LibDBIcon builds a real minimap frame with real templates, and a suite
-- asking "did the button move" would be asserting on the mock's fidelity rather than on this addon.
--
-- The fakes record what the library did with them: which objects were created and under what name,
-- how many times Register was called (idempotence is the library's claim, and a claim nobody counts
-- is a comment), and whether the button is currently shown.
--
-- Not a suite; callers dofile it like tests/wow_mock.lua.
local Loader     = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

--- A LibDataBroker-1.1 fake. NewDataObject answers nil for a name already taken, which is the real
--- library's behavior and the branch LibKa0s-Launcher-1.0 falls back to GetDataObjectByName on.
local function makeLDB()
  local objects = {}
  return {
    __objects = objects,
    NewDataObject = function(_, name, t)
      if objects[name] then return nil end
      objects[name] = t
      return t
    end,
    GetDataObjectByName = function(_, name) return objects[name] end,
  }
end

--- A LibDBIcon-1.0 fake. `registrations` is keyed by the name the launcher registered under -- which
--- launcher-§1 makes the addon's FOLDER name, because LibDBIcon keys the button's saved position
--- by it -- and holds the very table it was handed, so a suite can prove the settings row and the
--- button write one table rather than two.
local function makeIcon()
  local registrations = {}
  return {
    __registrations = registrations,
    Register = function(_, name, object, db)
      local r = registrations[name]
      if not r then
        r = { calls = 0 }
        registrations[name] = r
      end
      r.calls = r.calls + 1
      r.object, r.db = object, db
      r.shown = not db.hide
    end,
    Show = function(_, name) registrations[name].shown = true end,
    Hide = function(_, name) registrations[name].shown = false end,
  }
end

--- Load the addon whole against a fresh mock. `brokers` false leaves LibDataBroker and LibDBIcon out.
--- `sv`, when given, is the raw SavedVariables table InitDB opens -- a legacy store a suite seeds --
--- and the previous global is put back once the db holds it.
--- Returns the namespace, the mocks, and the two fakes (nil when `brokers` is false).
return function(brokers, sv)
  Loader.addonName = "PartyFrameEnhanced"
  local mocks, NS = buildMocks(), {}
  -- The client's context-menu API (Launcher minor 4's right click), installed as the global
  -- `MenuUtil` the library resolves on every right click. `mocks.__menu` is the handle a suite
  -- reads the opened menu through (`.last`, `:Click`, `:Checked`), and `.remove()` takes the API
  -- away to reach the library's settings-panel fallback.
  mocks.__menu = dofile("tests/mock_menu.lua")(mocks)
  local ldb, icons
  if brokers ~= false then
    ldb, icons = makeLDB(), makeIcon()
    -- Straight into the registry LibStub reads, before a line of the addon loads: the launcher
    -- resolves both at Register time, and Register runs inside OnEnable below.
    mocks.__libs["LibDataBroker-1.1"] = ldb
    mocks.__libs["LibDBIcon-1.0"] = icons
  end
  Loader.loadAll(Loader.xmlFiles("libs/LibKa0s/LibKa0s.xml"), NS, mocks)
  -- Keep the descriptor core/LauncherSetup.lua hands the library, so a suite can pin its fields
  -- (Launcher minor 3's tooltip fields above all) rather than only what the library drew from them.
  local Launcher = mocks.LibStub("LibKa0s-Launcher-1.0", true)
  if Launcher then
    local new = Launcher.New
    Launcher.New = function(self, d)
      mocks.__launcherDescriptor = d
      return new(self, d)
    end
  end
  Loader.loadAll(Loader.tocFiles("PartyFrameEnhanced.toc"), NS, mocks)
  local previous = _G.PartyFrameEnhancedDB
  if sv then _G.PartyFrameEnhancedDB = sv end
  NS:InitDB()
  if sv then _G.PartyFrameEnhancedDB = previous end
  NS.addon:OnEnable()
  while mocks.__fireTimers() > 0 do end
  return NS, mocks, ldb, icons
end
