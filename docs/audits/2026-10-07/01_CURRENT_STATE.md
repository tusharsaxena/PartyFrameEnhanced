# 01 — Current state: Ka0s Party Frame Enhanced

| | |
|---|---|
| Run date | 2026-10-07 |
| Repo kind | **Addon**. `dev-copilot-profile` reported `profile=wow kind=addon` (reason `toc:## Interface`). The repo has `PartyFrameEnhanced.toc` and a row in `standards/ADDONS.md` → *In-scope addons* (launcher menu entries **Enabled · Locked**). Detector and table agree. Audited against the whole addon rule set |
| Standard | **Ka0s WoW Addon Standard v2.76.1 (2026-10-07)**: `standards/STANDARDS.md` plus all **27** section files its *Sections* list links, fetched with `curl -fsSL` from `raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master` on 2026-10-07. `standards/ADDONS.md` fetched the same way |
| Playbook | `AUDIT.md` from the same ref (1156 lines) |
| Commit audited | `fb5c0b9` ("Merge branch 'feat/2026-10-06-revendor-libka0s-v1.69.0'"), branch `feat/2026-10-07-review-audit-remediation`, clean tree |
| Addon version | `## Version: 1.1.0` (`PartyFrameEnhanced.toc:5`) |
| Prior audits | `docs/audits/2026-09-15/` (v2.44.0) and `docs/audits/2026-09-23/` (v2.64.0). Prefix **`PFE`** is kept, and so are the recurring IDs. New findings start at PFE-25 |
| Bounded runner | `~/.claude/dev-copilot/bin/ka0s-bounded` (symlink into the dev-copilot 2.0.1 plugin). `luacheck`, `lua tests/run.lua`, `lua tests/run.lua --list` and the complexity suite all ran through it. No run exited 124 or 137 |

## Layout (`layout`)

- Folder load order is `libs → locales → core → defaults → modules → settings` (`PartyFrameEnhanced.toc:15-115`).
  The TOC lists 40 addon files and 15 library lines.
- Default census scope (`git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'`): 79 files, 15,781 lines.
  The largest are `tests/test_launcher.lua` (578), `tests/test_slash.lua` (540), `tests/test_disabled.lua`
  (533) and `settings/Slash.lua` (521). No file is in the 1000–1500 band or over the cap.
- The over-cap census heading `### Files over the 1500-line cap` sits under `## Documented deviations`
  and reads "Nothing is over the cap today" (`docs/ARCHITECTURE.md:430-435`). The kit gate
  `test_layout_cap` is wired by path (`tests/run.lua:110`).
- All 40 source files open on the namespace bootstrap (line 1) with the self-naming header at line 3.
  PFE-20 and PFE-20a are closed.
- `media/` holds `logos/` and `screenshots/` only. `media/logos/partyframeenhanced.logo.128.tga` is TGA
  type 2, 128×128, 32 bpp. The landing-page `.tga` is 512×512.
- No authored generator: `git ls-files '*.py' '*.sh'` returns only the vendored
  `tests/_kit/run-automated-tests.sh`, and there is no `tools/` folder.

## TOC (`toc-file`)

- Field order matches `toc-file-§1`. `## IconTexture` names the addon's own 128 logo (`:6`), and
  `## X-Curse-Project-ID: 1698335` (`:13`) is the published id. There is one `## Interface: 120100`, and
  the README badge reads `Midnight_12.1.0`.
- `libs\LibKa0s\LibKa0s.xml` is listed once, after Ace3 and the broker libraries (`:31`).
- `# Core` carries the group statement "Load-bearing positions say what resolves at load; the rest are
  conventional" (`:39-40`). Each load-bearing line names what resolves, including LifecycleSetup →
  PerfSetup (`:57-58`), SecureFollow (`:89-91`) and Diagnostics (`:97-99`, marked conventional). PFE-16 is closed.

## Libraries (`library-stack`)

- Ace3 subset (AceAddon, AceEvent, AceTimer, AceConsole, AceDB, AceGUI, AceConfig, AceDBOptions),
  LibSharedMedia-3.0, AceGUI-3.0-SharedMediaWidgets, LibDataBroker-1.1, LibDBIcon-1.0, and
  **LibKa0s v1.70.0**, vendored whole.
- Provenance: `CLAUDE.md:39`, `Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.70.0 (MIT).`
  It is not in `README.md`.
- `diff -r` against the LibKa0s **v1.70.0** tag (`git archive`): `libs/LibKa0s` is empty (159 files
  each side) and `tests/_kit` is empty (22 files each side). The kit is revision 37
  (`tests/_kit/framework.lua:20`).
- The addon wires twelve majors, one setup file each: Media, Env, Core, Compat (the `IsSecret` guard
  only), Bus, Lifecycle, Perf, DebugLog, Launcher, Schema (`settings/Schema.lua`), Slash and Options.
  Pool, Item and Widgets are vendored and not wired. Schema was adopted under #14, which is closed.
- Each wired major has a library-absent arm. `tests/test_surface_parity.lua` pins every stub against
  its live major, and the Slash stub's copy of `DISABLED_LINE_FORMAT` is pinned with
  `Kit.assertLibraryConstant`, the one carried string `slash-commands-§1` now sanctions. PFE-23 is
  closed upstream. The Launcher has no stub, and the reason is written down (`core/LauncherSetup.lua:33-40`).
- Suite integration: EllesmereUI is optional (`## OptionalDeps`). Its SavedVariables read is a
  **ratified register row** (`library-stack-§6`, see below).

## Architecture (`architecture`)

- `NS` is promoted through `AceAddon:NewAddon(NS, addonName, "AceEvent-3.0", "AceTimer-3.0",
  "AceConsole-3.0")`, and `NS.Print` is reclaimed (`core/PartyFrameEnhanced.lua:8-14`).
- The closed bus has four messages declared through `Bus.Catalog` with PascalCase tails
  (`core/Bus.lua:104-107`). No call site types a `Ka0s_` literal. The Message Bus table lists every
  consumer, Preview and SecureFollow included (`docs/ARCHITECTURE.md:136-139`).
- There is one write seam, `NS.SetByPath`, the `LibKa0s-Schema-1.0` instance's `Set`. The only writes
  into the stored tree outside it are `modules/Anchor.lua:393` and `:404` (named non-setting state
  `<feature>.position`, owner and writers named at `docs/ARCHITECTURE.md:94-96`) and the minimap row's
  own `set` (`settings/General.lua:64`).

## Settings (`options-ui`, `savedvariables`)

- AceDB `PartyFrameEnhancedDB`, `NS.SCHEMA_VERSION = 1` with an empty ladder. A "profile" step now runs
  over **every stored profile** (`core/Database.lua:53-62`), which closes PFE-22.
- Pages and tabs: General (Master controls · Party frames · Health updates); Cast Bars, Target Frames
  and Pet Frames (General · Size & Position · Bar · Border · Text, then Icon or Marker); Profiles
  (AceDBOptions); and the landing page `settings/About.lua`. Master controls is composed by
  `H.MasterControls` (`settings/General.lua:76-95`).
- The test mode exemption holds: unlocking is the preview (`modules/Preview.lua:7-15`).
- Color rows are the exempt palettes (`settings/CastBars.lua:52`, `settings/TargetFrames.lua:59`) or
  the `H.ColorPair` composer. No `disabledIf` sits on a color row, there are no reorder arrows, and
  font, border and bar groups are composed.

## Slash (`slash-commands`)

- `/pfe` and `/partyframeenhanced` are registered in `OnInitialize` (`settings/Slash.lua:518-521`).
  `NS.COMMANDS` holds 18 positional triples (`settings/Slash.lua:22-64`), including `enable` and
  `disable` (both write `enabled` through the seam), `diagnostics`, `lock` and `unlock`.
- While disabled, the library gate runs with `liveVerbs` set to the 13 reserved verbs plus `status`
  and `profile` (`settings/Slash.lua:95-99`). `resetposition`, `lock` and `unlock` get the one
  refusal line, which is the §2 SHOULD, met.

## Launcher (`launcher`)

- There is one LDB object through `LibKa0s-Launcher-1.0`: name `addonName`, icon the 128 logo, label
  `Ka0s Party Frame Enhanced`, and `isEnabled`/`setEnabled` plus `isLocked`/`toggleLock`, which match
  the ADDONS.md column. It also carries `version`, `debug` and `debugAtEnable`
  (`core/LauncherSetup.lua:46-102`). There is no host `onTooltipShow`, `OnClick` or menu.

## Disabled state (`slash-commands-§7`)

- One latch, two holds, through `LibKa0s-Lifecycle-1.0`. `NS.StandDown`
  (`core/PartyFrameEnhanced.lua:180-190`) unregisters the lifecycle events, runs every module's
  `Suspend`, publishes VISIBILITY, stands the bus down, and arms the pending-regen listener only while
  something is queued.
- Module teardowns are real unregisters. Providers unregisters its events **and** the
  `EditMode.Exit` callback, and `burst()` arms nothing while suspended (`modules/Providers.lua:57-73,
  377-403`), so PFE-12 is closed. RangeFade hides the fade frames and Anchor hides the holders
  (`Suspend` hooks), so PFE-13 is closed. SecureFollow's residual gated wrap is a ratified register row.
- `tests/test_disabled.lua` is listed (`tests/run.lua:102`), asserts on the recording mock's
  registration set (EventRegistry callbacks included), and dispatches both diagnostics forms.
- **The pending-regen listener is a private `CreateFrame("Frame")`** (`core/PartyFrameEnhanced.lua:117-129`)
  in an addon that embeds AceEvent-3.0. That is outside `events-frames-taint-§1`'s boundary-watcher
  carve-out (PFE-25).

## Debug (`debug-logging`)

- `LibKa0s-DebugLog-1.0` descriptor and stub are in `core/DebugLogSetup.lua`. The `debug` sink is
  passed to Slash, Options, Launcher, Lifecycle and Schema. `diagnostics` is a single `COMMANDS` row,
  `runDebug` tests `diagnostics` first, and there are no aliases.
- `runDebug` hand-routes `diagnostics`/`on`/`off` instead of calling the library's `DebugVerb`
  (`settings/Slash.lua:243-254`). It behaves correctly and is noted as PFE-31.

## Tests and lint (`testing`, `lint`)

- `luacheck .`: **0 warnings / 0 errors in 79 files**. `exclude_files` narrows to `tests/_kit/` plus
  `libs/`, `docs/audits/`, `docs/reviews/` and `_dev/`. There is no top-level `ignore`.
- `lua tests/run.lua`: **454 passed, 0 failed, 1 skipped, 455 total**. The skip is the kit's opt-out
  diagnostics contract case, which does not apply because this addon keeps the default. The README
  badge reads `454/455`, and `docs/test-cases.md` is byte-identical to a fresh `--list`.
- No raised heap, leak or case budget in `tests/run.lua`.

## Performance and complexity (`performance`, `automated-tests`)

- Ten declared buckets, `/pfe perf` registered by the addon. `docs/perf-analysis/` holds three bundles,
  each with `report.md`, `dump.json` and `ANALYSIS.md`.
- Sighted complexity now (`run-automated-tests.sh --suite complexity --no-bundle`): **1602 functions,
  max CCN 14, 0 warnings**, verdict green. The newest bundle `20260927-030324` measured `692cec2`, which
  is 47 commits behind HEAD: 1318 functions, max CCN 14, 0 warnings. That bundle predates the sighted
  suite, so its manifest carries no `blindFiles`. No threshold was crossed and no file entered the band.
  The watch list is empty.

## Packaging and line endings

- `.pkgmeta` checks (a), (b) and (c) print nothing except `.git`, which is exempt. PFE-21 is closed.
- `.gitattributes`: `* text=auto eol=crlf` (`:26`), `*.sh`/`*.py text eol=lf` (`:36-37`), 20 `binary`
  marks. The first 84 lines are identical to the canonical client-bound body, and there is no tail.
  Working-tree disagreement: **0**. `tests/_kit/test_eol.lua` is wired.

## Root docs (`documentation-§1/§2/§7`)

- README: H1, five canonical badges (the standard badge is bare, `:6`), description, Screenshots, Usage
  (prose, five paragraphs or fewer, closing signpost), How it works, FAQ, Troubleshooting (with the
  canonical *Reporting a bug* row), `## Reporting a bug` verbatim for `/pfe`, Issues, Version History
  (`- `-prefixed highlights), and `## Credits` (JetBrains Mono only, which is external credit). There
  is no logo image, no numbered list and no library inventory.
- `CLAUDE.md` is a stub carrying the Standards compliance section, the pointer list, the gate line and
  the provenance line. `DEPENDENCIES.md` has runtime, development and release groups with verification
  commands.

## `docs/` (`documentation-§3`)

- Tier 1: all six docs are present. Tier 2: `perf-analysis/README.md`, `slash-dispatch.md` (18
  commands), `profiles.md`, `midnight-quirks.md`, `compat-layer.md` (14 shims by the standard's grep)
  and `debug.md` are present. `message-bus.md` is *Not applicable* (4 messages).
- `## Documentation map` covers all 19 live `.md` files exactly once, with no dangling rows. It has
  **three** tables: `### Addon-specific` was deleted in `bc3c941` (PFE-29). The compat row states 15
  shims using its own grep (PFE-01).
- The hub is **435 lines**. Overview's build-status paragraph is a 1609-character re-vendor history
  line (`:55`) (PFE-27).
- `## Documented deviations` has two rows, read below.

## Register and issue store (`audit-review-history`)

- **Row 1, `slash-commands-§7`** (SecureFollow's gated wrap, Decided 2026-10-01). The cited rule still
  says what the row claims. The trigger (a safe by-header unwrap, or the carve-out extended) has not
  fired, and the cited ids resolve (#3 closed `state:done`; `GI-PF-02` is commit `abfd7e9`; D9 is in
  `Ka0sAddonsCommonTasks/docs/2026-10-01-GITHUB_ISSUE_PASS/00_OVERVIEW.md:56`). **Accepted**, not counted.
  The row still says "pending the owner's ratification" (PFE-28).
- **Row 2, `library-stack-§6`** (EllesmereUIDB read, Decided 2026-09-24). The rule is unchanged and
  still forbids the read. The trigger has not been observed to fire. **Accepted**, not counted. The
  **Why** cell cites no issue or bundle, which the standard asks for as a SHOULD (PFE-28).
- `gh issue list --state all`: 15 issues (#1–#15), each with one `state:` and one `severity:` label,
  and no `[status]` prefixes. There is no `LEDGER.md`. #1 (`state:will-not-do`, raid frames) is a
  scope decision rather than a rule departure.
- `docs/revendor/` has 14 bundles. **v1.69.0 and v1.70.0 were vendored with no bundle** (PFE-26).

## Status of the 2026-09-23 findings

| ID | Now |
|---|---|
| PFE-12 / 12a / 12b | **Closed**: callback unregistered in `Suspend`; the kit's EventRegistry recorder sees it; the table lists it |
| PFE-13 | **Closed**: fades and holders hidden on stand-down through `NS.RunSecure` |
| PFE-14 | **Closed**: every registration goes through `NS.SafeRegister*`, and rejects are reachable through `/pfe status` and diagnostics |
| PFE-10 | **Closed**: stale row retired |
| PFE-15 / 15a | **Closed** as a ratified register row, and the docs name the read |
| PFE-16 | **Closed**: TOC annotation plus load-order case |
| PFE-17 | **Closed**: the Lock row prints `NS.DisabledLine()` |
| PFE-18, PFE-05 | **Closed**: 210 keys, 0 unreferenced; provider labels routed |
| PFE-19 | **Closed** |
| PFE-01 | **Recurs**, with new content |
| PFE-20 / 20a | **Closed** |
| PFE-21 | **Closed** |
| PFE-08 | **Recurs** (Info), 18 hits, all the addon's own design spec |
| PFE-09 | **Recurs** (Info) |
| PFE-22 | **Closed** |
| PFE-23 | **Closed upstream**: `slash-commands-§1` sanctions the one carried string, with its pin |
| PFE-24 | **Closed**: `LOGO_PATH` built from `addonName` |
