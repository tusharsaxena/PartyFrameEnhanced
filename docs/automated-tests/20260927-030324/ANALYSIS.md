# Analysis — 20260927-030324

- **Addon:** PartyFrameEnhanced 1.0.1 → 1.1.0 (release run, `--release 1.1.0`)
- **Verdict:** green
- **Commit:** 692cec2 (master)
- **Previous run:** 20260926-193107

## Headline

This is the release run for 1.1.0, and the release gate passed on all five conditions: lint 0/0,
383 of 383 tests passed, 9 perf scenarios at `pass`, complexity at `pass`, and no function above
CCN 15 ([`manifest.json`](manifest.json)). Since the previous run the only changes the addon made
are three comment lines and documentation, so every counted figure is unchanged. `ms/iter` rose on
every perf scenario while `api/iter` and `bytes/iter` stayed identical, which is host timing, not the
addon. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260926-193107 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 75 files | [`lint.txt`](lint.txt) | unchanged (75 files, 0/0) |
| tests | pass | 383 passed, 0 skipped, 0 failed, 383 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | unchanged; the case inventory is identical, byte for byte |
| perf | pass | 9 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | same 9 scenarios; `api/iter` and `bytes/iter` identical; `ms/iter` higher on all nine (see below) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | unchanged on every footer field |

**Complexity is reported in full**, from `manifest.json`'s `suites.complexity`:

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

Every suite is a clean pass and none was skipped, so the release gate measured all four suites.

## What moved

- **lint**: no change, 0/0 over 75 files. `.luacheckrc` still excludes `libs/`, `docs/audits/`,
  `docs/reviews/`, `_dev/` and `tests/_kit/`.
- **tests**: no change. 383 cases, 383 passed, 0 skipped, and [`test-cases.md`](test-cases.md) is
  identical to the previous bundle's inventory.
- **perf**: the same 9 scenarios, with identical allocation and API counts on every one (for
  example `castStartStop` at 55.0 api/iter and 3.6 bytes/iter, `settingsDrag` at 25.0 and 925.9,
  [`perf.txt`](perf.txt)). `ms/iter` rose on all nine: `castStartStop` 0.02919 → 0.04078,
  `settingsDrag` 0.04469 → 0.07442, `resolveUnchanged` 0.00969 → 0.01482. The code the scenarios
  measure did not change between `09cc55e` and `692cec2`. The only source edits are comment lines in
  `settings/Slash.lua`, `tests/test_bus.lua` and `tests/test_surface_parity.lua`. A uniform rise
  with flat call and byte counts is the host running slower, not a regression.
- **complexity**: no change. 9976 NLOC, 1318 functions, avg CCN 2.1, max 14, 0 warnings, and no
  file in either `layout-§1` band.

Against the last release run, [`20260918-121606`](../20260918-121606/) (1.0.1), the addon grew from
7378 to 9976 NLOC and from 942 to 1318 functions, and the suite from 227 to 383 cases. Avg CCN fell
from 2.2 to 2.1, avg NLOC per function held at 6.3, and max CCN held at 14. The addon got bigger
without getting denser.

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
