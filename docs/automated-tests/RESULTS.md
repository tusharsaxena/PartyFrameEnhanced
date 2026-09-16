# Automated test results

<!-- Regenerated whole by tests/_kit/run-automated-tests.sh on every run. -->
<!-- This file is OVERWRITTEN IN PLACE — the git history of this one path is the trend line. -->
<!-- Everything here is generated EXCEPT the watch list's Disposition column. -->

One row per run. The frozen evidence for each is in the dated folder beside this file;
the analysis of a given run is its `ANALYSIS.md`.

**`lint` and `tests` gate the run and gate the commit** (`testing-§4`).
**`perf` and `complexity` never fail a run and never block a commit** — they are recorded,
read and compared, not thresholded (`performance-§9`, `performance-§10`).

**The tag is gated on all four suites at `pass`, plus zero functions above CCN 15**
(`automated-tests-§3`, *The release gate*), evaluated by `/wow-addon:bump-version` from the
`manifest.json` the release run writes — not by this script, whose exit code is unchanged.

A `skip` is a suite that did not run at all. It is never a pass, and at the release gate it is
**NOT EVALUATED** rather than passed: install the tool and re-run. A `—` is a suite that was
not selected, which is a different fact again.

The **Tests** cell reads `passed/skipped/total`.

| Run | Version | Lint w/e | Files | Tests | Perf | NLOC | Funcs | Avg NLOC | Avg CCN | Max CCN | CCN warn | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| [`20260916-184541`](20260916-184541/) | 0.1.0 | 0/0 | 68 | 212/0/212 | pass | 6868 | 880 | 6.1 | 2.2 | 15 | 0 | **green** |
| [`20260916-094218`](20260916-094218/) | 0.1.0 | 0/0 | 66 | 185/0/185 | pass | 6452 | 824 | 6.1 | 2.3 | 15 | 0 | **green** |
| [`20260915-154839`](20260915-154839/) | 0.1.0 → 0.1.0 | 0/0 | 61 | 136/0/136 | pass | 5242 | 678 | 5.8 | 2.3 | 15 | 0 | **green** |
| [`20260915-150853`](20260915-150853/) | 0.1.0 → 0.1.0 | 0/0 | 59 | 129/0/129 | pass | 4995 | 664 | 5.7 | 2.3 | 15 | 0 | **green** |
| [`20260915-141340`](20260915-141340/) | 0.1.0 | 0/0 | 39 | 66/0/66 | pass | 1828 | 288 | 4.3 | 2.0 | 15 | 0 | **green** |

## Test suite

**212 cases** — 212 passed, 0 failed, 0 skipped. The generated inventory
[`20260916-184541/test-cases.md`](20260916-184541/test-cases.md) is the authority on which cases existed at this run;
`docs/test-cases.md` is that same list at HEAD.

Moved **185 → 212** since the previous run.

No case reported a `skip`, so passed and total agree and nothing in this row claims coverage
that was not exercised.

## Lint

**0 warnings / 0 errors over 68 files** (`luacheck .`).

Read that figure with its scope attached: `.luacheckrc` sets `exclude_files = { "libs/", "docs/audits/", "docs/reviews/", "_dev/", "tests/_kit/" }`, so those paths
are not in it. A `0/0` that never moves is partly a statement about what was never looked at, which
is why the exclusion is restated on every run.

## Perf

**9 scenarios** from `tests/perf.lua`; the measurements are in
[`20260916-184541/perf.json`](20260916-184541/perf.json).

`perf` never fails a run and never blocks a commit — it is recorded, read and compared, not
thresholded (`performance-§9`). It does gate the **tag** (`automated-tests-§3`).

## Complexity watch list

Current as of [`20260916-184541`](20260916-184541/) — **this run's measurement, not its diff.** Max CCN **15** across 880
functions, **0** of them warned on; 0 file(s) in the 1000–1500 band and 0 over the 1500 cap
(`layout-§1`).

Every row below is generated from this run's own `lizard` output. **The `Disposition` column is
the one authored cell in this file** (`automated-tests-§4`, *the one boundary*): it is carried
forward verbatim while its entry is unchanged, and left **blank** when the entry is new — a blank
cell is this file saying something crossed and nobody has ruled on it yet.

### Functions `lizard` warned on

None.

### Files by `layout-§1` band

None.

`lizard` counts every `and`/`or` short-circuit as a decision, so in Lua a run of
`t.k = rec.k or D.k` defaulting lines scores high with no visible branching at all: a large CCN
here usually means *this function defaults or guards a lot of fields* rather than *this function
is tangled*, and the two want different fixes (`performance-§10`).

