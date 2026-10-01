# Candidates (PartyFrameEnhanced, LibKa0s v1.67.0)

Listed, **not interviewed**. The 2026-10-02 LibKa0s census adoption
(`Ka0sAddonsCommonTasks/docs/2026-10-02-LIBKA0S_CENSUS_ADOPTION/`, `01_DESIGN.md` D1 and D2, `items.tsv`)
already decides which item takes each new surface in every host, so this bundle records the mapping and
holds no interview. No issue is filed for anything below.

## A. Delivered on the re-vendor alone (not offered)

- **Core 10's grip, unchanged for callers that pass nothing new.** The debug console, the copy window
  and the perf panel build their grips through `Core.MakeResizable` with none of the three new fields,
  so they behave as at Core 9. Smoke `INSTALL-4` (with DIAG-10 to DIAG-12) confirms it in the client.
- **Options 28's docblock correction.** No behaviour.

## B. Host change required (candidates)

1. **Options descriptor `addonName` (Options 28 / OptionsIdList 3, LibKa0s#42).** Taken by
   **`CA-PF-NM`**: `settings/OptionsSetup.lua:1` keeps its first vararg (`local addonName, NS = ...`)
   and the descriptor at `settings/OptionsSetup.lua:40` passes `addonName = addonName`. Evidence:
   `docs/api/Options/version-28.2.34.2.3.8.1.7.4.2-docs.md` (LibKa0s), CHANGELOG v1.67.0, design D2.
   No visible effect here today: this addon draws no `O.IdList`, so no help mark exists for the name to
   reach. It protects the first one anyone adds.
2. **`MakeResizable`'s `canResize`, `onResizeStop` and `gripParent` (Core 10, LibKa0s#41).** This host's
   adoption item: **none**. The addon builds no resizable window of its own
   (`grep -rn MakeResizable --include='*.lua' . --exclude-dir=libs --exclude-dir=_kit`: none), so there
   is no grip to gate, persist or re-parent. Evidence: `docs/api/Core/version-10-docs.md`, "The resize
   grip" (LibKa0s); the adopting hosts are BankLedger (`CA-BL-01`), LootHistory (`CA-LH-01`) and
   MultiMeters (`CA-MM-02`).

## C. Whole-module adoption

None new: v1.67.0 adds no major. Pool, Item and Widgets remain reached through the library only.
