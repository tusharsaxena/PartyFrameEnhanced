Delta: LibKa0s v1.71.0 -> v1.75.0

# 01 — Delta (PartyFrameEnhanced)

Item `PF-RV` of the 2026-10-22 LibKa0s issues #45-#58 run, branch
`feat/2026-10-22-libka0s-issues-45-58`. Run per the installed `/dev-copilot:wow-revendor-libka0s` at
dev-copilot 2.4.0, non-interactively: under the run's ruling the interview step does not run and no
GitHub issue is filed. Copied from the **local** annotated tag `v1.75.0` (tag object `eae0ee5`, commit
`265a89e`, not yet pushed) with `git -C ../LibKa0s archive v1.75.0 LibKa0s testkit tools | tar -x -C
<scratch>`, never the LibKa0s working tree. `tools/` was extracted only for `prune-icons.lua`.

## Step 0. Pre-flight for this addon

The newest single-tag bundle, `2026-10-07-v1.71.0/`, states base v1.70.0 on its line 1.
`git show 01f0680^:CLAUDE.md` (01f0680 is that re-vendor) names v1.70.0. They agree: no base correction.

## 3a. Base

`grep -n '[Bb]undles' CLAUDE.md` -> `39:Bundles [LibKa0s](...) v1.71.0 (MIT).` The last commit touching
either payload is `01f0680` (`RV-PF: re-vendor LibKa0s v1.71.0; record v1.69.0-v1.70.0 span`), and
`diff -rq` of the v1.71.0 archive against both payloads printed `payload-matches` before the copy.
Base **v1.71.0**, from the provenance line.

`git -C ../LibKa0s log --oneline v1.71.0..v1.75.0`: 56 commits, 32 of them touching `LibKa0s/` or
`testkit/`. `git -C ../LibKa0s diff --stat v1.71.0 v1.75.0 -- LibKa0s testkit ':!LibKa0s/media'`:
26 files changed, 4536 insertions, 121 deletions (the icon catalog adds 5,700+ media files on top).

## 3b/3c. Per-file minors

The 3c loop over the tag's `LibKa0s.xml` (40 files, six of them new):

| File | v1.71.0 | v1.75.0 | Arrived in |
|---|---|---|---|
| `Core.lua` (`LibKa0s-Core-1.0`) | 10 | **11** | v1.75.0 |
| `Item.lua` (`LibKa0s-Item-1.0`) | 2 | **3** | v1.75.0 (`BonusIDsFromLink`) |
| `Glow.lua` (`LibKa0s-Glow-1.0`) | — | **1** | v1.75.0, new major |
| `Media.lua` (`LibKa0s-Media-1.0`) | 4 | **5** | v1.74.0 (`ICON_SETS`, `IconAuthor`) |
| `MediaIcons.lua` (`LibKa0s-Media-1.0`) | — | **1** | v1.74.0, new file (the 5,836-icon catalog) |
| `Widgets.lua` (`LibKa0s-Widgets-1.0`) | 12 | **13** | v1.75.0 (`SearchBox`, `TestStrip`) |
| `DebugLog.lua` (`LibKa0s-DebugLog-1.0`) | 19 | **20** | v1.75.0 (comment-only) |
| `DebugLogDiagnostics.lua` (`LibKa0s-DebugLog-1.0`) | 2 | **3** | v1.75.0 |
| `Options.lua` (`LibKa0s-Options-1.0`) | 28 | **29** | v1.73.0 (attaches the drawer; structural refresh keeps scroll) |
| `OptionsIdList.lua` (`LibKa0s-Options-1.0`) | 4 | **5** | v1.75.0 (comment-only) |
| `OptionsTabs.lua` (`LibKa0s-Options-1.0`) | 8 | **9** | v1.75.0 (`O.__releaseChrome` removed, #45) |
| `OptionsDrawer.lua` (`LibKa0s-Options-1.0`) | — | **1** | v1.73.0, new file (`O.Drawer`) |
| `Perf.lua` (`LibKa0s-Perf-1.0`) | 14 | **15** | v1.72.0 (`false` for an unbucketed run) |
| `PerfPanel.lua` (`LibKa0s-Perf-1.0`) | 6 | **7** | v1.75.0 |
| `Sim.lua` (`LibKa0s-Sim-1.0`) | — | **1** | v1.75.0, new major |
| `SimTimeline.lua` (`LibKa0s-Sim-1.0`) | — | **1** | v1.75.0, new file |
| `SimPanel.lua` (`LibKa0s-Sim-1.0`) | — | **1** | v1.75.0, new file (the Sim-private step panel) |
| the other 23 files | — | unchanged | |

No consumer file is behind the tag after the copy: no cross-major skew. No `WidgetsStepPanel.lua`:
LK-11 took outcome B, so `W.StepPanel` is not public and the renderer is Sim-private in `SimPanel.lua`.
The TOC loads `libs\LibKa0s\LibKa0s.xml` and `tests/run.lua` reads the same XML
(`Loader.xmlFiles`), so the six new files need no TOC or harness row.

## 3d. Diffs

Before the copy, `diff -rq <scratch>/LibKa0s libs/LibKa0s`: the twelve changed files above, plus
`LibKa0s.xml`, `Only in <scratch>` for the six new files, and 113 lines under `media/icons`.
`diff -rq <scratch>/testkit tests/_kit`: `README.md`, `framework.lua`, `inventory.lua`,
`mock_base.lua`, `mock_record.lua`, `run-automated-tests.sh`, `vendor_sync.lua` differ, and
`Only in <scratch>/testkit: latch.lua`. No `Only in libs/LibKa0s` or `Only in tests/_kit` line, so
nothing is deleted outside the icon prune.

After `cp -r` of both payloads and before the prune, `diff -r --strip-trailing-cr` in both payloads is
empty.

## 3e. Consumption

`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v /libs/ | grep -v
/tests/`: the same twelve majors as v1.71.0 (Bus, Compat, Core, DebugLog, Env, Launcher, Lifecycle,
Media, Perf, Options, Schema, Slash; `docs/ARCHITECTURE.md` Overview). Of the moved files, the host
consumes Core, Media, DebugLog, Options and Perf. Pool, Item and Widgets stay vendored and not wired,
and the new Glow and Sim majors are vendored and not wired.

## 3f. Kit revision

`Kit.VERSION` 38 -> **41** (`tests/_kit/framework.lua:20`):

- **39** (v1.72.0): `M.__fireUnconditional` reaches method-name and function handlers after
  unregister; `latch.lua` and `T.assertLatchHoldOrder`. The stand-down cases
  `tests/test_disabled.lua:201` and `tests/test_providers.lua:216` stay green, so no guard is owed.
- **40** (v1.75.0): the icon declaration gate. `tests/test_vendor_sync.lua` reads the `LibKa0s icons:`
  line under the provenance line and asserts the shipped `media/icons/` equals it.
- **41** (v1.75.0): a crashed lizard is a fail, with a crashed bucket in the complexity report.

Both payloads are copied whole in one commit, so the kit and the library tag stay paired (the
revision-11 pairing rule) by construction; `tests/test_vendor_sync.lua` asserts it.

## 3g. Contract delta — blockers

`grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit` is empty: the
host supplies no member a moved call site can reach. The contract changes that did reach this host:

1. **Options surface parity** (`tests/test_surface_parity.lua`, the Options stub case): red after the
   copy with `Drawer is missing (live: function)` (OptionsDrawer 1, v1.73.0). The addon has no
   `Drawer` caller, so `"Drawer"` joins the existing "No caller in this addon" exemption row beside
   `RefreshPanel`, `PageBanner` and `SubTabStrip`. No stub no-op is added to
   `settings/OptionsSetup.lua`, because that would be a member with no caller.
2. **`info.tga` assertion** (`tests/test_optionssetup.lua`, the descriptor case): it opened
   `libs/LibKa0s/media/icons/info.tga` and goes red after the prune, since the addon draws no IdList
   and does not declare `info`. The case keeps its two descriptor assertions (vararg 1 kept as
   `addonName`, the `addonName = addonName,` row) and replaces the file open with this rule: if a
   settings file has a live `IdList(` call (comments and the stub's name list excluded), the
   `LibKa0s icons:` line, read with the kit's own `VendorSync.iconDeclaration`, must name `info`, and
   the art must ship. Today there is no such call, so the case passes without opening the file. It was
   confirmed red on a scratch copy with an `H.IdList(...)` call added to `settings/General.lua`. Renamed
   to `optionssetup: the Options descriptor names the addon folder, and an IdList's help-mark art is
   declared when one is drawn`.
3. **Dead stub mirrors** (#45, OWNER_SCOPE G):
   `grep -rn '__releaseChrome\|__deviationRows\|__declineFor' . --include='*.lua' --exclude-dir=libs
   --exclude-dir=_kit` is empty. There is no `O.__releaseChrome`, `Kit.__deviationRows` or
   `Kit.__declineFor` mirror in this addon, so nothing is deleted.
4. **Kit-revision mentions.** The live docs already point at the provenance line (since v1.71.0's
   bundle). The historical "kit revision 26/23" citations in `tests/test_providers.lua`,
   `tests/test_surface_parity.lua`, `tests/test_slash.lua` and `DEPENDENCIES.md` are dated facts and
   stay.

Options 29's structural refresh now keeps the page's scroll position. The host never scrolled a page
back by hand, so nothing changes. Perf 15's `false` bucket argument is new and optional. Media 5 adds
exports that this host's stub does not pin (`tests/test_mediasetup.lua` pins no Media parity).

## 3h. Unrecorded tags

`v1.72.0`, `v1.73.0` and `v1.74.0` were never vendored here. The 3h walk lists no tag that was
vendored and has no bundle, so no span bundle is written.

## 3i. The icon declaration

`grep -n 'LibKa0s icons:' CLAUDE.md` found no line, so one was derived. The item spec pre-decides it,
so it is recorded here as decided:

    LibKa0s icons: clear, close, copy.

It is the next line after the provenance line (`CLAUDE.md:39`). That line ends the file and does not
run on into prose, so nothing had to be split. The derivation:

- **(a) The media seam.** `NS.Icon` (`core/MediaSetup.lua:21-24`) has no caller in `core/`, `modules/`
  or `settings/`. Its own comment says so (`:19-20`). The only callers are in
  `tests/test_mediasetup.lua:17,25`, which ask for `close`, and `close` is declared.
- **(b) Data and constants.** No table or constant names a catalog icon. `C.LOGO_PATH`
  (`core/Constants.lua:21`) is the addon's own `media/logos/`. The raid-marker and frame textures in
  `modules/Element.lua`, `modules/PetFrames.lua` and `modules/TargetFrames.lua` are client textures,
  and the spell icon is client art.
- **(c) Library-drawn** (the tag's `docs/releasing.md:312-324`, *Library-drawn icons are the host's
  to declare*). **`close`** is drawn by `Core.MakeCloseButton` given the addon name for three windows:
  the DebugLog console (`core/DebugLogSetup.lua:92-97` passes `addonName` and no `makeCloseButton`
  override), the Widgets copy window, and the Perf step panel (`core/PerfSetup.lua:25-29` passes
  `addonName`, with no `decorate`). **`copy`** and **`clear`** are the console's title-bar buttons,
  drawn by DebugLog's `makeIconButton`.
- **(d) `info` is not declared.** The help mark in OptionsIdList draws only for an IdList, and this
  addon never calls `Helpers.IdList`. The only hit is the degraded stub's no-op name list
  (`settings/OptionsSetup.lua:144`). The addon hosts no `W.TestStrip` and no Sim panel.

Hand-written icon lists have drifted before (KickCD `tests/test_mediasetup.lua:28`, WhatGroup
`tests/test_mediasetup.lua:19`). The owner's in-client smoke is the backstop: a pruned icon still
resolves to a path and draws blank, and no gate can see a name the host forgot to declare. That check
is INSTALL-4's icon step in `docs/smoke-tests.md`.

`lua <scratch>/tools/prune-icons.lua .` -> `prune-icons: .: 3 icon(s) declared; kept 4 file(s),
removed 5836`. `libs/LibKa0s/media/icons/` now holds `LICENSE-open-iconic.txt`, `clear.tga`,
`close.tga` and `copy.tga`. Every removed file was an Open Iconic, Phosphor or Game-icons mark, and
the Phosphor and Game-icons folders, with their licenses, went with them.

## 3j. Tests that assume the whole icon folder

`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v /_kit/` found only
`tests/test_optionssetup.lua:257,266-267`, which is blocker 2 above. No suite walks the catalog.
