# Analysis — 20261101-210026

- **Addon:** PartyFrameEnhanced 1.2.0 (label `final review findings`, not a release run)
- **Verdict:** green
- **Commit:** a376cf8 (feat/2026-11-01-full-skinning), clean tree
- **Previous run:** 20261101-202024

## Headline

The run records FS-PF-GATE: schema v5 is spent and writes nothing, so no stored Show border moves. The case count holds because the new ladder case replaced the old v5 case. Lint 0/0 over 91 files, 633 passed and 0 failed of 634 tests, 10 perf scenarios at `pass`, complexity at `pass` with max CCN 14 ([`manifest.json`](manifest.json)). Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261101-202024 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 91 files | [`lint.txt`](lint.txt) | files unchanged |
| tests | pass | 633 passed, 1 skipped, 0 failed, 634 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | total unchanged |
| perf | pass | 10 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | see below |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC 15217 → 15219, functions 2132 → 2133 |

**Complexity is reported in full**, from `manifest.json`'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 15219 |
| Functions | 2133 |
| Avg NLOC / function | 6.5 |
| Avg CCN | 2.1 |
| Max CCN | 14 |
| Avg tokens / function | 51.5 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.0 / 0.0 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The one skipped case is the same pre-existing skip as the previous run, NOT EVALUATED at the release gate.

## What moved

- **lint**: files unchanged, still 0/0.
- **tests**: total unchanged, passed unchanged, skipped unchanged, failed unchanged. `tests/test_skin_flip.lua`: the v5 case is replaced by `skin flip: no step of the ladder moves a stored Show border`, which was red against the old step and walks the real ladder from v1 to v4.
- **perf**: calls and bytes per iteration unchanged on every scenario. `ms/iter` moves are timing noise between runs.
- **complexity**: average CCN unchanged, average tokens unchanged, max CCN unchanged.

## Watch list

See `RESULTS.md`: no entry newly crossed a threshold (0 functions above CCN 15).
