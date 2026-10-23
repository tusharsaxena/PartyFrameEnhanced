# 05 — Summary (PartyFrameEnhanced)

LibKa0s v1.75.2 -> v1.76.0, copied from the local annotated tag (`546e284`, commit `9949368`). The
base, v1.75.2, comes from the CLAUDE.md provenance line and agrees with the last payload commit
`8e069a8`. Kit revision 41, unchanged. The provenance line was rolled in the same commit as the bytes.

- **Minors:** Widgets 13 -> 14, SimTimeline 2 -> 3, SimPanel 4 -> 5. The other 37 files are
  unchanged. Nothing was deleted outside the icon prune, and there is no cross-major skew.
- **Span bundle:** `2026-10-23-v1.75.1-v1.75.2/`, two tags (v1.75.1, v1.75.2), both carried by
  plain re-vendor commits with nothing adopted. No base correction.
- **Delivered with the copy (class A):** nothing this host reaches; neither moved major is consumed.
- **Contract blockers (3g):** none.
- **Icons:** `LibKa0s icons: clear, close, copy.` kept. The prune kept 4 files (3 Open Iconic marks
  and their license) and removed 5,836: the rest of Open Iconic and all of Phosphor and Game-icons.
  No provenance split.
- **Credits:** unchanged; the shipped sets did not move. No dead stub mirror.
- **Refresh files:** none.
- **Adopted:** nothing. **Not adopted in this run:** `W.TestStrip`'s `kind = "sim"` (no strip here),
  and Sim (settled, LibKa0s#54). **Declined:** nothing; no interview was held and no issue was filed.
- **Docs:** `docs/smoke-tests.md` INSTALL-4 now lists v1.76.0's minors (Widgets 14, SimTimeline 3,
  SimPanel 5), and its Result is reset to owed.
- **Smoke owed (the owner runs it):** INSTALL-4 on v1.76.0.
- **Gate after the copy and prune** (every run through `ka0s-bounded`): `lua tests/run.lua` gave 469
  passed, 0 failed, 1 skipped (470), including `tests/test_vendor_sync.lua`'s cases (payloads match
  v1.76.0, icon folder equals the declaration, runner 100755). `luacheck .` gave 0 warnings and 0
  errors in 79 files. Complexity is a release check and was not run here.

## Addendum — the tag moved (PF-RV2, LK-91)

The local tag v1.76.0 was moved for LK-91 (step-panel labels bounded before the command column):
tag object `546e284` -> `2949c78`, commit `9949368` -> `7e81ff7`. `libs/LibKa0s` and `tests/_kit`
were copied whole again from the moved tag and `media/icons` re-pruned to the unchanged
`LibKa0s icons: clear, close, copy.` line (kept 4, removed 5,836).

- **Files that changed:** `libs/LibKa0s/PerfPanel.lua` (PerfPanel minor 7 -> 8: the step label is
  bounded LABEL_GAP short of the command and truncates with word wrap off) and
  `libs/LibKa0s/SimPanel.lua` (the same bound in the sim step panel; SimPanel 5, paired on the
  shell's minor, so no counter moved). `tests/_kit` is byte-identical. Every other file unchanged.
- **Delivered with the copy (class A):** the `/pfe perf` step panel's long labels now truncate
  before the command column. No member or contract changed; no blocker; nothing to adopt.
- **Docs:** `docs/smoke-tests.md` INSTALL-4's minor list now reads PerfPanel 8; its Result stays owed.
- **Gate after the copy and prune:** see the PF-RV2 commit body.
