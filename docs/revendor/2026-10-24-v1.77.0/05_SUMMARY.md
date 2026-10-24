# 05 — Summary (PartyFrameEnhanced)

LibKa0s v1.76.0 -> v1.77.0, copied from the local annotated tag (`7380d36`, commit `78240f7`). The
base, v1.76.0, comes from the CLAUDE.md provenance line and agrees with the last payload commit
`a24e064`. Kit revision 41 -> 42. The provenance line was rolled in the same commit as the bytes.

- **Minors:** Core 11 -> 12, DebugLog 20 -> 21, PerfPanel 8 -> 9, SimPanel 5 -> 6, Widgets 14 -> 15,
  WidgetsDragHandle 4 -> 5, WidgetsAutocomplete 2 -> 3, Options 29 -> 30, OptionsIds 2 -> 3,
  OptionsCombat 1 -> 2, OptionsCompose 7 -> 8, and OptionsKeybinds new at 3. The other 29 files are
  unchanged. Nothing was deleted outside the icon prune, and there is no cross-major skew.
- **Span bundle:** none; no tag went unrecorded. No base correction.
- **Delivered with the copy (class A):** the debug console and the perf panel are toplevel and raise
  a shown confirmation; the settings dropdown menu is clamped to screen.
- **Contract blocker (3g):** the Options degradation stub owed `StrataTooltip`, `KeybindingsTab`,
  `KeybindRows` and `KEYBINDS_UNCHANGED` (`Kit.assertSurfaceParity` failed after the copy). Fixed in
  the re-vendor commit, in `settings/OptionsSetup.lua`'s stub.
- **Icons:** `LibKa0s icons: clear, close, copy.` kept. The prune kept 4 files (3 Open Iconic marks
  and their license) and removed 5,836: the rest of Open Iconic and all of Phosphor and Game-icons.
  No provenance split.
- **Credits:** unchanged; the shipped sets did not move. No dead stub mirror.
- **Refresh files:** none.
- **Adopted here:** nothing. **Planned in `PF-ZS`:** `O.StrataTooltip` on the `general.strata` row
  and the kit's `mock_layers.lua`. **Deferred (run 2026-10-24):** the Keybindings tab and the kit's
  binding mock and checks (no window, outside the keybinding scope), `Core.RaiseStaticPopups` for a
  host window, and WidgetsDragHandle 5's fields (no DragHandle). Sim stays settled (LibKa0s#54).
  **Declined:** nothing; no interview was held and no issue was filed.
- **Docs:** `docs/smoke-tests.md` INSTALL-4 now lists v1.77.0's minors, and its Result is reset to
  owed.
- **Smoke owed (the owner runs it):** INSTALL-4 on v1.77.0.
- **Gate after the copy, prune and stub fix** (every run through `ka0s-bounded`): `lua tests/run.lua`
  gave 469 passed, 0 failed, 1 skipped (470), including `tests/test_vendor_sync.lua`'s cases (payloads
  match v1.77.0, icon folder equals the declaration). Before the stub fix it gave 468 passed and 1
  failed (the Options surface parity case). `luacheck .` gave 0 warnings and 0 errors in 79 files.
  Complexity is a release check and was not run here.

## Re-vendor after the tag moved (M3)

The local tag v1.77.0 was moved by LibKa0s `LK-95` (the M3 settings-layout surfaces) before its
release was pushed (`git -C ../LibKa0s ls-remote --tags origin v1.77.0` prints nothing), so this is
a refresh of the same tag, not a new re-vendor, and it writes no new bundle.

- **Old tag:** tag object `7380d36`, commit `78240f7b2d69df27b74fc9280cbfbf7b95dd4f1f` (as recorded above).
- **New tag:** tag object `b2b8ee25c5f9fa26db146254bf786b366dec986b`, commit
  `afae2f75cb7ff61c57156d9a3d8a6b2b9f4c5e10` (`git -C ../LibKa0s rev-parse v1.77.0^{}`).
- **Minors that moved:** OptionsCompose 8 -> 11 (minor 9: MasterControls `notes`,
  `resetPositionTooltip` and `lockIsPreview`; minor 10: the group composers' `tooltips`; minor 11:
  `O.ResetAllTooltip(tail)`). It is the only file that changed between the two commits under
  `LibKa0s/` and `testkit/`; the kit revision stays 42 and the provenance line stays v1.77.0.
- **Copy and prune:** both payloads copied whole from `git archive v1.77.0 LibKa0s testkit tools`;
  both diffs were empty before the prune. The tag's `tools/prune-icons.lua` kept 4 files (clear,
  close, copy and the license) and removed 5,836, as before. Credits unchanged.
- **Contract blocker:** `Kit.assertSurfaceParity` failed after the copy (475 passed and 1 failed: the Options
  stub lacked `ResetAllTooltip`). Fixed in the same commit with an inert
  `Helpers.ResetAllTooltip` returning an empty string in `settings/OptionsSetup.lua`'s stub.
- **Adopted here:** nothing; `PF-LY` adopts the layout surfaces.
- **Docs:** `docs/smoke-tests.md` INSTALL-4 now lists OptionsCompose 11; its Result stays owed.
- **Gate** (through `ka0s-bounded`): `lua tests/run.lua` gave 476 passed, 0 failed, 1 skipped (477);
  before the stub fix 475 passed and 1 failed. `luacheck .` gave 0 warnings and 0 errors in 80 files.
