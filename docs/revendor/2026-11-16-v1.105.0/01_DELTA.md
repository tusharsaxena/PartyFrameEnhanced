Delta: LibKa0s v1.94.0 -> v1.105.0

Recorded for the re-vendor commit. Payload taken from the tag, never the sibling tree: `git -C ../LibKa0s archive v1.105.0 LibKa0s testkit tools` (tag 43ea2bd, commit 79b1d9c; a local annotated tag, not yet on origin: `git -C ../LibKa0s ls-remote --tags origin v1.105.0` prints nothing, which this run expects). Run under the LibKa0s #75+ run (Ka0sAddonsCommonTasks `docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/`), item RV-PFE: the copy and bundle half of `/dev-copilot:wow-revendor-libka0s` only. The adoption interview and its issue filing are skipped by that run's design (section 5); the candidates are listed in `02_CANDIDATES.md` as owed in its phase [3].

## Step 0 pre-flight
For this addon: newest single-tag bundle `docs/revendor/2026-11-07-v1.93.0`, base v1.92.0, vendored-before v1.92.0@cc8a683: `ok`. No base correction is owed.

## 3a Base
- `grep -n '[Bb]undles' CLAUDE.md` -> `42:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.94.0 (MIT).` before the roll.
- `git log -1 --format=%H -- libs/LibKa0s tests/_kit` = 2a6c47c (W2-PF-01, the Retail + Forever port); its CLAUDE.md names v1.94.0. They agree.
- Payload before the copy equalled the library at v1.94.0: `diff -rq --strip-trailing-cr` of a v1.94.0 extract against `libs/LibKa0s` (bar the undeclared icons) and against `tests/_kit` printed nothing (payload-matches).
- Range: `git -C ../LibKa0s log --oneline v1.94.0..v1.105.0` is 114 commits, tags v1.95.0 to v1.105.0.

## 3b/3c Per-file minors that moved (old = this addon, new = v1.105.0)
From the loop over the tag's `LibKa0s.xml` (`grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR ...'`):
```
Core.lua                     old: 17    new: 18
Tooltip.lua                  old: none  new: 1
Role.lua                     old: none  new: 1
Callout.lua                  old: none  new: 4
CalloutSettings.lua          old: none  new: 5
WaypointArrow.lua            old: none  new: 2
WaypointArrowSettings.lua    old: none  new: 2
Charts.lua                   old: 1     new: 2
Media.lua                    old: 12    new: 13
SkinDefs.lua                 old: 27    new: 28
SkinDefsOthers.lua           old: 8     new: 10
Widgets.lua                  old: 26    new: 27
WidgetsDropdown.lua          old: 1     new: 2
WidgetsReorder.lua           old: 6     new: 7
WidgetsDragHandle.lua        old: 13    new: 14
WidgetsDragHandleTip.lua     old: none  new: 1
WidgetsCopyWindow.lua        old: 5     new: 6
WidgetsHeader.lua            old: none  new: 1
WidgetsBar.lua               old: none  new: 1
DebugLog.lua                 old: 22    new: 23
DebugLogDiagnostics.lua      old: 7     new: 11
DebugLogWindow.lua           old: 4     new: 5
Launcher.lua                 old: 9     new: 11
OptionsWidgets.lua           old: 45    new: 46
OptionsNav.lua               old: 6     new: 7
OptionsSkinPicker.lua        old: 11    new: 12
OptionsSkinPickerQueue.lua   old: none  new: 1
IconBrowserWindow.lua        old: 1     new: 2
IconBrowser.lua              old: 1     new: 2
PerfPanel.lua                old: 13    new: 14
Sim.lua                      old: 2     new: 3
SimPanel.lua                 old: 10    new: 11
SimPanelRender.lua           old: 3     new: 4
```
Ten new files. Every other file matched v1.94.0 before the copy, and the claimed and actual minors agree, so there is no cross-major skew.

## 3d Diffs
Before the copy, `diff -rq --strip-trailing-cr` against the v1.105.0 extract showed the files above (ten only in the tag), `LibKa0s.xml`, `media/fonts/FONTS.md`, the two new faces (Bebas Neue, Russo One, with their OFL texts), and the new `media/sounds/` and `media/waypoint/` folders. In the kit: `README.md`, `client_globals.lua`, `framework.lua`, `glyphs.lua`, `mock_ace.lua`, `mock_events.lua`, `vendor_sync.lua`, and the new `mock_screen.lua`. No `Only in libs/LibKa0s` line: nothing was removed upstream, so nothing is deleted by hand.

After the copy and before the prune, both diffs (content and bytes) of both payloads were empty. After the prune the only difference is the undeclared icons and the sounds (`Only in <extract>/...`), and `tests/test_vendor_sync.lua` is green.

## 3e Consumption map
`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua'`, outside `libs/` and `tests/`:
```
core/Bus.lua:40            LibKa0s-Bus-1.0
core/Compat.lua:15         LibKa0s-Compat-1.0
core/CoreSetup.lua:16      LibKa0s-Core-1.0
core/Database.lua:117      LibKa0s-Skin-1.0
core/DebugLogSetup.lua:12  LibKa0s-DebugLog-1.0
core/EnvSetup.lua:11       LibKa0s-Env-1.0
core/LauncherSetup.lua:42  LibKa0s-Launcher-1.0
core/LifecycleSetup.lua:17 LibKa0s-Lifecycle-1.0
core/MediaSetup.lua:16     LibKa0s-Media-1.0
core/PerfSetup.lua:10      LibKa0s-Perf-1.0
core/SkinSetup.lua:73      LibKa0s-Skin-1.0
modules/Diagnostics.lua:219 LibKa0s-Bus-1.0
settings/OptionsSetup.lua:38 LibKa0s-Options-1.0
settings/Schema.lua:262    LibKa0s-Schema-1.0
settings/Schema.lua:358    LibKa0s-Slash-1.0
settings/Slash.lua:17      LibKa0s-Slash-1.0
```
Majors in the payload with no lookup here: Callout, Charts, Glow, IconBrowser, Item, Pool, Role, Sim, Toast, Tooltip, WaypointArrow, Widgets.

## 3f Kit revision
`grep -n 'Kit.VERSION'`: addon 53, tag 57. Both payloads move together in one commit (the pairing rule, kit 11 or newer for LibKa0s v1.9.0 or newer, is met by construction).

## 3g Contract delta
Majors that moved and that this addon looks up: Core (18), DebugLog (23, Diagnostics 11, Window 5), Launcher (11), Media (13), Skin (SkinDefs 28, SkinDefsOthers 10), Options (Widgets 46, Nav 7, SkinPicker 12, SkinPickerQueue 1), Perf (PerfPanel 14). Read in `CHANGELOG.md` at v1.105.0 (v1.95.0 to v1.105.0 blocks, the *What a consumer owes* lists of v1.101.0, v1.103.0 and v1.105.0) and the `docs/api/` documents:
- DebugLog 23 / DebugLogDiagnostics 11 (`docs/api/DebugLog/version-23.11.1.5-docs.md`, `members-23.11.1.5.json`): the instance gains `D:Report(tag, title, fn)` and `D:Serialize(value, opts)`; reports go to the console, Copy is plain text, the status line is a 24 px `W.Footer`. Additive for a host; the degradation stub owes the two members (fixed in this commit, below).
- OptionsNav 7 (v1.100.0, *The one tab*): adds `O.SideTabs`; additive; the Options stub owes it (fixed below).
- OptionsWidgets 46 (v1.101.0, *A slider's box takes no junk*): a slider box reverts junk on Enter and on focus loss; "What a consumer owes: nothing". A smoke line.
- Core 18, Launcher 11 (v1.105.0, *Header buttons*, *Launcher*): `RegisterSettingsOpener`, `HasSettings`, `OpenSettings`; every library window gets a settings mark that opens the owner's settings through the launcher registry. The registry key is `d.owner or d.name`; this addon's descriptor passes `name = addonName` (`core/LauncherSetup.lua:47`) and `openSettings` (`:76`), and the console is built with `addonName = addonName` (`core/DebugLogSetup.lua`), so the lookup meets. `extraEntries` is an optional descriptor field.
- Media 13, SkinDefs 28, SkinDefsOthers 10 (v1.97.0 faces; v1.105.0 *Skin*, #82/#84): two faces; Ka0s Default's list rows and seven skins' `icon.hot` move. This addon's tokens follow `list.sel`, `bar.fill` and `bar.bg` only (`core/SkinSetup.lua:93-102`), and its degraded fallback copies no `list.stripe`, `list.hover` or `icon.hot`, so nothing here re-copies.
- Tooltip 1 and the library's own tooltip sites (#92), OptionsSkinPicker 12 / Queue 1, PerfPanel 14, the sim panel: library-internal; visible changes reach this addon on the copy (smoke lines).
- Kit 57 (#75 half 2): a registered frame is held until it unregisters. No suite here went red on it. `LIBRARY_MARKS` gains `settings`, already declared here.
`grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit` finds no host attach site.

### Blockers
None. The two red parity cases on the first run were the stub members every host with a by-name parity case owes (design section 5), not contract changes:
- `parity: the DebugLog stub carries the whole live surface`: `Report is missing (live: function); Serialize is missing (live: function)`.
- `parity: the Options stub carries every helper the degraded build can reach`: `SideTabs is missing (live: function)`.

## 3h Span
`vendored.txt` minus `recorded.txt` names v1.94.0 (vendored by 2a6c47c, no bundle). A one-tag span bundle, `docs/revendor/2026-11-16-v1.94.0-v1.94.0/`, is written beside this one.

## 3i Icon declaration
`grep -n 'LibKa0s icons:' CLAUDE.md` -> line 43, directly under the provenance line: `chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high.` Kept as written: the run pre-decides no icon change, and `settings` (v1.105.0's new library mark) is already declared. No `LibKa0s sounds:` line: no line means none, so `media/sounds/` prunes to nothing. Hand lists have drifted before (KickCD `tests/test_mediasetup.lua:28`, WhatGroup `tests/test_mediasetup.lua:19`); the owner's in-client smoke is the backstop.

Prune: `lua <extract>/tools/prune-icons.lua .` removed 362 paths (214 icon entries, the `phosphor/` and `game-icons/` folders counted once each, and 148 callout sound paths); a second run reported `12 icon(s) declared; kept 13 file(s), removed 0` and `sounds none ... kept 0 file(s), removed 0`.

## 3j Tests that assume the whole icon folder
`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'`: `tests/test_optionssetup.lua:295-296` opens `info.tga`, a declared name. No whole-catalog loop.

## Dead stub mirrors
`grep -rn '__releaseChrome' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit`: none.
