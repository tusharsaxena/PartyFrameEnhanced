# Summary (PartyFrameEnhanced)

LibKa0s v1.66.0 -> v1.67.0 from the local tag (`0bccf4c`), base taken from the CLAUDE.md provenance
line and confirmed byte for byte. Core 9 -> 10, Options 27 -> 28 and OptionsIdList 2 -> 3; every other
file unchanged. `tests/_kit` stays at kit revision 35 (byte-identical). Both payloads copied whole;
nothing removed upstream, so nothing deleted. `LibKa0s.xml` is unchanged, so the TOC needs no row.

- **Span bundle:** none needed; the last bundle, `2026-10-01-v1.66.0/`, records the base tag.
- **Free (class A):** Core 10's grip, which the library's three windows use with no new field and so
  draw as before; Options 28's docblock correction.
- **Contract blockers:** none (see `01_DELTA.md` 3g).
- **Candidates:** the Options descriptor's `addonName` goes to `CA-PF-NM`; the `MakeResizable` fields
  have no adoption item here (none), since the addon builds no resizable window of its own. No
  interview; the census-adoption bundle decided both.
- **Consumer fix:** none. No library change broke a consumer test.
- **Docs:** CLAUDE.md provenance, `docs/ARCHITECTURE.md`'s two version-now lines and `docs/debug.md`'s
  vendored-release citation rolled to v1.67.0; `docs/smoke-tests.md` gains INSTALL-4 (a clean load on
  the vendored library, index range INSTALL-1 – 4) and its Pending sign-off row, which also points at
  DIAG-10 to DIAG-12 for the Core 10 grip. `docs/test-cases.md` regenerated with no change, and the
  README badge stays 453/454: the totals did not move.

Gate before the copy: tests 453 passed, 0 failed, 1 skipped (454); luacheck 0 / 0 in 79 files.

Gate at the commit:

- tests: 453 passed, 0 failed, 1 skipped, 454 total
- luacheck: 0 warnings / 0 errors in 79 files
- complexity (sighted, `bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle`): pass,
  maxCcn 14, 0 warnings, no blind file, 1601 functions
- vendor parity: `diff -r` of both payloads against `git archive v1.67.0` is empty, as is
  `diff -r --strip-trailing-cr ../LibKa0s/LibKa0s libs/LibKa0s`; `tests/test_vendor_sync.lua` green
