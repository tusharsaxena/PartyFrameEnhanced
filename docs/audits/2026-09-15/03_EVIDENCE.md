# 03 — Evidence: Ka0s Party Frame Enhanced v0.1.0

Every command below was run on 2026-09-15 from the repo root at `e215880`, with a clean working tree.
Output is pasted as produced; long outputs are trimmed with `…` and the trim is stated. Every
`file:line` cited in this bundle was re-read in one pass immediately before writing (§E0), and the
quoted text is the text on that line.

**Environment notes.**

- The shell's `grep` is **ugrep**, which prints repo-relative paths without a leading `./`. The
  `AUDIT.md` close-button sweep's `grep -v '/libs/'` therefore does not filter `libs/…` lines, and
  §E9 reads its output accordingly.
- Lua is 5.1.5, luacheck 1.2.0 and lizard 1.24.0.
- The sibling `../LibKa0s` is present. `git describe --tags HEAD` there reports `v1.36.2`.

---

## E0 — Citation re-read (every `file:line` this bundle quotes)

Command (bash): `sed -n "<line>p" <file> | tr -d "\r"` for each citation. Selected output (all
resolved; none were corrected or dropped):

```
PartyFrameEnhanced.toc:12: ## X-Standard: https://github.com/tusharsaxena/WowAddonStandards
PartyFrameEnhanced.toc:13: # X-Curse-Project-ID: not published on CurseForge yet
PartyFrameEnhanced.toc:27: libs\LibKa0s\LibKa0s.xml
PartyFrameEnhanced.toc:80: # Settings (last — depend on everything else being initialized)
PartyFrameEnhanced.toc:81: settings\Schema.lua
PartyFrameEnhanced.toc:83: # LOAD-BEARING: publishes NS.Helpers, which every settings page calls at file load.
CLAUDE.md:6: ## Standards compliance (read first)
CLAUDE.md:37: Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.36.1 (MIT).
README.md:5: ![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)
README.md:6: ![Tests](https://img.shields.io/badge/Tests-131%2F131_passing-green)
README.md:27: > Party Frame Enhanced is in development. The settings panel and the slash commands are in place; the
README.md:28: > three elements are being built now, and the first release follows in-game testing.
README.md:96: | 0.1.0 | unreleased | First version, in development: settings panel, slash commands, profiles. |
.gitattributes:26: * text=auto eol=crlf
.gitattributes:34: *.sh text eol=lf
.luacheckrc:8: exclude_files = { "libs/", "docs/audits/", "docs/reviews/", "_dev/", "tests/_kit/" }
.luacheckrc:43: files["tests/"] = {
core/CoreSetup.lua:15: local lib = LibStub and LibStub("LibKa0s-Core-1.0", true)
core/CoreSetup.lua:86: NS.MakeCloseButton = function(parent, onClick)
core/CoreSetup.lua:87:     return lib.MakeCloseButton(parent, onClick, addonName)
core/DebugLogSetup.lua:11: local lib = LibStub and LibStub("LibKa0s-DebugLog-1.0", true)
core/DebugLogSetup.lua:70:     addonName = addonName,
core/PerfSetup.lua:10: local lib = LibStub and LibStub("LibKa0s-Perf-1.0", true)
core/PerfSetup.lua:75:     -- No `decorate`: the library draws the panel's close control from addonName, matching the debug
core/MediaSetup.lua:34: if Media then Media.RegisterLSM(addonName) end
core/EnvSetup.lua:10: local Env = LibStub and LibStub("LibKa0s-Env-1.0", true)
settings/OptionsSetup.lua:38:     skipRestoreAll = vetoedFromResetAll,
settings/OptionsSetup.lua:142: NS.Helpers = lib:New(descriptor)
settings/Slash.lua:37:             print("Positions reset")
settings/Slash.lua:89:     print("Frame system: " .. (NS.Providers.ActiveLabel() or "none found"))
settings/Slash.lua:298:     NS.addon:RegisterChatCommand("pfe", function(msg) Sl:OnSlash(msg) end)
settings/Schema.lua:25: function NS.RegisterSchemaRows(rows)
settings/Schema.lua:113: --- Store a setting without any side effect. Every caller outside this file uses NS.SetByPath.
settings/Schema.lua:159: function NS.SetByPath(path, value)
settings/Schema.lua:167:         NS.Debug("Set", "%s = %s", path, row and NS.FormatSchemaValue(row, value) or tostring(value))
settings/Schema.lua:170:     if row.onChange then row.onChange(value) end
settings/Schema.lua:269: function NS.ValidateSchema()
modules/Preview.lua:34: function NS.OnLockChanged(locked)
modules/Preview.lua:35:     if not locked and InCombatLockdown() then
modules/Preview.lua:37:         NS.SetSetting("locked", true)
settings/General.lua:68: NS.RegisterSchemaRows(masterRows)
settings/General.lua:97:     text         = L["Reset this profile to the addon's defaults? Everything you have configured or added in it is discarded \226\128\148 your other profiles are not affected."],
settings/CastBars.lua:79: NS.RegisterSchemaRows(rows)
settings/TargetFrames.lua:79: NS.RegisterSchemaRows(rows)
settings/PetFrames.lua:49: NS.RegisterSchemaRows(rows)
settings/About.lua:16:             heading = "Slash Commands",
modules/Anchor.lua:262:     cfg.position = { point = point, x = math.floor((x or 0) + 0.5), y = math.floor((y or 0) + 0.5) }
modules/Anchor.lua:271:         spec.config().position = nil
docs/ARCHITECTURE.md:25: Build status: feature-complete for v0.1.0. What remains is the offline perf pass, the release record
docs/ARCHITECTURE.md:30: Twenty-two files load today, in the fixed folder order `libs → locales → core → defaults → modules →
docs/ARCHITECTURE.md:40: `NS.SetByPath` — carries every write to a schema path: the panel (the Options descriptor's `set` /
docs/ARCHITECTURE.md:41: `applyDefault`), `/pfe set`, `/pfe lock`/`unlock` and every reset. The seam stores the value, runs the
docs/ARCHITECTURE.md:48:   Arrives with the anchor engine (plan P2).
docs/ARCHITECTURE.md:172: | `events-frames-taint-§1` | `UNIT_SPELLCAST_*`, `UNIT_TARGET` and the pet unit events are registered with `RegisterUnitEvent` on each element's own frame, not through AceEvent | … | 2026-09-15 | AceEvent or LibKa0s gains a unit-filtered registration |
docs/testing.md:19: `.luacheckrc` carries **no top-level `ignore`**. Three `files[...]` stanzas each name one file and one
docs/testing.md:34: schema and its write seam, the slash table, the lifecycle and the secure-write queue, and (as they
docs/testing.md:35: land) the providers, the anchor engine and the three features. The library's own internals are tested
docs/schema.md:69:   position* button and `/pfe resetposition`). Arrives in plan P2.
docs/data-flow.md:53: Stage 1 of the addon — the lifecycle, the settings seam and the bus that every arrow above uses — is
docs/data-flow.md:54: in the tree. The providers, the anchor engine and the three features land in plan P2–P5.
docs/common-tasks.md:29: 1. Add a provider table to `modules/Providers.lua` (plan P2): `id`, `label`, `priority`,
DEPENDENCIES.md:20:   presence guard lives in `modules/Providers.lua` (plan P2).
DEPENDENCIES.md:29: | `git` | any recent | the vendored-payload gate (`tests/test_vendor_sync.lua` reads the LibKa0s tag with `git`), the EOL gate (`tests/_kit/test_eol.lua` runs `git ls-files` / `git check-attr`) | those two files |
tests/test_perfsetup.lua:44: test("perfsetup: without LibKa0s the stub carries every member the addon calls", function()
tests/test_optionssetup.lua:33: test("optionssetup: the live and degraded builds veto the same rows from Reset All", function()
tests/test_database.lua:30: test("database: a counted profile reset restores defaults and publishes PROFILE once", function()
tests/test_spelling.lua:74:   local p = io.popen and io.popen("git ls-files")
tests/run.lua:48:   dir = "tests/",
modules/Element.lua:16: local SHIELD_TEXTURE = "Interface\\CastingBar\\UI-CastingBar-Small-Shield"
modules/Element.lua:253:     if NS.Perf.suspended then return false end
modules/CastBars.lua:215: local TICKS = { casting = tickCasting, holding = tickHolding, fading = tickFading }
modules/Providers.lua:96:         return ERFPartyHeader ~= nil and Compat.IsAddOnLoaded("EllesmereUIRaidFrames")
core/Database.lua:34: local SCHEMA_STEPS = {}
defaults/Profile.lua:118:     schemaVersion = 1,
core/Namespace.lua:8: NS.PREFIX = "|cff00ffff[PFE]|r"
core/PartyFrameEnhanced.lua:14: if NS.Util and NS.Util.print then NS.Print = NS.Util.print end
```

**Figure reconciliation.** Several figures appear in more than one artifact. Each was re-derived from
the commands below, and all artifacts agree on these values:

| Figure | Value | Source |
|---|---|---|
| Cases | 131 | §E2 |
| Lint files | 60 | §E1 |
| Schema rows, full / degraded / composer gap | 115 / 58 / 57 | §E12 |
| Shims | 17 | §E14 |
| Commands | 16 | §E14 |
| Messages | 4 | §E14 |
| TOC lua files | 34 | §E15 |
| `files[...]` stanzas for `212/self` | 8 | §E15 |
| Dotted-notation hits | 17 | §E16 |
| Citations | 155 | §E16 |
| Unrouted print literals | 28 | §E17 |
| NLOC / functions / max CCN | 5084 / 667 / 15 | §E3 |

---

## E1 — Lint (`lint`)

Scope: `luacheck .`, which uses `.luacheckrc`'s `exclude_files`. Those exclude `libs/`,
`docs/audits/`, `docs/reviews/`, `_dev/` and `tests/_kit/`, and include the rest of `tests/`
(`.luacheckrc:8`). The harness global is in `files["tests/"]` (`:43-48`), not in top-level
`read_globals`. There is no top-level `ignore`. The eight narrow `212/self` stanzas are each commented.

```
$ luacheck . | tail -1
Total: 0 warnings / 0 errors in 60 files
```

## E2 — Headless suite (`testing`)

```
$ lua5.1 tests/run.lua | tail -6
  PASS  parity: the Slash stub carries every dispatcher member the addon calls
  PASS  libs/LibKa0s is the LibKa0s release CLAUDE.md says this addon bundles
  PASS  tests/_kit is the test kit that shipped with that release
  PASS  the automated-test runner is recorded executable (100755)
  PASS  eol: every tracked file carries the terminator .gitattributes declares for it

131 passed, 0 failed, 0 skipped, 131 total

$ ( time lua5.1 tests/run.lua >/dev/null 2>&1 )
real 0m5.252s   user 0m0.569s   sys 0m0.525s

$ diff <(lua5.1 tests/run.lua --list) docs/test-cases.md && echo IN-SYNC
IN-SYNC
```

Suite-list pin: `tests/run.lua:47-49` calls `Kit.run{ dir = "tests/", … }`. `tests/_kit/framework.lua:876-886`
runs `Kit.assertSuiteInventory(dir, suites)` whenever `dir` is explicit, and that call covers both
directions (declared but not on disk, and on disk but not declared). Kit revision:
`tests/_kit/framework.lua:20: Kit.VERSION = 21`.

## E3 — Complexity (`performance-§10`), verbatim invocation

```
$ lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .   (footer)
Total nloc   Avg.NLOC  AvgCCN  Avg.token   Fun Cnt  Warning cnt   Fun Rt   nloc Rt
      5084       5.7     2.3       42.6      667            0      0.00    0.00
No thresholds exceeded (cyclomatic_complexity > 15 or length > 1000 or nloc > 1000000 or parameter_count > 100)
```

The maximum CCN is 15, at `NS.ValidateSchema@269-297@./settings/Schema.lua` (29 NLOC). That function
is a flat sequence of independent row checks, so the score is dense guarding, not nested control flow.

**Drift against the latest bundle.** `docs/automated-tests/20260915-150853/manifest.json:16` reads:

```
"complexity": { "status": "pass", …, "warnings": 0, "maxCcn": 15, "nloc": 4995, "functions": 664, "avgCcn": 2.3, "avgNloc": 5.7, …, "bandFiles": 0, "overCapFiles": 0, … }
```

Since then NLOC is +89 and functions +3 (the spelling gate in `e215880`). No function crossed a
threshold, and no file entered the 1000–1500 band. The bundle's `startedAt` is
`2026-09-15T15:08:53+05:30`, about 3 minutes before HEAD's commit time (`2026-09-15 15:11:30 +0530`).
`RESULTS.md` watch list: "None." for functions and for bands, with 0 `Accepted` dispositions.

```
$ git log --format='%h %ad %s' --date=iso -- docs/automated-tests/RESULTS.md
e215880 2026-09-15 15:11:30 +0530 Record the v0.1.0 release-candidate run and add the US-spelling gate
e2557d9 2026-09-15 14:14:01 +0530 Add the doc set, the placeholder logo and the first automated-test bundle
```

**Complexity refactor `e4a6e9a` (performance-§11).** The commit message says "applyFree reads growth
from a direction table, the cast bar's tick dispatches one step per state from a table built at load,
and Element.Reskin names its bar, marks and font layout as helpers".

- The diff introduces module-level `GROWTH_DIR` and `stackSize` (`modules/Anchor.lua`) and the
  module-level `TICKS` table (`modules/CastBars.lua:215`, commented "Built once at file load").
- Every extracted helper names a recognizable block: `tickCasting`, `tickHolding`, `tickFading`,
  `applyBar`, `applyMarks`, `applyFonts`, `applyMasterAlpha`.
- None of these allocates per call or introduces `or`-defaulting over a stored boolean.
- Coverage predated the refactor: `tests/test_anchor.lua`, `tests/test_castbars.lua` and
  `tests/test_targetframes.lua` landed in `3ee3a27`, `98a9dcb` and `691d1ab`.

## E4 — Line endings (`line-endings`)

```
$ test -f .gitattributes || echo MISSING            → (no output)
$ grep -n '^\* text=auto eol=\(crlf\|lf\)$' .gitattributes
26:* text=auto eol=crlf
$ grep -n '^\*\.sh text eol=lf$' .gitattributes
34:*.sh text eol=lf
$ grep -c ' binary$' .gitattributes
20
$ git ls-files -z | xargs -0 -I{} sh -c '
    set -- $(git check-attr text eol -- "{}" | sed "s/.*: //")
    [ "$1" = unset ] && exit
    cr=$(tr -dc "\r" < "{}" | wc -c); lf=$(tr -dc "\n" < "{}" | wc -c)
    case "$2" in crlf) [ "$lf" -gt 0 ] && [ "$cr" -ne "$lf" ] && echo "{}";;
                 lf)   [ "$cr" -gt 0 ] && echo "{}";; esac' 2>/dev/null | wc -l
0
```

Scope: the whole tracked set, 309 files with no exclusions. The kind is client-bound (a `.toc` is
present), so the pin is CRLF, which is correct.

Body check (`line-endings-§5`). The canonical client-bound body was extracted from the fetched
`line-endings.md` lines 153-233, 81 lines:

```
$ diff <(head -n 81 .gitattributes | tr -d '\r') canon_client.gitattributes && echo EMPTY
EMPTY
$ tail -n +82 .gitattributes | tr -d '\r' | grep -m1 . || echo "(nothing after body)"
(nothing after body)
```

The in-repo gate `tests/_kit/test_eol.lua` (kit 21 ≥ 15) reports PASS in §E2, which agrees with the
count of 0.

## E5 — Packaging (`packaging`)

```
$ for e in .luacheckrc .pkgmeta .gitignore .gitattributes .claude .superpowers docs tests _dev; do
    grep -q "^  - $e\b" .pkgmeta || echo "NOT IGNORED — $e"; done
(no output)
$ for e in .[!.]*; do [ -e "$e" ] || continue; grep -q "^  - $e\b" .pkgmeta || echo "UNACCOUNTED — $e"; done
UNACCOUNTED — .git
```

`.git` is the one entry that needs no row. No `externals:` block exists (`.pkgmeta:1-22`).

## E6 — Write paths into the stored tree (`architecture-§5`)

Scope: the authored source tree, `git ls-files '*.lua' | grep -vE '^(libs/|tests/)'`, 34 files.

```
$ … | xargs grep -nE 'db\.(profile|global|char)|\bprofile\.[a-zA-Z_]+[^=]*=[^=]|table\.(insert|remove)|\bwipe\('
core/Database.lua:38:    local g = NS.db and NS.db.global
core/Database.lua:43:            step.apply(NS.db.profile)
core/DebugLogSetup.lua:84:        local schemaVer = NS.db and NS.db.global and NS.db.global.schemaVersion
modules/CastBars.lua:57:local cfg                -- NS.db.profile.castbar, re-read on PROFILE
modules/CastBars.lua:329:    cfg = NS.db.profile.castbar
modules/CastBars.lua:376:    cfg = NS.db.profile.castbar
modules/PetFrames.lua:107:    cfg = NS.db.profile.pet
modules/PetFrames.lua:154:    cfg = NS.db.profile.pet
modules/TargetFrames.lua:190:    cfg = NS.db.profile.target
modules/TargetFrames.lua:237:    cfg = NS.db.profile.target
settings/Profiles.lua:19:    if not (NS.db and NS.db.profile) then return nil end
settings/Schema.lua:106:    if db and db.profile then
settings/Schema.lua:107:        local val = NS.ResolvePath(db.profile, path)
settings/Schema.lua:121:    if db and db.profile then NS.SetPath(db.profile, path, value) end
settings/Slash.lua:98:        local cfg = NS.db.profile[f[1]]
$ … | xargs grep -n "SetSetting("
modules/Preview.lua:37:        NS.SetSetting("locked", true)
settings/Schema.lua:114:function NS.SetSetting(path, value)
settings/Schema.lua:162:    NS.SetSetting(path, value)
```

Classification:

| Hit | Class | Result |
|---|---|---|
| `settings/Schema.lua:121` | the helper's own store | compliant |
| `core/Database.lua:38-45` | the load pass (runner) | compliant |
| `modules/*:cfg = NS.db.profile.*` | a reference re-read, not a write | not a write |
| `modules/Anchor.lua:262`, `:271` | named non-setting state; the owner and both writers are named at `docs/ARCHITECTURE.md:45-48` | compliant |
| `settings/OptionsSetup.lua:43-46`, `settings/Slash.lua` profile verbs | wholesale replacement by AceDB | compliant |
| **`modules/Preview.lua:37`** | a schema-row (`locked`) write outside `NS.SetByPath` | **PFE-03** |

Sequence behind PFE-03, from `settings/Schema.lua:159-173`. The function stores the value (`:162`),
then logs `[Set] locked = false` (`:167`), then runs `onChange` (`:170`), which reverts the value
through the raw store (`modules/Preview.lua:37`). It then publishes CONFIG (`:172`). The logged write
never survives the call.

## E7 — Deviation register and issue store (`audit-review-history`)

`docs/ARCHITECTURE.md:168-172` holds one row (quoted in §E0). The trigger was evaluated:

```
$ grep -rln "RegisterUnitEvent" libs/
(no output)        → no unit-filtered registration in vendored AceEvent-3.0 or LibKa0s v1.36.1; trigger not fired
```

```
$ gh issue list --state all --limit 200 --json number,title,state,labels --jq '.[] | …'
12  OPEN  enhancement,state:triaged,severity:low     Attribute the 16.6 bytes per cast cycle the offline perf runner still measures
11  OPEN  enhancement,state:triaged,severity:low     Support arena frames
10  OPEN  enhancement,state:triaged,severity:low     Replace the generated placeholder logo with real art
 9  OPEN  enhancement,state:triaged,severity:low     Translate the addon (deDE, frFR, and others)
 8  OPEN  enhancement,state:triaged,severity:low     Attach the player's row to PlayerFrame in Blizzard's classic party layout
 7  OPEN  enhancement,state:triaged,severity:low     Show auras and target-of-target on target frames
 6  OPEN  enhancement,state:triaged,severity:low     Show the cast's target on the cast bar
 5  OPEN  enhancement,state:triaged,severity:low     Allow per-unit style overrides
 4  OPEN  enhancement,state:triaged,severity:low     Draw empowered-cast stage markers on cast bars
 3  OPEN  enhancement,state:triaged,severity:medium  Re-anchor the clickable target and pet frames during combat through a secure handler
 2  OPEN  enhancement,state:triaged,severity:low     Attach to more frame systems: ElvUI, Cell, Grid2, VuhDo, DandersFrames
 1  OPEN  enhancement,state:triaged,severity:low     Support raid frames
```

The store has no `state:will-not-do` issue, so no decline is owed a register row. No title carries a
`[status]` prefix, and `docs/pending/LEDGER.md` is absent (see the listing in §E13).

## E8 — Vendored LibKa0s (`library-stack-§7`, `testing-§11`)

```
$ grep -n 'Bundles \[LibKa0s\]' CLAUDE.md
37:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.36.1 (MIT).
$ grep -n 'Bundles \[LibKa0s\]' README.md                         → (no output)
$ grep -nE '^## (Libraries|Bundled libraries|Libraries and credits|Credits and libraries|Credits and bundled libraries)' README.md   → (no output)
$ grep -n 'WoW_Addon_Standard' README.md
5:![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)

$ cd ../LibKa0s && git tag | grep v1.36.1 && git describe --tags HEAD
v1.36.1
v1.36.2
$ git archive v1.36.1 LibKa0s testkit | tar -x -C <tmp>
$ diff -r --strip-trailing-cr <tmp>/LibKa0s  libs/LibKa0s ; echo rc=$?   → rc=0 (empty)
$ diff -r --strip-trailing-cr <tmp>/testkit  tests/_kit   ; echo rc=$?   → rc=0 (empty)
files: tag LibKa0s/ 139, addon libs/LibKa0s/ 139
```

The blob-versus-worktree CR strip is the one normalization `testing-§11` permits, because the archive
side is LF by construction. The consumer gate `tests/test_vendor_sync.lua` passes (§E2).

`libs/` holds AceAddon-3.0, AceConfig-3.0, AceConsole-3.0, AceDB-3.0, AceDBOptions-3.0, AceEvent-3.0,
AceGUI-3.0, AceGUI-3.0-SharedMediaWidgets, AceTimer-3.0, CallbackHandler-1.0, LibKa0s,
LibSharedMedia-3.0 and LibStub. Each one is listed in the TOC `# Libraries` block.

## E9 — Close button, media, reorder (`standalone-windows`, `library-stack-§8`, `options-ui-§18`)

```
$ grep -rn 'MakeCloseButton(' --include='*.lua' . | grep -v '/libs/' | grep -v '/tests/'
core/CoreSetup.lua:87:    return lib.MakeCloseButton(parent, onClick, addonName)
libs/LibKa0s/Core.lua:234:function lib.MakeCloseButton(parent, onClick, addonName)
libs/LibKa0s/DebugLog.lua:75:function lib.MakeCloseButton(parent, onClick, addonName)
libs/LibKa0s/DebugLog.lua:76:  return core.MakeCloseButton(parent, onClick, addonName)
libs/LibKa0s/PerfPanel.lua:190:      local close = core.MakeCloseButton(frame, P.HidePanel, d.addonName or d.name)
tests/test_coresetup.lua:29:  NS.MakeCloseButton({}, function() end)
```

The `libs/` and `tests/` lines appear only because ugrep drops the `./` prefix (see Environment
notes). Only one addon-owned hit remains, the wrapper at `core/CoreSetup.lua:87`, which is compliant.

```
$ grep -rn 'ScrollUp-Up\|ScrollDown-Up' --include='*.lua' settings/   → (no output)
$ … | xargs grep -n 'Interface\\\\'          (authored source, 34 files)
core/Constants.lua:7:C.FALLBACK_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
core/Constants.lua:8:C.FALLBACK_BORDER  = "Interface\\Tooltips\\UI-Tooltip-Border"
core/Constants.lua:17:C.LOGO_PATH = "Interface\\AddOns\\PartyFrameEnhanced\\media\\logos\\partyframeenhanced.logo.tga"
modules/Element.lua:15:local SPARK_TEXTURE  = "Interface\\CastingBar\\UI-CastingBar-Spark"
modules/Element.lua:16:local SHIELD_TEXTURE = "Interface\\CastingBar\\UI-CastingBar-Small-Shield"
modules/Element.lua:17:local MARKER_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
$ ls libs/LibKa0s/media/icons | grep -iE "shield|spark|target|skull|marker|star"
map-marker.tga
shield.tga
star.tga
target.tga
$ … | xargs grep -nE 'SetAtlas|SetText\("(X|x|Copy|Clear)'   → (no output)
```

This output is the basis for PFE-11: the catalog has a `shield` mark and no spark or raid-marker art.

## E10 — Stub coverage (`performance-§1`, `debug-logging-§7`, `slash-commands-§1`, `testing-§8`)

Scope: the 34 authored source files (`xargs … < src.txt`, the list from §E6).

```
$ … | xargs grep -ohE "NS\.DebugLog[:.][A-Za-z]+" | sort | uniq -c
      2 NS.DebugLog.Add
      1 NS.DebugLog.ConsoleCheckbox
      2 NS.DebugLog.Debug
      1 NS.DebugLog.Show
      2 NS.DebugLog:Add
      1 NS.DebugLog:ConsoleCheckbox
      1 NS.DebugLog:IsShown
      1 NS.DebugLog:SetEnabled
      1 NS.DebugLog:Show
      1 NS.DebugLog:Toggle
$ … | xargs grep -ohE "(NS\.)?Perf[:.][A-Za-z]+" | sort | uniq -c
      1 NS.Perf.OnCommand
      3 NS.Perf.suspended
     13 Perf.Note
     12 Perf.on
$ … | xargs grep -ohE "cli:[A-Za-z]+|SlashLib\.[A-Za-z]+" | sort | uniq -c
      2 SlashLib.FormatRow
      1 SlashLib.FormatValue
      1 cli:CliGet
      1 cli:CliList
      1 cli:CliReset
      1 cli:CliSet
      1 cli:LandingRows
      1 cli:OnSlash
      1 cli:PrintHelp
```

Every member listed is answered by its stub:

| Module | Stub location |
|---|---|
| DebugLog | `core/DebugLogSetup.lua:26-60` |
| Perf | `core/PerfSetup.lua:14-21` |
| Slash | `settings/Slash.lua:228-262`; `FormatValue` is guarded by `if SlashLib` at `settings/Schema.lua:251` |

```
$ grep -n "NS.Meta\|NS.Version\|EnvSetup\|LibKa0s-Env" tests/*.lua   → (no output)     [PFE-06: Env degraded path untested]
```

`tests/test_perfsetup.lua:44-51` asserts `on`, `suspended`, `Note` and `OnCommand` on the degraded
arm from a hand-written list, and its comment names no grep (PFE-06). Parity cases exist for Core
(`tests/test_surface_parity.lua:11-22`, member list derived from source), DebugLog (`:24-33`),
Options (`:35-52`) and Slash (`:54-61`), each against a real library-absent load
(`tests/degraded_env.lua`).

## E11 — TOC position annotations (`toc-file-§5`)

These file-scope captures and load-time calls cross within-section positions:

```
$ grep -nE "^local [A-Za-z_, ]+ *= *NS\.[A-Za-z]+" modules/*.lua settings/*.lua   (excerpt)
modules/CastBars.lua:24:local Element = NS.Element          → Element.lua annotated (TOC :70)
modules/TargetFrames.lua:21:local UnitButtons = NS.UnitButtons → UnitButtons.lua annotated (TOC :73)
settings/General.lua:18:local H = NS.Helpers             → OptionsSetup.lua annotated (TOC :83)
settings/CastBars.lua:20:local ElementRows = NS.ElementRows → ElementRows.lua annotated (TOC :87)
$ grep -nE "^(NS\.RegisterSchemaRows)" settings/*.lua
settings/CastBars.lua:79:NS.RegisterSchemaRows(rows)
settings/General.lua:68:NS.RegisterSchemaRows(masterRows)
settings/General.lua:70:NS.RegisterSchemaRows({
settings/PetFrames.lua:49:NS.RegisterSchemaRows(rows)
settings/TargetFrames.lua:79:NS.RegisterSchemaRows(rows)
```

`NS.RegisterSchemaRows` is defined only at `settings/Schema.lua:25`, and the TOC line
`settings\Schema.lua` (`:81`) sits directly under the group header (`:80`) with no annotation. That
is **PFE-02**. `tests/test_loadorder.lua` pins MediaSetup, CoreSetup, OptionsSetup and PerfSetup
(`:41-73`) but not Schema.

## E12 — Settings content from the schema (`options-ui` (a)–(d)), measured headlessly

A read-only script builds the environment exactly as `tests/run.lua:7-29` does, then walks
`NS.SchemaForPage`. It writes nothing.

```
schema rows: 115
PAGE general  tabs: Master controls | Party frames
PAGE castbar  tabs: General | Position | Bar | Border | Text | Icon
  color castbar.barColor             src=unit   next=castbar.useClassColorBar       nextType=bool   nextSrc=unit disabledIf=false
  color castbar.channelColor         src=nil    next=castbar.empowerColor           nextType=color  nextSrc=nil  disabledIf=false   (palette)
  color castbar.empowerColor         src=nil    next=castbar.uninterruptibleColor   nextType=color  nextSrc=nil  disabledIf=false   (palette)
  color castbar.uninterruptibleColor src=nil    next=castbar.failedColor            nextType=color  nextSrc=nil  disabledIf=false   (palette)
  color castbar.failedColor          src=nil    next=castbar.bgColor                nextType=color  nextSrc=unit disabledIf=false   (palette)
  color castbar.bgColor              src=unit   next=castbar.useClassColorBg        nextType=bool   nextSrc=unit disabledIf=false
  color castbar.borderColor          src=unit   next=castbar.useClassColorBorder    nextType=bool   nextSrc=unit disabledIf=false
  color castbar.fontColor            src=unit   next=castbar.useClassColorFont      nextType=bool   nextSrc=unit disabledIf=false
PAGE target   tabs: General | Position | Bar | Border | Text | Marker
  color target.barColor … next=target.useClassColorBar (bool, unit) · hostile/neutral/friendly (palette) · bgColor/borderColor/fontColor → companions (unit)
PAGE pet      tabs: General | Position | Bar | Border | Text
  color pet.barColor / bgColor / borderColor / fontColor → each followed by its useClassColor* bool (unit)
General first-tab rows, in order:
  enabled  [Enable Party Frame Enhanced]
  visibility  [General visibility]
  scale  [Master scale]
  alpha  [Master alpha]
  locked  [Lock frame]
  state.debugConsole  [Debug console]
```

The target and pet lines are condensed from the full per-row output, which matches the castbar shape
above. *Reset position* and *Reset all settings* are the composer's after-group button pair (`masterTail`,
`settings/General.lua:31-49`, `:128`). `SetMovable` appears at `modules/Anchor.lua:211`, so the addon is
not frameless. The only `disabledIf` in the schema is a comment, at `settings/Schema.lua:15`.

For check (h), the vendored strip measures its pitch once, from the inactive cap
(`libs/LibKa0s/OptionsWidgets.lua:404-441`). That is library-owned and not re-audited here.

Global reset coverage (PFE-07). The only reset-related cases found are listed below, and none drives
`RestoreAllDefaults` and checks the profile list or the active profile:

```
$ grep -rn "RestoreAllDefaults\|ResetProfile\|GetProfiles\|MSG.PROFILE" tests/*.lua
tests/test_database.lua:32:  local n = received(NS.MSG.PROFILE, function() NS.ResetProfileCounted(NS.db) end)
tests/test_database.lua:39:  local profiles = received(NS.MSG.PROFILE, function()
tests/test_optionssetup.lua:36:  local live = vetoedByResetAll(NS, NS.Helpers.RestoreAllDefaults)
tests/test_optionssetup.lua:37:  local degraded = vetoedByResetAll(NS2, NS2.Helpers.RestoreAllDefaults)
tests/test_optionssetup.lua:69:                          "MasterControls", "RestoreAllDefaults" }) do
tests/test_preview.lua:53:  NS.bus:SendMessage(NS.MSG.PROFILE)
tests/test_preview.lua:56:  NS.bus:SendMessage(NS.MSG.PROFILE)
```

`vetoedByResetAll` replaces `ns.ApplyDefault` with a recorder (`tests/test_optionssetup.lua:19-20`),
so it checks only which rows the walk touches.

## E13 — Documentation shape (`documentation-§3`)

Scope: `git ls-files 'docs/*.md'`, excluding the frozen run bundles
`docs/automated-tests/<stamp>/` and `docs/perf-analysis/<stamp>/`.

```
docs .md present            map rows (docs/ARCHITECTURE.md:122-166)
ARCHITECTURE.md             ARCHITECTURE.md (MAY self-row — not filed either way)
automated-tests/README.md   scope.md module-map.md schema.md settings-panel.md data-flow.md common-tasks.md   [Required]
automated-tests/RESULTS.md  perf-analysis/README.md slash-dispatch.md profiles.md midnight-quirks.md compat-layer.md
common-tasks.md             message-bus.md (Not applicable, 4 messages) debug.md (Not applicable)          [Conditional]
compat-layer.md             testing.md smoke-tests.md test-cases.md performance.md
data-flow.md                automated-tests/README.md automated-tests/RESULTS.md                          [Verification and record]
midnight-quirks.md          superpowers/ (directory)                                                        [Addon-specific]
module-map.md
perf-analysis/README.md
performance.md
profiles.md
schema.md
scope.md
settings-panel.md
slash-dispatch.md
smoke-tests.md
superpowers/plans/2026-09-15-party-frame-enhanced-v0.1.0.md
superpowers/specs/2026-09-15-party-frame-enhanced-design.md
test-cases.md
testing.md
```

Every `.md` appears in exactly one table: the two `superpowers/` files are covered by the directory
row, and no row dangles. Hub: `wc -l docs/ARCHITECTURE.md` gives 172 lines, and its ten mandated
headings sit at `:8`, `:28`, `:37`, `:54`, `:67`, `:73`, `:89`, `:107`, `:122` and `:168`. Nothing
retired survives (no `file-index.md`, `conventions.md`, `complexity.md`, `docs/perf-runs/` or
`docs/pending/`).

## E14 — Tier 2 trigger counts

```
$ grep -cE '^\s*function\s+[A-Za-z_][A-Za-z0-9_]*\.' core/Compat.lua
17
$ grep -cE '^    \{"' settings/Slash.lua                      (NS.COMMANDS entries)
16
$ grep -cE '^\s+[A-Z]+\s+= "Ka0s_' core/Bus.lua              (distinct messages)
4
```

## E15 — Doc-drift measurements (PFE-01)

```
$ grep -vE '^(#|$)' PartyFrameEnhanced.toc | grep -iE '\.lua$' | grep -viE '^libs' | wc -l
34                                  (docs/ARCHITECTURE.md:30 says "Twenty-two")
$ grep -c '^files\[' .luacheckrc ; grep -c '212/self' .luacheckrc
9
8                                   (docs/testing.md:19 says "Three `files[...]` stanzas")
$ git log --oneline | grep -E "perf pass|cast bars|target and pet|providers"
6722124 Run the offline perf pass and pin the hot paths
691d1ab Add the target and pet frames
98a9dcb Add the cast bars
3ee3a27 Add the frame-system providers and the anchor engine
```

`6722124` is the perf pass that `ARCHITECTURE.md:25` still lists as remaining. `3ee3a27`, `98a9dcb`
and `691d1ab` land what `schema.md:69`, `ARCHITECTURE.md:48` and `data-flow.md:53-54` still describe
in the future tense. `DEPENDENCIES.md:29` names two `git` users; `tests/test_spelling.lua:74` is a
third (`io.popen("git ls-files")`).

## E16 — Citation sweeps (`documentation-§6`)

This is the documented command, plus `--exclude-dir=.git` so the sweep does not read git's object
store; that is the only change. Scope: the whole checkout except `libs/`, `tests/_kit/` and the frozen
`audits/`, `reviews/` and `automated-tests/` trees.

```
$ grep -rEn '§[0-9]+\.[0-9]' . --exclude-dir=libs --exclude-dir=_kit --exclude-dir=audits \
    --exclude-dir=reviews --exclude-dir=automated-tests --exclude-dir=.git | wc -l
17
```

All 17 hits read `spec §N.M`, meaning the addon's design spec at
`docs/superpowers/specs/2026-09-15-party-frame-enhanced-design.md`:

- `core/Compat.lua:80`, `:159`
- `core/PartyFrameEnhanced.lua:130`
- `core/Units.lua:5`
- `defaults/Profile.lua:62`
- `docs/midnight-quirks.md:97`
- the spec itself at `:54` and `:592`
- `modules/Anchor.lua:3`
- `modules/CastBars.lua:3`, `:60`
- `modules/Element.lua:248`
- `modules/PetFrames.lua:3`
- `modules/TargetFrames.lua:3`
- `modules/UnitButtons.lua:5`, `:7`, `:120`

None is a citation of the standard, so the count of retired standard notation is 0 (PFE-08). The
list is given for classification only; the finding stays rolled up.

The range check covered every `filename-§N` in the same scope, built from `git ls-files`: 155
citations. Each was checked against `grep -c '^### [0-9]'` of its section file.

```
OUT OF RANGE: 0   BARE-FILE CITED WITH §N: 0   UNKNOWN FILE: 0
(self-test with injected options-ui-§99 / lint-§1 / nosuch-§1 flagged all three)
```

## E17 — Localization

```
$ lua5.1 lkeys.lua        (loads locales/enUS.lua; collects every L["…"] literal in 33 non-locale source files)
defined keys: 121, distinct keys read by L["..."] literals: 121
DEAD (defined, never read by a literal): 0
READ BUT NOT DEFINED (fall through to key): 0
$ diff <standard BRITISH+ALLOWED> <tests/test_spelling.lua BRITISH+ALLOWED> && echo "LISTS IDENTICAL"
LISTS IDENTICAL
$ grep -nE 'print\("|print\(\("' settings/Slash.lua settings/General.lua | wc -l
28                                  (unrouted user-facing chat literals — PFE-05; e.g. settings/Slash.lua:37, :89)
```

## E18 — Debug trace coverage (`debug-logging-§8`)

```
$ … | xargs grep -c "NS.Debug(" | grep -v ":0"        (authored source, 34 files)
core/Database.lua:1
core/DebugLogSetup.lua:1
core/PartyFrameEnhanced.lua:4
modules/Anchor.lua:1
modules/Preview.lua:1
modules/Providers.lua:1
settings/OptionsSetup.lua:1
settings/Schema.lua:2
```

`modules/CastBars.lua`, `modules/TargetFrames.lua`, `modules/PetFrames.lua`, `modules/UnitButtons.lua`
and `modules/Element.lua` do not appear in this output: each has 0 trace lines (PFE-04). Their only
debug-visible output is the per-combat counters `castsStarted`, `castsInterrupted` and `targetTicks`,
flushed as one `[Combat]` line at `core/PartyFrameEnhanced.lua:154-159`.

## E19 — Release-candidate record vs HEAD (PFE-09)

`docs/automated-tests/20260915-150853/manifest.json:10` reads
`"git": { "sha": "275f786bcd1d1d27d6e3c53a8c3d10a1cfdb4de5", "branch": "master", "dirty": false }`,
and `:14` reads `"tests": { … "passed": 129, … "total": 129 …}`. HEAD is `e215880`, and §E2 counts
131. Only the spelling gate commit separates the two.
