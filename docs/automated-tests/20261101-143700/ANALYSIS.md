# Analysis — 20261101-143700

- **Addon:** PartyFrameEnhanced 1.2.0 (no label, not a release run)
- **Verdict:** green
- **Commit:** aa832f0 (feat/2026-11-01-full-skinning)
- **Previous run:** 20261101-025420

## Headline

The full skinning run is green on LibKa0s v1.85.0: lint 0/0 over 91 files, 593 passed and 0 failed of 594 tests, 10 perf scenarios at `pass`, complexity at `pass` with no function above CCN 15 and no blind or crashed file ([`manifest.json`](manifest.json)). The 27 new cases are the flip, the step, gloss and the icon edge. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261101-025420 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 91 files | [`lint.txt`](lint.txt) | one file more, `tests/test_skin_flip.lua` |
| tests | pass | 593 passed, 1 skipped, 0 failed, 594 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 27 cases net |
| perf | pass | 10 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | see below |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC +672, functions +76; avg NLOC and avg tokens up, max unchanged |

**Complexity is reported in full**, from `manifest.json`'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 14964 |
| Functions | 2074 |
| Avg NLOC / function | 6.5 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 51.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The kit is sighted: `blindFiles` and `crashedFiles` are both 0. The one skipped case is the kit's diagnostics opt-out contract, the same pre-existing skip as the previous run, NOT EVALUATED at the release gate.

## What moved

- **lint**: 90 → 91 files, still 0/0.
- **tests**: 567 → 594 cases, 566 → 593 passed, skipped still 1, failed still 0. New: `tests/test_skin_flip.lua`. Removed: the X4 case in `tests/test_skin_hud.lua`, which pinned what the owner's ruling reversed.
- **perf**: see the table in [`perf.txt`](perf.txt); `api/iter` is unchanged on all 10 scenarios. `bytes/iter` moved by under 1 on four: `castStartStop` 0.0 → 0.6, `settingsDrag` 925.9 → 926.1, `probeOverheadOff` 0.0 → 0.6 and `probeOverheadOn` 0.5 → 1.2. Every `SetPoint` figure stays 0.0.
- **complexity**: the growth is the new suite, the library's and the step. Average CCN and max CCN did not move.

## Watch list

None. `RESULTS.md`'s two tables are empty.
