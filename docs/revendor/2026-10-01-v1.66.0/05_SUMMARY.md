# Summary (PartyFrameEnhanced)

LibKa0s v1.65.0 -> v1.66.0 from the local tag (`e4c5ef7`), base taken from the CLAUDE.md provenance
line and confirmed byte for byte. Widgets 11 -> 12, DebugLog 18 -> 19, Slash 18 -> 19, OptionsWidgets
33 -> 34, OptionsTabs 7 -> 8, Perf 13 -> 14, and four new secondary files (`WidgetsReorder` 1,
`SlashParse` 1, `PerfSampler` 1, `PerfCommands` 1); every other file unchanged. `tests/_kit` moves to
kit revision 35. Both payloads copied whole; nothing removed upstream, so nothing deleted. The TOC
loads the library through `LibKa0s.xml`, so it needs no new row.

- **Span bundle:** `2026-10-01-v1.64.0-v1.65.0/` records the two tags (v1.64.0, v1.65.0) this addon
  vendored on 2026-09-30 and 2026-10-01 with no bundle. No base correction was needed.
- **Free (class A):** the host `L` in the dispatcher's parse refusals, declared Perf parents with zero
  counts, the four peels, DebugLog 19's helper split, and kit 35's sighted complexity suite.
- **Contract blockers:** none (see `01_DELTA.md` 3g).
- **Adopted:** nothing. **Declined:** nothing. **Unreached:** the four class B candidates in
  `02_CANDIDATES.md`, deferred to `GI-LK-13` by spec S4.
- **Consumer fix in the re-vendor commit:** `tests/test_surface_parity.lua`'s CliProfile /
  ProfileSwitch case built its call list inside a `for ... in` header, which the sighted suite reports
  as blind (28 of 29 functions listed). The table is hoisted into a local; the case is unchanged.
- **Docs:** `tests/run.lua` wires `test_lizard_sighted`; `docs/test-cases.md` regenerated; README badge
  428/429; CLAUDE.md provenance, `docs/ARCHITECTURE.md`'s two version-now lines and `docs/debug.md`'s
  DebugLog citation (19.2.1) rolled; the raw `lizard -l lua ...` command in `docs/testing.md`,
  `docs/automated-tests/README.md` and `DEPENDENCIES.md` replaced with the runner's sighted complexity
  suite. CLAUDE.md's green-gate line quotes no lizard command, so it is unchanged.

Gate before the copy: tests 420 passed, 0 failed, 1 skipped (421); luacheck 0 / 0 in 77 files.

Gate at the commit:

- tests: 428 passed, 0 failed, 1 skipped, 429 total (the eight new cases are kit 35's
  `test_lizard_sighted`, including the live-lizard parity case, which ran)
- luacheck: 0 warnings / 0 errors
- complexity (sighted, `bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle`): pass,
  maxCcn 14, 0 warnings, blindFiles 0, 1509 functions
- vendor parity: `diff -r` of both payloads against `git archive v1.66.0` is empty;
  `tests/test_vendor_sync.lua` green
