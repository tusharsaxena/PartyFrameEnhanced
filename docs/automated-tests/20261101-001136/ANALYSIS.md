# Analysis — 20261101-001136

- **Addon:** PartyFrameEnhanced 1.2.0 (label `v1.84.0-adoption`, not a release run)
- **Verdict:** green
- **Commit:** b75dc68 (feat/2026-10-31-findings-remediation)
- **Previous run:** 20261031-211517

## Headline

The LibKa0s v1.84.0 adoption run is green: lint 0/0, 565 passed and 0 failed of 566 tests, 10 perf
scenarios at `pass`, complexity at `pass` with no function above CCN 15 and no blind or crashed file
([`manifest.json`](manifest.json)). Every gated and complexity figure matches the previous run; the
re-vendor and the one-line `tests/test_surface_parity.lua` change moved none of them. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261031-211517 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 90 files | [`lint.txt`](lint.txt) | no change |
| tests | pass | 565 passed, 1 skipped, 0 failed, 566 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | no change; same case list |
| perf | pass | 10 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | same 10 scenarios; `api/iter` and `bytes/iter` unchanged on all 10 |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | no change in any manifest field |

**Complexity is reported in full**, from `manifest.json`'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 14279 |
| Functions | 1997 |
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
537), the same pre-existing skip as the previous run: its stated reason is that this addon keeps the
default, so its report turns logging on, and the case above it holds that behavior. It is a skip with
its reason, not an unmeasured suite, and it is NOT EVALUATED at the release gate.

## What moved

- **lint**: did not move, 0/0 over 90 files, and [`lint.txt`](lint.txt) is identical to the previous
  run's.
- **tests**: did not move, 566 cases with 565 passed and 1 skipped. [`test-cases.md`](test-cases.md) is
  identical to the previous run's inventory. `RESULTS.md` now flags the count as flat across 3 runs;
  the addon did not grow across those runs either, so that flag does not point at a coverage gap here.
- **perf**: no scenario was added or removed. `api/iter` and `bytes/iter` match the previous run on all
  10 scenarios, every `SetPoint` figure in [`perf.txt`](perf.txt) is 0.0, the batch-size line holds at
  40 layout requests coalesced into 1 resolve, and `probeOverheadOff` holds at 0 bracket calls per
  iteration. `ms/iter` rose on six scenarios and fell on four; `perf.txt` says timings are for
  orientation only, and the work counters above show no change in what the code does.
- **complexity**: every field in `manifest.json` is unchanged. The whole of the difference in
  [`complexity.txt`](complexity.txt) is one anonymous function in `tests/test_surface_parity.lua`,
  68 → 70 tokens, which took that file's average tokens from 66.8 to 66.9. No file entered either
  `layout-§1` band.

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
