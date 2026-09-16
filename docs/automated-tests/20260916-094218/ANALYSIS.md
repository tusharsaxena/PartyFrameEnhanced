# Analysis — 20260916-094218

- **Addon:** PartyFrameEnhanced 0.1.0
- **Verdict:** green
- **Commit:** 9712cb9 (master)
- **Previous run:** 20260915-154839

## Headline

First recorded run since the 0.1.0 release candidate, and the first to cover the `/pfe test`
stand-in feature and the LibKa0s v1.37.0 → v1.38.0 re-vendor. All four suites pass over a clean
tree, and the release gate's extra condition still holds: **zero functions above CCN 15** (max is
exactly 15, unchanged). The addon grew substantially — 5242 → 6452 NLOC, 678 → 824 functions — and
the test suite grew with it, 136 → 185 cases, so the coverage-per-code ratio did not slip while the
feature landed.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260915-154839 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 66 files | [`lint.txt`](lint.txt) | files 61 → 66 |
| tests | pass | 185 passed, 0 skipped, 0 failed, 185 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 136 → 185 |
| perf | pass | 9 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | unchanged (timings only) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | see below |

Complexity, in full — from [`manifest.json`](manifest.json) `suites.complexity` and the
[`complexity.txt`](complexity.txt) footer:

| Metric | Value | Previous |
|---|---|---|
| Total NLOC | 6452 | 5242 |
| Functions | 824 | 678 |
| Avg NLOC / function | 6.1 | 5.8 |
| Avg CCN | 2.3 | 2.3 |
| Max CCN | 15 | 15 |
| Avg tokens / function | 45.9 | 43.2 |
| Warnings (CCN > 15) | 0 | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 | 0 |
| Files over the 1500 cap | 0 | 0 |

Every suite is a clean pass; there is no skip to explain. All four tools were present on the host
([`manifest.json`](manifest.json) `host`): Lua 5.1.5, Luacheck 1.2.0, lizard 1.24.0.

## What moved

- **lint:** still 0/0, now over 66 files (61 before) — the five new files are the stand-in and
  test-mode module plus their suites. The `0/0` is scoped: `.luacheckrc` excludes `libs/`,
  `docs/audits/`, `docs/reviews/`, `_dev/` and `tests/_kit/`, so those were never in the count.
- **tests:** 136 → 185, the largest jump since the harness was stood up. New suite files
  `test_standin.lua` (12) and `test_testmode.lua` (16) and `test_party.lua` (6) account for 34 of
  the 49; the rest is growth inside existing files — `test_targetframes.lua` 12 → 16,
  `test_slash.lua` 9 → 12, `test_optionssetup.lua` 5 → 8, `test_preview.lua` 5 → 7,
  `test_providers.lua` 11 → 12, `test_petframes.lua` 5 → 6, `test_loadorder.lua` 12 → 13,
  `test_surface_parity.lua` 4 → 5. `test_compat.lua` dropped 7 → 6. Nothing skipped, so passed and
  total agree.
- **perf:** the deterministic columns are identical to 20260915-154839 row for row — 0 bytes/iter on
  every hot path except `castStartStop` at 16.6 (issue #12) and `settingsDrag` at 595.9, which is
  reported and unasserted by design; api/iter matches on all nine scenarios; SetPoint calls/iter is
  0.0 everywhere. The stand-in/test-mode work therefore added no allocation or API traffic to a hot
  path. Only ms/iter moved, and every scenario got *faster* by a similar factor (e.g.
  `resolveUnchanged` 0.00981 → 0.00780, `targetTickMoving` 0.00815 → 0.00547), which is the
  signature of host noise rather than a code change — wall-clock timings are for orientation within
  a run only.
- **complexity:** NLOC 5242 → 6452 (+23%) and functions 678 → 824 (+22%) — the addon grew, and the
  two grew together. The **averages** are what carry the density signal, and they barely moved: avg
  NLOC/function 5.8 → 6.1, avg CCN flat at 2.3, avg tokens 43.2 → 45.9. Max CCN held at exactly 15
  and the warning count stayed at 0, so nothing newly approached the gate. The densest functions
  remain `Providers.Resolve` (CCN 15, `modules/Providers.lua:199`) and `NS.ValidateSchema` (CCN 15,
  `settings/Schema.lua:278`), both at the ceiling but neither over it.

## Complexity watch list

### Functions `lizard` warned on

None. Nothing crossed CCN 15 this run; the two functions sitting *at* 15 are noted above and are
dense defaulting/validation rather than tangled control flow — `lizard` scores each `and`/`or`
short-circuit as a decision, and both are runs of field-by-field defaulting and checking.

### Files by `layout-§1` band

None. No file reached the 1000-line band, let alone the 1500 cap.

## Actions

1. `Providers.Resolve` and `NS.ValidateSchema` sit at exactly CCN 15, the release gate's ceiling.
   Neither is a warning today, but a single extra `or` default in either one turns the next release
   run red at `/wow-addon:bump-version`. Worth a split before more provider kinds land.
2. Otherwise none. The remaining pre-tag work is what only a live client can show: the in-game smoke
   suite and a `/pfe perf` capture (plan P10). Parked work is issues #1–#12.
