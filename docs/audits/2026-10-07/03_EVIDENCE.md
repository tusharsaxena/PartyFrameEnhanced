# 03 — Evidence: Ka0s Party Frame Enhanced

Every citation below was re-read at `fb5c0b9` before it was written, and each is quoted. Every count
comes from a recorded command, with its scope stated. Commands ran from the repo root.

## A. Findings

### PFE-25 — private boundary-watcher frame in an AceEvent addon

- `core/PartyFrameEnhanced.lua:8`: `local addon = AceAddon:NewAddon(NS, addonName, "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")`
- `core/PartyFrameEnhanced.lua:113-116`: `-- On its OWN frame rather than on the addon object, because the addon object's PLAYER_REGEN_ENABLED` / `-- is OnLeaveCombat and AceEvent keys a callback by (event, target): registering the same event on` …
- `core/PartyFrameEnhanced.lua:122`: `regenWatch = CreateFrame("Frame")`
- `core/PartyFrameEnhanced.lua:128`: `NS.SafeRegisterEvent(regenWatch, "PLAYER_REGEN_ENABLED", nil, NS.RejectedEvents)`
- `docs/ARCHITECTURE.md:199`: `| PLAYER_REGEN_ENABLED (armed only while a secure write is queued) | core/PartyFrameEnhanced.lua, its own frame | …`
- The rule, from the fetched `events-frames-taint.md:30`: an addon that embeds **no AceEvent-3.0 anywhere** "MAY carry one private `CreateFrame("Frame")` watcher for non-unit boundary events". And `:36`: "**An addon that embeds AceEvent-3.0 gets no such carve-out.** … a watcher frame beside it is the per-module event frame the first bullet forbids."
- Census of private frames in shipped code (scope: `git ls-files` for `core/ modules/ settings/`, which excludes `libs/` and `tests/`):
  `grep -n 'CreateFrame' $(git ls-files 'core/*.lua' 'modules/*.lua' 'settings/*.lua')`. The only
  bare `CreateFrame("Frame")` is `core/PartyFrameEnhanced.lua:122`. Every other hit is a drawn element,
  a holder, a fade frame, the stand-in or the secure header, and none of those carries non-unit event
  traffic.

### PFE-26 — two re-vendor tags unrecorded

Command (`AUDIT.md`'s check, run under `bash`, scope: commits touching `libs/LibKa0s` or `tests/_kit`
since the store's first bundle; tags read from `CLAUDE.md` at each commit and from the bundles):

```
horizon=2026-09-23
vendored: v1.55.0 v1.56.0 v1.57.0 v1.58.0 v1.60.0 v1.61.0 v1.62.0 v1.63.0 v1.64.0 v1.65.0 v1.66.0 v1.67.0 v1.68.0 v1.68.1 v1.69.0 v1.70.0
recorded: v1.37.0 … v1.54.2 v1.55.0 v1.56.0 v1.57.0 v1.58.0 v1.60.0 v1.61.0 v1.62.0 v1.63.0 v1.64.0 v1.65.0 v1.66.0 v1.67.0 v1.68.0 v1.68.1
UNRECORDED:
v1.69.0
v1.70.0
```

- `547ac68` 2026-10-06 `chore: re-vendor LibKa0s v1.69.0 (kit 37; adds the line chart widget)`. Its
  non-payload files are `CLAUDE.md` and `docs/testing.md`.
- `735a111` 2026-10-07 `chore: re-vendor LibKa0s v1.70.0`. Its only non-payload file is `CLAUDE.md`.
- `git diff 02b8254 HEAD --stat -- libs/LibKa0s`: `LibKa0s.xml | 2 +`, `WidgetsAutocomplete.lua | 375 +`,
  `WidgetsLineChart.lua | 465 +`. The new minors are `AUTOCOMPLETE_MINOR = 1` and `CHART_MINOR = 2`.
- `ls docs/revendor`: 14 folders, the newest `2026-10-04-v1.68.1`. There is no register row about
  re-vendor bundles in `docs/ARCHITECTURE.md:423-428`.

### PFE-26a — docs still at v1.68.1 / kit 36

- `docs/ARCHITECTURE.md:23`: `and **LibKa0s v1.68.1** vendored whole, plus **LibDataBroker-1.1** and **LibDBIcon-1.0** for the`
- `docs/ARCHITECTURE.md:43`: `diagnostics report for bug reports; and LibKa0s is re-vendored, v1.62.0 in the release and now at v1.68.1.`
- `docs/smoke-tests.md:55`: `- **INSTALL-4. A clean load on the vendored LibKa0s.** With \`libs/LibKa0s\` at v1.68.1 (Core 10, Options`
- `DEPENDENCIES.md:32`: `… the runner measures a sanitized shadow (\`tests/_kit/lizard_sighted.lua\`, kit 36) …`
- Against `CLAUDE.md:39`, `Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.70.0 (MIT).`,
  and `tests/_kit/framework.lua:20`, `Kit.VERSION = 37`.
- Sweep (scope: tracked `.md` files outside `docs/{audits,reviews,revendor,superpowers}/` and the dated
  bundle folders): `git ls-files 'docs/*.md' '*.md' | grep -vE … | xargs grep -nE 'v1\.6[0-9]\.[0-9]|v1\.70|kit (revision )?3[0-9]|revision 3[0-9]'`.
  The stale hits are the four above. The other v1.6x hits are historical records of what arrived in
  which tag (`docs/smoke-tests.md:636-646`, `docs/debug.md:16`, where DebugLog 19 is still the vendored
  minor), and they are correct.

### PFE-01 — other doc drift

- `docs/automated-tests/README.md:29`: `… (sighted: kit 35 measures a sanitized shadow, with parity) …`, against `docs/testing.md:93`: `… (sighted: kit 37 measures …`.
- `docs/perf-analysis/README.md:70`: `lifecycle lines — the three inputs \`/wow-addon:perf-analysis\` needs.` The fetched `STANDARDS.md` (v2.76.0 entry) renames the plugin to `dev-copilot` and its WoW-only commands to `/dev-copilot:wow-*`, including `/dev-copilot:wow-perf-analysis`.
- `docs/automated-tests/RESULTS.md:15`: `… evaluated by \`/wow-addon:bump-version\` from the`. This line is generated, so it is not hand-fixed.
- `docs/ARCHITECTURE.md:404`: `| compat-layer.md | Present | core/Compat.lua publishes 15 shims — 14 function Compat.X statements plus the Compat.IsSecret assignment; count both forms with grep -cE '^function Compat\.\|^Compat\.[A-Za-z]+ *=' core/Compat.lua (trigger: three or more) |`
- The standard's count: `grep -cE '^\s*function\s+[A-Za-z_][A-Za-z0-9_]*\.' core/Compat.lua` → **14**. The row's own grep `grep -cE '^function Compat\.|^Compat\.[A-Za-z]+ *=' core/Compat.lua` → **15**. The difference is `core/Compat.lua:20`, `Compat.IsSecret = CompatLib and CompatLib.IsSecret or function(v)`.
- `docs/compat-layer.md:17`: `| IsSecret(v) | LibKa0s-Compat-1.0's IsSecret (issecretvalue) | true only for a value the client marks secret | …`

### PFE-29 — three-table map

- `grep -n '^###' docs/ARCHITECTURE.md` within the map: `:384 ### Required (documentation-§3, Tier 1)`, `:396 ### Conditional (documentation-§3, Tier 2)`, `:408 ### Verification and record (documentation-§3)`, then `:423 ## Documented deviations`. There is no `### Addon-specific`.
- `git show bc3c941 -- docs/ARCHITECTURE.md` removes `-### Addon-specific (documentation-§3, Tier 3)` and its one row `| superpowers/ | The v0.1.0 design spec and the checkpointed build plan (directory) |`, and adds `superpowers/` to the frozen sentence (`:419-421`).
- Map coverage (scope: `git ls-files 'docs/*.md'` minus the frozen stores): 19 files, each in exactly one table, with no dangling rows. `message-bus.md` is the one *Not applicable* row.

### PFE-27 — hub length

- `wc -l < docs/ARCHITECTURE.md` → `435`.
- Per-section line counts (awk over `^## `): Overview 51, Module Map 12, Settings Schema 46, Message Bus 24, Slash Commands 18, Launcher 25, Event Subscriptions 34, The disabled state is total 79, Taint Notes 50, Known Limitations 35, Documentation map 41, Documented deviations 13.
- `awk 'length($0)>400' docs/ARCHITECTURE.md` → `55: 1609` (the re-vendor narrative ending "… v1.68.1 is rename-only … nothing is adopted").
- The 2026-09-23 bundle recorded 359 lines (`docs/audits/2026-09-23/01_CURRENT_STATE.md`, docs section).

### PFE-28 — register-row text

- `docs/ARCHITECTURE.md:427` (Decided cell): `2026-10-01 (GI-PF-02, #3; owner default D9 in the 2026-10-01 GitHub issue pass, pending the owner's ratification)`.
- `gh issue list --state all …`: `3 CLOSED enhancement,state:done,severity:medium Re-anchor the clickable target and pet frames during combat through a secure handler`.
- `Ka0sAddonsCommonTasks/docs/2026-10-01-GITHUB_ISSUE_PASS/00_OVERVIEW.md:56`: `| D9 | PartyFrameEnhanced#3 wraps lazily … becomes a Documented-deviations row under slash-commands-§7. **#3 stays open until the owner's in-client combat checks pass** |`
- `docs/ARCHITECTURE.md:319`: `the owner's smoke checks COMBAT-6, COMBAT-9 and COMBAT-10 passed in the client on 2026-10-02.`
- `docs/ARCHITECTURE.md:428` **Why**: `EllesmereUI's hidden party buttons carry its raid size until it lays out a party, so measuring one copies the wrong frame; the fallback is EllesmereUI's own 125 × 60`. It cites no issue or bundle id.

### PFE-30 — settings-panel shape

- `docs/settings-panel.md:12`: `| Page | Tab | Covers |`, followed by 23 rows (`:14-36`), one per tab.
- `docs/settings-panel.md:38`: `## General → Master controls`.

### PFE-31 — runDebug duplicates DebugVerb

- `settings/Slash.lua:243-254`: `function runDebug(rest)` … `if sub == "diagnostics" then NS.DebugLog:RunDiagnostics() return end` … `if sub == "on" or sub == "off" then NS.DebugLog:SetEnabled(sub == "on") return end` … `NS.DebugLog:Toggle()`.
- `libs/LibKa0s/DebugLogDiagnostics.lua:413`: `function D:DebugVerb(rest)`.
- `core/DebugLogSetup.lua:71-75` (stub): `DebugVerb = function(self, rest)` … `if word == "diagnostics" then self:RunDiagnostics() return true end` …

### PFE-08 — retired notation

`grep -rEn '§[0-9]+\.[0-9]' . --exclude-dir=libs --exclude-dir=_kit --exclude-dir=audits --exclude-dir=reviews --exclude-dir=automated-tests --exclude-dir=revendor --exclude-dir=.git | wc -l` → **18**.
The scope is the working tree minus the vendored and frozen stores, with `docs/superpowers/` **included**.
Every hit reads `design spec §6.x` or `§3.2` and cites the addon's own spec, for example
`modules/CastBars.lua:3`, `-- modules/CastBars.lua — one cast bar per tracked unit (design spec §6.2).`

Range check (scope: `git ls-files` minus `libs/`, `tests/_kit/`, the frozen stores and the dated
bundles), using `grep -ohE '\b[a-z][a-z-]+-§[0-9]+'` and comparing each against
`grep -c '^### [0-9]' <section>.md`: **362 citations, 70 distinct, 0 out of range, 0 unknown files.**

### PFE-09 — complexity record

```
$ ~/.claude/dev-copilot/bin/ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle
PartyFrameEnhanced 1.1.0 — automated tests — 20261007-160834
  complexity  pass  — 0 warnings (fun rate 0.00), 11361 NLOC / 1602 funcs, avg NLOC 6.4, avg CCN 2.1 (max 14), avg tokens 50.1 (recorded, non-gating)
  verdict: green
  record:  newest bundle 20260927-030324 measured 692cec2, 47 commit(s) behind HEAD — its figures describe a tree this one is no longer
```

- `docs/automated-tests/20260927-030324/manifest.json` `suites.complexity`: `maxCcn 14, nloc 9976, functions 1318, bandFiles 0, overCapFiles 0`. There is no `blindFiles` key, because the bundle predates kit 35.
- `docs/automated-tests/RESULTS.md:106` and `:113`: the warned-functions table and the band table each read `None.` The watch list has 0 Accepted entries.
- `{ name = "test_lizard_sighted", dir = "tests/_kit/" }` at `tests/run.lua:111`.

## B. Mechanical checks (compliance evidence)

### Lint and suite (bounded)

- `ka0s-bounded luacheck .` → `Total: 0 warnings / 0 errors in 79 files`. `.luacheckrc:8`:
  `exclude_files = { "libs/", "docs/audits/", "docs/reviews/", "_dev/", "tests/_kit/" }`. There is no
  top-level `ignore`, and the per-file `212/self` stanzas start at `:63`.
- `ka0s-bounded lua tests/run.lua` → exit 0, `454 passed, 0 failed, 1 skipped, 455 total`. The skip is
  `diagnostics contract: an addon that opts out lands the report and leaves logging off — this addon keeps the default …`.
- `ka0s-bounded lua tests/run.lua --list` compared with `docs/test-cases.md` (CR stripped): **IDENTICAL**.
- `grep -nE 'heapBudgetMB|leakBudgetMB|caseSeconds|KA0S_KIT' tests/*.lua` returns nothing.

### Vendoring (`library-stack-§7`, #45/#48)

```
git -C ../LibKa0s archive v1.70.0 LibKa0s testkit | tar -x -C $SCRATCH/lk
diff -r $SCRATCH/lk/LibKa0s libs/LibKa0s   → (empty), exit 0; 159 files each side
diff -r $SCRATCH/lk/testkit tests/_kit     → (empty), exit 0; 22 files each side
```

The tag is `CLAUDE.md:39`'s. `git -C ../LibKa0s rev-parse v1.70.0` → `26f441a2…`.

- `grep -n 'Bundles \[LibKa0s\]' CLAUDE.md` → `39:` (one hit); in `README.md` → none.
- `grep -nE '^## (Libraries|Bundled libraries|…)' README.md` → none. `grep -n 'WoW_Addon_Standard' README.md` → `6:![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)`, the bare form.
- `grep -nE '^[[:space:]]*[0-9]+[.)][[:space:]]' README.md` → none. `grep -nE 'media/logos|<img' README.md` → none.

### Line endings (`line-endings`)

- `.gitattributes` exists. `:26 * text=auto eol=crlf`, `:36 *.sh text eol=lf`, `:37 *.py text eol=lf`, and `grep -c ' binary$'` → 20.
- `diff <(head -84 .gitattributes | tr -d '\r') <canonical client-bound body from line-endings.md:166-249>` → identical. `tail -n +85` is empty.
- The (e) one-liner from the playbook, run over the whole tracked set → **0**.

### Packaging (`packaging`)

Checks (a), (b) and (c), run under `bash`, print only `UNACCOUNTED — .git`, which is exempt. `.pkgmeta`
ignores `.luacheckrc .pkgmeta .gitignore .gitattributes docs tests _dev` and carries no `.claude` or
`.superpowers` line.

### Disabled state (`slash-commands-§7`)

Registration census (scope: `git ls-files '*.lua' ':!libs' ':!tests'`):
`grep -nE 'Register(Unit)?Event|RegisterMessage|RegisterBucketEvent|RegisterCallback|SafeRegister|hooksecurefunc|HookScript|SecureHandlerWrapScript|C_Timer|ScheduleTimer|ScheduleRepeatingTimer|NewTicker|SetScript\("OnUpdate"|RegisterStateDriver'`.
Each hit pairs with its stand-down:

| Registration | Undone at |
|---|---|
| Lifecycle events (`core/PartyFrameEnhanced.lua:158`) | `:181` `addon:UnregisterEvent(event)` |
| Bus messages (every module's `ev:RegisterMessage`) | `NS.BusStandDown` (`core/PartyFrameEnhanced.lua:184`) |
| Providers events (`modules/Providers.lua:365-367`) and `EditMode.Exit` (`:381`) | `Providers:Suspend` `:397-403` (`ev:UnregisterAllEvents()`, `editModeCallback(false)`) |
| `C_Timer.After` (`modules/Providers.lua:60,71-72`) | gated by `burstGen` and `suspended`; `burst()` arms nothing while suspended (`:67`) |
| CastBars unit events and `OnUpdate` (`modules/CastBars.lua:338`, `:135`) | `syncEvents` → `el:UnregisterAllEvents()` + `idle(el)` → `SetScript("OnUpdate", nil)` (`:346-349`, `:138`) |
| TargetFrames ticker and events (`modules/TargetFrames.lua:166`, `:245`, `:260`) | `CancelTimer` (`:161`); `syncModuleEvents(false)` / `btn:UnregisterAllEvents()` (`:247`, `:264`) |
| PetFrames, RangeFade, Preview events | their `Suspend` / `listen(false)` |
| State drivers (`modules/UnitButtons.lua:63`) | `UnitButtons.Release` through `NS.RunSecure` |
| `hooksecurefunc` / `HookScript` (Providers, RangeFade, TargetFrames) | not undoable, so each body gates itself (sanctioned) |
| SecureFollow wraps (`modules/SecureFollow.lua:173`) | `unwrapAll` on Suspend; the residue is the ratified register row |
| `regenWatch` (`core/PartyFrameEnhanced.lua:128`) | released on fire (`:124`); this is the one registration §7 permits (see PFE-25 for its frame type) |

- `tests/test_disabled.lua:31`: `-- 26 also records every live EventRegistry callback …`. `:121`: `mocks.EventRegistry:TriggerEvent("EditMode.Exit")`. `:265`: `for _, form in ipairs({ "diagnostics", "debug diagnostics" }) do`. It is listed at `tests/run.lua:102`.
- Game-event SV writes: `Preview:Suspend` → `forceLock` (`modules/Preview.lua:159-178`) runs on the player's own stand-down write. The combat re-lock listener is registered only while preview is on (`:92-100`), and preview ends at stand-down.

### Slash, diagnostics, launcher

- `grep -n '"diagnostics"' settings/*.lua core/*.lua` → `settings/Slash.lua:56` (the row), `:97` (live list), `:245` (the `runDebug` first test), and `core/DebugLogSetup.lua:73` (stub). `grep -rniE '"(diag|dump|dx)"' settings core modules` → none.
- `grep -n 'diagnosticsEnablesLogging' core/*.lua` → none, which is the default. No host `SetEnabled` wraps `RunDiagnostics`.
- `settings/Slash.lua:95-99`: the live set holds the 13 reserved verbs plus `status` and `profile`.
- `core/LauncherSetup.lua:81-84`: `isEnabled`, `setEnabled`, `isLocked`, `toggleLock`. This matches `ADDONS.md`: `| Ka0s Party Frame Enhanced | … | Enabled · Locked |`. `:66` `label = "Ka0s Party Frame Enhanced"`.
- `debug =` forwarders: `core/LauncherSetup.lua:96`, `core/LifecycleSetup.lua:29`, `settings/OptionsSetup.lua:48`, `settings/Schema.lua:289`, `settings/Slash.lua:490`. `debugAtEnable` is at `core/LauncherSetup.lua:101`.
- `grep -rn 'MakeCloseButton(' … | grep -v libs | grep -v tests` → only the wrapper and its degraded twin (`core/CoreSetup.lua:54`, `:117-118`). There is no `decorate` hook (`core/PerfSetup.lua:73`).
- `grep -rnE 'SettingsPanel|HideUIPanel|ToggleGameMenu|OpenToCategory' core settings modules` → no code hits.
- Bus: `(Send|Register)Message\("Ka0s_` → none. Literals appear only at `core/Bus.lua:104-107`, all PascalCase.

### Writes (`architecture-§5`)

`git ls-files '*.lua' ':!libs' ':!tests' | xargs grep -nE '(db\.(profile|global|char)…\s*=[^=])|table\.(insert|remove)\(…db|wipe\(…db|\.position\s*=[^=]|\.hide\s*=[^=]'`
→ `modules/Anchor.lua:393` (`cfg.position = {…}`, drag-stop), `:404` (`spec.config().position = nil`,
reset), and `settings/General.lua:64` (`m.hide = not shown`, the row's own `set`). The first two are
named non-setting state with owner and writers named at `docs/ARCHITECTURE.md:94-96`. The third is the
schema row's stamped storage.

### Localization

Script (scope: keys in `locales/enUS.lua`, references in `core/ modules/ settings/ defaults/`): 210
keys, **0** without a quoted reference in shipped source.

### Issue store

`gh issue list --state all --limit 200 --json number,title,state,labels,url` returned 15 issues. Each
has exactly one `state:` label and one `severity:` label, and no title carries a `[` prefix. Open:
#2, #4–#9, #11, #15 (`state:triaged`) and #13 (`state:untriaged`). Closed: #1 (`will-not-do`), #3,
#10, #12 and #14 (`done`).
