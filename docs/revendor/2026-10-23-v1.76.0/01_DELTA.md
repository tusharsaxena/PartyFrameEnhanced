Delta: LibKa0s v1.75.2 -> v1.76.0

# 01 — Delta (PartyFrameEnhanced)

Item `PF-RV` of the 2026-10-23 sim auto-run, QC preview selector, mode strips and MM/KCD simulators
run (Ka0sAddonsCommonTasks `docs/2026-10-23-SIM_PREVIEW_MODE_STRIPS/`), branch
`feat/2026-10-23-sim-preview-mode-strips`. Run per the installed `/dev-copilot:wow-revendor-libka0s`
at dev-copilot 2.4.0, non-interactively: under the run's ruling the interview step does not run and no
GitHub issue is filed. Copied from the **local** annotated tag `v1.76.0` (tag object `546e284`, commit
`9949368`, not yet pushed: `git -C ../LibKa0s ls-remote --tags origin v1.76.0` prints nothing) with
`git -C ../LibKa0s archive v1.76.0 LibKa0s testkit tools | tar -x -C <scratch>`, never the LibKa0s
working tree. `tools/` was extracted only for `prune-icons.lua`.

## Step 0. Pre-flight for this addon

The newest single-tag bundle, `2026-10-22-v1.75.0/`, states base v1.71.0 on its line 1.
`git show 0a988f6^:CLAUDE.md` (0a988f6 is that re-vendor) names v1.71.0. They agree: no base
correction.

## 3a. Base

`grep -n '[Bb]undles' CLAUDE.md` -> `39:Bundles [LibKa0s](...) v1.75.2 (MIT).` The last commit touching
either payload is `8e069a8` (`Re-vendor LibKa0s v1.75.2 (SimPanel minor 4)`), and its `CLAUDE.md`
names v1.75.2. `diff -rq` of the v1.75.2 archive against `tests/_kit` was empty and against
`libs/LibKa0s` differed only by `Only in <scratch>/LibKa0s/media/icons` lines (the icons this addon
does not declare). Base **v1.75.2**, from the provenance line.

`git -C ../LibKa0s log --oneline v1.75.2..v1.76.0`: 8 commits. `git -C ../LibKa0s diff --stat v1.75.2
v1.76.0 -- LibKa0s testkit`: 3 files changed, 148 insertions, 53 deletions (`SimPanel.lua`,
`SimTimeline.lua`, `Widgets.lua`). The kit is unchanged.

## 3b/3c. Per-file minors

3b: the payload's minors before the copy are v1.75.2's (`SimPanel` 4, `SimTimeline` 2, `Widgets` 13),
matching the line. The 3c loop over the tag's `LibKa0s.xml` (40 files, none new) prints three files
whose constant moved:

| File | v1.75.2 | v1.76.0 | What moved |
|---|---|---|---|
| `Widgets.lua` (`LibKa0s-Widgets-1.0`) | 13 | **14** | `W.TestStrip(parent, { kind = "sim" })`, `strip.kind` |
| `SimTimeline.lua` (`TIMELINE_MINOR`) | 2 | **3** | a verb start or restart plays the run on its own |
| `SimPanel.lua` (`SIM_PANEL_MINOR`) | 4 | **5** | Run all removed; Pause/Resume, Restart, Stop |
| the other 37 files | — | unchanged | |

No consumer file is behind the tag after the copy: no cross-major skew. Seventeen majors across forty
files, as at v1.75.2.

## 3d. Diffs

Before the copy, `diff -rq <scratch>/LibKa0s libs/LibKa0s`: `SimPanel.lua`, `SimTimeline.lua` and
`Widgets.lua` differ, plus `Only in <scratch>/LibKa0s/media/icons` lines. `diff -rq <scratch>/testkit
tests/_kit`: empty. No `Only in libs/LibKa0s` or `Only in tests/_kit` line, so nothing is deleted
outside the icon prune.

After `cp -r` of both payloads and before the prune, `diff -r --strip-trailing-cr` and `diff -rq` are
empty in both payloads.

## 3e. Consumption

`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v /libs/ | grep -v
/tests/`: the same twelve majors as v1.75.0 (Bus, Compat, Core, DebugLog, Env, Launcher, Lifecycle,
Media, Perf, Options, Schema, Slash). Neither moved major is looked up by the host: Sim is vendored and
not wired, and Widgets reaches the addon only through the library's own DebugLog console and copy
window, which draw no strip.

## 3f. Kit revision

`Kit.VERSION` 41 -> **41** (`tests/_kit/framework.lua:20`, both sides). Both payloads are copied whole
in one commit, so the kit and the library tag stay paired (the revision-11 pairing rule) by
construction; `tests/test_vendor_sync.lua` asserts it.

## 3g. Contract delta — blockers

None. The moved majors (Widgets, Sim) intersect the consumed set (3e) nowhere.
`grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit` is empty.
The v1.76.0 `CHANGELOG.md` *What a consumer owes* list asks for no code, re-trued sim suites and
reworded Run all docs; this addon has no sim suite, no `RUN_ALL` override and no doc naming Run all
(`grep -rn 'Run all\|RUN_ALL' core modules settings locales tests docs --include='*.lua'
--include='*.md'` outside `tests/_kit` finds nothing). `Widgets 14` is additive: `members-14.1.4.3.2.json`
lists the same names as 13 (`docs/api/Widgets/version-14.1.4.3.2-docs.md` at the tag).

## 3h. Unrecorded tags

The 3h walk lists `v1.75.1` and `v1.75.2`: vendored here by `b27a600` and `8e069a8` with no bundle.
One consolidated span bundle is written beside this one, `docs/revendor/2026-10-23-v1.75.1-v1.75.2/`.

## 3i. The icon declaration

`grep -n 'LibKa0s icons:' CLAUDE.md` -> `40:LibKa0s icons: clear, close, copy.`, the next line after the
provenance line. Kept as it stands: v1.76.0's *What a consumer owes* adds no library-drawn name, and
the host draws no new surface. Hand lists have drifted before (KickCD `tests/test_mediasetup.lua:28`,
WhatGroup `tests/test_mediasetup.lua:19`); the owner's in-client smoke (INSTALL-4) is the backstop.

## 3j. Tests that assume the whole icon folder

`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'`:
`tests/test_optionssetup.lua:256,290-291`, the IdList-gated `info.tga` check narrowed at v1.75.0. No
IdList is drawn, so it opens no file. No blocker.
