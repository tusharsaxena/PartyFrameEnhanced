# Analysis — 20261031-202100

- **Addon:** PartyFrameEnhanced 1.2.0 (label `pre-merge`, not a release run)
- **Verdict:** green
- **Commit:** 531f3bc (feat/2026-10-31-font-pickers-skin-faces)
- **Previous run:** 20261009-191745

## Headline

The pre-merge run is green: lint 0/0, 565 passed and 0 failed of 566 tests, 10 perf scenarios at
`pass`, complexity at `pass` with no function above CCN 15 and no blind or crashed file
([`manifest.json`](manifest.json)). Since 1.2.0 the addon took the skin seam, the skin picker and font
work, so the totals rose while avg CCN held at 2.1. Max CCN moved 14 → 15, on a test helper and still
at the limit rather than above it. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261009-191745 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 90 files | [`lint.txt`](lint.txt) | 79 → 90 files, still 0/0 |
| tests | pass | 565 passed, 1 skipped, 0 failed, 566 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 464 → 566 cases; skipped unchanged at 1 |
| perf | pass | 10 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | same 10 scenarios; `api/iter` and `bytes/iter` unchanged on all 10 |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | totals up, avg CCN flat, max CCN 14 → 15 |

**Complexity is reported in full**, from `manifest.json`'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 14275 |
| Functions | 1996 |
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

- **lint**: 0/0, now over 90 files instead of 79. The eleven new files are `core/SkinSetup.lua` and
  ten test files. The excluded paths are unchanged: `libs/`, `docs/audits/`, `docs/reviews/`, `_dev/`
  and `tests/_kit/`.
- **tests**: 464 → 566 cases, 565 passed and 1 skipped. The growth is the skin suites and the
  layering and settings-layout suites, plus cases from the LibKa0s re-vendors.
  [`test-cases.md`](test-cases.md) is the inventory.
- **perf**: no scenario was added or removed. `api/iter` and `bytes/iter` match the previous run on
  all 10 scenarios, so the skin work added no API calls or allocation to any measured path. `ms/iter`
  rose on seven scenarios and fell on `resolveUnchanged`, `targetTickMoving` and `probeOverheadOff`;
  timings are host-dependent and are not compared across runs.
- **complexity**: 11581 → 14275 NLOC and 1639 → 1996 functions. Avg CCN held at 2.1 and avg NLOC per
  function at 6.4, and avg tokens went from 50.1 to 50.5. Max CCN rose from 14 to 15 on
  `splitArgs` in `tests/test_skin_literals.lua`, the only function at 15 in
  [`complexity.txt`](complexity.txt) and a test helper rather than shipped code. It sits at the limit,
  not over it, so it is not a warning. No file entered either `layout-§1` band. The addon got bigger
  without getting meaningfully denser.

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
