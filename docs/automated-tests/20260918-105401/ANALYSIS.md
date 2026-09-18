# Analysis — 20260918-105401

- **Addon:** Ka0s Party Frame Enhanced 0.1.0
- **Verdict:** green
- **Commit:** f111ee0 (master), dirty
- **Previous run:** [`20260916-184541`](../20260916-184541/)

The tree was dirty with documentation only. The uncommitted files were the two in-game perf-analysis
bundles from this morning (`docs/perf-analysis/20260918-102842/`, `20260918-104528/`) and their
store `README.md`. No `.lua` file differed from `f111ee0`, so every suite measured that commit's code.

## Headline

All four suites passed. Lint is clean over 70 files, and all 226 cases passed with none skipped. One
thing needs acting on: **`OnSlash` in `settings/Slash.lua` newly crossed to CCN 16**. That doesn't
affect this run or a commit, but it **blocks the next release** until it's split, because the tag
needs zero functions above 15. The two functions that sat at exactly 15 last run have been split
(`e0a453e`) and are off the ceiling.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260916-184541 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 70 files | [`lint.txt`](lint.txt) | files 68 → 70; still 0/0 |
| tests | pass | 226 passed, 0 skipped, 0 failed, 226 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 212 → 226 (+14) |
| perf | pass | 9 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | same 9; `api/iter` unchanged everywhere; `settingsDrag` bytes up (below) |
| complexity | pass | 1 warning, max CCN 16 | [`complexity.txt`](complexity.txt) | warnings 0 → 1, max 15 → 16 |

Every figure comes from [`manifest.json`](manifest.json) and the linked artifacts:

| Metric | Value |
|---|---|
| Total NLOC | 7322 |
| Functions | 936 |
| Avg NLOC / function | 6.2 |
| Avg CCN | 2.2 |
| Max CCN | 16 |
| Avg tokens / function | 46.9 |
| Warnings (CCN > 15) | 1 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |

**complexity** ran and reported, so it isn't a failure, but it has one warning. `OnSlash@353-377`
(NLOC 22, CCN 16, 192 tokens, [`complexity.txt`](complexity.txt) line 482) is the dispatcher of the
**fallback slash stub**, which `settings/Slash.lua` builds when `LibKa0s-Slash` is missing. The
previous run measured it at CCN 12 (NLOC 17, lines 343-360). The +4 came in with `a8e3a44`, which
added the disabled gate: `isDown()`, the `live[cmd]` checks and the second refusal after the loop.
About half its decisions are `or` defaults (`msg or ""`, `cmd or ""`, `d.aliases or {}`,
`rest or ""`, plus the `match(...) or ""` trim). The other half is real dispatch: bare versus verb,
the lookup loop, and the two disabled-refusal branches. It's **mixed**, not purely defaulting, so a
peel is the right response rather than accepting it.

## What moved

- **lint:** 68 → 70 files in scope, still 0/0. The exclusions are the same five
  (`libs/`, `docs/audits/`, `docs/reviews/`, `_dev/`, `tests/_kit/`). The two new files are
  `core/LifecycleSetup.lua` and `tests/test_disabled.lua`, both from `a8e3a44`.
- **tests:** 212 → 226. The +14 come from the stand-down work (`tests/test_disabled.lua`) and the
  in-game fixes since the last run (anchor drag handles, lock clearing the drag, late target names,
  the player's own target). None skipped, as before.
- **perf:** the same nine scenarios. `api/iter` is unchanged in every one, and `SetPoint` calls/iter
  are still 0.0 across the board. Allocation moved in two:
  - `castStartStop` went from **16.6 to 3.6 bytes/iter**.
  - `settingsDrag` went from **595.9 to 885.9 bytes/iter** (+49%) with the same 25 `api/iter`. That's
    a settings-panel drag, not a combat path. But the run doesn't say where the extra ~290 bytes
    come from, and `a8e3a44`'s wrapping of bus receivers (`core/Bus.lua`) is the change in range
    that touches message dispatch. That's a lead, not a finding.

  `ms/iter` figures moved slightly in both directions. The runner says they're for orientation only
  and not comparable across runs.
- **complexity:** NLOC 6868 → 7322 (+454), functions 880 → 936 (+56). **Avg CCN is unchanged at
  2.2.** Avg NLOC went from 6.1 to 6.2 and avg tokens from 46.3 to 46.9, both essentially flat. The
  addon grew without getting denser. The one real signal is the single function that crossed: max CCN
  went from 15 to 16, and warnings from 0 to 1. No file entered the 1000–1500 band.
- **The previous run's action 1** (`NS.ValidateSchema` and `Providers.Resolve` at exactly CCN 15) was
  done in `e0a453e`. Neither appears near the ceiling now.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|
| `OnSlash` | 16 | `settings/Slash.lua` | **Peel next.** New this run (12 → 16 from `a8e3a44`'s disabled gate). Mixed defaulting and real dispatch. It blocks the next release |

**Files by `layout-§1` band:**

None.

## Actions

1. **Peel the fallback stub's `OnSlash` below 16 before the next release** (`settings/Slash.lua:353`).
   The command lookup plus its disabled gate (the loop and the post-loop `live[cmd]` refusal) is one
   question, "resolve this verb to a handler or a refusal", and can be lifted into a local helper,
   leaving `OnSlash` to trim, handle the bare case and call it. Pin the stub's behavior first. This
   path runs only without LibKa0s, so check that `tests/test_slash.lua` exercises the stub (the
   library-missing arm), not only the library dispatcher, before moving anything. New here, and
   `/wow-addon:bump-version` refuses the tag until it's done.
2. **Account for `settingsDrag`'s +290 bytes/iter** (`tests/perf.lua` `settingsDrag`, 595.9 → 885.9).
   Check whether each CONFIG publish during a drag now allocates in `core/Bus.lua`'s receiver
   wrapper, and if so whether it can reuse a table. It's not a combat path, so it's low priority.
   New here.
3. The in-game work still outstanding is recorded in the perf-analysis store, not here: pet frames
   still have no measurement, and a solo capture would confirm the hidden-target-button fix. See
   `docs/perf-analysis/README.md`. These offline scenarios say nothing about frame time.
