# Analysis — 20260915-150853

- **Addon:** PartyFrameEnhanced 0.1.0 (release candidate — `--release 0.1.0`)
- **Verdict:** green
- **Commit:** 275f786 (master)
- **Previous run:** 20260915-141340

## Headline

All four suites pass over a clean tree, and the release gate's extra condition holds: **zero
functions above CCN 15** (max is exactly 15). This is the first run with the three features, the
providers and the anchor engine in the tree, and the first with real offline perf scenarios (9).
Nothing to act on before the tag except what only a live client can show: the in-game smoke suite and
a `/pfe perf` capture (plan P10).

## Suites

| Suite | Status | Result | Artifact | Moved since 20260915-141340 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 59 files | [`lint.txt`](lint.txt) | files 39 → 59 |
| tests | pass | 129 passed, 0 skipped, 0 failed, 129 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 66 → 129 |
| perf | pass | 9 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | 0 → 9 |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | see below |

| Metric | Value |
|---|---|
| Total NLOC | 4995 |
| Functions | 664 |
| Avg NLOC / function | 5.7 |
| Avg CCN | 2.3 |
| Max CCN | 15 |
| Avg tokens / function | 42.5 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |

Every suite is a clean pass; there is no skip to explain.

## What moved

- **lint:** still 0/0; the file count grew 39 → 59 as the modules and feature pages landed.
- **tests:** 66 → 129. The new cases cover the providers, the anchor engine, the three features, preview
  mode, and — new since the previous run — `tests/test_perf_buckets.lua`, which proves every declared
  perf bucket is reached and each nested one is observed inside its declared parent.
- **perf:** 0 → 9 scenarios. The previous run's `tests/perf.lua` was a skeleton that loaded the addon and
  measured nothing. [`perf.txt`](perf.txt) now pins resolve coalescing (40 requests → 1 resolve), zero
  API calls on an unchanged resolve and on an unchanged ticker pass, zero `SetPoint` on an unchanged
  anchor pass, and every hot path at 0 bytes/iter except `castStartStop` at 16.6 (ceiling 41; the
  residue is issue #12). `settingsDrag` (606.9 bytes/iter) is reported and unasserted by design.
- **complexity:** NLOC 1828 → 4995 and functions 288 → 664, the addon's growth; the **averages** are the
  signal and barely moved — avg NLOC 4.3 → 5.7, avg CCN 2.0 → 2.3, avg tokens 31.1 → 42.5. Max CCN held
  at 15. Between the runs three functions briefly scored 17–19 (`Anchor.applyFree`, the cast bar's tick,
  `Element.Reskin`); they were split for readability in e4a6e9a before this run, which is why the
  watch list is empty.

## Complexity watch list

### Functions `lizard` warned on

None.

### Files by `layout-§1` band

None.

## Actions

None before the tag beyond plan P10 (in-game smoke on Blizzard classic, raid-style and EllesmereUI,
and a first `/pfe perf` capture recorded with `/wow-addon:perf-analysis`). Parked work is issues
#1–#12.
