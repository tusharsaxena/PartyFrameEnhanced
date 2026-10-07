# Final summary — Ka0s Party Frame Enhanced (2026-10-07 review)

*Written on the assumption that every change in `02_PROPOSED_CHANGES.md` has landed and every check in `03_SMOKE_TESTS.md` has passed. Until the sign-off table there is filled in, this is a projection, not a record.*

## Headline

The review found the addon in good shape. Lint was clean, all 454 runnable tests passed, nothing exceeded the complexity limit, and the vendored payload matched the library exactly. The fixes close two edge-case holes in how the addon handles combat. First, a profile switch during a fight can no longer turn the placeholder preview on, which had hidden real cast bars until the fight ended. Second, one failing deferred secure write can no longer silently disable every later queued write for the rest of the session. The remaining changes tidy `/pfe status`, make `/pfe profile new` rebuild once instead of twice, and trim small allocations on combat transitions.

## Counts

Critical fixed: 0, High fixed: 0, Medium fixed: 2, Low fixed: 4. Nothing is deferred.

## Changes by theme

### A. One combat gate for the preview switch

- **What changed.** Switching to a profile saved unlocked while in combat now re-locks that profile and prints `Locked — combat started`, as entering combat already did.
- **Why it mattered.** The combat refusal lived only on the Lock row, so a profile switch went around it and replaced live cast bars with placeholders for the rest of the fight.
- **Findings / changes.** F-001 / C-001.
- **Files.** `modules/Preview.lua`, `tests/test_profile_switch.lua`.

### B. A flush that cannot strand its own queue

- **What changed.** Each deferred secure write runs isolated. A failure is logged on the console and passed to the client's error handler, and the rest of the queue still runs. The stand-down's re-wrap of another addon's handler is guarded.
- **Why it mattered.** One raising write used to abort the flush and leave later keys permanently unqueueable in combat until `/reload`.
- **Findings / changes.** F-002, F-003 / C-002, C-003.
- **Files.** `core/PartyFrameEnhanced.lua`, `modules/SecureFollow.lua`, `.luacheckrc`, `tests/test_lifecycle.lua` (or `tests/test_secure_queue.lua` plus `tests/run.lua`), `tests/test_securefollow.lua`.

### C. Status and profile-verb polish

- **What changed.** `/pfe status` names the unlocked state once. `/pfe profile new` no longer runs a reset that changed nothing.
- **Findings / changes.** F-004, F-005 / C-004, C-005.
- **Files.** `settings/Slash.lua`, `locales/enUS.lua`, `tests/test_preview_standin.lua`, `tests/test_slash.lua`.

### D. Precompute what the secure paths rebuild

- **What changed.** Visibility-driver strings are built once per button, and the in-combat anchor key and closure once per feature. A `visibilityFlip` offline scenario measures the effect.
- **Findings / changes.** F-006 / C-006.
- **Files.** `modules/UnitButtons.lua`, `modules/Anchor.lua`, `tests/perf.lua`, `docs/performance.md`.

## API / behavior changes

- Switching to a profile stored unlocked during combat now locks it and prints one chat line.
- `/pfe profile new <name>` writes one `[Profile]` debug line instead of a `[Profile]` and a `[Set]` line.
- `/pfe status` no longer prints a trailing bare `unlocked`. The locale key `"unlocked"` is removed from `locales/enUS.lua`.
- No slash verbs, schema rows, defaults or SavedVariables keys were added, renamed or removed.

## SavedVariables / migration notes

None. No schema bump, and `NS.SCHEMA_VERSION` stays at 1.

## Deprecated-API migrations

None.

## Performance impact

The only measured figure is C-006's `visibilityFlip` before and after, from one `tests/perf.lua` session, as recorded in `docs/performance.md` by T7. No number is stated here until that run exists.

## Test and complexity movement

- Pass count: 454 passed / 455 total → **461 passed / 462 total** (7 new cases, 1 skip unchanged). `docs/test-cases.md` and the README `Tests` badge move in each commit that adds cases.
- Complexity: no watch-list entry is expected to move. Max CCN was 14 today, and the next release's regeneration of `docs/automated-tests/RESULTS.md` should confirm that.

## Known follow-ups

- `docs/automated-tests/RESULTS.md` is 47 commits stale (newest bundle `20260927-030324`). It regenerates at the next release, and it is not regenerated here.
- The Documented-deviations row on the gated SecureFollow residue says it is pending owner ratification. That belongs to the standards audit, not this review.

## Verification evidence

- `03_SMOKE_TESTS.md` with its sign-off table filled in by the owner.
- The commit range on `feat/2026-10-07-review-audit-remediation` implementing T1–T7.

## Suggested PR description

```
PartyFrameEnhanced: 2026-10-07 review fixes (F-001..F-006)

- F-001: a profile switch during combat re-locks instead of starting preview, so live cast bars
  are never replaced by placeholders mid-fight.
- F-002: each deferred secure write runs isolated; one raise no longer orphans later keys for
  the session.
- F-003: SecureFollow's re-wrap of another addon's handler is guarded.
- F-004: /pfe status prints the unlocked state once.
- F-005: /pfe profile new no longer runs a redundant reset (one rebuild, not two).
- F-006: driver strings and the in-combat anchor closure are precomputed; a new visibilityFlip
  offline scenario measures it.

Tests 455 -> 462 (461 passed, 1 skipped); luacheck 0/0; no CCN > 15; no SavedVariables change.
```
