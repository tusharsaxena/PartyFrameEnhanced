Delta: LibKa0s v1.107.0 -> v1.108.0

Recorded for the re-vendor commit. Payload taken from the tag, never the sibling tree: `git -C ../LibKa0s archive v1.108.0 LibKa0s testkit tools` (tag fc7714f, commit 56c20b7, a local annotated tag on the library's `feat/2026-11-20-libka0s-94-97-99-100`, not yet on origin: `git -C ../LibKa0s ls-remote --tags origin v1.108.0` prints nothing, which this run expects). Run under the LibKa0s #94/#97/#99/#100 run (Ka0sAddonsCommonTasks `docs/2026-11-20-LIBKA0S_94_97_99_100/`), item SD-RV-PFE: the copy, provenance, icon-declaration and prune half of `/dev-copilot:wow-revendor-libka0s`. The adoption interview and issue filing are skipped by that run's design; the skin-defaults work is its own item, SD-SK-PFE.

## Step 0 pre-flight
For this addon: newest single-tag bundle `docs/revendor/2026-11-19-v1.107.0`, base v1.106.0, vendored-before v1.106.0@dbae93d: `ok`. No base correction is owed.

## 3a Base
- `grep -n '[Bb]undles' CLAUDE.md` -> `42:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.107.0 (MIT).` before the roll.
- `git log -1 --format=%H -- libs/LibKa0s tests/_kit` = 132b941 (the re-cut v1.107.0 re-vendor); its CLAUDE.md names v1.107.0. They agree.
- Range: `git -C ../LibKa0s log --oneline v1.107.0..v1.108.0` is 15 commits (SD-LK-94, SD-LK-99, SD-LK-100, SD-LK-97 Batches A to D with reviews, SD-LK-GUARD x3, SD-LK-REL x2).

## 3b/3c Per-file minors that moved (old = this addon, new = v1.108.0)
From the loop over the tag's `LibKa0s.xml`:
```
Core.lua                  18 -> 19
Callout.lua                4 -> 5
CalloutSettings.lua        5 -> 6
WaypointArrow.lua          2 -> 3
WaypointArrowSettings.lua  2 -> 3
Charts.lua                 2 -> 3
ChartsRender.lua           1 -> 2
SkinPaint.lua             19 -> 20
SkinPaintHud.lua           1 -> 2
SkinPaintControls.lua     18 -> 19
Widgets.lua               29 -> 30
WidgetsDropdown.lua        2 -> 3
WidgetsDragHandle.lua     15 -> 16
WidgetsDragHandleTip.lua   2 -> 3
WidgetsLineChart.lua       7 -> 8
WidgetsBar.lua             1 -> 2
OptionsCompose.lua        19 -> 20
```
Every other file matches v1.107.0, as the tag's CHANGELOG version block says. No file added or removed.

## 3d Diffs
After the copy and before the prune, `diff -rq <extract>/LibKa0s libs/LibKa0s` and `diff -rq <extract>/testkit tests/_kit` printed nothing. After the prune the only difference is the undeclared icons and the callout sounds, and `tests/test_vendor_sync.lua` is green. No `Only in libs/LibKa0s` line: nothing removed upstream.

## 3e Consumption map
`grep -rnE 'FontGroup|BorderGroup|BarGroup|ColorPair|ApplyBarFill|BarStyle|ContextMenu|Callout|WaypointArrow|Charts|OwnerWarnings|skinBands' . --include='*.lua'` outside `libs/` and `tests/_kit/`: the four composers, through `NS.Helpers` in `settings/ElementRows.lua` (Border, Font, Bar, Background); `S.BarGloss` in `modules/Element.lua:173`; `ApplyBarFill` and `BarStyle` only as degraded-facade no-ops in `core/SkinSetup.lua`. No Callout, WaypointArrow, Charts, `W.Bar`, `W.ContextMenu` or drag strip.

## 3f Kit revision
`grep -n 'Kit.VERSION'`: addon 57, tag 58. Both payloads move together.

## 3g Contract delta
- **OptionsCompose minor 20 (Batch A).** Every composer emits its companions unless the host opts out. This addon already passes `fromSkin = true` (`fromSkin = "bar"` on the border) and declares every color and shadow companion as an `extra` row, which the composer now finds and governs with (`declared(spec)`), so no path is added or duplicated: the 158-setting layout pin stays 158. One row moves: Font shadow is now `disabledIf` its companion (`shadowFromSkinRow`), as the Options document's *Moving to* says. Kept: it is what `modules/Element.lua` already draws (the stored shadow is not read while the companion is on). `tests/test_settings_layout.lua` re-pins the three `fontShadow` rows to `dim=true`, and `tests/test_skin_flip.lua` asserts Font shadow is governed by its companion instead of asserting no dim. Docs: `docs/schema.md`, `docs/settings-panel.md`, the `settings/ElementRows.lua` header.
- **SkinPaintHud minor 2 (`S.BarGloss` takes a Texture too).** This addon passes the StatusBar; both shapes answer. No change.
- **Test kit revision 58.** `test_skin_values` reads `return` triples now: three new hits, `modules/StandIn.lua:66` and `:75` (the stand-in's fallback hues, rows citing the stand-in like their neighbors) and `modules/Element.lua:357` (`return 1, 1, 1, 1` for a stored swatch that is no table, `category = "unreachable default"`). `test_skin_switch` gained its texture-falsifiability case and the per-family checks; every declared surface still passes. The guard's new fields (`expect`, `hold`, `clear`) are SD-SK-PFE's.
- Batch B, C and D surfaces (`W.BarStyle`, `S.ApplyBarFill`, Charts, Callout, WaypointArrow, `skinBands`, `W.OwnerWarnings`): no host here.

### Blockers
None beyond the two re-pins and three rows above, all fixed in the re-vendor commit.

## 3h Span
None: every vendored tag since the horizon has its bundle (v1.107.0 recorded by `2026-11-19-v1.107.0`).

## 3i Icon declaration
`grep -n 'LibKa0s icons:' CLAUDE.md` -> line 43, directly under the provenance line: `chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high.` Kept as written: v1.108.0 adds no library-drawn icon this addon wires. No `LibKa0s sounds:` line. Hand lists have drifted before (KickCD `tests/test_mediasetup.lua:28`, WhatGroup `tests/test_mediasetup.lua:19`); the owner's in-client smoke is the backstop.

Prune: `lua <extract>/tools/prune-icons.lua .` ended `sounds none (no LibKa0s sounds: line); kept 0 file(s), removed 362`. `libs/LibKa0s/media/icons/` holds 13 entries after it.

## 3j Tests that assume the whole icon folder
Unchanged from v1.107.0: `tests/test_optionssetup.lua:295-296` opens `info.tga`, a declared name.

## Dead stub mirrors
`grep -rn '__releaseChrome' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit`: none.
