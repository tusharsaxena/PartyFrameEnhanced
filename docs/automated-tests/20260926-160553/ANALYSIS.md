# Analysis — 20260926-160553

- **Addon:** PartyFrameEnhanced 1.0.1
- **Verdict:** green
- **Commit:** 8250bd2 (master), clean
- **Previous run:** 20260924-110428

## Headline

All four suites passed and the verdict is green ([`manifest.json`](manifest.json)). Since the previous run
(21 commits: the LibKa0s v1.57.0 → v1.61.0 re-vendors, the diagnostics report and the NavRail stub),
the suite grew 342 → 383 cases and lint scope grew 72 → 75 files. Total NLOC and function count rose
while avg CCN edged down (2.2 → 2.1) and max CCN held at 14, so nothing got denser. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260924-110428 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 75 files | [`lint.txt`](lint.txt) | files 72 → 75; still 0/0 |
| tests | pass | 383 passed, 0 skipped, 0 failed, 383 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 342 → 383 (+41); still 0 skipped, 0 failed |
| perf | pass (recorded; gates the tag, not the run or commit) | 9 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | same 9 scenarios; api/iter and bytes/iter identical |
| complexity | pass (recorded; gates the tag, not the run or commit) | see below | [`complexity.txt`](complexity.txt) | see What moved |

| Metric | Value |
|---|---|
| Total NLOC | 9976 |
| Functions | 1318 |
| Avg NLOC / function | 6.3 |
| Avg CCN | 2.1 |
| Max CCN | 14 |
| Avg tokens / function | 47.3 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |

All values are from [`manifest.json`](manifest.json) `suites.complexity` and the footer of
[`complexity.txt`](complexity.txt). Every suite is a clean pass, so no per-suite failure paragraph is owed.

## What moved

- **lint:** 0/0 held; scope rose 72 → 75 files ([`lint.txt`](lint.txt)). The three new authored `.lua`
  files since `c888121` are `modules/Diagnostics.lua`, `tests/mock_menu.lua` and
  `tests/test_diagnostics.lua`.
- **tests:** 342 → 383 passed, 0 skipped both runs ([`tests.txt`](tests.txt)).
- **perf:** the same 9 scenarios. `api/iter` and `bytes/iter` match the previous run on every
  scenario (for example `castStartStop` 55.0 / 3.6, `settingsDrag` 25.0 / 925.9), and `SetPoint`
  calls/iter are 0.0 throughout ([`perf.txt`](perf.txt)). The ms/iter timings were slightly lower on
  every scenario, but they are for orientation only and are not compared across runs.
- **complexity:** NLOC 9154 → 9976 (+822), functions 1192 → 1318 (+126), avg NLOC/function 6.3 → 6.3,
  avg CCN 2.2 → 2.1, avg tokens 47.4 → 47.3, max CCN 14 → 14, warnings 0 → 0. The totals grew and the
  averages held or fell, so this is growth, not densification. The highest scorer is still
  `NS.ResolveColor` (CCN 14, `core/CoreSetup.lua:37`), one below the threshold. The next ones are
  `stubPrepare` (13, `settings/Schema.lua:130`) and four functions at 12, all at the same CCN as
  last run ([`complexity.txt`](complexity.txt)).
- The largest authored file is `tests/test_launcher.lua` at 578 lines, well below the 1000-line
  notice band.

Of the 11 bundles in `docs/automated-tests/`, one earlier bundle (`20260915-141340`) has no
`ANALYSIS.md`. It is not backfilled (`automated-tests-§5`).

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|

None.

## Actions

None.
