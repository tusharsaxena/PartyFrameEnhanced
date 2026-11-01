# Analysis — 20261101-202024

- **Addon:** PartyFrameEnhanced 1.2.0 (label `fs-pf-gate`, not a release run)
- **Verdict:** green
- **Commit:** ab05a0c (feat/2026-11-01-full-skinning), clean tree
- **Previous run:** 20261101-143700

## Headline

The re-cut LibKa0s v1.85.0 and the skin gates are green: lint 0/0 over 91 files, 633 passed and 0 failed of 634 tests, 10 perf scenarios at `pass`, complexity at `pass` with max CCN 14 and no blind or crashed file ([`manifest.json`](manifest.json)). The 40 new cases are mostly the kit's two skin suites. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261101-143700 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 91 files | [`lint.txt`](lint.txt) | file count unchanged |
| tests | pass | 633 passed, 1 skipped, 0 failed, 634 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 40 cases net |
| perf | pass | 10 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | see below |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC +253, functions +58; max CCN 15 → 14 |

**Complexity is reported in full**, from `manifest.json`'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 15217 |
| Functions | 2132 |
| Avg NLOC / function | 6.5 |
| Avg CCN | 2.1 |
| Max CCN | 14 |
| Avg tokens / function | 51.5 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The kit is sighted: `blindFiles` and `crashedFiles` are both 0. The one skipped case is the kit's diagnostics opt-out contract, the same pre-existing skip as the previous run, NOT EVALUATED at the release gate.

## What moved

- **lint**: 91 files both runs, still 0/0. `tests/skin_facts.lua` came in and `tests/test_skin_literals.lua` went.
- **tests**: 594 → 634 cases, 593 → 633 passed, skipped still 1, failed still 0. In: the kit's `test_skin_values` (3) and `test_skin_switch` (31), and `tests/test_skin_flip.lua` up 2. Out: `tests/test_skin_literals.lua`, whose glyph case moved to `tests/test_skin_fonts.lua`.
- **perf**: `api/iter` is unchanged on all 10 scenarios. `bytes/iter` moved on one, `settingsDrag` 926.1 → 926.2. `ms/iter` moves are timing noise between runs, not a measurement to compare.
- **complexity**: average CCN unchanged at 2.1, average tokens 51.6 → 51.5, max CCN 15 → 14.

## Watch list

None. `RESULTS.md`'s two tables are empty.
