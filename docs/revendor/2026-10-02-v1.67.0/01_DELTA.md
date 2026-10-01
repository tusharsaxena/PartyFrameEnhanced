Delta: LibKa0s v1.66.0 -> v1.67.0

# LibKa0s v1.66.0 -> v1.67.0: the delta (PartyFrameEnhanced)

Copied from the local tag `v1.67.0` (tag object `749c42e`, commit `0bccf4c`). The sibling checkout
`../LibKa0s` was at that commit with a clean tree; the payloads were still exported with
`git archive v1.67.0 LibKa0s testkit`, never copied from a working tree, and the export is byte-equal to
the checkout. Item `CA-PF-RV` of the 2026-10-02 LibKa0s census adoption
(`Ka0sAddonsCommonTasks/docs/2026-10-02-LIBKA0S_CENSUS_ADOPTION/`).

## 3a. Base

```sh
grep -n '[Bb]undles' CLAUDE.md
# 39:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.66.0 (MIT).
git log -1 --format=%h -- libs/LibKa0s tests/_kit     # aa3d64d GI-PF-RV: re-vendor LibKa0s v1.66.0 (kit 35), ...
git -C ../LibKa0s archive v1.66.0 LibKa0s testkit | tar -x -C <scratch>/claimed
diff -rq <scratch>/claimed/LibKa0s libs/LibKa0s && diff -rq <scratch>/claimed/testkit tests/_kit && echo payload-matches
# payload-matches
```

The provenance line, the last payload commit and the bytes agree: the base is **v1.66.0**. The newest
bundle, `2026-10-01-v1.66.0`, records the same tag, so no tag went unrecorded and no span bundle is
needed.

## 3b. Actual version (before the copy)

`grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR *= *("[^"]+", *)?[0-9]+' libs/LibKa0s/*.lua` gave 32 constants,
each equal to v1.66.0's. The line and the bytes agree.

## 3c. Per-file minors (the tag's `LibKa0s.xml`)

| File | v1.66.0 | v1.67.0 |
|---|---|---|
| `Core.lua` | 9 | 10 |
| `Options.lua` | 27 | 28 |
| `OptionsIdList.lua` | `IDLIST_MINOR` 2 | `IDLIST_MINOR` 3 |

The Options key goes `27.2.34.2.2.8.1.7.4.2` -> `28.2.34.2.3.8.1.7.4.2`. Every other file is unchanged:
Env 1, Compat 1, Lifecycle 3, Bus 2, Schema 2, Pool 3, Item 2, Media 4, Widgets 12 (with
WidgetsReorder 1 and WidgetsDragHandle 3), DebugLog 19 (with DebugLogDiagnostics 2 and DebugLogGates 1),
Slash 19 (with SlashParse 1), Launcher 5, OptionsRegistry 2, OptionsIds 2, OptionsCombat 1,
OptionsWidgets 34, OptionsCompose 7, OptionsTabs 8, OptionsScroll 4, OptionsNav 2, Perf 14 (with
PerfSampler 1, PerfCommands 1 and PerfPanel 6). No `NEEDS_*` floor rises, so no consumer file is behind
and there is no cross-major skew. The payload stays at 32 Lua files and `LibKa0s.xml` is unchanged, so
neither the TOC nor `tests/run.lua` (which derives its library list from the same XML) needs a row.

## 3d. Both diffs (before the copy, tag vs this repo)

```text
diff -rq --strip-trailing-cr <tag>/LibKa0s libs/LibKa0s
Files differ: Core.lua, Options.lua, OptionsIdList.lua

diff -rq --strip-trailing-cr <tag>/testkit tests/_kit
(empty)
```

No `Only in libs/LibKa0s` or `Only in tests/_kit` line: nothing was removed upstream, so nothing is
deleted here. The copy was `rsync -a --delete --checksum` from the export, so a file only the addon
held would have gone. After it both `diff -r` runs (bytes, not just content) against the export are
empty, and `diff -r --strip-trailing-cr ../LibKa0s/LibKa0s libs/LibKa0s` is empty. Line endings are as
the v1.66.0 re-vendor left them: text stored LF and checked out CRLF under `.gitattributes`, the
`.tga` and `.ttf` media binary, and `tests/_kit/run-automated-tests.sh` LF and recorded 100755.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
```

The same twelve majors as at v1.66.0: Env, Media, Core (`core/CoreSetup.lua:16`), Bus (`core/Bus.lua`,
plus `modules/Diagnostics.lua:219`), Lifecycle, Compat, DebugLog, Launcher, Perf, Schema
(`settings/Schema.lua:262`), Slash (`settings/Schema.lua:360`, `settings/Slash.lua:17`) and Options
(`settings/OptionsSetup.lua:38`). Of the majors whose minor moved, this addon consumes Core and Options.

- **Core 10.** The host never calls `MakeResizable` itself
  (`grep -rn MakeResizable --include='*.lua' . --exclude-dir=libs --exclude-dir=_kit`: none). It reaches
  the grip only through the library's own windows: the debug console (`DebugLog.lua:690`), the copy
  window (`Widgets.lua:513`) and the perf panel (`PerfPanel.lua:163`). None of those passes the three
  new fields.
- **Options 28 / OptionsIdList 3.** `settings/OptionsSetup.lua:40` builds the descriptor with no
  `addonName` (the file opens `local _, NS = ...`). This addon draws no `O.IdList`
  (`IdList` appears only in the stub's member list at `settings/OptionsSetup.lua:141`), so the new
  guard and its debug line have nothing to fire on here.

## 3f. Kit revision

`Kit.VERSION` 35 -> **35**. The v1.67.0 testkit is byte-identical to v1.66.0's; both payloads are still
copied whole, and the runner stays recorded 100755 in the index. No suite is added, so
`Kit.assertSuiteInventory` needs nothing new in `tests/run.lua`.

## 3g. Contract delta

Read for Core (9 -> 10) and Options (27.2.34.2.2.8.1.7.4.2 -> 28.2.34.2.3.8.1.7.4.2), from the v1.67.0
CHANGELOG block, `docs/api/Core/version-10-docs.md` ("The resize grip") and
`docs/api/Options/version-28.2.34.2.3.8.1.7.4.2-docs.md`.

- **Core 10**: `MakeResizable(frame, opts)` reads three new optional fields, `canResize`,
  `onResizeStop` and `gripParent`. With none of them passed the grip is built, anchored and wired as at
  Core 9: `buildGrip(gripParent)` defaults `gripParent` to `frame`, and `wireGrip` skips both new
  callbacks when they are nil. The library's own three windows pass none of them, so the console, the
  copy window and the perf panel resize as before.
- **Options 28**: a docblock correction only. The descriptor's `addonName` is now documented as
  RECOMMENDED and read by `OptionsIdList.lua`; `lib:New` still raises only for `mainPanelName`.
- **OptionsIdList 3**: the help-mark art ladder accepts `d.addonName` only when the client says it is
  a loaded addon (`C_AddOns.IsAddOnLoaded`, trusted when no such API exists), and writes one `[Cfg]
  help art:` line per instance through `d.debug` when it falls past that rung. Only an `O.IdList` whose
  entries carry `help` draws the mark, and this addon draws no `O.IdList`.

**Blockers: none.** The whole suite is green on the copy plus the provenance roll (453 passed, 0
failed, 1 skipped, 454 total, the same totals as before the copy). The copy alone fails exactly one
case, `tests/test_vendor_sync.lua`'s "libs/LibKa0s is the LibKa0s release CLAUDE.md says this addon
bundles", until CLAUDE.md names v1.67.0; that is the gate working, not a consumer break.

## The sighted complexity suite on this tree

`bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle` after the copy:

```text
complexity  pass  — 0 warnings (fun rate 0.00), 11347 NLOC / 1601 funcs, avg NLOC 6.4, avg CCN 2.1 (max 14)
```

maxCcn 14, warnings 0, no blind file.
