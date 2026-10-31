# Analysis — 20261031-211517

- **Addon:** PartyFrameEnhanced 1.2.0 (label `findings-remediation`, not a release run)
- **Verdict:** green
- **Commit:** f942fe1 (feat/2026-10-31-findings-remediation)
- **Previous run:** 20261031-202100

## Headline

The post-remediation run is green: lint 0/0, 565 passed and 0 failed of 566 tests, 10 perf scenarios
at `pass`, complexity at `pass` with no function above CCN 15 and no blind or crashed file
([`manifest.json`](manifest.json)). The only movement is 14275 → 14279 NLOC and 1996 → 1997 functions,
all of it from removing `NS.ProfileRowsOffDefault` and rewriting its test. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261031-202100 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 90 files | [`lint.txt`](lint.txt) | no change |
| tests | pass | 565 passed, 1 skipped, 0 failed, 566 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | no change; same case list |
| perf | pass | 10 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | same 10 scenarios; `api/iter` and `bytes/iter` unchanged on all 10 |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | 14275 → 14279 NLOC, 1996 → 1997 functions; averages and max CCN flat |

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

The kit is sighted: `blindFiles` and `crashedFiles` are both recorded, both at 0, so `lizard` saw
every function. The one skipped case is the kit's diagnostics opt-out contract
([`tests.txt`](tests.txt) line 537), the same pre-existing skip as the previous run: it covers an addon
that sets `diagnosticsEnablesLogging = false`, this addon keeps the default, and the case above it
holds the behavior instead. It is a skip with its reason, not an unmeasured suite.

## What moved

- **lint**: did not move, 0/0 over 90 files. The exclusions named in `RESULTS.md` are unchanged:
  `libs/`, `docs/audits/`, `docs/reviews/`, `_dev/` and `tests/_kit/`.
- **tests**: did not move, 566 cases with 565 passed and 1 skipped. [`test-cases.md`](test-cases.md)
  matches the previous run's inventory line for line, so the rewritten schema case kept its name.
- **perf**: no scenario was added or removed. `api/iter` and `bytes/iter` match the previous run on
  all 10 scenarios, and every `SetPoint` figure in [`perf.txt`](perf.txt) is 0.0. `ms/iter` fell on seven
  scenarios and rose on `castTick`, `settingsDrag` and `probeOverheadOff`; timings are host-dependent
  and are not compared across runs. The batch-size line holds at 40 layout requests coalesced into 1
  resolve, and `probeOverheadOff` at 0 bracket calls per iteration.
- **complexity**: 14275 → 14279 NLOC and 1996 → 1997 functions. Avg CCN held at 2.1, avg NLOC per
  function at 6.4, avg tokens at 50.5, and max CCN at 15, still on `splitArgs` in
  `tests/test_skin_literals.lua`, at the limit and not over it. In
  [`complexity.txt`](complexity.txt), `settings/Schema.lua` lost `NS.ProfileRowsOffDefault` (262 → 261
  NLOC, 53 → 52 functions) and `tests/test_schema.lua` gained `countedRows` and its `ResetProfile`
  stand-in (220 → 225 NLOC, 37 → 39 functions), which nets to the +1 function. The total rose because
  a test grew, not because anything got denser. No file entered either `layout-§1` band.

## Complexity watch list

### Functions `lizard` warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|

None.

Nothing newly crossed a threshold, and no entry carries an **Accepted** disposition, so none has
reached the three-release shelf life.

## Actions

None.
