# Analysis — 20260916-184541

- **Addon:** PartyFrameEnhanced 0.1.0
- **Verdict:** green
- **Commit:** 01e7c1e392fd4587b66334e54ef187c1c113349b (master), clean
- **Previous run:** 20260916-094218

## Headline

All four suites pass over a clean tree, and the release gate's extra condition still holds — **zero
functions above CCN 15**, with the ceiling sitting at exactly 15 for the fourth run running. The day's
work since the morning run was the launcher adoption plus the removal of the separate test mode in
favour of the lock being the only preview switch, and the suite grew with it: **185 → 212 cases**. The
density figures barely moved (avg CCN 2.3 → 2.2, avg NLOC/function flat at 6.1) while the addon added
416 NLOC, so the growth was breadth, not tangle. Nothing is owed a disposition.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260916-094218 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 68 files | [`lint.txt`](lint.txt) | files 66 → 68 |
| tests | pass | 212 passed, 0 skipped, 0 failed, 212 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 185 → 212 |
| perf | pass | 9 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | unchanged (timings only) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | see below |

Complexity, in full — from [`manifest.json`](manifest.json) `suites.complexity` and the
[`complexity.txt`](complexity.txt) footer:

| Metric | Value | Previous |
|---|---|---|
| Total NLOC | 6868 | 6452 |
| Functions | 880 | 824 |
| Avg NLOC / function | 6.1 | 6.1 |
| Avg CCN | 2.2 | 2.3 |
| Max CCN | 15 | 15 |
| Avg tokens / function | 46.3 | 45.9 |
| Warnings (CCN > 15) | 0 | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 | 0 |
| Files over the 1500 cap | 0 | 0 |

Every suite is a clean pass, so there is no non-passing suite to explain and no skip to report. All
three external tools were present on the host ([`manifest.json`](manifest.json) `host`): Lua 5.1.5,
Luacheck 1.2.0, lizard 1.24.0. The whole run took 11.5 s.

## What moved

- **lint:** still **0/0**, now over **68** files (66 before). The file list in
  [`lint.txt`](lint.txt) explains the +2 exactly: `core/LauncherSetup.lua`, `tests/launcher_env.lua`,
  `tests/test_launcher.lua` and `tests/test_preview_standin.lua` arrived; `modules/TestMode.lua` and
  `tests/test_testmode.lua` left with the test mode. Read the `0/0` with its scope attached —
  `.luacheckrc`'s `exclude_files` holds `libs/`, `docs/audits/`, `docs/reviews/`, `_dev/` and
  `tests/_kit/`, so none of those was ever in the 68.
- **tests:** **185 → 212** (+27), and the git log makes every part of it legible. Per file, from
  [`test-cases.md`](test-cases.md) against the previous run's copy: `test_launcher.lua` **new, 17**
  (the LDB object and minimap button adopted in `0ef382e` / `336518a`); `test_preview_standin.lua`
  **new, 17** replacing `test_testmode.lua` (**−16**) — test mode was removed in favour of the lock
  being the only preview switch, so the stand-in is now exercised through preview rather than through
  a verb of its own; `test_slash.lua` **12 → 19** (+7), which is `2777866` making a disabled addon
  refuse the verbs that drive what it draws; `test_targetframes.lua` **16 → 18** (+2), the regression
  cover for `e07419c` — the player's own frame is now driven by `PLAYER_TARGET_CHANGED`, because
  `UNIT_TARGET` does not fire for the player. Every other file's count is unchanged. Nothing skipped,
  so passed and total agree and the row claims no coverage that was not exercised.
- **perf:** **9 scenarios**, the same nine as the previous run. The deterministic columns are
  identical row for row: api/iter matches on all nine, SetPoint calls/iter is 0.0 everywhere, and
  bytes/iter is 0.0 on every hot path except `castStartStop` at 16.6 (issue #12) and `settingsDrag`
  at 595.9, both reported and unasserted by design. So the launcher and the test-mode removal added
  no allocation and no API traffic to a hot path. Only ms/iter moved, and every scenario got slower
  by a similar factor (`resolveUnchanged` 0.00780 → 0.00904, `targetTickMoving` 0.00547 → 0.00707) —
  a uniform shift across all nine is host noise, not a code change, and the harness says as much:
  timings are for orientation within a run only.
- **complexity:** NLOC 6452 → 6868 (+6.4%) and functions 824 → 880 (+6.8%) — the addon grew, and the
  two grew together, which is why the **totals** rising is not a complexity signal. The **averages**
  are: avg NLOC/function flat at 6.1, avg CCN 2.3 → **2.2** (down), avg tokens 45.9 → 46.3. Max CCN
  held at exactly **15** and warnings stayed at **0**, so nothing newly approached the gate. The two
  functions at the ceiling are unchanged in count and shape: `NS.ValidateSchema` (CCN 15,
  `settings/Schema.lua`, whose range slid 278-306 → 328-357 as the schema grew) and
  `Providers.Resolve` (CCN 15, `modules/Providers.lua:199-228`, identical range). Below them the
  ranking is also unchanged — `NS.SetByPath` 14, `NS.ResolveColor` 14, `build` 12, `OnSlash` 12.

## Complexity watch list

### Functions `lizard` warned on

None. Nothing crossed CCN 15 this run, and nothing has in any recorded run, so no disposition has
ever been carried here — the three-release **Accepted** shelf life has nothing to bite on. The two
functions sitting *at* 15 are dense **defaulting and validating**, not tangled control flow:
`NS.ValidateSchema` walks the schema field by field, and `Providers.Resolve` is a run of
`t.k = rec.k or D.k` defaults. `lizard` scores every `and` / `or` short-circuit as a decision, so
both score high with almost no visible branching; they want a split, not an untangle.

### Files by `layout-§1` band

None. No authored `.lua` the repo tracks reached the 1000-line band, let alone the 1500 cap
([`manifest.json`](manifest.json): `bandFiles` 0, `overCapFiles` 0).

## Actions

1. `NS.ValidateSchema` (`settings/Schema.lua:328`) and `Providers.Resolve`
   (`modules/Providers.lua:199`) still sit at exactly CCN 15, the release gate's ceiling, and this is
   the second consecutive run carrying that note. Neither is a warning today, but one more `or`
   default in either turns the next release run red at `/wow-addon:bump-version`. `ValidateSchema`
   gained 30 lines of range this run without gaining a decision; the next schema field may not be so
   kind. Worth a split before more provider kinds or schema sections land.
2. `docs/testing.md`'s lint paragraph — "Eight `files[...]` stanzas each name one file and one code
   (`212/self`)" — was checked against `.luacheckrc` and is **correct**, and there is no disagreement
   to flag. The file holds nine `files[...]` stanzas, of which the first (`files["tests/"]`) declares
   harness globals rather than an ignore, leaving exactly eight `212/self` stanzas over
   `core/PartyFrameEnhanced.lua`, `core/Database.lua`, `settings/Slash.lua` and the five modules
   (`Providers`, `CastBars`, `TargetFrames`, `PetFrames`, `Preview`). No action; recorded so the next
   run does not re-derive it.
3. Otherwise none. The remaining pre-tag work is what only a live client can show: the in-game smoke
   suite and a `/pfe perf` capture (plan P10). Parked work is issues #1–#12.
