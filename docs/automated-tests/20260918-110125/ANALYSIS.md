# Analysis — 20260918-110125

- **Addon:** Ka0s Party Frame Enhanced 0.1.0
- **Verdict:** green
- **Commit:** f111ee0 (master), dirty
- **Previous run:** [`20260918-105401`](../20260918-105401/)

The tree was dirty with two kinds of change, and only the second is code:

- **Records.** Two in-game perf-analysis bundles and their store README, plus the previous run's
  bundle and its `RESULTS.md` row.
- **The CCN fix.** `settings/Slash.lua` (the library-less stub dispatcher split) and
  `tests/test_surface_parity.lua` (its characterization case). This run measures that fix
  uncommitted on top of `f111ee0`.

## Headline

All four suites passed, and **the complexity watch list is empty again**: `OnSlash` is down from CCN
16 to 12 and no function is above 15. So the release gate's zero-above-15 condition holds on this
tree. One function sits **exactly at the ceiling**: `applyAttached` in `modules/Anchor.lua` at 15. It
was already there in the previous run, and that run's analysis didn't mention it.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260918-105401 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 70 files | [`lint.txt`](lint.txt) | unchanged |
| tests | pass | 227 passed, 0 skipped, 0 failed, 227 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 226 → 227 (+1) |
| perf | pass | 9 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | `api/iter` and `bytes/iter` identical in all nine |
| complexity | pass | 0 warnings, max CCN 15 | [`complexity.txt`](complexity.txt) | warnings 1 → 0, max 16 → 15 |

Every figure comes from [`manifest.json`](manifest.json):

| Metric | Value |
|---|---|
| Total NLOC | 7357 |
| Functions | 940 |
| Avg NLOC / function | 6.3 |
| Avg CCN | 2.2 |
| Max CCN | 15 |
| Avg tokens / function | 46.9 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |

All four suites passed cleanly. Nothing was skipped: `lua`, `luacheck` and `lizard` were all present.

## What moved

- **lint:** 70 files, 0/0, unchanged. The same five exclusions (`libs/`, `docs/audits/`,
  `docs/reviews/`, `_dev/`, `tests/_kit/`).
- **tests:** 226 → 227. The one new case is in `test_surface_parity.lua` (5 → 6,
  [`test-cases.md`](test-cases.md)). It pins the library-less stub's dispatch: the verb lowercased
  and trimmed, the `options` alias, a typo getting `unknown command` plus help, and the disabled gate
  (a feature verb refused on one line, a live verb, the bare form and a typo all still answering).
- **perf:** identical `api/iter` and `bytes/iter` in all nine scenarios, so the dispatcher change
  touched no measured path. `settingsDrag` is still 885.9 bytes/iter, so the previous run's open
  question about its +290 bytes remains open. `ms/iter` moved by small amounts in both directions,
  which the runner says is orientation only.
- **complexity:** max CCN 16 → 15 and warnings 1 → 0. NLOC 7322 → 7357 (+35) and functions
  936 → 940 (+4): the lifted `findCommand` helper plus the new test's closures. Avg CCN is unchanged
  at 2.2, avg NLOC went from 6.2 to 6.3, and avg tokens is unchanged at 46.9. In
  [`complexity.txt`](complexity.txt), `OnSlash@359-378` now reads CCN 12 and `findCommand@345-349`
  reads 3.
- **At the ceiling, not over it:** `applyAttached@117-148` in `modules/Anchor.lua` is at **CCN 15**
  ([`complexity.txt`](complexity.txt)). It was 8 in every bundle up to `20260916-184541`, and
  reached 15 with `285623b`, the profile-switch crash fix that defaults `point` and `relativePoint`
  and unpins an element it can't place. The previous run already measured it at 15, and its analysis
  should have flagged it. It's almost entirely **defaulting and guarding**: `cfg.point or d.point`,
  `cfg.relativePoint or d.relativePoint`, the two offset defaults, `matchWidth and true or false`,
  and `not target or not point or not rel` plus `(point and rel) and target or nil`. The control flow
  itself is one loop. It isn't a warning, but one more `or` there makes the next release run red.
  The two functions next closest are both at 14: `NS.ResolveColor` (`core/CoreSetup.lua`) and
  `NS.SetByPath` (`settings/Schema.lua`).

## Complexity watch list

**Functions `lizard` warned on:**

None.

**Files by `layout-§1` band:**

None.

## Actions

1. **Take `applyAttached` off the ceiling before it's touched again** (`modules/Anchor.lua:117`). Lift
   the placement defaulting (point, relative point, offsets, match width, with the shipped fallback)
   into a local `placementOf(spec, cfg)` that returns the five values. That leaves the loop and the
   unplaceable-element guard in `applyAttached`, and it's the same split `e0a453e` gave
   `ValidateSchema` and `Providers.Resolve`. `tests/test_anchor.lua` already pins the stripped-profile
   case from `285623b`. New here. The previous run missed it.
2. **Account for `settingsDrag`'s 885.9 bytes/iter** (carried from 20260918-105401, still untracked).
   It's unchanged by this run, which rules out the stub dispatcher and leaves `core/Bus.lua`'s
   receiver wrapper as the lead.
3. **Commit the fix this run measured.** `settings/Slash.lua` and `tests/test_surface_parity.lua` are
   uncommitted. A release run has to be taken on a clean tree for its `manifest.json` to name the
   commit it gates.
