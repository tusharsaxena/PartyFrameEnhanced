# Analysis — 20260924-110428

- **Addon:** PartyFrameEnhanced 1.0.1
- **Verdict:** green
- **Commit:** c8881214551ab595aba32739fc482f7688039b4e (feat/2026-09-23-review-audit-remediation)
- **Previous run:** 20260918-121606

## Headline

All four suites pass on a clean tree, with no function above CCN 15 and no file in either
`layout-§1` band ([`manifest.json`](manifest.json)). This run replaces `20260918-121606` as the
current record. That bundle measured `e4d7f41` on `master`, 63 commits behind the one measured
here and before the LibKa0s v1.55.0 and v1.56.0 re-vendors and the 2026-09-23 remediation items.
The suite grew from 227 to 342 cases and the code grew with it. The averages held, so the addon
is bigger but no denser. There is nothing to act on, and this is not a release run.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260918-121606 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 72 files | [`lint.txt`](lint.txt) | files 70 → 72; still 0/0 |
| tests | pass | 342 passed, 0 skipped, 0 failed, 342 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 227 → 342 cases, all passing |
| perf | pass | 9 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | same 9 scenarios; `settingsDrag` 885.9 → 925.9 bytes/iter, every other api and bytes figure unchanged |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | totals up, averages flat, max CCN 14 in both |

| Metric | Value |
|---|---|
| Total NLOC | 9154 |
| Functions | 1192 |
| Avg NLOC / function | 6.3 |
| Avg CCN | 2.2 |
| Max CCN | 14 |
| Avg tokens / function | 47.4 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |

Every suite passed cleanly, so no suite needs a paragraph of its own.

## What moved

- **lint:** 70 → 72 files, 0/0 in both runs ([`lint.txt`](lint.txt)). Three authored files
  arrived (`modules/RangeFade.lua`, `tests/test_rangefade.lua`, `tests/test_profile_switch.lua`)
  and one left (`tests/test_spelling.lua`, retired for the kit's prose gate). `tests/_kit/` stays
  in `.luacheckrc`'s exclusions, so the kit's new files are not in the count.
- **tests:** 227 → 342, with 0 skipped in both ([`tests.txt`](tests.txt)). The new cases are the
  out-of-range fade's and the profile switch's suites, the kit's `test_prose` and
  `test_layout_cap` gates, and the red-first cases the remediation items added.
  [`test-cases.md`](test-cases.md) is the authority on which cases ran.
- **perf:** the same nine scenarios. Every `api/iter` figure is unchanged. Only `settingsDrag`
  moved on bytes, 885.9 → 925.9 ([`perf.txt`](perf.txt)). `docs/performance.md` ("Where
  `settingsDrag` grew") attributes the rise commit by commit: 10 bytes to the LibKa0s v1.47.0
  re-vendor, 40 to PF-11's move of `NS.SetByPath` onto the Schema instance, and −10 to a change in
  `tests/perf.lua` itself. `probeOverheadOff` makes 0 bracket calls per iteration with the capture
  off (9 with it on). The `ms/iter` column is for orientation only and is not compared across runs.
- **complexity:** NLOC 7378 → 9154 and functions 942 → 1192, while avg NLOC stayed at 6.3 and
  avg CCN at 2.2. Avg tokens went from 47.0 to 47.4, and max CCN is 14 in both runs, with 0
  warnings ([`complexity.txt`](complexity.txt)). That is growth, not densification.

## Complexity watch list

**Functions warned on (CCN > 15)**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band**

| Band | File | LOC | Disposition |
|---|---|---|---|

None.

## Actions

None.
