# 01 — Current state: Ka0s Party Frame Enhanced

| | |
|---|---|
| Run date | 2026-09-23 |
| Repo kind | **Addon** (has `PartyFrameEnhanced.toc`; row in `standards/ADDONS.md` → *In-scope addons*, launcher rung **(b)**) — audited against the whole addon rule set |
| Standard | **Ka0s WoW Addon Standard v2.64.0 (2026-09-23)**, `standards/STANDARDS.md` plus all 27 section files its *Sections* list links, fetched with `curl -fsSL` from `raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master` on 2026-09-23 |
| Playbook | `AUDIT.md` fetched from the same ref |
| Commit audited | `314c95ecfe8f3b10c8158bdc8fc37357d5559b05` (`314c95e`, "Merge branch 'suite/2026-09-22-standards-sweep'"), branch `feat/2026-09-23-review-audit-remediation` |
| Working tree | clean for tracked files. One untracked path, `docs/reviews/2026-09-23/`, was written by a concurrent review run and is not part of what this audit measured |
| Addon version | `## Version: 1.0.1` (`PartyFrameEnhanced.toc:5`), `NS.version = "1.0.1"` (`core/Namespace.lua:5`) |
| Prior audit | `docs/audits/2026-09-15/` (v2.44.0, prefix **`PFE`**). This run keeps the prefix and every recurring ID |
| Bounded runner | `ka0s-bounded` is not on `PATH` in this shell. The plugin's own copy at `~/.claude/wow-addon/bin/ka0s-bounded` exists and was called by its full path for `luacheck`, `lua tests/run.lua` and `lizard`. Nothing ran unbounded, and no run exited 124 or 137 |

## Layout (`layout`)

- Folder load order `libs → locales → core → defaults → modules → settings` (`PartyFrameEnhanced.toc:15-108`).
- 38 addon files in the TOC plus 15 library lines. Authored, tracked Lua (default census scope,
  `libs/` and `tests/_kit/` excluded) is 71 files and 11,230 lines. The largest is `settings/Slash.lua`
  at 437 lines. Nothing sits in the 1000–1500 band or over the cap.
- The over-cap census heading `### Files over the 1500-line cap` is present, nested under
  `## Documented deviations`, reading "Nothing is over the cap today" (`docs/ARCHITECTURE.md:354-359`).
  The kit's `tests/_kit/test_layout_cap.lua` is wired by path (`tests/run.lua:87`).
- `media/` holds only `logos/` and `screenshots/`. `media/logos/partyframeenhanced.logo.128.tga` is
  TGA type 2, 128×128, 32 bpp. The landing-page `partyframeenhanced.logo.tga` is 512×512.
- No authored generator (`git ls-files '*.py' '*.sh'` returns only the vendored
  `tests/_kit/run-automated-tests.sh`) and no `tools/` folder.
- 10 of the 38 source files do not open on the namespace bootstrap line (see PFE-20).

## TOC (`toc-file`)

- Field order matches `toc-file-§1`. `## IconTexture` names the addon's own 128 logo (`:6`).
  `## SavedVariables: PartyFrameEnhancedDB, PartyFrameEnhancedPerfDB` (`:7`).
  `## X-Curse-Project-ID: 1698335` (`:13`). The addon is published, and the README's CurseForge badge
  uses the same id.
- Single `## Interface: 120100`. The README badge `Midnight_12.1.0` agrees.
- `libs\LibKa0s\LibKa0s.xml` is listed once, after Ace3 and the broker libraries (`:31`).
- Core annotations: a group statement says unannotated lines are conventional (`:39-40`).
  MediaSetup, CoreSetup, DebugLogSetup, Providers, RangeFade, UnitButtons, Preview, Schema, OptionsSetup
  and ElementRows are annotated. The comment at `:57` belongs to PerfSetup's constraint but sits
  directly above `core\LifecycleSetup.lua` (`:58`), and LifecycleSetup's own load-bearing reason is not
  named anywhere in the TOC (PFE-16).

## Libraries (`library-stack`)

- Ace3 subset: AceAddon, AceEvent, AceTimer, AceConsole, AceDB, AceGUI, AceConfig, AceDBOptions.
  Also LibSharedMedia-3.0, AceGUI-3.0-SharedMediaWidgets, LibDataBroker-1.1, LibDBIcon-1.0 and
  **LibKa0s v1.55.0**, vendored whole.
- Provenance line: `CLAUDE.md:38` — `Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.55.0 (MIT).`
  No copy in `README.md`.
- `diff -r` against the LibKa0s `v1.55.0` tag: `libs/LibKa0s` and `tests/_kit` are both **empty**.
  146 files match 146. The kit is revision 25 (`tests/_kit/framework.lua:20`).
- Eleven LibKa0s majors are wired through one seam each: Media (`core/MediaSetup.lua`), Env
  (`core/EnvSetup.lua`), Core (`core/CoreSetup.lua`), Compat (`core/Compat.lua:13,20`, `IsSecret`
  only), Bus (`core/Bus.lua:40-75`), Lifecycle (`core/LifecycleSetup.lua:17-76`), Perf
  (`core/PerfSetup.lua:10-75`), DebugLog (`core/DebugLogSetup.lua:11-100`), Launcher
  (`core/LauncherSetup.lua:36-76`), Slash (`settings/Slash.lua:16,325-424`) and Options
  (`settings/OptionsSetup.lua:267-406`). Pool, Item, Widgets and Schema are vendored and not wired.
  Schema adoption is deferred under issue #14, and v2.64.0 makes adopting it optional.
- Each seam has a library-absent arm. Core, DebugLog, Perf, Lifecycle, Env and Media answer members;
  Options is load-completing (`settings/OptionsSetup.lua:342-391`); Slash has a stub dispatcher
  (`settings/Slash.lua:325-391`); Bus uses the untracked-target stub the Bus API document prescribes
  (`core/Bus.lua:42-65`); Compat uses the guard arm (`core/Compat.lua:20-23`). The Launcher has no stub,
  and the decision is written down (`core/LauncherSetup.lua:27-34`). `tests/test_surface_parity.lua`
  holds every stub to its live major.
- **Suite integration:** EllesmereUI is optional and presence-guarded (`## OptionalDeps`, `:8`;
  `Compat.IsAddOnLoaded`). `modules/Providers.lua:292-302` reads EllesmereUI's SavedVariables
  (`EllesmereUIDB`) to size the preview stand-in (PFE-15).

## Architecture patterns (`architecture`)

- `NS` is promoted with `AceAddon:NewAddon(NS, …)`, and `NS.Print` is reclaimed from `NS.Util.print`
  (`core/PartyFrameEnhanced.lua:7-14`).
- The closed bus has four messages, declared once through `Bus.Catalog` (`core/Bus.lua:92-97`) with
  PascalCase tails. No call site types a `Ka0s_` literal. Each receiver gets its own
  `NS.NewBusTarget()`. The Message Bus table leaves Preview off the CONFIG and PROFILE consumer lists
  (PFE-19).
- Schema: one registry, and one write seam `NS.SetByPath` with a pre-store `validate`
  (`settings/Schema.lua:198-220`). There are no structural registries. Named non-setting state
  (`<feature>.position`) has one owner, `modules/Anchor.lua`, and every writer is named
  (`docs/ARCHITECTURE.md:67-69`). The global row `global.minimap.hide` is handled through a registered
  get/set.

## Settings (`options-ui`, `savedvariables`)

- AceDB `PartyFrameEnhancedDB`. `schemaVersion = 1` sits in the global store, and the migration ladder
  is empty (`core/Database.lua:34-48`).
- Pages: General (Master controls · Party frames · Health updates), Cast Bars (General · Size &
  Position · Bar · Border · Text · Icon), Target Frames (General · Size & Position · Bar · Border ·
  Text · Marker), Pet Frames (the same six), and Profiles through AceDBOptions. The landing page is
  `settings/About.lua`. Every schema page draws a strip, and the General page's first tab is
  `Master controls`, composed by `H.MasterControls` (`settings/General.lua:65-84`).
- Test mode is exempt, because unlocking shows the placeholders (`core/State.lua:7-10`,
  `modules/Preview.lua:7-15`). The whole-repo `SetMovable` sweep finds `modules/Anchor.lua:257` and
  `modules/StandIn.lua:153`, so the display is positionable and the exemption is the governing clause.
- Font, border and bar groups are composed. Cast-state and reaction palettes are the exempt color
  shape. No `disabledIf` sits on a color row. No reorder arrows.
- No settings page closes Blizzard's settings window, and the addon has no combat lock of its own
  (the grep finds nothing outside `libs/`).

## Slash (`slash-commands`)

- `/pfe` and `/partyframeenhanced` are registered through AceConsole in `OnInitialize`
  (`settings/Slash.lua:434-437`). `NS.COMMANDS` holds 17 positional triples (`:21-59`), including the
  reserved `enable`/`disable` (writing `enabled` through the seam, `:151-155`) and `lock`/`unlock`.
- Disabled surface: the library gate with `LIVE_WHILE_DISABLED` = the 12 reserved verbs plus `status`
  and `profile` (`:89-93`). `resetposition`, `lock` and `unlock` get the collection's one refusal line.
  The Lock-frame row also has a refusal of its own, reached through the checkbox or
  `/pfe set locked false`, and it is worded differently (PFE-17).

## Launcher (`launcher`)

- One LDB object through `LibKa0s-Launcher-1.0`. `name = addonName`, the icon is the 128 logo, and the
  label is `Ka0s Party Frame Enhanced` (`core/LauncherSetup.lua:40-76`). It registers in `OnEnable`
  (`core/PartyFrameEnhanced.lua:197`).
- Left click is rung (b): `NS.ToggleLock`, which prints `cli:DisabledLine()` while the addon is
  disabled (`settings/Slash.lua:135-138`). Right click opens the panel in either state.
- `global.minimap.hide` is exempt from both resets (`settings/OptionsSetup.lua:254-292`).

## Disabled state (`slash-commands-§7`)

- One latch with two holds, through `LibKa0s-Lifecycle-1.0` (`core/LifecycleSetup.lua`). The perf
  harness takes the same latch (`core/PerfSetup.lua:56`). The stand-down is `NS.StandDown`
  (`core/PartyFrameEnhanced.lua:151-160`): lifecycle events come off, each module runs `Suspend`,
  `VISIBILITY` is published, the bus record is stood down, and the regen listener is armed only while a
  secure write is pending.
- `tests/test_disabled.lua` is present, listed (`tests/run.lua:81`), asserts on the mock's
  **registration set**, and carries the falsification comments. It is green.
- What still survives the stand-down: the `EditMode.Exit` EventRegistry callback, which also arms two
  `C_Timer.After` timers each time it fires (PFE-12); and eight owned container frames (five fade
  frames and three holders), which are empty but stay shown (PFE-13). The suite sees neither.

## Debug (`debug-logging`)

- `LibKa0s-DebugLog-1.0` descriptor with `name`/`addonName` = the folder, the monospace font from
  Media, and the session-only flag (`core/DebugLogSetup.lua:65-97`). Core flows are traced: Cast,
  Target, Pet, Provider, Anchor, Secure, Set, Profile, Preview, Party.

## Tests and lint (`testing`, `lint`)

- `luacheck .`: **0 warnings / 0 errors in 71 files**. `.luacheckrc` excludes `libs/`, `docs/audits/`,
  `docs/reviews/`, `_dev/` and `tests/_kit/`, which is the `lint` template's list. The harness global
  is declared in `files["tests/"]` only. There is no top-level `ignore`.
- `lua tests/run.lua`: **289 passed, 0 failed, 0 skipped**. The load lists come from the TOC and the
  XML (`tests/run.lua:24-25`). The kit's `test_prose`, `test_eol` and `test_layout_cap` are wired by
  path. The README badge says `289/289`.

## Performance (`performance`, `automated-tests`)

- Ten declared buckets with nesting (`core/PerfSetup.lua:37-48`). `/pfe perf` is registered by the
  addon. The ring is `PartyFrameEnhancedPerfDB`.
- `docs/perf-analysis/` has three bundles, each carrying `report.md`, `dump.json` and `ANALYSIS.md`,
  with an index in the README.
- `lizard` now: 1047 functions, max CCN 14, 0 warnings. The latest record,
  `docs/automated-tests/20260918-121606/`, measured `e4d7f41` (clean), which is 32 commits behind HEAD:
  942 functions, max CCN 14, 0 warnings. No function crossed a threshold and no file entered the
  1000–1500 band. The watch list is empty.

## Packaging and line endings (`packaging`, `line-endings`)

- `.pkgmeta` has no externals and ignores every dev-only entry the repo has. It also ignores `.claude`
  and `.superpowers`, and neither directory exists (PFE-21).
- `.gitattributes`: `* text=auto eol=crlf` (`:26`), `*.sh`/`*.py text eol=lf` (`:36-37`), 20 `binary`
  marks. The first 84 lines are byte-identical to the canonical client-bound body, with no appendix.
  Working-tree disagreement count: **0**. The owning gate, `tests/_kit/test_eol.lua`, is wired.

## Root docs (`documentation-§1/§2/§7`)

- README: H1, five badges in canonical form (the standard badge is bare, `:6`), description,
  Screenshots, Usage (prose, no tables), `## How it works`, FAQ, Troubleshooting, Issues, Version
  History (`- `-prefixed highlights). No logo image, no library inventory, no `## Credits`, no angle
  placeholders.
- `CLAUDE.md` is a stub with the Standards compliance section verbatim in substance, the green gate and
  the provenance line. Its pointer list still sends readers to the v0.1.0 build plan's status ledger as
  the resume point (`CLAUDE.md:33`, PFE-01).
- `DEPENDENCIES.md` covers runtime, development and release, with pipx for lizard and verification
  commands.

## `docs/` (`documentation-§3`)

- Tier 1: all six are present under their canonical names. Tier 2: `slash-dispatch.md` (17 commands),
  `midnight-quirks.md`, `compat-layer.md` (14 shims by the standard's grep), `profiles.md` and
  `perf-analysis/README.md` are present. `message-bus.md` (4 messages) and `debug.md` have *Not
  applicable* rows that state their triggers.
- `## Documentation map`: four tables in order, with the six verification-and-record rows. The map and
  the tree agree in both directions. The only map entries without a file are the two *Not applicable*
  rows and the `superpowers/` store row. No orphans, no non-canonical or retired names, no `TODO.md`,
  no `docs/pending/`.
- The hub is 359 lines, and no mandated section is over about 60 lines.
- `## Documented deviations` has one row (`events-frames-taint-§1`, Decided 2026-09-15). The v2.63.0
  changelog says that row "turned out not to be a violation at all" (PFE-10).

## Register and issue store (`audit-review-history`)

- `gh issue list --state all` returned 14 issues (#1–#14). Every one carries a `state:` label and a
  `severity:` label, and none has a `[status]` title prefix. #1 (`state:will-not-do`, raid frames) is a
  feature scope decision recorded in `docs/scope.md:20-21`, not a departure from a rule. No
  `LEDGER.md` exists.
- `docs/revendor/` holds one bundle, `2026-09-23-v1.55.0/`. The re-vendor commit in scope (`e331135`)
  vendored `v1.55.0`, and that tag is recorded.

## Status of the 2026-09-15 findings

| ID | Then | Now |
|---|---|---|
| PFE-01 | doc set lags code | **Recurs** with different content (see 02) |
| PFE-02 | Schema TOC position unannotated | **Closed** — `PartyFrameEnhanced.toc:95-96`, pinned by `tests/test_loadorder.lua:65` |
| PFE-03 | raw `SetSetting` revert in Preview | **Closed** — pre-store `validate` (`settings/Schema.lua:203`, `settings/General.lua:115-117`) |
| PFE-04 | core flows untraced | **Closed** — Cast/Target/Pet/Secure lines present |
| PFE-05 | strings partly routed | **Recurs, narrowed** to the provider labels and degraded-stub lines |
| PFE-06 | Env/Perf stub cases | **Closed** — `tests/test_envsetup.lua` degraded case; `tests/test_perfsetup.lua:44,66` |
| PFE-07 | no end-to-end reset-all case | **Closed** — `tests/test_optionssetup.lua:215-240` |
| PFE-08 | dotted notation (design spec) | **Recurs** (Info), 18 hits, all the addon's own spec |
| PFE-09 | release record predates HEAD | **Recurs** (Info) |
| PFE-10 | recorded deviation, `events-frames-taint-§1` | **Reclassified**: the register row is now stale (rule changed at v2.63.0) |
| PFE-11 | Blizzard shield texture | **Closed** — decision commented at `modules/Element.lua:16-17` |
