# 05 — Summary (PartyFrameEnhanced)

LibKa0s v1.83.0 -> v1.84.0, copied from the local tag (commit `e917ccd`). The base comes from the
`CLAUDE.md` provenance line and agrees with the last payload commit. Kit revision 46 -> 47. The minor
table is in `01_DELTA.md`; there is no cross-major skew and nothing was deleted outside the icon prune.

- **Span bundle:** none; no tag went unrecorded. No base correction.
- **Delivered with the copy (class A):** nothing a player sees here.
- **Contract blocker (3g):** the Options degradation stub owed `PositionBlock`. Fixed in the re-vendor
  commit, in `settings/OptionsSetup.lua`.
- **Icons:** `LibKa0s icons: clear, close, copy, eye, settings.` kept. The prune kept 6 files and
  removed 5,834. No provenance split.
- **Credits:** unchanged. No dead stub mirror. No refresh file.
- **Consumer pins:** this addon hand-types no LibKa0s file list and pins no minor that moved.
- **Adopted:** nothing. **Declined:** every candidate, by the brief, in `03_DECISIONS.md`; no issue
  filed.
- **LibKa0s#67:** none. Anchor mode, the one selector that picks a group, has used `shownWhen` since
  v1.45.0. The remaining dims stay `disabledIf` under options-ui §22, "Hidden is not disabled": the
  marker rows and health rows follow a check box, and Width and Match party frame width are columns
  inside a shown group.
- **LibKa0s#68:** fits by computation. `modules/Anchor.lua` anchors its label at one point with no
  width, so the text sets its own width, and the grip is pinned to the label's corners with a 4 px
  margin. Nothing can cut the title. The in-client sweep and its screenshots are the owner's.
- **Docs:** `docs/smoke-tests.md` INSTALL-4 lists v1.84.0's minors, and its Result is empty.
- **Smoke owed (the owner runs it):** INSTALL-4 on v1.84.0.
- **Gate after the copy, prune and stub fix** (through `ka0s-bounded`): `lua tests/run.lua` 565 passed,
  0 failed, 1 skipped; `luacheck .` 0 warnings / 0 errors in 90 files.
