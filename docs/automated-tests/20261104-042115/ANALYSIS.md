# Analysis — 20261104-042115

- **Addon:** PartyFrameEnhanced 1.2.0
- **Verdict:** green
- **Commit:** a9b2e43 (feat/2026-11-01-full-skinning)
- **Previous run:** 20261101-210026 (a376cf8)

## Headline

All four suites pass on a clean tree at `a9b2e43`, the head of round 6 of the full skinning run. Since the previous run (25 commits back) the suite grew by 14 cases to 648 and lint covers one more file (the new `tests/test_launcher_skin_entry.lua`). Complexity averages are flat (avg CCN 2.1, avg NLOC 6.5), max CCN stays 14, and nothing is on the watch list. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261101-210026 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 92 files | [`lint.txt`](lint.txt) | files 91 → 92; still 0/0 |
| tests | pass | 647 passed, 1 skipped, 0 failed, 648 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | total 634 → 648, passed 633 → 647; same single skip |
| perf | pass | 10 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | same 10 scenarios; api/iter and bytes/iter unchanged in every scenario |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC 15219 → 15614, functions 2133 → 2188; avg NLOC and avg CCN unchanged, avg tokens 51.5 → 51.6 |

**Complexity is reported in full**, from [`manifest.json`](manifest.json) `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 15614 |
| Functions | 2188 |
| Avg NLOC / function | 6.5 |
| Avg CCN | 2.1 |
| Max CCN | 14 |
| Avg tokens / function | 51.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The run is sighted (`blindFiles` 0) and nothing crashed (`crashedFiles` 0), so the complexity figures are a full measurement.

**tests — one skip.** [`tests.txt`](tests.txt) reports one `SKIP`: the kit's diagnostics-contract case for an addon that opts out of logging. This addon keeps the default (`Kit.diagnostics.enablesLogging` is not false), so the opt-out case does not apply and the case above it holds the contract. It is a pre-existing, by-design skip, present in the previous run too; it is counted in neither `passed` nor `failed`.

## What moved

- **lint:** 91 → 92 files, the added file being `tests/test_launcher_skin_entry.lua` (R6 work: Open skin selector from the launcher menu). Still 0/0. `.luacheckrc` exclusions unchanged.
- **tests:** 634 → 648 total (+14), 633 → 647 passed, skip count unchanged at 1. The new cases sit in the new launcher-entry suite and in `tests/test_skin_picker.lua`, `tests/test_skin_flip.lua`, `tests/test_profile_switch.lua` and `tests/test_database.lua` (the R6-PV preview/unlock work and the R6-PF1 profile-switch fix). `test-cases.md` is the authority.
- **perf:** the same 10 scenarios. `api/iter` and `bytes/iter` are identical to the previous run in all 10 (from both `perf.json` files), so no scenario does more work or allocates more. `ms/iter` moved in both directions (for example `maxMs` of `settingsDrag` 0.2104 → 0.1750 and of `resolveUnchanged` 0.0098 → 0.0123), which is host timing noise on an offline run and not a signal.
- **complexity:** NLOC 15219 → 15614 and functions 2133 → 2188 (the addon grew, mostly tests). avg NLOC 6.5 and avg CCN 2.1 unchanged, avg tokens 51.5 → 51.6 (within rounding of a flat density); max CCN 14 unchanged; 0 warnings both runs; no file entered the 1000–1500 band.

## Complexity watch list

### Functions `lizard` warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|

None.

## Actions

None.
