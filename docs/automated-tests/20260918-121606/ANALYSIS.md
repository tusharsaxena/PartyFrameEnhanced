# Analysis — 20260918-121606

- **Addon:** Ka0s Party Frame Enhanced 1.0.0 → 1.0.1 (release run, `--release 1.0.1`)
- **Verdict:** green
- **Commit:** e4d7f41 (master), clean
- **Previous run:** [`20260918-111950`](../20260918-111950/)

The manifest records `addonVersion` 1.0.0 because the run is the gate: it measures the tree *before*
the bump edits anything, and `release` names the version it gates. The bump that followed changed only
the version string, its three test assertions, the README's Version History row, and docs.

**This is the second 1.0.1 release run, and the one that counts.** An earlier run on `b6eb1dd` also
passed the gate, but it left two functions at exactly CCN 15. The splits that fixed that (`e4d7f41`)
were made before 1.0.1 was committed, so the release was gated again on the code that actually
ships. The earlier bundle was never committed and does not appear in `RESULTS.md`.

## Headline

**The release gate for 1.0.1 passed on all five conditions, and nothing sits at the ceiling any
more.** Max CCN dropped from 15 to **14**. Since the 1.0.0 release run there are two changes. The
target-frame fix (`b6eb1dd`) repaints a party member's target frame that was painted before its unit
had resolved. The complexity splits (`e4d7f41`) take `tick` and `applyAttached` off 15.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260918-111950 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 70 files | [`lint.txt`](lint.txt) | unchanged |
| tests | pass | 227 passed, 0 skipped, 0 failed, 227 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | count unchanged; two cases replaced |
| perf | pass | 9 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | `api/iter` and `bytes/iter` identical in all nine |
| complexity | pass | 0 warnings, max CCN 14 | [`complexity.txt`](complexity.txt) | +21 NLOC, +2 functions; max 15 → 14 |

Every figure comes from [`manifest.json`](manifest.json):

| Metric | Value |
|---|---|
| Total NLOC | 7378 |
| Functions | 942 |
| Avg NLOC / function | 6.3 |
| Avg CCN | 2.2 |
| Max CCN | 14 |
| Avg tokens / function | 47.0 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |

**The release gate** (`automated-tests-§3`) passed on all five:

| Gate | Condition | Result |
|---|---|---|
| Lint | `suites.lint.status == "pass"` | pass: 0/0 over 70 files |
| Tests | `status == "pass"` and `failed == 0` | pass: 227/227, 0 skipped |
| Perf | `suites.perf.status == "pass"` | pass: 9 scenarios, measured (not the no-`perf.lua` exception) |
| Complexity | `suites.complexity.status == "pass"` | pass: `lizard` 1.24.0 ran |
| CCN ≤ 15 | `suites.complexity.warnings == 0` | pass: 0, max 14 |

Nothing was skipped: `lua`, `luacheck` and `lizard` were all present.

## What moved

- **lint:** 0/0 over 70 files, unchanged, with the same five exclusions (`libs/`, `docs/audits/`,
  `docs/reviews/`, `_dev/`, `tests/_kit/`).
- **tests:** still 227. Two cases left `tests/test_targetframes.lua`: they tested a
  `UNIT_NAME_UPDATE` registration that never fires for a compound token such as `party2target`.
  Two arrived: an unresolved target repainted by the ticker, and the ticker with *Update health* off
  running only until the pending target resolves. Both new cases are red against the 1.0.0 module.
  The runner flags the count as flat across recent runs. Here it is a like-for-like swap, not a
  stalled suite.
- **perf:** `api/iter` and `bytes/iter` are identical in all nine scenarios. That includes
  `targetTickUnchanged` (0 API calls) and `targetTickMoving` (15), so neither the pending check nor
  the `tickButton` call adds an API call to a resolved button's tick. `settingsDrag` is still 885.9
  bytes/iter. `ms/iter` moved by small amounts, which the runner treats as orientation only.
- **complexity:** NLOC 7357 → 7378 and functions 940 → 942 (`tickButton`, `placementOf`).
  - `applyAttached` (`modules/Anchor.lua`): **15 → 9**. The placement defaulting moved into
    `placementOf` (7), as 20260918-110125's action 1 described.
  - `tick` (`modules/TargetFrames.lua`): 11 at 1.0.0, 15 after the fix, and **11** after the split.
    One button's share of a pass is now `tickButton` (5).
  - `paintAll` 3 → 4 and `tickerWanted` 7 → 8, from the pending flag.
  - The highest function is now **14**, and two functions share it: `NS.SetByPath`
    (`settings/Schema.lua:198`) and `NS.ResolveColor` (`core/CoreSetup.lua:36`). Both were already
    at 14 in the previous run, so neither is new.

## Complexity watch list

**Functions `lizard` warned on:**

None. This holds by construction for a release bundle whose gate passed.

**Files by `layout-§1` band:**

None.

No function sits at the ceiling of 15. No watch-list entry has carried an *Accepted* disposition,
across this release or any earlier run.

## Actions

1. **Account for `settingsDrag`'s 885.9 bytes/iter** (carried over from 20260918-105401).
   `core/Bus.lua`'s receiver wrapper is still the lead. Not a combat path.
2. **Keep an eye on the two functions at 14**: `NS.SetByPath` and `NS.ResolveColor`. Neither is
   urgent, but each is one branch from the ceiling. Split whichever is touched next before adding a
   branch to it.
