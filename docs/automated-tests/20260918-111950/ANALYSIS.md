# Analysis — 20260918-111950

- **Addon:** Ka0s Party Frame Enhanced 0.1.0 → 1.0.0 (release run, `--release 1.0.0`)
- **Verdict:** green
- **Commit:** 65ca753 (master), clean
- **Previous run:** [`20260918-110125`](../20260918-110125/)

The manifest records `addonVersion` 0.1.0 because the run is the gate: it measures the tree *before*
the bump edits anything, and `release` names the version it gates. The bump that followed changed only
the version string, its three test assertions, and docs.

## Headline

**The release gate for 1.0.0 passed on all five conditions.** Lint, tests, perf and complexity all
passed, and no function is above CCN 15. Nothing moved since the previous run: this tree is that run's
tree with the fix committed, so the same code was measured twice and gave the same figures. The one
thing to watch is `applyAttached` in `modules/Anchor.lua`, still at exactly CCN 15, the ceiling.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260918-110125 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 70 files | [`lint.txt`](lint.txt) | unchanged |
| tests | pass | 227 passed, 0 skipped, 0 failed, 227 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | unchanged; identical inventory |
| perf | pass | 9 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | `api/iter` and `bytes/iter` identical in all nine |
| complexity | pass | 0 warnings, max CCN 15 | [`complexity.txt`](complexity.txt) | unchanged |

Every figure comes from [`manifest.json`](manifest.json):

| Metric | Value |
|---|---|
| Total NLOC | 7357 |
| Functions | 940 |
| Avg NLOC / function | 6.3 |
| Avg CCN | 2.2 |
| Max CCN | 15 |
| Avg tokens / function | 46.9 |
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
| CCN ≤ 15 | `suites.complexity.warnings == 0` | pass: 0, max 15 |

Nothing was skipped: `lua`, `luacheck` and `lizard` were all present.

## What moved

Nothing. The code is byte-identical to the previous run's dirty tree, which `65ca753` committed.

- **lint:** 0/0 over 70 files, unchanged, with the same five exclusions (`libs/`, `docs/audits/`,
  `docs/reviews/`, `_dev/`, `tests/_kit/`).
- **tests:** 227, and the per-file inventory in [`test-cases.md`](test-cases.md) matches the previous
  run's exactly.
- **perf:** `api/iter` and `bytes/iter` are identical in all nine scenarios. `settingsDrag` is still
  885.9 bytes/iter, so the question from 20260918-105401 is still open. `ms/iter` moved by small
  amounts in both directions, which the runner says is orientation only.
- **complexity:** every field of the footer is unchanged. `applyAttached@117-148` in `modules/Anchor.lua`
  is still at **exactly CCN 15**. It's the function closest to the release ceiling, and the previous
  run's analysis describes the split it needs.

## Complexity watch list

**Functions `lizard` warned on:**

None. This holds by construction for a release bundle whose gate passed.

**Files by `layout-§1` band:**

None.

No watch-list entry has carried an *Accepted* disposition, across this release or any earlier run.

## Actions

1. **Take `applyAttached` off the ceiling during 1.0.x** (`modules/Anchor.lua:117`). Split out the
   placement defaulting as 20260918-110125's action 1 describes, before the next change to that
   function makes a release run red. Carried over.
2. **Account for `settingsDrag`'s 885.9 bytes/iter** (carried over from 20260918-105401).
   `core/Bus.lua`'s receiver wrapper is still the lead. Not a combat path.
