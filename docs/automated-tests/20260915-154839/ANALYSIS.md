# Analysis — 20260915-154839

- **Addon:** PartyFrameEnhanced 0.1.0 (release candidate — `--release 0.1.0`)
- **Verdict:** green
- **Commit:** 89d30b0 (master)
- **Previous run:** 20260915-150853

## Headline

The release candidate re-run after the first standards audit (`docs/audits/2026-09-15/`). All four
suites pass over a clean tree and the release gate's extra condition still holds: **zero functions
above CCN 15** (max is exactly 15). The audit fixes changed no hot path, which is exactly what the
perf table shows: every deterministic column is identical to the previous run. What remains before
the tag is only what a live client can show: the in-game smoke suite and a `/pfe perf` capture (plan
P10).

## Suites

| Suite | Status | Result | Artifact | Moved since 20260915-150853 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 61 files | [`lint.txt`](lint.txt) | files 59 → 61 |
| tests | pass | 136 passed, 0 skipped, 0 failed, 136 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 129 → 136 |
| perf | pass | 9 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | unchanged (timings only) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | see below |

| Metric | Value |
|---|---|
| Total NLOC | 5242 |
| Functions | 678 |
| Avg NLOC / function | 5.8 |
| Avg CCN | 2.3 |
| Max CCN | 15 |
| Avg tokens / function | 43.2 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |

Every suite is a clean pass; there is no skip to explain.

## What moved

- **lint:** still 0/0; two more files (`tests/test_envsetup.lua` and the spelling gate, which landed
  between the runs).
- **tests:** 129 → 136. New since the previous run: the US-English spelling gate, the EnvSetup
  descriptor and stub suite, a case deriving the Perf stub's members from the live library, the
  Schema load-order pin, and a Reset All blast-radius case (the active profile resets; the profile
  list, the active profile and an open debug console are left alone).
- **perf:** the API-call and bytes/iter columns match 20260915-150853 row for row: 0 bytes/iter on every
  hot path except `castStartStop` at 16.6 (ceiling 41; issue #12), `settingsDrag` at 595.9 reported and
  unasserted by design. Only the ms/iter column moved, within run-to-run noise (largest: `castTick`
  0.0033 → 0.0052 ms, `castStartStop` 0.0289 → 0.0237 ms).
- **complexity:** NLOC 4995 → 5242 and functions 664 → 678, from the audit fixes (the slash status
  verb split into `featureState` / `statusFlags`, the lock validate hook, debug traces). Averages
  essentially flat: avg NLOC 5.7 → 5.8, avg CCN held at 2.3, avg tokens 42.5 → 43.2. Max CCN held at 15.

## Complexity watch list

### Functions `lizard` warned on

None.

### Files by `layout-§1` band

None.

## Actions

None before the tag beyond plan P10 (in-game smoke on Blizzard classic, raid-style and EllesmereUI,
and a first `/pfe perf` capture recorded with `/wow-addon:perf-analysis`). Parked work is issues
#1–#12.
