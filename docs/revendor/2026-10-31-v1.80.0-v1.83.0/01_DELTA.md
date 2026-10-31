Delta: LibKa0s v1.80.0 -> v1.83.0 (span: v1.80.0 v1.81.0 v1.82.0 v1.83.0)

# LibKa0s v1.80.0 to v1.83.0: the consolidated span (PartyFrameEnhanced)

Written 2026-10-31 by `FX-PF-DOCS` of the findings remediation, as the revendor-libka0s Step 3h
back-fill. The re-vendors of the skinning rollout, the skin library follow-ups, the skin fonts run and
the font pickers run wrote no `docs/revendor/` bundle. Nothing is decided here in retrospect. v1.78.0
and v1.79.0 are not in the span: this addon went from v1.77.0 to v1.80.0 and never vendored them.

## The listing

```sh
horizon=$(ls -1 docs/revendor | sort | head -1 | cut -c1-10)     # 2026-09-23
# vendored: every tag the provenance line named at a payload commit or a CLAUDE.md roll since the horizon
# recorded: every tag a docs/revendor/ bundle names
grep -vxF -f recorded.txt vendored.txt
v1.80.0
v1.81.0
v1.82.0
v1.83.0
```

(The full script is revendor-libka0s Step 3h.)

## The carriers

| Tag | Library tag / commit | Carrier commit here | Non-payload files it touched |
|---|---|---|---|
| v1.80.0 | `315c79e` / `912f1b4` | `5c5448a` 2026-10-29 `PF-RV: Re-vendor LibKa0s v1.80.0 from the local tag` | `CLAUDE.md`, `README.md`, `docs/smoke-tests.md`, `settings/OptionsSetup.lua` |
| v1.81.0 | `56ebc24` / `aefeba9` | `4d60bb0` 2026-10-30 `PF-RV: Re-vendor LibKa0s v1.81.0 from the local tag` | `CLAUDE.md`, `docs/smoke-tests.md` |
| v1.82.0 | `5eca031` / `277081f` | `943a978` 2026-10-30 `PF-01: Re-vendor LibKa0s v1.82.0 from the local tag` | `CLAUDE.md`, `core/SkinSetup.lua`, `settings/OptionsSetup.lua`, `tests/test_skin_hud.lua`, `tests/test_skinsetup.lua` |
| v1.83.0 | `c88588a` / `6c816fd` | `491abb9`, then `72027c4` and `531f3bc` 2026-10-31, as the tag was re-cut (LK-A1 to LK-A3) | `491abb9`: the outline default and faces move, listed in its commit. The two re-cuts touched only the payloads |

The library columns are the tags as they stand today. `tests/test_vendor_sync.lua` holds this tree
against v1.83.0 on every run; the earlier carriers were not re-compared for this bundle.

## Per-file minors (LibStub), v1.77.0 -> v1.83.0

Read from each tag's `LibKa0s/` files.

| File | v1.77.0 | v1.80.0 | v1.81.0 | v1.82.0 | v1.83.0 |
|---|---|---|---|---|---|
| `Core.lua` | 12 | 13 | 14 | 14 | 14 |
| `DebugLog.lua` | 21 | 22 | 22 | 22 | 22 |
| `DebugLogDiagnostics.lua` | 3 | 5 | 5 | 5 | 5 |
| `DebugLogWindow.lua` | absent | 1 | 2 | 2 | 2 |
| `Media.lua` | 5 | 9 | 9 | 10 | 11 |
| `Options.lua` | 30 | 34 | 34 | 34 | 34 |
| `OptionsAppearance.lua` | absent | 3 | 3 | 4 | 5 |
| `OptionsCombat.lua` | 2 | 3 | 3 | 3 | 3 |
| `OptionsCompose.lua` | 11 | 13 | 13 | 14 | 14 |
| `OptionsDrawer.lua` | 1 | 2 | 3 | 3 | 3 |
| `OptionsIdList.lua` | 5 | 6 | 7 | 7 | 7 |
| `OptionsIds.lua` | 3 | 4 | 5 | 5 | 5 |
| `OptionsKeybinds.lua` | 4 | 5 | 6 | 6 | 6 |
| `OptionsMedia.lua` | absent | absent | absent | absent | 1 |
| `OptionsNav.lua` | 2 | 3 | 4 | 4 | 4 |
| `OptionsRegistry.lua` | 2 | 4 | 4 | 4 | 4 |
| `OptionsScroll.lua` | 4 | 8 | 9 | 9 | 9 |
| `OptionsSkinPicker.lua` | absent | 1 | 2 | 3 | 4 |
| `OptionsSwitch.lua` | absent | absent | absent | 1 | 1 |
| `OptionsTabs.lua` | 9 | 10 | 11 | 11 | 11 |
| `OptionsWidgets.lua` | 34 | 35 | 36 | 37 | 38 |
| `PerfPanel.lua` | 9 | 10 | 11 | 11 | 11 |
| `SimPanel.lua` | 6 | 7 | 8 | 8 | 8 |
| `Skin.lua` | absent | 7 | 8 | 9 | 10 |
| `SkinAce.lua` | absent | 4 | 4 | 4 | 5 |
| `SkinDefs.lua` | absent | 15 | 16 | 17 | 18 |
| `SkinEUI.lua` | absent | 2 | 2 | 2 | 2 |
| `SkinPaint.lua` | absent | 11 | 12 | 13 | 13 |
| `SkinPaintControls.lua` | absent | 9 | 10 | 11 | 11 |
| `SkinPaintExtras.lua` | absent | 5 | 6 | 7 | 7 |
| `Toast.lua` | absent | 1 | 1 | 1 | 1 |
| `Widgets.lua` | 15 | 16 | 17 | 17 | 17 |
| `WidgetsAutocomplete.lua` | 3 | 4 | 5 | 5 | 5 |
| `WidgetsCopyWindow.lua` | absent | 1 | 2 | 2 | 2 |
| `WidgetsDragHandle.lua` | 5 | 6 | 7 | 8 | 8 |
| `WidgetsLineChart.lua` | 3 | 4 | 5 | 5 | 5 |
| `WidgetsReorder.lua` | 1 | 2 | 3 | 3 | 3 |
| every other file (18) | unchanged | unchanged | unchanged | unchanged | unchanged |

## Test kit

Revision 42 at v1.77.0, 44 at v1.80.0 and v1.81.0, 45 at v1.82.0, 46 at v1.83.0.

## Consumption

What each tag owed this addon is written in its carrier's commit message. The Options stub gained
`AppearanceTab`, `AppearanceRows`, `SkinPicker`, `HideSkinPicker` (v1.80.0) and `SkinVerb` (v1.82.0).
The degraded skin facade gained `FontFlags` and `HudFontSize` (v1.82.0). The adoptions themselves were
the runs' own items, and their records are the Ka0sAddonsCommonTasks bundles
`docs/2026-10-29-SKINNING_ROLLOUT`, `docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS`,
`docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK` and `docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES`.
