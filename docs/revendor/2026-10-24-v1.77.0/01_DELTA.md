Delta: LibKa0s v1.76.0 -> v1.77.0

# 01 — Delta (PartyFrameEnhanced)

Item `PF-RV` of the 2026-10-24 keybindings, settings layout and frame strata run (Ka0sAddonsCommonTasks
`docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`), branch `feat/2026-10-24-keybinds-layout-strata`. Run per
the installed `/dev-copilot:wow-revendor-libka0s` at dev-copilot 2.4.0, non-interactively: the item
spec rules that no interview runs and no GitHub issue is filed. Copied from the **local** annotated
tag `v1.77.0` (tag object `7380d36`, commit `78240f7`, not yet pushed:
`git -C ../LibKa0s ls-remote --tags origin v1.77.0` prints nothing) with
`git -C ../LibKa0s archive v1.77.0 LibKa0s testkit tools | tar -x -C <scratch>`, never the LibKa0s
working tree. `tools/` was extracted only for `prune-icons.lua`.

## Step 0. Pre-flight for this addon

The newest single-tag bundle, `2026-10-23-v1.76.0/`, states base v1.75.2 on its line 1.
`git show 8e69c79^:CLAUDE.md` (8e69c79 is that re-vendor) names v1.75.2. They agree: no base
correction.

## 3a. Base

`grep -n '[Bb]undles' CLAUDE.md` -> `39:Bundles [LibKa0s](...) v1.76.0 (MIT).` The last commit touching
either payload is `a24e064` (`PF-RV2: re-vendor LibKa0s from the moved local tag v1.76.0`), and its
`CLAUDE.md` names v1.76.0. Base **v1.76.0**, from the provenance line.

`git -C ../LibKa0s log --oneline v1.76.0..v1.77.0`: 15 commits (LK-00 to LK-90).
`git -C ../LibKa0s diff --stat v1.76.0 v1.77.0 -- LibKa0s testkit`: 18 files changed, 1672
insertions, 34 deletions.

## 3b/3c. Per-file minors

3b: the payload's minors before the copy were v1.76.0's, matching the line. The 3c loop over the
tag's `LibKa0s.xml` (41 files, one new) prints twelve files whose constant moved:

| File | v1.76.0 | v1.77.0 | What moved |
|---|---|---|---|
| `Core.lua` (`LibKa0s-Core-1.0`) | 11 | **12** | `Core.RaiseStaticPopups()` |
| `DebugLog.lua` (`LibKa0s-DebugLog-1.0`) | 20 | **21** | the console is toplevel and raises a shown popup |
| `PerfPanel.lua` (`PANEL_MINOR`) | 8 | **9** | the perf panel is toplevel and raises a shown popup |
| `SimPanel.lua` (`SIM_PANEL_MINOR`) | 5 | **6** | the sim panel likewise |
| `Widgets.lua` (`LibKa0s-Widgets-1.0`) | 14 | **15** | the dropdown menu is clamped to screen |
| `WidgetsDragHandle.lua` (`DRAG_MINOR`) | 4 | **5** | `spec.level`, `handle:ApplyLevel()`, `spec.ignoreParentAlpha` |
| `WidgetsAutocomplete.lua` (`AUTOCOMPLETE_MINOR`) | 2 | **3** | the suggestion list is clamped to screen |
| `Options.lua` (`LibKa0s-Options-1.0`) | 29 | **30** | attaches `OptionsKeybinds.lua` |
| `OptionsIds.lua` (`IDS_MINOR`) | 2 | **3** | `O.__closeOwnedSuggest` |
| `OptionsCombat.lua` (`COMBAT_MINOR`) | 1 | **2** | the suggestion list closes at combat start |
| `OptionsCompose.lua` (`COMPOSE_MINOR`) | 7 | **8** | `O.StrataTooltip(values[, strings])` |
| `OptionsKeybinds.lua` (`KEYBINDS_MINOR`) | — (new) | **3** | the Keybindings tab: `O.KeybindingsTab`, `O.KeybindRows`, `O.KEYBINDS_UNCHANGED` |
| the other 29 files | — | unchanged | |

No consumer file is behind the tag after the copy: no cross-major skew. Seventeen majors across
forty-one files.

## 3d. Diffs

Before the copy, `diff -rq --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s`: the eleven moved
files and `LibKa0s.xml` differ, `Only in <scratch>/LibKa0s: OptionsKeybinds.lua`, plus the
`Only in <scratch>/LibKa0s/media/icons` lines. `diff -rq <scratch>/testkit tests/_kit`: `README.md`
and `framework.lua` differ, and `bindings_xml.lua`, `mock_bindings.lua` and `mock_layers.lua` are only
in the tag. No `Only in libs/LibKa0s` or `Only in tests/_kit` line, so nothing is deleted outside the
icon prune.

After `cp -r` of both payloads and before the prune, `diff -r --strip-trailing-cr` and `diff -rq` are
empty in both payloads.

## 3e. Consumption

`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -vE
'^(\./)?(libs|tests)/'`: the same twelve majors as v1.76.0 (Bus, Compat, Core, DebugLog, Env,
Launcher, Lifecycle, Media, Perf, Options, Schema, Slash). Of the moved majors the host looks up
Core, DebugLog, Perf and Options; Widgets reaches it only through the library's own console and copy
window, and Sim is vendored and not wired.

## 3f. Kit revision

`Kit.VERSION` 41 -> **42** (`tests/_kit/framework.lua:20`). Both payloads are copied whole in one
commit, so the kit and the library tag stay paired (the revision-11 pairing rule) by construction;
`tests/test_vendor_sync.lua` asserts it.

## 3g. Contract delta — blockers

`grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit` is empty.
The tag's `CHANGELOG.md` *What a consumer owes* lists two code debts, both under Options, which the
host consumes:

- **OptionsCompose minor 8:** "every Options degradation stub gains `StrataTooltip`".
- **OptionsKeybinds minor 2:** "every Options degradation stub gains `KeybindingsTab`, `KeybindRows`
  and `KEYBINDS_UNCHANGED`, in every addon, windowed or not".

`Kit.assertSurfaceParity` compares the stub against the live instance. After the copy,
`tests/test_surface_parity.lua` (*the Options stub carries every helper the degraded build can
reach*) failed with `KEYBINDS_UNCHANGED is missing (live: string); KeybindRows is missing (live:
function); KeybindingsTab is missing (live: function); StrataTooltip is missing (live: function)`.
**Blocker, fixed in the re-vendor commit:** `settings/OptionsSetup.lua`'s stub adds
`StrataTooltip`, `KeybindingsTab` and `KeybindRows` to its no-op list and
`KEYBINDS_UNCHANGED = ""`. A stub reaches none of them from a drawn panel, because the panel never
opens without the library. The suite went green with nothing else touched.

The other moves are additive or library-internal: `Core.RaiseStaticPopups` is new; DebugLog 21 and
PerfPanel 9 change the windows' own layering, not a host-supplied member; OptionsIds 3 and
OptionsCombat 2 are `__`-prefixed.

## 3h. Unrecorded tags

The 3h walk lists nothing: every tag vendored since the store's first bundle has one. No span bundle.

## 3i. The icon declaration

`grep -n 'LibKa0s icons:' CLAUDE.md` -> `40:LibKa0s icons: clear, close, copy.`, the next line after the
provenance line. Kept: v1.77.0's *What a consumer owes* adds no library-drawn name, and the host
draws no new surface. Hand lists have drifted before (KickCD `tests/test_mediasetup.lua:28`,
WhatGroup `tests/test_mediasetup.lua:19`); the owner's in-client smoke (INSTALL-4) is the backstop.

## 3j. Tests that assume the whole icon folder

`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'`:
`tests/test_optionssetup.lua:256,290-291`, the IdList-gated `info.tga` check narrowed at v1.75.0. No
IdList is drawn, so it opens no file. No blocker.
