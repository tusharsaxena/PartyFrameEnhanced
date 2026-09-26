# Analysis — 20260926-193107

- **Addon:** PartyFrameEnhanced 1.0.1
- **Verdict:** green
- **Commit:** 09cc55e (feat/2026-09-26-automated-tests-sweep), clean
- **Previous run:** 20260926-160553

## Headline

All four suites passed and the verdict is green ([`manifest.json`](manifest.json)). This is the
final run of the 2026-09-26 automated-tests sweep. The only change since the previous run is the
LibKa0s v1.61.0 → v1.62.0 re-vendor (test-kit revision 31), which touched `libs/` and `tests/_kit/`
and nothing the addon authors, so every addon-side figure is unchanged. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260926-160553 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 75 files | [`lint.txt`](lint.txt) | unchanged (75 files, 0/0) |
| tests | pass | 383 passed, 0 skipped, 0 failed, 383 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | unchanged; the case inventory is identical |
| perf | pass | 9 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | same 9 scenarios; `api/iter` and `bytes/iter` identical, `ms/iter` within timing noise |
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

Every suite is a clean pass; no suite was skipped. `perf` and `complexity` do not gate the run or
the commit, but they do gate the tag, and both are at `pass` with zero functions above CCN 15.

## What moved

- **lint** — did not move: 0/0 over 75 files. `.luacheckrc` still excludes `libs/`, `docs/audits/`,
  `docs/reviews/`, `_dev/` and `tests/_kit/`, which is why the re-vendor could not move the count.
- **tests** — did not move: 383 cases, 383 passed, 0 skipped. `test-cases.md` is the same list as
  the previous bundle's. Kit revision 31 split `framework.lua` and `test_prose.lua` into new modules
  (`inventory.lua`, `prose_coverage.lua`, `prose_selftests.lua`) without changing the set of cases
  this addon runs.
- **perf** — the same 9 scenarios. Allocation and API counts are identical on every scenario, for
  example `settingsDrag` at 25.0 api/iter and 925.9 bytes/iter, and `castStartStop` at 55.0 / 3.6
  ([`perf.txt`](perf.txt)). `ms/iter` drifts in both directions: `resolveUnchanged` 0.00858 →
  0.00969, `settingsDrag` 0.04624 → 0.04469. Nothing in the measured code changed, so this is
  wall-clock noise and not a regression.
- **complexity** — did not move: 9976 NLOC, 1318 functions, avg CCN 2.1, max 14, 0 warnings, and
  no file in either `layout-§1` band. `lizard` excludes `libs/` and `tests/_kit/`, so the re-vendor's
  large `libs/LibKa0s/` rewrite (the new `OptionsIds.lua`, `OptionsIdList.lua`, `OptionsRegistry.lua`
  and `OptionsCombat.lua`) is outside this measurement by design.

## Complexity watch list

### Functions `lizard` warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|

None.

No entry carries a disposition, so nothing is owed a ruling and no **Accepted** entry has reached
the three-release shelf life.

## Actions

None.
