std = "lua51"
max_line_length = false
codes = true

-- libs/ is vendored (LibKa0s is linted in its own repo); tests/_kit/ is a byte copy of the library's
-- testkit. Everything else under tests/ is ours and is linted (lint). Under docs/ only the frozen
-- evidence bundles are excluded, so Lua a future doc carries is still checked.
exclude_files = { "libs/", "docs/audits/", "docs/reviews/", "_dev/", "tests/_kit/" }

-- No top-level `ignore`: an entry there reaches every file. A receiver a calling convention forces
-- on a body that does not read it earns a per-file stanza at the foot of this file, naming the file
-- and the variable.

read_globals = {
  "_G", "LibStub", "CreateFrame", "UIParent", "select",
  "Settings", "C_Timer", "C_AddOns", "GetAddOnMetadata", "IsAddOnLoaded", "DEFAULT_CHAT_FRAME",
  "StaticPopup_Show", "hooksecurefunc", "InCombatLockdown", "UnitAffectingCombat",
  -- Units and their data. Several return secret values in combat; see spec §7 and core/Compat.lua.
  -- UnitExists is absent on purpose: a raw UnitExists(compound token) is the secret-value hazard
  -- core/Compat.lua documents removing (the "No UnitExists shim" note), so a new call fails lint.
  "UnitClass", "UnitName", "UnitIsPlayer", "UnitReaction",
  "UnitHealth", "UnitHealthMax", "UnitHealthPercent",
  "UnitInRange",
  "UnitCastingInfo", "UnitChannelInfo", "UnitCastingDuration", "UnitChannelDuration",
  "UnitEmpoweredChannelDuration", "GetRaidTargetIndex", "SetRaidTargetIconTexture",
  "IsInRaid", "IsInGroup", "RAID_CLASS_COLORS", "issecretvalue", "C_CurveUtil",
  "Enum", "GetCVarBool", "CurveConstants",
  -- The stand-in's classic look (modules/StandIn.lua).
  "SetPortraitTexture", "UnitPowerType", "PowerBarColor",
  -- The client's own localized words for a stopped cast, displayed only.
  "INTERRUPTED", "FAILED",
  -- Secure frames (target and pet frames).
  "RegisterStateDriver", "UnregisterStateDriver",
  -- Frame systems we attach to — read-only, presence-guarded (library-stack-§6).
  "EditModeManagerFrame", "CompactPartyFrame", "PartyFrame", "ERFPartyHeader",
  "ERFPartySelfButton", "EventRegistry",
  -- EllesmereUI's saved settings: the stand-in's party frame size (modules/Providers.lua), read-only.
  "EllesmereUIDB",
  -- The perf bracket's clock (performance-§2).
  "debugprofilestop",
}

globals = {
  "PartyFrameEnhancedDB",     -- the SavedVariables write target
  "PartyFrameEnhancedPerfDB", -- the perf capture ring (core/PerfSetup.lua, performance-§5)
  "StaticPopupDialogs",       -- the Reset all settings confirmation registers here
}

-- The harness global is declared for tests/ only, so no shipped file can reach for it.
files["tests/"] = {
  globals = {
    "_G.PFE_TEST",
    "_G.PartyFrameEnhancedDB", "_G.PartyFrameEnhancedPerfDB",
  },
}

-- ── narrowed 212s: receivers a calling convention forces on bodies that do not read them ─────────

-- AceAddon calls OnInitialize/OnEnable with the addon as receiver, and AceEvent invokes a handler
-- registered by name as self[method](self, event, ...). The bodies read NS, which IS the addon.
files["core/PartyFrameEnhanced.lua"] = { ignore = { "212/self" } }

-- NS:InitDB and NS:RunMigrations are reached with a colon (OnInitialize, tests/run.lua); the
-- receiver and the namespace are one table.
files["core/Database.lua"] = { ignore = { "212/self" } }

-- The module lifecycle calls m:OnEnable() / m:Suspend() / m:Resume() with a colon
-- (core/PartyFrameEnhanced.lua's `each`); a module whose state is file-local does not read the
-- receiver.
files["modules/Providers.lua"] = { ignore = { "212/self" } }
files["modules/CastBars.lua"] = { ignore = { "212/self" } }
files["modules/TargetFrames.lua"] = { ignore = { "212/self" } }
files["modules/PetFrames.lua"] = { ignore = { "212/self" } }
files["modules/RangeFade.lua"] = { ignore = { "212/self" } }
files["modules/Preview.lua"] = { ignore = { "212/self" } }

-- tests/mock_menu.lua is LibKa0s v1.58.0's own client-menu fake, copied verbatim so a re-copy is a
-- clean diff. It mirrors the client's `root:CreateCheckbox` / `element:SetEnabled` method shapes, so
-- its methods take receivers they do not read, and the element's methods shadow the root's.
files["tests/mock_menu.lua"] = { ignore = { "212/self", "432/self" } }
files["modules/Anchor.lua"] = { ignore = { "212/self" } }

-- SlashLib:New in the degraded stub mirrors the library's `lib:New(d)`, and Sl:LandingRows /
-- Sl:OnSlash / Sl:Register mirror the instance's colon methods; a stub that narrows a signature
-- lets a caller pass here and fail in the client.
files["settings/Slash.lua"] = { ignore = { "212/self" } }
