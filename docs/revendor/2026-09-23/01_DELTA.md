# Re-vendor delta: LibKa0s v1.54.2 -> v1.55.0

Written before the copy, per `revendor-libka0s` Step 3. Every figure below carries the command that
produced it. `<tag>` is `git -C ../LibKa0s archive v1.55.0 LibKa0s testkit` extracted into a scratch
folder outside this repo.

## Tag

```sh
git -C ../LibKa0s tag --sort=-v:refname | head -1      # v1.55.0 (tagged locally, not pushed)
```

## 3a. Claimed version

```sh
grep -n '[Bb]undles' CLAUDE.md
# 38:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.54.2 (MIT).
```

## 3b/3c. Actual version, and the per-file minor delta

```sh
grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR *= *("[^"]+", *)?[0-9]+' libs/LibKa0s/*.lua <tag>/LibKa0s/*.lua
grep -o 'file="[^"]*"' <tag>/LibKa0s/LibKa0s.xml      # the file list, from what shipped
```

| File | Constant | v1.54.2 (vendored) | v1.55.0 (tag) |
|---|---|---|---|
| `Core.lua` | `MINOR` | 7 | 7 |
| `Env.lua` | `MINOR` | 1 | 1 |
| `Compat.lua` | `MINOR` | absent | **1 (new major `LibKa0s-Compat-1.0`)** |
| `Lifecycle.lua` | `MINOR` | 1 | 1 |
| `Bus.lua` | `MINOR` | absent | **1 (new major `LibKa0s-Bus-1.0`)** |
| `Schema.lua` | `MINOR` | absent | **1 (new major `LibKa0s-Schema-1.0`)** |
| `Pool.lua` | `MINOR` | 3 | 3 |
| `Item.lua` | `MINOR` | 1 | 1 |
| `Media.lua` | `MINOR` | 3 | 3 |
| `Widgets.lua` | `MINOR` | 9 | 9 |
| `WidgetsDragHandle.lua` | `DRAG_MINOR` | 2 | 2 |
| `DebugLog.lua` | `MINOR` | 12 | 12 |
| `Slash.lua` | `MINOR` | 14 | 14 |
| `Launcher.lua` | `MINOR` | 1 | 1 |
| `Options.lua` | `MINOR` | 23 | 23 |
| `OptionsWidgets.lua` | `WIDGETS_MINOR` | 30 | 30 |
| `OptionsTabs.lua` | `TABS_MINOR` | 3 | 3 |
| `OptionsCompose.lua` | `COMPOSE_MINOR` | 7 | 7 |
| `OptionsScroll.lua` | `SCROLL_MINOR` | 3 | 3 |
| `Perf.lua` | `MINOR` | 12 | 12 |
| `PerfPanel.lua` | `PANEL_MINOR` | 5 | 5 |

The claim (v1.54.2) and the vendored minors agree. No file is behind the tag on an existing major,
so there is **no cross-major skew**. The only moves are three new majors, and `LibKa0s.xml` gaining
the three `<Script>` rows that load them.

## 3d. Both diffs

```sh
diff -rq --strip-trailing-cr <tag>/LibKa0s libs/LibKa0s     # content
diff -rq                     <tag>/LibKa0s libs/LibKa0s     # bytes
diff -rq --strip-trailing-cr <tag>/testkit tests/_kit
diff -rq                     <tag>/testkit tests/_kit
```

- `libs/LibKa0s`: content and bytes agree on the same list. `Only in <tag>`: `Bus.lua`, `Compat.lua`,
  `Schema.lua`; `LibKa0s.xml` differs. Nothing is `Only in libs/LibKa0s`, so nothing is deleted.
- `tests/_kit`: content and bytes agree on the same list. `Only in <tag>`: `test_layout_cap.lua`;
  differing: `README.md`, `framework.lua`, `run-automated-tests.sh`, `test_eol.lua`,
  `test_prose.lua`. Nothing is `Only in tests/_kit`.

No line-ending-only drift in either payload (the byte and content lists are identical).

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
```

| Major | Lookup site(s) |
|---|---|
| `LibKa0s-Core-1.0` | `core/CoreSetup.lua:15` |
| `LibKa0s-Env-1.0` | `core/EnvSetup.lua:10` |
| `LibKa0s-Media-1.0` | `core/MediaSetup.lua:16` |
| `LibKa0s-Lifecycle-1.0` | `core/LifecycleSetup.lua:17` |
| `LibKa0s-DebugLog-1.0` | `core/DebugLogSetup.lua:11` |
| `LibKa0s-Launcher-1.0` | `core/LauncherSetup.lua:36` |
| `LibKa0s-Perf-1.0` | `core/PerfSetup.lua:10` |
| `LibKa0s-Slash-1.0` | `settings/Slash.lua:16`, `settings/Schema.lua:294` |
| `LibKa0s-Options-1.0` | `settings/OptionsSetup.lua:37` |

Unconsumed majors in the payload: `Pool`, `Item`, `Widgets` (reached transitively through the
library), and the three new ones, `Compat`, `Bus`, `Schema`. The new three feed Step 5, which is not
this phase's.

## 3f. Kit revision, and the pairing rule

```sh
grep -n 'Kit.VERSION' <tag>/testkit/framework.lua tests/_kit/framework.lua
# <tag>/testkit/framework.lua:20:Kit.VERSION = 25
# tests/_kit/framework.lua:20:Kit.VERSION = 24
```

Kit revision 24 -> 25. Both payloads are copied whole in one commit, which satisfies the pairing
rule by construction (a consumer on LibKa0s v1.9.0 or newer takes kit revision 11 or newer in the
same commit). Revision 25 brings: the `layout-§1` 1500-line cap census gate
(`tests/_kit/test_layout_cap.lua`, which must be wired in `tests/run.lua`), the `.gitattributes`
body case in `test_eol.lua`, suite declaration keyed by (basename, directory) with
shadow/unreferenced reporting, and the commit SHA in the automated-test record.

## 3g. Contract delta

Majors to read = (minor moved, per 3c) intersected with (consumed, per 3e) = **none**. No existing
file's minor moved, and the library's own `CHANGELOG.md` v1.55.0 block states "No existing `.lua`
file in the library changes" (`git -C ../LibKa0s show v1.55.0:CHANGELOG.md`, the opening paragraph
of the v1.55.0 block).

```sh
git -C ../LibKa0s diff --stat v1.54.2 v1.55.0 -- LibKa0s testkit docs/api
grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=Libs --exclude-dir=_kit
# (no output: this addon hands the library no __Attach* members)
```

The only edits to an existing API document in the range are the header tables of
`docs/api/Widgets/version-9.1-docs.md` and `version-9.2-docs.md` (the `Status` / `Superseded by`
rows repaired, and a "Moving to version 9.2" note); no surface's contract moves, and this addon
does not look Widgets up. The three new modules each floor on Core minor 1, call no Core member at
load, and assign no global (`grep -nE '_G\.|_G\[' <tag>/LibKa0s/{Bus,Compat,Schema}.lua`: no
output), so loading them changes nothing the addon's existing lookups see.

The kit contract does move: suite declaration is keyed by (basename, directory), and a kit suite
that arrives undeclared reddens `Kit.assertSuiteInventory`. That is expected on every first vendor
of revision 25 and is resolved in the vendor commit by wiring
`{ name = "test_layout_cap", dir = "tests/_kit/" }` in `tests/run.lua`. It is harness wiring, not a
host-supplied member.

### Blockers

None.
