# Analysis — 20261009-191745

- **Addon:** PartyFrameEnhanced 1.1.0 → 1.2.0 (release run, `--release 1.2.0`)
- **Verdict:** green
- **Commit:** 5ef0164 (master)
- **Previous run:** 20260927-030324

## Headline

This is the release run for 1.2.0, and the release gate passed on all six conditions: lint 0/0,
463 passed and 0 failed of 464 tests, 10 perf scenarios at `pass`, complexity at `pass`, no function
above CCN 15, and `blindFiles` 0 ([`manifest.json`](manifest.json)). The addon grew by SecureFollow,
the `/pfe profile` verb and the review fixes since 1.1.0, so the totals rose (81 more cases, 321 more
functions) while avg CCN held at 2.1 and max CCN at 14. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260927-030324 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 79 files | [`lint.txt`](lint.txt) | 75 → 79 files, still 0/0 |
| tests | pass | 463 passed, 1 skipped, 0 failed, 464 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 383 → 464 cases; 0 → 1 skipped |
| perf | pass | 10 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | 9 → 10 scenarios (`followSyncUnchanged` new); `castStartStop` bytes/iter 3.6 → 0.0 |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | totals up, averages flat, max CCN unchanged at 14 |

**Complexity is reported in full**, from `manifest.json`'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 11581 |
| Functions | 1639 |
| Avg NLOC / function | 6.4 |
| Avg CCN | 2.1 |
| Max CCN | 14 |
| Avg tokens / function | 50.1 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |

This is the addon's first release run on a sighted kit (`blindFiles` is recorded; the previous
release manifest has no such field). `lizard` saw every function, and none is above CCN 15, so there
is nothing newly measured to report.

The one skipped case is the kit's diagnostics opt-out contract ([`tests.txt`](tests.txt) line 435):
it covers an addon that sets `diagnosticsEnablesLogging = false`, and this addon keeps the default,
so the case above it holds the behavior instead. It is a skip with its reason, not an unmeasured
suite, and `suites.tests.failed` is 0.

## What moved

- **lint**: 0/0, now over 79 files instead of 75. The four new files are the SecureFollow module and
  new test files. `.luacheckrc` still excludes `libs/`, `docs/audits/`, `docs/reviews/`, `_dev/` and
  `tests/_kit/`.
- **tests**: 383 → 464 cases, 463 passed and 1 skipped (above). The growth is SecureFollow, the
  `/pfe profile` verb through `CliProfile`, the diagnostics logging change, the LibKa0s re-vendors'
  kit cases and the review fixes. [`test-cases.md`](test-cases.md) is the inventory.
- **perf**: one new scenario, `followSyncUnchanged`, at 0.0 api/iter and 0.0 bytes/iter, which is what
  SecureFollow's unchanged-attribute memo should give. `castStartStop` went from 3.6 to 0.0
  bytes/iter: `tests/perf.lua` now runs one untimed warm-up cycle first, after the 3.6 was traced to
  one-time table-shape growth on the first cast (commit `c3d4298`, #12). `targetTickUnchanged` reads
  0.1 bytes/iter against 0.0 before, with 0.0 api/iter on both, which is a collector rounding figure
  at this size and not a retained allocation. `api/iter` is unchanged on every scenario that existed
  in both runs ([`perf.txt`](perf.txt)). `ms/iter` fell on six scenarios and rose on
  `targetTickMoving`, `settingsDrag` and `probeOverheadOff`; timings are host-dependent and are not compared across runs.
- **complexity**: 9976 → 11581 NLOC and 1318 → 1639 functions. Avg CCN held at 2.1 and max CCN at 14,
  avg NLOC per function went from 6.3 to 6.4 and avg tokens from 47.3 to 50.1. No file entered either
  `layout-§1` band. The addon got bigger without getting meaningfully denser.

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
