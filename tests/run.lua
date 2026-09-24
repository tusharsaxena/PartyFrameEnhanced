-- Headless test runner for Ka0s Party Frame Enhanced.  Run from the repo root:  lua tests/run.lua
--
-- The registry, the assertions, the loader and the universal WoW-API mock are the shared kit under
-- tests/_kit/ (vendored from LibKa0s/testkit). What stays here is this addon's load list, the
-- lifecycle kick and the suite list — and nothing else (testing-§9).

local Kit        = dofile("tests/_kit/framework.lua")
local Loader     = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local mocks = buildMocks()
local NS = {}

-- The test world is a party. The addon is party-only (docs/superpowers/specs/2026-09-15-test-mode-design.md
-- §1), and the kit's mock starts solo, which would hide every element every feature suite asserts on.
-- Suites that need solo or a raid set these two fields and put them back.
mocks.__context.inGroup, mocks.__context.inRaid = true, false

Loader.addonName = "PartyFrameEnhanced"

-- The vendored library files come from the XML the TOC loads them through (Loader.tocFiles cannot
-- see inside it); the addon's own files come from the TOC itself, so neither list can drift from
-- what the client loads. tests/test_loadorder.lua pins both derivations.
local LIB_FILES   = Loader.xmlFiles("libs/LibKa0s/LibKa0s.xml")
local ADDON_FILES = Loader.tocFiles("PartyFrameEnhanced.toc")

Loader.loadAll(LIB_FILES, NS, mocks)
Loader.loadAll(ADDON_FILES, NS, mocks)

-- Mirror the in-game lifecycle: OnInitialize opens the DB; OnEnable enables every module (the
-- features build their elements) and registers the settings panel.
NS:InitDB()
NS.addon:OnEnable()
while mocks.__fireTimers() > 0 do end

-- The live halves of the degradation-stub parity checks. The Options, DebugLog and Slash stubs
-- mirror INSTANCES (what lib:New returned), not the library tables LibStub answers, so they are
-- registered explicitly — before Kit.expose, which only auto-wires a source when none is set.
Kit.setSurfaceSource{
  ["LibKa0s-Options-1.0"]  = NS.Helpers,
  ["LibKa0s-DebugLog-1.0"] = NS.DebugLog,
  ["LibKa0s-Slash-1.0"]    = NS.Slash and NS.Slash.__cli,
  ["LibKa0s-Bus-1.0"]      = mocks.LibStub("LibKa0s-Bus-1.0", true),
  ["LibKa0s-Compat-1.0"]   = mocks.LibStub("LibKa0s-Compat-1.0", true),
  ["LibKa0s-Schema-1.0"]   = mocks.LibStub("LibKa0s-Schema-1.0", true),
}

_G.PFE_TEST = Kit.expose{
  NS = NS, mocks = mocks,
  -- What the loader was actually fed, so tests/test_loadorder.lua compares it against a fresh read.
  loadedAddonFiles = ADDON_FILES,
  loadedLibFiles   = LIB_FILES,
}

Kit.run{
  dir = "tests/",
  suites = {
    "test_loadorder",
    "test_schema",
    "test_database",
    "test_coresetup",
    "test_envsetup",
    "test_mediasetup",
    "test_debuglog",
    "test_perfsetup",
    "test_lifecycle",
    "test_bus",
    "test_compat",
    "test_providers",
    "test_anchor",
    "test_profile_switch",
    "test_castbars",
    "test_targetframes",
    "test_petframes",
    "test_rangefade",
    "test_party",
    "test_preview",
    "test_standin",
    "test_preview_standin",
    "test_perf_buckets",
    { name = "test_prose", dir = "tests/_kit/" },
    "test_slash",
    "test_disabled",
    "test_launcher",
    "test_optionssetup",
    "test_surface_parity",
    "test_vendor_sync",
    { name = "test_eol", dir = "tests/_kit/" },
    { name = "test_layout_cap", dir = "tests/_kit/" },
  },
}
