Delta: LibKa0s v1.67.0 -> v1.68.0

# LibKa0s v1.67.0 -> v1.68.0: the delta (PartyFrameEnhanced)

Copied from the local annotated tag `v1.68.0` (tag object `6d83731`, commit `cc9f5eb`). The sibling
checkout `../LibKa0s` sat on `feat/2026-10-02-drag-attach` at that commit, and
`git -C ../LibKa0s diff --quiet v1.68.0 -- LibKa0s testkit` exited 0. The payloads were still exported
with `git archive v1.68.0 LibKa0s testkit`, never copied from the working tree. Item `TP-PF-01` of
`Ka0sAddonsCommonTasks/docs/2026-10-02-LIBKA0S_TOOLTIP_PLACE/`. The run was delegated: no interview,
every decision taken by the executor and recorded here and in `03_DECISIONS.md`.

## Step 0. Pre-flight (this addon)

The newest single-tag bundle, `2026-10-02-v1.67.0`, opens `Delta: LibKa0s v1.66.0 -> v1.67.0`. The
commit that rolled the line to v1.67.0 is `1a8723c`, and the line at its parent names v1.66.0. Result:
`ok` (base v1.66.0, vendored-before v1.66.0@1a8723c), so there is no correction to carry. The check
was run for this addon only; the other addons are their own items in this plan.

## 3a. Base

```sh
grep -n '[Bb]undles' CLAUDE.md
# 39:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.67.0 (MIT).
git log -1 --format='%h %s' -- libs/LibKa0s tests/_kit
# 1a8723c CA-PF-RV: re-vendor LibKa0s v1.67.0 (Core 10, Options 28, OptionsIdList 3; kit 35)
git -C ../LibKa0s archive v1.67.0 LibKa0s testkit | tar -x -C <scratch>/claimed
diff -rq --strip-trailing-cr <scratch>/claimed/LibKa0s libs/LibKa0s && \
  diff -rq --strip-trailing-cr <scratch>/claimed/testkit tests/_kit && echo payload-matches
# payload-matches
```

The provenance line, the last payload commit and the bytes agree: the base is **v1.67.0**.

```sh
git -C ../LibKa0s log --oneline v1.67.0..v1.68.0
# cc9f5eb DA-LK-07R ... 6ffa4ca DA-LK-06R ... 3fe6b43 DA-LK-05R ... ee9dcfe DA-LK-05 ...
# 3cd411d DA-LK-04 ... da221a7 DA-LK-03 ... 1382135 DA-LK-02 ...
# 2cc8a03 DA-LK-01: WidgetsDragHandle minor 4 - tooltipPlace lets the host place the strip's tooltip (AuraMaster#22)
# fce3003 Merge branch 'feat/2026-10-02-libka0s-census-adoption' (and the census commits it carries)
git -C ../LibKa0s diff --stat v1.67.0 v1.68.0 -- LibKa0s testkit
# LibKa0s/WidgetsDragHandle.lua | 84 +-   (the only payload file that moved; testkit untouched)
```

## 3b. Actual version (before the copy)

`grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR *= *("[^"]+", *)?[0-9]+' libs/LibKa0s/*.lua` gave 32
constants, each equal to v1.67.0's. The line and the bytes agree.

## 3c. Per-file minors (the tag's `LibKa0s.xml`)

| File | v1.67.0 | v1.68.0 |
|---|---|---|
| `WidgetsDragHandle.lua` | `DRAG_MINOR` 3 | `DRAG_MINOR` 4 |

The Widgets key goes `12.1.3` -> `12.1.4`. Every other file is unchanged (the loop over the tag's XML
printed one row): Core 10, Env 1, Compat 1, Lifecycle 3, Bus 2, Schema 2, Pool 3, Item 2, Media 4,
Widgets 12, WidgetsReorder 1, DebugLog key 19.2.1, Slash key 19.1, Launcher 5, Options key
28.2.34.2.3.8.1.7.4.2, Perf key 14.1.1.6. No `NEEDS_*` floor rises, so no file here is behind and there
is no cross-major skew. `LibKa0s.xml` is unchanged (still 32 Lua files), so neither the TOC nor
`tests/run.lua` needs a row.

## 3d. Both diffs (before the copy, tag vs this repo)

```text
diff -rq --strip-trailing-cr <tag>/LibKa0s libs/LibKa0s
Files <tag>/LibKa0s/WidgetsDragHandle.lua and libs/LibKa0s/WidgetsDragHandle.lua differ

diff -rq --strip-trailing-cr <tag>/testkit tests/_kit
(empty)
```

No `Only in libs/LibKa0s` or `Only in tests/_kit` line: nothing was removed upstream, so nothing is
deleted here.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' --include='*.lua' --exclude-dir=libs --exclude-dir=tests .
```

The same twelve majors as at v1.67.0: Bus (`core/Bus.lua`, `modules/Diagnostics.lua`), Compat, Core,
DebugLog, Env, Launcher, Lifecycle, Media, Perf (each from its `core/*Setup.lua`), Options
(`settings/OptionsSetup.lua`), Schema (`settings/Schema.lua`) and Slash (`settings/Schema.lua`,
`settings/Slash.lua`). **Widgets, the only major whose key moved, has no lookup in this addon.** It is
reached only inside the library (DebugLog, Widgets' own copy window, OptionsWidgets). No library file
other than `WidgetsDragHandle.lua` itself builds a drag handle
(`grep -rn DragHandle ../LibKa0s/LibKa0s/*.lua`: one comment in `OptionsIdList.lua:386`), and the addon
calls none (`grep -rn 'DragHandle\|tooltipPlace' --include='*.lua' . --exclude-dir=libs --exclude-dir=_kit`:
none).

## 3f. Kit revision

`grep -n 'Kit.VERSION' <tag>/testkit/framework.lua tests/_kit/framework.lua` -> 35 and **35**. The
v1.68.0 testkit is byte-identical to v1.67.0's. Both payloads are still copied whole, which keeps the
pairing rule satisfied by construction. No suite is added, so `Kit.assertSuiteInventory` needs nothing
new in `tests/run.lua`.

## 3g. Contract delta

Majors whose minor moved (3c) intersected with majors this addon looks up (3e): **none**. For the
record, `docs/api/Widgets/version-12.1.4-docs.md` and the v1.68.0 CHANGELOG block were still read:
`tooltipPlace` (and a descriptor's own `place`) is optional, and with neither set
`dhShowTooltip` makes minor 3's calls in minor 3's order (`LibKa0s/WidgetsDragHandle.lua`, the
`dhPlacer` -> nil branch). No member, `DRAG_HANDLE` field or handle method is added. The addon has no
`__Attach*` site (`grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=Libs --exclude-dir=_kit`: none).

**Blockers: none.**

## 3h. Unrecorded vendored tags

The audit's walk since the store's horizon (2026-09-23), plus the provenance-roll commits, against the
tags the bundles record: the `grep -vxF` printed nothing. No span bundle is needed.

## Gate before the copy

- tests (`ka0s-bounded lua tests/run.lua`): 454 passed, 0 failed, 1 skipped, 455 total
- luacheck (`ka0s-bounded luacheck .`): 0 warnings / 0 errors in 79 files

## After the copy

`cp -r` of both exported payloads, then both diffs in both readings against the export:
`diff -r --strip-trailing-cr` (content) and `diff -rq` (bytes) are empty for `libs/LibKa0s` and
`tests/_kit`. Only `libs/LibKa0s/WidgetsDragHandle.lua` changed in git.
