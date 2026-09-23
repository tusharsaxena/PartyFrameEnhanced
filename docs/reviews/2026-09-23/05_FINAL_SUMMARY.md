# Final summary — PartyFrameEnhanced review-and-fix cycle (2026-09-23)

*This summary assumes every change in `02_PROPOSED_CHANGES.md` was applied through the milestones in
`04_EXECUTION_PLAN.md`, and that `03_SMOKE_TESTS.md` passed. Any number marked **TBD** comes from
the implementing run and must be filled from its measured output. None may be estimated.*

## Headline

This cycle fixed two defects players hit in normal use:
- Switching or resetting a profile could leave cast bars, target frames or pet frames where the
  *previous* profile put them. The cause was bus handler ordering, which Lua does not define.
- `/pfe profile new <name>` could silently erase an existing profile of the same name.

It also:
- hardened the other profile sub-verbs against mistyped names;
- made an in-combat change to *Click to target* that is reverted stick after combat;
- completed the "disabled means not running" contract for the two registrations that still survived
  it, the Edit Mode callback and the secure state drivers;
- made the offline perf evidence prove what it claims, and tidied lint, locale, migration and
  packaging loose ends.

Two test-kit fidelity gaps were fixed upstream in LibKa0s and arrived here by a whole-folder
re-vendor.

## Counts

| Bucket | Raised | Fixed | Deferred |
|---|---|---|---|
| Critical | 0 | 0 | 0 |
| High | 2 (F-001, F-002) | 2 | 0 |
| Medium | 7 (F-003–F-008, F-011) | 7 (F-011 upstream + re-vendor) | 0 |
| Low | 9 (F-009, F-010, F-012–F-018) | 9 (F-012 upstream + re-vendor) | 0 |

**Deferred:** none by plan. U-3 (a documentation of the Slash stub shape in LibKa0s) is optional.
C-009 is complete without it.

## Changes by theme

### T1 — Profile adoption no longer depends on dispatch order

- **What changed:** the anchor engine reads each feature's settings straight from the active profile.
  It no longer reads through a copy that the feature refreshes in its own profile handler.
- **Why it mattered:** Lua visits message receivers in hash order, so after a switch or reset some
  features stayed placed by the old profile. Which ones varied per session.
- **Findings:** F-001, F-008. **Changes:** C-001.
- **Files:**
  - `modules/CastBars.lua`, `modules/TargetFrames.lua`, `modules/PetFrames.lua`, `modules/Anchor.lua`
  - `tests/test_anchor.lua` (or `tests/test_profile_switch.lua`, plus `tests/run.lua`)
  - `docs/test-cases.md`, `README.md` (badge)

### T2 — Profile sub-verbs validate names

- **What changed:**
  - `new` refuses an existing name.
  - `use`, `copy` and `delete` refuse an unknown name.
  - `copy` refuses the current profile.

  Each refusal is one tagged line.
- **Why it mattered:** `new` wiped existing profiles, `copy` raised raw AceDB errors, `delete`
  acknowledged deletions that never happened, and `use` created profiles from typos.
- **Findings:** F-002, F-004, F-008. **Changes:** C-002.
- **Files:** `settings/Slash.lua`, `locales/enUS.lua`, `tests/test_slash.lua`, `docs/test-cases.md`,
  `README.md` (badge).

### T3 — Secure writes honor the latest request

- **What changed:** the click-to-target and visibility-driver writes remember what was last
  *asked for*, not what was last *applied*.
- **Why it mattered:** a setting reverted during combat was dropped, which left target and pet frames
  unclickable after combat.
- **Findings:** F-003. **Changes:** C-003.
- **Files:** `modules/UnitButtons.lua`, `tests/test_targetframes.lua`, `tests/test_petframes.lua`.

### T4 — The stand-down is complete

- **What changed:** disabling the addon now also unregisters the Edit Mode exit callback, arms no
  timers, and releases the ten secure state drivers. It re-registers everything from current settings
  on enable. All of this goes through the existing single latch; there is no second teardown path.
- **Why it mattered:** slash-commands-§7 requires a disabled addon to register nothing with a real
  unregister. These two were the last survivors, and the first was invisible to the headless suite.
- **Findings:** F-005, F-006. **Changes:** C-004, C-005.
- **Files:** `modules/Providers.lua`, `modules/UnitButtons.lua`, `modules/TargetFrames.lua`,
  `modules/PetFrames.lua`, `tests/test_disabled.lua`, `tests/test_providers.lua`.

### T5 — Evidence that can go red

- **What changed:**
  - The zero-overhead scenario now pins zero probe calls and no extra allocation against the
    unbracketed path.
  - `docs/performance.md` quotes a fresh run.
  - Real profile-switch and profile-verb cases exist.
- **Why it mattered:** the old assertion could not catch a dormant bracket that allocates, and the
  suite stayed green over both High defects.
- **Findings:** F-007, F-008, F-009. **Changes:** C-006, C-007 (plus the new cases in C-001 and C-002).
- **Files:** `tests/perf.lua`, `docs/performance.md`.

### T6 — Hygiene

- **What changed:**
  - The lint whitelist was trimmed, and `UnitExists` stays out on purpose.
  - A dead locale key was dropped and two wordings were unified.
  - The migration runner walks every profile.
  - Movable frames are kept out of the layout cache.
  - A few session-long registrations became feature-gated, and debug arguments are no longer built
    with debug off.
  - Screenshots no longer ship.
  - The degraded Slash stub no longer copies the library's refusal format.
- **Findings:** F-010, F-013–F-018. **Changes:** C-008, C-009.
- **Files:** `.luacheckrc`, `locales/enUS.lua`, `settings/Slash.lua`, `settings/General.lua`,
  `core/Database.lua`, `modules/Anchor.lua`, `modules/StandIn.lua`, `modules/TargetFrames.lua`,
  `modules/PetFrames.lua`, `modules/Preview.lua`, `.pkgmeta`, `tests/test_surface_parity.lua`,
  `tests/test_database.lua`.

### Upstream (LibKa0s) — test-kit fidelity

- **What changed:**
  - The kit's AceDB fake now raises where AceDB-3.0 raises (`CopyProfile`, `DeleteProfile`) and
    strips defaults from the outgoing profile on `SetProfile`.
  - The kit gains a recording `EventRegistry`.
  - Both landed in the LibKa0s repo under a kit revision bump and reached this addon through one
    whole-folder re-vendor commit.
- **Findings:** F-011, F-012. **Files here:** `tests/_kit/**` and `libs/LibKa0s/**` (copies only),
  `CLAUDE.md` provenance line.

## API / behavior changes

- **`/pfe profile use <name>`** no longer creates a profile. It refuses an unknown name and points to
  `/pfe profile new`.
- **`/pfe profile new <name>`** refuses an existing name. Before, it silently reset that profile.
- **`/pfe profile copy|delete <name>`** refuse a missing or invalid name with one line, instead of
  raising or printing a false acknowledgment.
- **New locale keys** hold the refusal lines above. They are listed in the T-2 commit.
- **Removed key:** `"/pfe %s does nothing while the addon is off — /pfe enable turns it back on"`.
- **Merged keys:** `"All settings reset to defaults."` and
  `"Cannot reset settings — the settings helpers failed to load."` are gone; their period-less
  twins remain.
- **While disabled,** target and pet buttons have no state driver registered, rather than a `"hide"`
  driver, and the Edit Mode callback is unregistered.
- There is no new slash verb, no removed verb and no new default.

## Saved-variable / migration notes

- There is no schema bump; `schemaVersion` stays 1.
- The migration runner now applies each future step to every stored profile before stamping the
  account-wide version. That changes behavior for future ladders only; the ladder is empty today.
- Existing profiles need no action.

## Deprecated-API migrations

None. No deprecated call was found. `C_AddOns.*` is used with a presence-guarded fallback in
`core/Compat.lua`.

| Old API | New API | Files |
|---|---|---|
| — | — | — |

## Performance impact

Every value is measured offline with `lua5.1 tests/perf.lua`. Fill in the After column from the
post-M2 run; nothing may be estimated.

| Scenario | Before (2026-09-23) | After |
|---|---|---|
| `anchorUnchanged` bytes/iter | 0.0 | TBD (must stay ≤ 24; expected 0) |
| `castStartStop` bytes/iter | 5.4 | TBD |
| `settingsDrag` bytes/iter | 895.9 | TBD |
| `probeOverheadOff` / `On` bytes/iter | 0.0 / 0.5 | TBD |
| Probe calls with capture off (new assertion) | not measured | TBD (asserted 0) |

- **In-game bucket figures** are unchanged unless S-P1 is run. If it is, cite the new
  `docs/perf-analysis/<stamp>/` bundle against `20260918-104528` (`targetTick` 0.352 ms/s,
  `castTick` 0.197 ms/s).

## Test and complexity movement

- **Pass count:** before, 289/289. After: TBD (about 300–305 is expected). `docs/test-cases.md` and
  the README `Tests-…` badge moved in each count-moving commit (testing-§5).
- **Complexity:**
  - Before the changes: max CCN 14 and 0 warnings (fresh run), with no watch-list entries.
  - Expected after: no function crosses 15. `PROFILE_VERBS` guards live in small closures, and
    `NS.SetByPath` is untouched.
  - The next release's `/wow-addon:bump-version` regeneration of `docs/automated-tests/` confirms
    this; nothing is regenerated here.
- **RESULTS.md:** the committed file (227 tests, bundle `20260918-121606`) remains stale until that
  release run.

## Known follow-ups

- **U-3 (optional):** LibKa0s documents a prescribed library-absent Slash stub shape. It lets every
  host's stub converge without improvising.
- **Collection-wide kit fidelity (U-1):** other consumers whose suites relied on the lenient AceDB
  fake may redden after re-vendor. That is the fake becoming honest, and it is tracked in the
  collection plan, not here.
- **Screenshot filenames:** `partframeenhanced.*` is misspelled. They no longer ship, and the rename
  is cosmetic.

## Verification evidence

- The completed `docs/reviews/2026-09-23/03_SMOKE_TESTS.md` sign-off table.
- Commit range: from `314c95e` to TBD on `feat/2026-09-23-review-audit-remediation`. The re-vendor
  commit is V-1, and the upstream LibKa0s tag is TBD.

## Suggested commit / PR description

```
PartyFrameEnhanced: profile-switch placement, safe profile verbs, complete stand-down

- Anchor reads each feature's section live; a profile switch/copy/reset now places from the new
  profile regardless of message dispatch order (F-001)
- /pfe profile new|use|copy|delete validate names: no silent wipe, no raw AceDB error, no false
  "Deleted", no typo-created profiles (F-002, F-004)
- Secure-write memos track the latest request, so an in-combat revert of Click to target sticks (F-003)
- Stand-down unregisters the Edit Mode callback and releases the secure state drivers (F-005, F-006)
- Zero-overhead perf scenario pinned against the unbracketed path; performance.md refreshed (F-007, F-009)
- Real profile-switch and profile-verb test cases (F-008)
- Hygiene: lint whitelist, locale keys, per-profile migrations, layout cache, gated registrations,
  .pkgmeta, degraded Slash stub (F-010, F-013–F-018)
- Re-vendor LibKa0s <tag>: kit AceDB fake raises like AceDB; EventRegistry recorded (F-011, F-012)

Review bundle: docs/reviews/2026-09-23/
```
