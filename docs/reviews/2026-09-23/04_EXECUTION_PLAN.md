# Execution plan — PartyFrameEnhanced review (2026-09-23)

Findings are in `01_FINDINGS.md`; changes are in `02_PROPOSED_CHANGES.md`. The standard is v2.64.0.
The work lands on the branch already checked out, `feat/2026-09-23-review-audit-remediation`. Pushing
and merging are the coordinator's call, not this plan's.

The order is fixed: **upstream first, then re-vendor, then this addon's own changes.** The re-vendor
is its own commit, so a later bisect can tell a library change from a host change.

## Milestones

### M0 — Upstream (LibKa0s repo): test-kit fidelity  *(cross-repo handoff)*

**Done when:** a LibKa0s release/tag exists whose `testkit/` carries both upstream fixes, the kit
README records the new revision, and LibKa0s's own suite is green.

| Task | Owner role | Findings | Files (LibKa0s repo) |
|---|---|---|---|
| U-1 | `testkit-maintainer` | F-011 | `testkit/mock_record.lua` (AceDB fake: `CopyProfile`/`DeleteProfile` raise like AceDB-3.0; `SetProfile` strips defaults from the outgoing profile), `testkit/README.md` revision entry |
| U-2 | `testkit-maintainer` | F-012 | `testkit/mock_base.lua` / `testkit/mock_record.lua` (a recording `EventRegistry`, surfaced in `__registrations()`), README revision entry |
| U-3 (optional) | `lib-docs` | F-010 | LibKa0s `docs/api/Slash/…` "Degradation": the prescribed library-absent stub shape |

**Serialization:**
- U-1 and U-2 touch overlapping kit files and share one revision bump, so they are serialized.
- U-3 is parallelizable with both.

**Collection impact:** U-1 can redden other consumers' suites wherever they relied on the lenient
fake. That is expected: it is the fake becoming honest. Coordinate it with the collection-wide plan.

### M1 — Re-vendor into this addon

**Done when:**
- `diff -rq tests/_kit ../LibKa0s/testkit` is empty, and so is
  `diff -rq libs/LibKa0s ../LibKa0s/LibKa0s` (the whole library folder, even if only the kit moved).
- `CLAUDE.md`'s provenance line names the new tag.
- `lua5.1 tests/run.lua` is green, **or** is red only where the new kit fidelity exposes F-004. If
  so, record that as expected and fix it in M2 (T-2), not by weakening a test.

| Task | Owner | Findings | Files |
|---|---|---|---|
| V-1 | `vendor-sync` | F-011, F-012 (consumer side) | `tests/_kit/**`, `libs/LibKa0s/**` (whole-folder copies only), `CLAUDE.md` provenance line |

### Checkpoint A (human)

Confirm the re-vendor commit contains **only** copied files plus the provenance line. Confirm
`tests/test_vendor_sync.lua` is green. List which existing cases the new kit reddened.

### M2 — Correctness fixes (High, then Medium)

**Done when:**
- every new case in 02 exists and carries its `-- red under:` comment;
- each new case was seen red against the pre-fix code, then green;
- the suite and lint are green, and `docs/test-cases.md` plus the README badge are regenerated in
  the **same commit** as each count move.

| Task | Owner | Findings / change | Files |
|---|---|---|---|
| T-1 | `lua-refactorer` | F-001, F-008 / C-001 | `modules/CastBars.lua`, `modules/TargetFrames.lua`, `modules/PetFrames.lua`, `modules/Anchor.lua` (comment), `tests/test_anchor.lua` or new `tests/test_profile_switch.lua` (+ `tests/run.lua` suite list if new) |
| T-2 | `ux-cleanup` | F-002, F-004, F-008 / C-002 | `settings/Slash.lua`, `locales/enUS.lua`, `tests/test_slash.lua` |
| T-3 | `secure-frames` | F-003 / C-003 | `modules/UnitButtons.lua`, `tests/test_targetframes.lua` (+ `tests/test_petframes.lua`) |

**Concurrency:**
- **T-1 ∥ T-3:** file sets are disjoint. T-1 touches the three feature files' `Anchor.Register`
  specs; T-3 touches `UnitButtons.lua`. Parallelizable.
- **T-2** shares `locales/enUS.lua` with T-8 (M4) only; parallel with T-1 and T-3.
- **Badge and inventory:** the three tasks each move the pass count. **Serialize their final commits**
  and regenerate `docs/test-cases.md` and the README badge in each one. Do not batch.

### Checkpoint B (human)

- Run smoke S-001, S-002 and S-003 in-client. S-001 needs five-plus switches, because the failure is
  hash-order dependent.
- Confirm there is no taint (T-1 in `03_SMOKE_TESTS.md`) before any stand-down work.

### M3 — Stand-down completeness

**Done when:** `tests/test_disabled.lua` asserts both stand-down changes (with the F-012 kit in
place, the registration-set step counts the `EventRegistry` callback), and smoke S-004 and S-005
pass.

| Task | Owner | Findings / change | Files |
|---|---|---|---|
| T-4 | `lifecycle` | F-005 / C-004 | `modules/Providers.lua`, `tests/test_disabled.lua` and/or `tests/test_providers.lua` |
| T-5 | `secure-frames` | F-006 / C-005 | `modules/UnitButtons.lua`, `modules/TargetFrames.lua`, `modules/PetFrames.lua`, `.luacheckrc` (UnregisterStateDriver kept), `tests/test_disabled.lua` |

**Concurrency:**
- **T-5 must follow T-3:** both edit `modules/UnitButtons.lua`, and T-5 builds on the `__driverWant`
  convention.
- **T-5 must follow T-1:** both edit `modules/TargetFrames.lua` and `modules/PetFrames.lua`, in
  different functions, but serialize to avoid merge churn.
- **T-4 ∥ T-5**, except that both add cases to `tests/test_disabled.lua`. Serialize the test edits,
  or give T-4 its cases in `tests/test_providers.lua`.

### Checkpoint C (human)

Run S-005 in and out of combat, with `/etrace` watching `ADDON_ACTION_BLOCKED`. **This is the
secure-code gate.**

### M4 — Evidence and hygiene

**Done when:**
- `tests/perf.lua` carries C-007's assertions and passes;
- `docs/performance.md` quotes a fresh run from the same commit;
- the hygiene rows are done with lint 0/0 and the suite green;
- smoke S-008 and S-009 pass.

| Task | Owner | Findings / change | Files |
|---|---|---|---|
| T-6 | `perf-evidence` | F-007 / C-007 | `tests/perf.lua` |
| T-7 | `perf-evidence` | F-009 / C-006 | `docs/performance.md`, `tests/perf.lua` (comments) |
| T-8 | `ux-cleanup` | F-014 / C-008 | `locales/enUS.lua`, `settings/Slash.lua`, `settings/General.lua` |
| T-9 | `lint-hygiene` | F-013 / C-008 | `.luacheckrc` |
| T-10 | `lua-refactorer` | F-015 / C-008 | `core/Database.lua`, `tests/test_database.lua` |
| T-11 | `ux-cleanup` | F-016 / C-008 | `modules/Anchor.lua`, `modules/StandIn.lua` |
| T-12 | `lua-refactorer` | F-017 / C-008 | `modules/TargetFrames.lua`, `modules/PetFrames.lua`, `modules/Preview.lua` |
| T-13 | `release-hygiene` | F-018 / C-008 | `.pkgmeta` (+ optional rename in `media/screenshots/`) |
| T-14 | `ux-cleanup` | F-010 / C-009 | `settings/Slash.lua`, `tests/test_surface_parity.lua` |

**Concurrency:**
- **T-6 → T-7:** serialize. They share `tests/perf.lua`, and T-7 quotes T-6's run.
- **T-8 → T-14:** serialize. They share `settings/Slash.lua`. T-8 also comes after T-2, because they
  share `settings/Slash.lua` and `locales/enUS.lua`.
- **T-9** comes after T-5, because `UnregisterStateDriver` gains its use there.
- **T-11** comes after T-1 (`modules/Anchor.lua`).
- **T-12** comes after T-1 and T-5 (feature files).
- **T-10 and T-13** are fully parallelizable.

### Checkpoint D (human)

Run the full regression suite R-1..R-9 and the cross-addon in-client step. Fill in the sign-off
table in `03_SMOKE_TESTS.md`.

## Critical path

**U-1/U-2 → V-1 → (T-1 ∥ T-2 ∥ T-3) → T-5 → T-12 → Checkpoint D.**

T-4, T-6/T-7, T-8/T-14, T-9, T-10, T-11 and T-13 hang off that path as noted above.

## Incremental commit strategy

One commit per task. The upstream milestone's commits live in the LibKa0s repo. Suggested messages
(imperative, matching the repo's recent history):

| Task | Commit message |
|---|---|
| V-1 | `Re-vendor LibKa0s vX.Y.Z (kit revision N: AceDB fake raises like AceDB, EventRegistry recorded)` |
| T-1 | `Anchor reads each feature's section live, so a profile switch places from the new profile` |
| T-2 | `Profile sub-verbs refuse a missing or existing name instead of wiping or raising` |
| T-3 | `Secure-write memos track the latest request, so an in-combat revert is not lost` |
| T-4 | `Stand the Edit Mode callback down with the rest of Providers` |
| T-5 | `Release the target and pet state drivers while stood down` |
| T-6 | `Pin the zero-overhead scenario against the unbracketed path` |
| T-7 | `Refresh docs/performance.md from a fresh offline run` |
| T-8..T-14 | one message each, naming the finding |

Every commit must pass `lua5.1 tests/run.lua` and `luacheck .`, and must carry the
`docs/test-cases.md` and badge move when the count moves. No commit touches `libs/` or `tests/_kit/`
except V-1.
