# 01 — Current state: Ka0s Party Frame Enhanced v0.1.0

**Audit run:** 2026-09-15 (first audit of this addon; deviation prefix **`PFE`** assigned here).
**Audited tree:** `master` at **`e215880`** ("Record the v0.1.0 release-candidate run and add the
US-spelling gate"), working tree clean (`git status --short` → 0 lines).
**Standard:** **Ka0s WoW Addon Standard v2.44.0 (2026-09-12)**. `AUDIT.md`, `standards/STANDARDS.md`,
all 26 section files linked from its Sections list, and `standards/ADDONS.md` were fetched with
`curl -fsSL` from `raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master` on the audit date.
**Rule set used:** the **addon** rule set. The repo has a `.toc`, and it is a roster row in
`standards/ADDONS.md:27` ("Ka0s Party Frame Enhanced"). It is not a library and not a documentation repo.

Every claim below is backed in `03_EVIDENCE.md`; deviations are in `02_DEVIATIONS.md`.

---

## Layout (`layout`)

- Modular skeleton present: `core/` (14 files), `defaults/` (1), `locales/` (1), `modules/` (8),
  `settings/` (10), plus `libs/`, `tests/`, `docs/`, `media/`. Nothing loose at the root beyond the
  sanctioned root docs and dotfiles.
- Folder load order in the TOC is `libs → locales → core → defaults → modules → settings`.
- **LOC cap (`layout-§1`).** Census over the default denominator
  (`git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'`, 60 files, `tests/` included): largest
  file is `modules/CastBars.lua` at 382 lines; **0** files in the 1000–1500 band, **0** over 1500.
- Casing: root folder `PartyFrameEnhanced` matches `## Title: Ka0s Party Frame Enhanced`; lowercase
  subfolders; PascalCase Lua files.
- `media/` holds only `media/logos/partyframeenhanced.logo.tga` (runtime) and its `.png` source. No
  private copy of a shared-media asset (`layout-§3`, anti-pattern #63).

## TOC (`toc-file`)

- Field order matches `toc-file-§1` exactly (Interface → … → X-Standard). Single
  `## Interface: 120100` line. `## X-License: MIT`; `## X-Standard:` points at the standards repo
  (`PartyFrameEnhanced.toc:12`).
- `X-Curse-Project-ID` is absent with the comment `# X-Curse-Project-ID: not published on CurseForge
  yet` in the field's own position (`:13`). That is the **compliant** unpublished state, and nothing is
  filed for it.
- `## SavedVariables: PartyFrameEnhancedDB, PartyFrameEnhancedPerfDB`: two globals, because the perf
  harness is wired (`toc-file-§2`).
- `# Libraries` lists each vendored library directly and `libs\LibKa0s\LibKa0s.xml` once, after
  Ace3 (`:27`).
- **Position annotations (`toc-file-§5`).** The load-bearing positions I found by reading the seam files
  and `core/Constants.lua` are Namespace, MediaSetup (before Constants), CoreSetup, PerfSetup,
  DebugLogSetup, Providers, Element, UnitButtons, `settings\Schema.lua`, OptionsSetup and ElementRows.
  All are annotated **except `settings\Schema.lua`** (`:81`) → **PFE-02**. Conventional positions are
  declared once for the group (`:35-36`). The file ends in one `\r\n`.

## Libraries (`library-stack`)

- Vendored under `libs/`: LibStub, CallbackHandler-1.0, AceAddon/AceEvent/AceTimer/AceConsole/AceDB/
  AceGUI/AceConfig/AceDBOptions-3.0, LibSharedMedia-3.0, AceGUI-3.0-SharedMediaWidgets, LibKa0s. Every
  one is reached (mixin strings in `core/PartyFrameEnhanced.lua:8`, the Profiles page, the Options
  composers' LSM widgets). No `externals:`.
- **LibKa0s v1.36.1**, named by the provenance line in `CLAUDE.md:37`. The provenance line is in
  `CLAUDE.md` only, not in `README.md`, and the README has no library inventory (anti-patterns
  #58/#59: compliant).
- **Vendor sync.** I diffed both payloads against tag `v1.36.1` in the sibling `../LibKa0s`
  (`git archive v1.36.1`). `diff -r --strip-trailing-cr` is **empty** for `LibKa0s/` against
  `libs/LibKa0s/` (139 files each side) and for `testkit/` against `tests/_kit/`. The in-suite gate
  `tests/test_vendor_sync.lua` passes rather than skipping. The sibling's own HEAD sits at `v1.36.2`.
  Moving to it is a scheduling decision, not a compliance one, so nothing is filed.
- Seven majors wired, one setup file each: Media (`core/MediaSetup.lua`), Env (`core/EnvSetup.lua`),
  Core (`core/CoreSetup.lua`), Perf (`core/PerfSetup.lua`), DebugLog (`core/DebugLogSetup.lua`), Slash
  (`settings/Slash.lua`), Options (`settings/OptionsSetup.lua`). Pool, Item and Widgets are vendored
  but not wired, which is the whole-folder rule working as intended.
- Optional suite integration is EllesmereUI. It is presence-guarded through `Compat.IsAddOnLoaded`
  (`modules/Providers.lua:96`), listed in `## OptionalDeps:`, and falls back to Blizzard frames or free
  placement (`library-stack-§6`).

## The shared subsystems: descriptor + stub, not hand-rolled

| Module | Setup file | Lookup | Stub branch | Members the addon reaches (grep) | Stub answers all? |
|---|---|---|---|---|---|
| Core | `core/CoreSetup.lua` | `:15` | `:17-69` | `NS.SafeToString`, `NS.ResolveColor`, `NS.Print`, `NS.MakeCloseButton`, `NS.SKIN`/`ApplySkin` | yes |
| DebugLog | `core/DebugLogSetup.lua` | `:11` | `:13-63` | `Add`, `Debug`, `Show`, `IsShown`, `SetEnabled`, `Toggle`, `ConsoleCheckbox` | yes |
| Perf | `core/PerfSetup.lua` | `:10` | `:11-23` | `Perf.on`, `Perf.Note`, `NS.Perf.suspended`, `NS.Perf.OnCommand` | yes |
| Slash | `settings/Slash.lua` | `:14` | `:226-263` | `cli:PrintHelp/CliList/CliGet/CliSet/CliReset/LandingRows/OnSlash`, `SlashLib.FormatRow` | yes; `FormatValue` is guarded at `settings/Schema.lua:251` |
| Options | `settings/OptionsSetup.lua` | `:22` | `:84-133` | load-time composers + `LSMValues`; the rest no-op | **load-completing by design** (the one documented exception); the composers are hollow |
| Media | `core/MediaSetup.lua` | `:16` | per-function nil answers `:21-30` | `NS.Icon`, `NS.MediaFont` | yes |
| Env | `core/EnvSetup.lua` | `:10` | per-function fallback ladder `:13-29` | `NS.Meta`, `NS.Version` | yes (but see **PFE-06**: untested degraded) |

No private console, widget maker, flow engine, dispatcher, parser or test framework exists in the addon
(anti-pattern #47: compliant).

**Close-button wrapper (`standalone-windows`).** One wrapper at `core/CoreSetup.lua:86-88` passes
`addonName`, and there is a degraded twin at `:53`. The only caller is a test. There is no decoration
hook on the perf panel (`core/PerfSetup.lua:75-76`), and the DebugLog descriptor carries `addonName`
(`core/DebugLogSetup.lua:70`, debug-logging-§13).

**Shared media.** `core/MediaSetup.lua` passes the file's own first vararg, loads before
`core/Constants.lua` and makes one `RegisterLSM` call at file load (`:34`). The hard-coded `Interface\`
paths are the fallback bar texture and border (`core/Constants.lua:7-8`) and the Blizzard cast-bar
spark, shield and raid-marker art (`modules/Element.lua:15-17`). On the last of those see **PFE-11**.

## Patterns (`architecture`)

- `NS` comes from the vararg in all 34 source files. Ten open with a header comment above the
  bootstrap line, which the standard's own worked example in `localization-§1` does too, so this is
  noted, not filed. No `_G[addonName]` write exists. The two `_G[...]` hits are reads of other
  addons' frames (`modules/Providers.lua:90`, `:126`).
- AceAddon promotion with `NS` as the addon object, and `NS.Print` reclaimed after `NewAddon`
  (`core/PartyFrameEnhanced.lua:8`, `:14`; architecture-§2, anti-pattern #36).
- **Closed bus:** 4 messages, one sender each, and one `NS.NewBusTarget()` per receiver
  (`core/Bus.lua:26-37`). The table is in `ARCHITECTURE.md`.
- **Schema as single source.** 115 rows fully loaded. There is one write seam, `NS.SetByPath`
  (`settings/Schema.lua:159-173`), and boot validation, `NS.ValidateSchema` (`:269`).
- **Write-path classification** (the step 4 grep in `03_EVIDENCE.md` §E6):
  - (d) **Wholesale replacement.** The global reset is a profile reset
    (`settings/OptionsSetup.lua:43-46`), and `/pfe profile use|new|copy|reset` goes through AceDB. Compliant.
  - (c) **Load pass.** `NS:RunMigrations` (`core/Database.lua:37-48`) and the AceDB-less fallback
    (`:21-27`) are reached from `OnInitialize` and the harness only. Compliant.
  - (e) **Named non-setting state.** `castbar/target/pet.position` is written by
    `Anchor.SavePosition` on drag-stop (`modules/Anchor.lua:218-221`, `:262`) and cleared by
    `Anchor.ResetPositions` (`:271`). Both writers are named in `ARCHITECTURE.md:45-48` and
    `docs/schema.md:66-69`. Compliant.
  - (a) **Schema-row write outside the helper.** `modules/Preview.lua:37` writes `locked` through the
    raw `NS.SetSetting` → **PFE-03**.
  - No structural registries: the player creates and deletes nothing.

## SavedVariables (`savedvariables`)

- AceDB `PartyFrameEnhancedDB` with defaults only in `defaults/Profile.lua`. `global.schemaVersion = 1`
  (`defaults/Profile.lua:118`); the runner ladder is empty by design (`core/Database.lua:34`). There is
  an AceDB-less soft fallback.
- `PartyFrameEnhancedPerfDB` is the one sanctioned diagnostics global, outside the AceDB tree.
- No `or`-defaulting of a stored boolean, empty string or empty set was found (savedvariables-§5).

## Settings panel (`options-ui`) — measured from the schema, headlessly

| Page | Tabs, in declaration order |
|---|---|
| Landing | exempt (host `buildMain`: logo, Notes, "Slash Commands" rows from `NS.COMMANDS`) |
| General | **Master controls** · Party frames |
| Cast Bars | General · Position · Bar · Border · Text · Icon |
| Target Frames | General · Position · Bar · Border · Text · Marker |
| Pet Frames | General · Position · Bar · Border · Text |
| Profiles | exempt (AceDBOptions via AceConfigDialog, the one sanctioned AceConfig use) |

- (a) Every flow-engine page renders through `RenderTabbedSchema`.
- (b) The General first tab is exactly `Master controls`. Its rows are enabled, visibility, scale,
  alpha, locked and state.debugConsole, followed by the composed *Reset position* | *Reset all
  settings* pair. The addon is not frameless (`SetMovable` at `modules/Anchor.lua:211`).
  `visibility` has been the four-value dropdown since schema v1, so no migration is owed.
- (c) Every non-palette color row is followed by its `Use class color` bool, both carry
  `classColorSource = "unit"`, and the render paths resolve the unit the surface describes
  (`modules/CastBars.lua:88`, `modules/TargetFrames.lua:44-57`, `modules/PetFrames.lua:35`). The
  cast-state and NPC-reaction palettes are the sanctioned exemption.
- (d) No `disabledIf` in the schema.
- (e) No reorder arrows, and there is nothing to reorder.
- (f) The font, border and bar blocks are composed. Palette and extra rows sit under their own subgroups.
- (g) The feature pages keep their page-wide *Enable* on a first tab named `General`. No page edits
  one-of-many instances, so no picker or band is owed.
- (h) The vendored strip measures its pitch once, from the unselected cap
  (`libs/LibKa0s/OptionsWidgets.lua:404-441`). That is library-owned and not re-audited here.
- (i) There is no secondary strip.
- **Global reset.** The live and degraded builds share one veto (`settings/OptionsSetup.lua:17-20`,
  `:38`, `:101`). The popup wording is verbatim (`settings/General.lua:97`), with Yes/No, `timeout 0`,
  `whileDead` and `hideOnEscape`. There is no `afterRestoreAll` geometry hook. The suite's coverage of
  the blast radius is partial → **PFE-07**.
- **Degraded Options.** The stub is load-completing and its composers are hollow. The suite pins
  115 rows fully loaded, 58 library-absent, and a composer gap of 57
  (`tests/test_optionssetup.lua:47-64`).

## Slash (`slash-commands`)

- `/pfe` and `/partyframeenhanced` are registered through AceConsole (`settings/Slash.lua:298-299`).
  `NS.COMMANDS` holds 16 positional triples. All ten reserved verbs are present, plus `resetposition`,
  `lock`, `unlock`, `preview`, `status` and `profile`. The alias `options` maps to `config`.
- The chat tag `NS.PREFIX = "|cff00ffff[PFE]|r"` (`core/Namespace.lua:8`) goes through the Core printer.
- In the degraded stub the host verbs keep working, and each schema CLI verb names the missing library.

## Debug (`debug-logging`)

- The console comes from the library descriptor. The flag is session-only in `NS.State.debug`. There
  is one `SetEnabled` seam and an `initSummary`. `[Set]` is logged once at the seam, with a bulk
  bracket and profile-event lines.
- Traced flows: provider resolve, anchor passes, preview, secure queue/flush, a combat rollup of
  per-combat counters, migrations, `[Set]`. **No trace line exists in `modules/CastBars.lua`,
  `modules/TargetFrames.lua` or `modules/PetFrames.lua`** → **PFE-04**.

## Events / taint (`events-frames-taint`)

- Lifecycle, roster and Edit Mode events use AceEvent on each module's own target. Per-unit
  events use `RegisterUnitEvent` on the element frames, which is the **recorded deviation**
  (see Register, below).
- Every secure write goes through `NS.RunSecure`: out of combat it runs at once; in combat it is
  queued per key and flushed on `PLAYER_REGEN_ENABLED`. Secure buttons are created at `OnEnable`, and
  visibility is a state driver. Display logic uses the combat flag; secure gating uses `InCombatLockdown`.
- Secret values go only to C setters or through `Compat` guards, and none is concatenated, formatted
  in Lua or compared.

## Compat (`compat`)

- `core/Compat.lua` publishes **17** shims. `docs/compat-layer.md` exists, as the Tier 2 trigger
  (3 or more) requires.

## Localization (`localization`)

- `NS.L` has a key-returning metatable, and `enUS.lua` ships 121 keys. None is dead: every defined key
  is read by an `L["..."]` literal and none is read undefined.
- Game data is matched on tokens and ids, never on display strings. The class token comes from
  `UnitClass`'s second return (`core/Compat.lua:178-182`).
- The US-English gate `tests/test_spelling.lua` carries both canonical lists, byte-identical to
  `localization-§5`, and passes.
- Chat output in `settings/Slash.lua` and the landing heading bypass `NS.L`, and there is no
  English-only register row → **PFE-05**.

## Tests (`testing`)

- Kit revision 21 is vendored whole. `tests/run.lua` derives both load lists: the library half from
  `LibKa0s.xml`, the addon half from the TOC. `Kit.run{ dir = "tests/" }` runs
  `assertSuiteInventory` in both directions.
- `lua tests/run.lua` gives **131 passed, 0 failed, 0 skipped**. `docs/test-cases.md` is in sync with
  `--list` (131) and the README badge reads `131/131`. The gate takes 5.25 s wall and 0.57 s user, so
  `--jobs` is not owed.
- Degraded path: `tests/degraded_env.lua` is a real library-absent load. Parity cases exist for Core,
  DebugLog, Options and Slash. Perf is covered by a hand-listed case, and Env has no degraded case at
  all → **PFE-06**.

## Performance (`performance`)

- The harness is wired, with ten declared buckets and two nested ones declaring `within`. All brackets
  use Shape A with a load-time `Perf` upvalue. `tests/test_perf_buckets.lua` pins the bucket
  reachability. Suspend/resume goes through the module registry, and every show ladder checks
  `NS.Perf.suspended` first (`modules/Element.lua:253`).
- `tests/perf.lua` runs 9 scenarios, including the zero-overhead pair `probeOverheadOff`/`On`, and is
  outside the gate. `docs/perf-analysis/README.md` holds no captures yet; P10 is blocked on the player.
- **Complexity** (`lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .`, verbatim): NLOC 5084 over 667
  functions, averages 5.7 NLOC and CCN 2.3, **max CCN 15**, **0 warnings**. The max is
  `NS.ValidateSchema` (`settings/Schema.lua:269-297`), a flat sequence of independent guard checks,
  not tangled control flow.
- The drift against the latest bundle `20260915-150853` (NLOC 4995, 664 functions, max 15, 0 warnings)
  is the spelling gate added in the same commit. No threshold crossed and no file entered the band.
  The watch list is empty, with 0 `Accepted` entries. See **PFE-09**.
- The complexity refactor `e4a6e9a` uses only permitted shapes (performance-§11): named file-local
  helpers, and module-level tables `TICKS` (`modules/CastBars.lua:215`) and `GROWTH_DIR`. All three
  touched functions were already covered by `test_anchor`, `test_castbars` and `test_targetframes`.

## Automated-test record (`automated-tests`)

- The runner `tests/_kit/run-automated-tests.sh` is vendored and recorded `100755`. `README.md` and
  `RESULTS.md` both exist. There are two bundles, and the release-candidate one carries
  `ANALYSIS.md`. No retired `docs/complexity.md` or `docs/perf-runs/` survives.

## Packaging (`packaging`)

- `.pkgmeta` ignores every named dev entry. Every root dot-entry except `.git` is accounted for
  (`.git` is exempt). There is no `externals:`.

## `.gitattributes` (`line-endings`) — recorded verbatim

- The pin is `* text=auto eol=crlf` (`:26`), which is correct for a client-bound repo; the carve-out
  `*.sh text eol=lf` is at `:34`; 20 `binary` lines.
- The body is byte-identical to the canonical 81-line client-bound file, with nothing after it.
- Working-tree strays: **0**. The vendored EOL gate `tests/_kit/test_eol.lua` (kit ≥ 15) is green and
  agrees.

## Root doc set and `docs/`

- `README.md` follows the canonical order (no Screenshots yet; unpublished, and the section would be
  empty). It has a bare `![Standard](…)` badge (`README.md:5`), no library inventory, and no
  angle-bracket placeholders.
- `CLAUDE.md` is a stub carrying `## Standards compliance (read first)` (`:6`) and the provenance
  line (`:37`). `DEPENDENCIES.md` is split into runtime, development and release groups.
- **Tier model (`documentation-§3`).**
  - Tier 1: all six docs are present under their canonical names.
  - Tier 2: the present docs match fired triggers — `slash-dispatch.md` (16 commands),
    `midnight-quirks.md`, `compat-layer.md` (17 shims), `profiles.md` and `perf-analysis/README.md`.
    `message-bus.md` (4 messages, trigger is more than ten) and `debug.md` carry accurate *Not
    applicable* rows.
  - The map has all four tables. *Verification and record* holds exactly the six mandated docs, and
    `superpowers/` is named once as a directory. It covers every `.md` under `docs/` with no dangling
    rows. There are no non-canonical names and no retired docs.
  - The hub is 172 lines and no section passes about 60 lines.
- **Doc drift at HEAD** → **PFE-01**. The plan ledger marks P8 "Docs sync … done" at
  `docs/superpowers/plans/2026-09-15-party-frame-enhanced-v0.1.0.md:36`, but the sites listed there
  were missed.

## Register and issue store (`audit-review-history`)

- `## Documented deviations` (`ARCHITECTURE.md:168-172`) has one row: `events-frames-taint-§1`,
  RegisterUnitEvent on element frames, Decided 2026-09-15, re-check trigger "AceEvent or LibKa0s
  gains a unit-filtered registration".
  - The rule is unchanged in v2.44.0.
  - The trigger has **not** fired (`grep -rln RegisterUnitEvent libs/` → nothing).
  - The row cites no evidence ids, so there are none to resolve.
  - It is **accepted** as **PFE-10** and does not count toward the MUST tally.
- The issue store (`gh issue list --state all`) holds 12 issues, all open, all `state:triaged`, each
  with a `severity:` label. No `[status]` title prefixes, no `state:will-not-do` declines, so no
  register row is owed by an issue.
- There is no `docs/pending/LEDGER.md`, and no prior `docs/audits/` or `docs/reviews/`.
