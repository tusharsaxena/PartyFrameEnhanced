# 05 — Summary (PartyFrameEnhanced)

LibKa0s v1.71.0 -> v1.75.0, copied from the local annotated tag (`eae0ee5`, commit `265a89e`). The
base, v1.71.0, comes from the CLAUDE.md provenance line and agrees with the last payload commit
`01f0680`. Kit revision 38 -> 41. The provenance line and the new `LibKa0s icons:` line were rolled in
the same commit as the bytes.

- **Minors:** Core 11, Item 3, Media 5, Widgets 13, DebugLog 20, DebugLogDiagnostics 3, Options 29,
  OptionsIdList 5, OptionsTabs 9, Perf 15 and PerfPanel 7. New files: MediaIcons 1, OptionsDrawer 1,
  Glow 1, Sim 1, SimTimeline 1 and SimPanel 1. The other 23 files are unchanged. The kit gains
  `latch.lua`. Nothing was deleted outside the icon prune, and there is no cross-major skew.
- **Span bundle:** none. v1.72.0-v1.74.0 were never vendored here.
- **Delivered with the copy (class A):** Perf 15's `false` bucket, the Options 29 refresh that keeps
  scroll position, and kit 39-41.
- **Contract blockers (3g), fixed in the re-vendor commit:** Options surface parity (`Drawer`, now on
  the no-caller exemption row), and `tests/test_optionssetup.lua`'s `info.tga` assertion, which now
  checks the declaration only when an IdList is drawn. Neither `__releaseChrome` nor any other dead
  mirror existed here.
- **Icons:** the line `LibKa0s icons: clear, close, copy.` was written under the provenance line, with
  no split needed. The prune kept 4 files (3 Open Iconic marks and their license) and removed 5,836:
  the rest of Open Iconic and all of Phosphor and Game-icons.
- **Credits:** README `## Credits` gains an Open Iconic sentence (MIT, its license path). No Phosphor or
  Game-icons line, because neither ships.
- **Docs:** `docs/ARCHITECTURE.md` now says the whole-folder vendoring excludes `media/icons/`, and
  that Glow and Sim are vendored but not wired. `docs/test-cases.md` was regenerated: one case was
  renamed, Total stays 469 with `Skipped | 1`, and the README badge stays 469/469. In
  `docs/smoke-tests.md`, INSTALL-4 now lists v1.75.0's minors and has an icon step, and its Result is
  reset to owed.
- **Adopted:** nothing. **Not adopted in this run:** Drawer, SearchBox, TestStrip,
  Item.BonusIDsFromLink, Glow and Sim; StepPanel was withdrawn upstream. **Declined:** nothing; no
  interview was held and no issue was filed.
- **Smoke owed (the owner runs it):** INSTALL-4 on v1.75.0, a clean load plus `/pfe config`,
  `/pfe status` and `/pfe unlock`. Also its icon step: the console's Copy, Clear and close, the copy
  window's close and the perf panel's close all draw as icons.
- **Gate after the copy and prune** (every run through `ka0s-bounded`): `lua tests/run.lua` gave 469
  passed, 0 failed, 1 skipped, including `tests/test_vendor_sync.lua`'s three cases (payloads match
  v1.75.0, icon folder equals the declaration, runner 100755). `luacheck .` gave 0 warnings and 0
  errors in 79 files. Complexity is a release check and was not run here.
