# Execution plan — Ka0s Party Frame Enhanced (2026-10-07 review)

Branch: `feat/2026-10-07-review-audit-remediation` (shared with the collection-wide run). The green gate before every commit is `lua tests/run.lua` plus `luacheck .` at 0/0, and complexity stays at 0 functions above CCN 15. Nothing is pushed, merged or version-bumped without the owner's go-ahead.

## Milestones

### M1: correctness and resilience (F-001, F-002, F-003)

Done when C-001, C-002 and C-003 are committed, the suite is green at 460 total (459 passed, 1 skipped), and `docs/test-cases.md` and the README badge match.

| Task | Role | Implements | Files |
|---|---|---|---|
| T1 | lua-fixer | F-001 / C-001 | `modules/Preview.lua`, `tests/test_profile_switch.lua`, `docs/test-cases.md`, `README.md` |
| T2 | lua-fixer | F-002 / C-002 | `core/PartyFrameEnhanced.lua`, `.luacheckrc`, `tests/test_lifecycle.lua` (or new `tests/test_secure_queue.lua` plus `tests/run.lua`), `docs/test-cases.md`, `README.md` |
| T3 | lua-fixer | F-003 / C-003 | `modules/SecureFollow.lua`, `tests/test_securefollow.lua`, `docs/test-cases.md`, `README.md` |

### M2: UX and profile-verb polish (F-004, F-005)

Done when the suite is green at 462 total and the inventory and badge match.

| Task | Role | Implements | Files |
|---|---|---|---|
| T4 | ux-cleanup | F-004 / C-004 | `settings/Slash.lua`, `locales/enUS.lua`, `tests/test_preview_standin.lua`, `docs/test-cases.md`, `README.md` |
| T5 | ux-cleanup | F-005 / C-005 | `settings/Slash.lua`, `tests/test_slash.lua`, `docs/test-cases.md`, `README.md` |

### M3: allocation trim (F-006)

Done when the `visibilityFlip` scenario exists, its before and after figures from one session are recorded in `docs/performance.md`, and the suite is green with no count change.

| Task | Role | Implements | Files |
|---|---|---|---|
| T6 | perf | F-006 / C-006, step 1 (scenario first) | `tests/perf.lua` |
| T7 | perf | F-006 / C-006, steps 2–3 | `modules/UnitButtons.lua`, `modules/Anchor.lua`, `docs/performance.md` |

No upstream milestone: there are no `[upstream]` findings.

## Critical path and concurrency

- `docs/test-cases.md` and `README.md` are touched by T1–T5, so **those tasks must serialize** (each regenerates the inventory and moves the badge in its own commit).
- `settings/Slash.lua` is touched by T4 and T5, so they serialize.
- T2 adds `geterrorhandler` to `.luacheckrc`. No other task touches that file.
- T6 must precede T7, because the before figure is measured first.
- Code edits with disjoint file sets can be **drafted in parallel**: T1 (Preview), T2 (core), T3 (SecureFollow), T6 and T7 (perf, UnitButtons, Anchor). Commits still land one at a time because of the shared inventory.
- Order: T1 → T2 → T3 → checkpoint → T4 → T5 → T6 → T7 → checkpoint.

## Checkpoints

- **After M1:** run the full gate. Then run in-client smoke tests C-001 through C-003, plus the taint-specific check (owner).
- **After M3:** run the full gate, then `lua tests/perf.lua` to confirm the `visibilityFlip` direction. Owner smoke covers C-004 through C-006 and the regression suite.

## Commit strategy

One commit per task, with each subject starting with the item id the collection plan assigns to it. Suggested bodies:

- T1: `fix(preview): a profile switch in combat re-locks instead of starting preview (F-001)`
- T2: `fix(core): isolate each deferred secure write so one raise cannot orphan the queue (F-002)`
- T3: `fix(follow): guard the re-wrap in unwrapFrame (F-003)`
- T4: `fix(slash): /pfe status prints one unlocked flag (F-004)`
- T5: `fix(slash): /pfe profile new no longer runs a redundant reset (F-005)`
- T6: `test(perf): add the visibilityFlip scenario (F-006)`
- T7: `perf: cache driver strings and the in-combat anchor closure (F-006)`

Each commit ends with the session's attribution trailers.
