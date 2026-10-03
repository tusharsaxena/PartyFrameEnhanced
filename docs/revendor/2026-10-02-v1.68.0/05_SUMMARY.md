# Summary (PartyFrameEnhanced)

LibKa0s v1.67.0 -> v1.68.0 from the local annotated tag (`6d83731`, commit `cc9f5eb`). The base was
taken from the CLAUDE.md provenance line and confirmed byte for byte against `git archive v1.67.0`.
WidgetsDragHandle 3 -> 4 (Widgets key 12.1.3 -> 12.1.4); every other file is unchanged. `tests/_kit`
stays at kit revision 35 and is byte-identical. Both payloads were copied whole. Nothing was removed
upstream, so nothing was deleted. `LibKa0s.xml` is unchanged, so the TOC needs no row.

- **Pre-flight / span bundle:** Step 0 `ok`. 3h printed no unrecorded tag, so no span bundle was
  written.
- **Free (class A):** the drag handle's evaluate/draw split, which leaves a hook-less host on minor 3's
  calls. This addon builds no drag handle, so nothing changes on screen.
- **Contract blockers:** none. Widgets, the only major that moved, is not looked up by this addon
  (see `01_DELTA.md` 3e and 3g).
- **Adopted:** nothing.
- **Declined:** `tooltipPlace` / descriptor `place`, as not applicable because the addon has no drag
  strip. No GitHub issue was filed, because this is not a gap (`03_DECISIONS.md`).
- **Skipped / unreached:** none. `04_EXECUTION_PLAN.md` is not written, since nothing was adopted.
- **Docs:** the CLAUDE.md provenance line, `docs/ARCHITECTURE.md`'s two version-now lines (plus one
  sentence on v1.68.0) and `docs/debug.md`'s vendored-release citation are rolled to v1.68.0.
  `docs/smoke-tests.md` INSTALL-4 now names v1.68.0, and its Pending sign-off row is restated for
  v1.68.0. The test totals did not move, so `docs/test-cases.md` and the README badge (454/455) are
  unchanged.

Gate before the copy: tests 454 passed, 0 failed, 1 skipped (455); luacheck 0 / 0 in 79 files.

Gate at the commit (Lua runs through `ka0s-bounded`):

- tests: 454 passed, 0 failed, 1 skipped, 455 total, including `tests/test_vendor_sync.lua`'s two
  cases ("libs/LibKa0s is the LibKa0s release CLAUDE.md says this addon bundles", "tests/_kit is the
  test kit that shipped with that release")
- luacheck: 0 warnings / 0 errors in 79 files (`.luacheckrc` excludes `libs/` and `tests/_kit/`; no
  host file changed)
- complexity (sighted, `bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle`): pass,
  0 warnings, max CCN 14, 1602 functions
- vendor parity: `diff -r` of both payloads against `git archive v1.68.0` is empty in both readings

In-client smoke (INSTALL-4 on v1.68.0) is the owner's to run.
