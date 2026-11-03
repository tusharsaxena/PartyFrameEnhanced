Delta: LibKa0s v1.84.0 -> v1.85.0

Part of Ka0sAddonsCommonTasks `docs/2026-11-01-FULL_SKINNING/` (FS-PF-RV). The tag is local, cut by that run's `FS-REL`, at library commit `9776130`.

## Base (3a)

`grep -n '[Bb]undles' CLAUDE.md` names v1.84.0, and `git log -1 --format=%H -- libs/LibKa0s tests/_kit` gives `ccad475`, whose line names v1.84.0 too. No correction owed.

## Per-file minors (3c), moved files only

`for f in LibKa0s.xml files: grep the [A-Z_]*MINOR constant, old against tag`

| File | old | new |
|---|---|---|
| Glow.lua | 1 | 2 |
| Toast.lua | 1 | 2 |
| Skin.lua | 11 | 14 |
| SkinDefs.lua | 19 | 24 |
| SkinDefsOthers.lua | 1 | 6 |
| SkinPaint.lua | 13 | 16 |
| SkinPaintExtras.lua | 7 | 15 |
| SkinPaintControls.lua | 11 | 14 |
| SkinEUI.lua | 2 | 3 |
| SkinAce.lua | 6 | 9 |
| Widgets.lua | 17 | 20 |
| WidgetsReorder.lua | 3 | 5 |
| WidgetsDragHandle.lua | 10 | 12 |
| WidgetsLineChart.lua | 5 | 6 |
| WidgetsAutocomplete.lua | 5 | 6 |
| WidgetsCopyWindow.lua | 2 | 4 |
| DebugLogWindow.lua | 2 | 3 |
| Launcher.lua | 5 | 6 |
| OptionsWidgets.lua | 41 | 44 |
| OptionsIds.lua | 6 | 7 |
| OptionsIdList.lua | 7 | 8 |
| OptionsTabs.lua | 13 | 15 |
| OptionsCompose.lua | 16 | 17 |
| OptionsScroll.lua | 10 | 13 |
| OptionsNav.lua | 4 | 5 |
| OptionsDrawer.lua | 4 | 5 |
| OptionsKeybinds.lua | 6 | 7 |
| OptionsAppearance.lua | 5 | 6 |
| OptionsSkinPicker.lua | 5 | 7 |
| OptionsMedia.lua | 3 | 4 |
| PerfPanel.lua | 11 | 12 |
| SimPanel.lua | 9 | 10 |
| SimPanelRender.lua | 1 | 2 |

No file is behind the old tag: no cross-major skew.

## Kit (3f)

`grep -n 'Kit.VERSION' tests/_kit/framework.lua`: revision 47 -> 49. The two payloads move together.

## Consumption (3e)

No lookup was added or removed by this commit.

## Blockers (3g, 3j)

- **Facades.** `docs/releasing.md` step 8 and `CHANGELOG.md` v1.85.0, "What a consumer owes": the degraded Skin facade (`core/SkinSetup.lua`) gains `Mark`, `MarkText`, `HudTextColor`, `HudLabelColor`, `BarFillColor`, `HudShadow`, `BarGloss` and `HudFont`; the Options stub (`settings/OptionsSetup.lua`) gains `LabelFont`. `tests/test_surface_parity.lua` was red on both before the fix. Fixed in the re-vendor commit.
- **Icons.** `docs/releasing.md` "Step 8 for v1.85.0": `chevron-down, chevron-up, close, confirm, info, move, reset, volume-high`, joined to this addon's `clear, close, copy, eye, settings`. Decided by the plan.
- No `__Attach*` site moved under this addon.

## Unrecorded tags (3h)

v1.80.0 to v1.83.0 are recorded by the span bundle `2026-10-31-v1.80.0-v1.83.0`; nothing unrecorded.
