# 02 — Candidates (PartyFrameEnhanced)

Sources: `git -C ../LibKa0s log --oneline v1.76.0..v1.77.0`, the LibKa0s `CHANGELOG.md` block v1.77.0
and its *What a consumer owes* lists, and the API documents at the tag for the majors whose minor
moved: `docs/api/Options/version-30.2.34.3.5.9.2.8.4.2.1.3-docs.md`,
`docs/api/Widgets/version-15.1.5.3.3-docs.md` and `docs/api/testkit/version-42-docs.md`.

The item spec forbids an interview here: the run's own items do the adoptions this run needs, and
for PartyFrameEnhanced that is `PF-ZS` (item 030, frame layering). The addon is not in the
keybinding scope (OWNER_SCOPE ruling 2: only the seven addons with a window), so it has no KB item.
Every other candidate is recorded as **deferred (run 2026-10-24)**, with no interview and no GitHub
issue.

- **Class A (delivered with the copy):**
  - The debug console and the `/pfe perf` panel are toplevel, and each raises a shown Blizzard
    confirmation from its `OnShow` (Core 12, DebugLog 21, PerfPanel 9). A tool window opened after
    *Reset all settings* no longer buries its popup.
  - The shared dropdown menu is clamped to screen (Widgets 15), so a settings dropdown near an edge
    keeps its menu on screen.
  - The Options degradation stub's four new members, a blocker fixed in the re-vendor commit
    (`01_DELTA.md` 3g), not a candidate.
- **Class B (needs a host change):**
  - `O.StrataTooltip(values[, strings])` (OptionsCompose 8; CHANGELOG *OptionsCompose minor 8*):
    `settings/General.lua`'s `general.strata` row. **Planned in `PF-ZS`** (its step 3), not here.
  - The kit's frame-layer recorder `mock_layers.lua` (kit revision 42): **planned in `PF-ZS`**
    (its step 2).
  - `O.KeybindingsTab`, `O.KeybindRows`, `O.KEYBINDS_UNCHANGED` (OptionsKeybinds 2), the kit's
    `mock_bindings.lua`, `Kit.assertBindingsXml` and `Kit.keybindThroughTab`: **deferred (run
    2026-10-24)**. The addon draws no window and ships no `Bindings.xml`, so it is outside the run's
    keybinding scope.
  - `Core.RaiseStaticPopups()` (Core 12) for a host's own window: **deferred (run 2026-10-24)**.
    The addon has no window of its own that shows over a popup.
  - WidgetsDragHandle 5's `spec.level`, `handle:ApplyLevel()` and `spec.ignoreParentAlpha`:
    **deferred (run 2026-10-24)**. The addon builds no DragHandle
    (`grep -rn DragHandle core modules settings` finds nothing).
- **Class C (whole module), not adopted:**
  - `LibKa0s-Sim-1.0` (SimPanel 6): settled. Ruled out in LibKa0s#54 (recorded in
    `2026-10-22-v1.75.0/02_CANDIDATES.md`): the addon draws on secure unit frames, which cannot show
    made-up units. v1.77.0 changes the panel's layering, not that premise.
