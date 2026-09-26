# Automated test records

Every recorded run of the four out-of-game suites. The normative rules are the standard's
[`automated-tests`](https://github.com/tusharsaxena/WowAddonStandards/blob/master/standards/standards/automated-tests.md)
section; this file is the local how-to.

## Running

```sh
tests/_kit/run-automated-tests.sh                                          # all four, writes a bundle
tests/_kit/run-automated-tests.sh --suite complexity                       # a subset
tests/_kit/run-automated-tests.sh --suite lint --suite tests --no-bundle   # the green gate; writes nothing
tests/_kit/run-automated-tests.sh --release 1.0.1                          # the release run, before the tag
```

The runner is **vendored** from LibKa0s's `testkit/` and is byte-identical in every Ka0s addon. Never
edit `tests/_kit/` — a kit fix goes upstream and is re-vendored.

## What gates, and what only records

There are **two checkpoints** — the run (and the commit it gates) and the release tag — and a suite's
answer differs between them:

| Suite | Command | Run + commit | Release tag |
|---|---|---|---|
| `lint` | `luacheck .` | **gates** | **gates** |
| `tests` | `lua tests/run.lua` | **gates** | **gates** |
| `perf` | `lua tests/perf.lua` | no — recorded | **gates** — `pass` required |
| `complexity` | `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` | no — recorded | **gates** — `pass`, zero functions above CCN 15 |

`perf` and `complexity` are **measured, recorded and diffed — they never fail a run and never block a
commit** (`performance-§9`, `performance-§10`). A threshold that fails a run teaches everyone to
reach for `--no-verify`, after which the gate protects nothing. They contribute `amber`, a signal
rather than a stop.

**At the tag all four gate** (`automated-tests-§3`, *The release gate*): `/wow-addon:bump-version`
reads the release run's `manifest.json` and refuses unless all four suites are at `pass` with
`suites.complexity.warnings` at `0`. That is a separate checkpoint evaluated by a separate actor — the
runner's exit code does not change — and a `skip` there is **NOT EVALUATED**, never a pass.

**A missing tool is a skip, not a failure**, recorded with its reason, so a green run that measured
nothing cannot be mistaken for one that measured everything.

## What is here

- **`RESULTS.md`** — one row per run across all four suites, plus the complexity watch list.
  **Generated** by the runner and overwritten in place, so the git history of that one path is the
  trend line. The one hand-written cell is the watch list's `Disposition` column.
- **`<YYYYMMDD-HHMMSS>/`** — one frozen bundle per run: `manifest.json`, one file per suite, and
  `ANALYSIS.md`, the hand-written write-up: required for a release run and written for most others
  (`automated-tests-§5`). Bundles are **never edited** and **never pruned**.

Offline perf records live in the bundle of the run that produced them. **In-game** captures cannot be
produced by a script, so they keep their own store at [`../perf-analysis/`](../perf-analysis/).
