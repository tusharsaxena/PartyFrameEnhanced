Delta: LibKa0s v1.65.0 -> v1.66.0

# LibKa0s v1.65.0 -> v1.66.0: the delta (PartyFrameEnhanced)

Copied from the local tag `v1.66.0` (tag object `178ee0b`, commit `e4c5ef7`,
`git archive v1.66.0 LibKa0s testkit`), never from a working tree. Item `GI-PF-RV` of the 2026-10-01
GitHub issue pass (`Ka0sAddonsCommonTasks/docs/2026-10-01-GITHUB_ISSUE_PASS/`, spec S4).

## 3a. Base

```sh
grep -n '[Bb]undles' CLAUDE.md
# 39:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.65.0 (MIT).
git log -1 --format=%h -- libs/LibKa0s tests/_kit     # 485b786 DG-PF-01: re-vendor LibKa0s v1.65.0 (kit 34)
git -C ../LibKa0s archive v1.65.0 LibKa0s testkit | tar -x -C <scratch>/claimed
diff -rq <scratch>/claimed/LibKa0s libs/LibKa0s && diff -rq <scratch>/claimed/testkit tests/_kit && echo payload-matches
# payload-matches
```

The provenance line, the last payload commit and the bytes agree: the base is **v1.65.0**. Step 0's
pre-flight for this addon: the newest single-tag bundle, `2026-09-29-v1.63.0`, states base v1.62.0,
which is what the history shows. No base correction. Two tags this addon vendored since then have no
bundle; 3h records them in the span bundle `2026-10-01-v1.64.0-v1.65.0/`.

## 3b. Actual version (before the copy)

`grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR *= *("[^"]+", *)?[0-9]+' libs/LibKa0s/*.lua` gave 28 constants,
each equal to v1.65.0's. The line and the bytes agree.

## 3c. Per-file minors (the tag's `LibKa0s.xml`)

| File | v1.65.0 | v1.66.0 |
|---|---|---|
| `Widgets.lua` | 11 | 12 |
| `WidgetsReorder.lua` | — | `REORDER_MINOR` 1 (new) |
| `DebugLog.lua` | 18 | 19 |
| `Slash.lua` | 18 | 19 |
| `SlashParse.lua` | — | `PARSE_MINOR` 1 (new) |
| `OptionsWidgets.lua` | 33 | 34 |
| `OptionsTabs.lua` | 7 | 8 |
| `Perf.lua` | 13 | 14 |
| `PerfSampler.lua` | — | `SAMPLER_MINOR` 1 (new) |
| `PerfCommands.lua` | — | `COMMANDS_MINOR` 1 (new) |

Every other file is unchanged: Core 9, Env 1, Compat 1, Lifecycle 3, Bus 2, Schema 2, Pool 3, Item 2,
Media 4, WidgetsDragHandle 3, DebugLogDiagnostics 2, DebugLogGates 1, Launcher 5, Options 27,
OptionsRegistry 2, OptionsIds 2, OptionsIdList 2, OptionsCombat 1, OptionsCompose 7, OptionsScroll 4,
OptionsNav 2, PerfPanel 6. No consumer file is behind: no cross-major skew. The payload goes from 28 to
32 Lua files. The TOC loads the library through `libs\LibKa0s\LibKa0s.xml` and `tests/run.lua` derives
its library list from the same XML (`Loader.xmlFiles`), so neither needs a new row.

## 3d. Both diffs (before the copy, tag vs this repo)

```text
diff -rq --strip-trailing-cr <tag>/LibKa0s libs/LibKa0s
Files differ: DebugLog.lua, LibKa0s.xml, OptionsTabs.lua, OptionsWidgets.lua, Perf.lua, Slash.lua, Widgets.lua
Only in <tag>/LibKa0s: PerfCommands.lua, PerfSampler.lua, SlashParse.lua, WidgetsReorder.lua

diff -rq --strip-trailing-cr <tag>/testkit tests/_kit
Files differ: README.md, asserts.lua, framework.lua, inventory.lua, mock_base.lua, run-automated-tests.sh, test_eol.lua
Only in <tag>/testkit: lizard_sighted.lua, test_lizard_sighted.lua
```

No `Only in libs/LibKa0s` or `Only in tests/_kit` line: nothing was removed upstream, so nothing is
deleted here. After the copy both `diff -r` runs (bytes, not just content) are empty.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
```

Twelve majors, one setup file each: Media, Compat, Env, Lifecycle, Bus (`core/Bus.lua`, plus
`modules/Diagnostics.lua:215`), Core, Launcher, DebugLog, Perf, Schema (`settings/Schema.lua:262`), Slash
(`settings/Schema.lua:360`, `settings/Slash.lua:17`), Options. Pool, Item and Widgets are reached only
through those. Of the majors whose minor moved, this addon consumes DebugLog, Slash, Options and Perf.

## 3f. Kit revision

`Kit.VERSION` 34 -> **35**. Both payloads move together, copied whole; the runner stays recorded
100755 in the index. Kit 35 adds `test_lizard_sighted`, which `Kit.assertSuiteInventory` requires wired
in `tests/run.lua`.

## 3g. Contract delta

Read for DebugLog (18.2.1 -> 19.2.1), Slash (18 -> 19.1), Options (27.2.33.2.2.7.1.7.4.2 -> 27.2.34.2.2.8.1.7.4.2)
and Perf (13.6 -> 14.1.1.6), from the v1.66.0 CHANGELOG block and the `Superseded by` rows.

- **DebugLog 19**: `lib:New`'s descriptor reads moved into helpers; "the same surface and behavior"
  (version-19.2.1 header). Nothing this addon hands over changes meaning.
- **Slash 19**: `ParseValue(row, text, textOf)` / `FormatValue(row, v, textOf)` take an optional third
  argument; a host `d.parse` is handed the resolver as a third argument. This addon declares no `parse`
  (`grep -rn 'parse *=' --include='*.lua' . --exclude-dir=libs --exclude-dir=_kit`: none), and its one
  direct call, `settings/Schema.lua:366` `SlashLib.FormatValue(row, v)`, is the two-argument form,
  which answers as before. The parser's move to `SlashParse.lua` moves no member.
- **OptionsWidgets 34 / OptionsTabs 8**: `RenderGrid`'s new `parent` / `opts.gap` and
  `RenderTabbedSchema`'s three fields are opt-in and off by default. This addon calls
  `RenderTabbedSchema` at `settings/General.lua:235` and `settings/ElementRows.lua:149` with no opts
  table that names them, so it draws what it drew.
- **Perf 14**: the command surface and the capture moved to `PerfCommands.lua` / `PerfSampler.lua` with
  no member moved; `BuildRecord` now emits a declared parent with zero counts when a child names it
  (LibKa0s#12), and per-bucket `budget` is opt-in (LibKa0s#1). `core/PerfSetup.lua` passes no budget.

**Blockers: none.** The whole suite is green on the copy alone (428 passed, 0 failed, 1 skipped, 429
total, the eight new cases being kit 35's `test_lizard_sighted`).

## The sighted complexity suite on this tree

`bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle` on the copy, before any fix:

```text
complexity  fail  — 0 warnings (fun rate 0.00), 10601 NLOC / 1508 funcs, avg NLOC 6.3, avg CCN 2.1 (max 14)
            lizard blind in 1 file(s): `tests/test_surface_parity.lua` (28 of 29 functions listed)
```

The blind spot is the one the kit 35 document names but does not rewrite: a function literal in a
`for ... in` header (`for _, call in ipairs({ function() ... end, ... }) do` in the CliProfile /
ProfileSwitch case). The fix, in the re-vendor commit, hoists the table into a local `calls`. After it:

```text
complexity  pass  — 0 warnings (fun rate 0.00), 10602 NLOC / 1509 funcs, avg NLOC 6.3, avg CCN 2.1 (max 14)
```

maxCcn 14, warnings 0, blindFiles 0. The validation pass found no function above CCN 15 here, and the
sighted shadow agrees.
