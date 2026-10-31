# Analysis — 20261101-025420

- **Addon:** PartyFrameEnhanced 1.2.0 (label `final-pre-merge`, not a release run)
- **Verdict:** green
- **Commit:** b1b2c4a (feat/2026-10-31-findings-remediation)
- **Previous run:** 20261101-001136

## Headline

The final pre-merge run is green: lint 0/0 over 90 files, 566 passed and 0 failed of 567 tests, 10 perf
scenarios at `pass`, complexity at `pass` with no function above CCN 15 and no blind or crashed file
([`manifest.json`](manifest.json)). The only movement is the one case and 13 NLOC added for the
Ka0sMedia picker change, and the perf work counters did not move. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261101-001136 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 90 files | [`lint.txt`](lint.txt) | no change |
| tests | pass | 566 passed, 1 skipped, 0 failed, 567 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | one case added, passing |
| perf | pass | 10 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | same 10 scenarios; `api/iter` and `bytes/iter` unchanged on all 10 |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC +13, functions +1; averages and max unchanged |

**Complexity is reported in full**, from `manifest.json`'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 14292 |
| Functions | 1998 |
| Avg NLOC / function | 6.4 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 50.5 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The kit is sighted: `blindFiles` and `crashedFiles` are both recorded, both at 0, so `lizard` saw every
function. The one skipped case is the kit's diagnostics opt-out contract ([`tests.txt`](tests.txt) line
538), the same pre-existing skip as the previous run: its stated reason is that this addon keeps the
default, so its report turns logging on, and the case above it holds that behavior. It is a skip with
its reason, not an unmeasured suite, and it is NOT EVALUATED at the release gate.

## What moved

- **lint**: did not move, 0/0 over 90 files, and [`lint.txt`](lint.txt) is identical to the previous
  run's.
- **tests**: 566 → 567 cases, 565 → 566 passed, skipped still 1, failed still 0. The one addition in
  [`test-cases.md`](test-cases.md) is `layout: every media row is a Ka0sMedia picker, font and border
  among them`, in `test_settings_layout.lua`. Nothing was removed or renamed.
- **perf**: no scenario was added or removed. `api/iter` and `bytes/iter` match the previous run on all
  10 scenarios, every `SetPoint` figure in [`perf.txt`](perf.txt) is 0.0, and `probeOverheadOff` holds at
  0 bracket calls per iteration. `ms/iter` rose on seven scenarios and fell on three; the code those
  scenarios drive did not change, and the work counters above show no change in what it does.
- **complexity**: NLOC 14279 → 14292 and functions 1997 → 1998; every other field in `manifest.json` is
  unchanged. Per [`complexity.txt`](complexity.txt), `tests/test_settings_layout.lua` gained one
  anonymous function (CCN 14, 14 NLOC) and `settings/OptionsSetup.lua` lost one NLOC. No file entered
  either `layout-§1` band.

## Complexity watch list

### Functions `lizard` warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|

None.

## Actions

None.
