# In-client smoke tests — Ka0s Party Frame Enhanced (2026-10-07 review)

These checks are for the owner to run in the client. Nothing here is marked passed by an agent.

## Pre-flight

1. Run the headless gate after the changes land: `lua tests/run.lua` (expect 461 passed, 0 failed, 1 skipped, 462 total) and `luacheck .` (0/0).
2. Use retail Midnight, `## Interface: 120100`. The game loads `GIT/PartyFrameEnhanced` through its symlink, so test from that folder, never from a side worktree.
3. Run `/console scriptErrors 1`, and keep BugSack/BugGrabber on if installed.
4. Use a character in a 5-man party (a follower dungeon is enough), with a target dummy for combat entry. Run `/pfe debug on` and open the console with `/pfe debug`.

## Per-change tests

### C-001: a profile switch in combat does not start preview

- **Setup.** Run `/pfe profile new SmokeA`, then `/pfe unlock`. Elements show placeholders. Run `/pfe profile use Default`. Preview ends, and SmokeA stays stored unlocked.
- **Steps.**
  1. Attack the dummy to enter combat.
  2. In combat, run `/pfe profile use SmokeA`.
  3. Watch the cast bars while a party member casts during the fight.
  4. Leave combat and wait 2 seconds.
- **Expected.** Step 2 prints `[PFE] Locked — combat started`. No "Preview cast" placeholder appears, and real casts keep drawing. After combat, `/pfe get locked` answers `locked = true` and no placeholders appear. There is no "Interface action failed" message.
- **Pass/Fail.** Pass when no placeholder is drawn at any point during the fight and `locked` reads true afterward.

### C-002: the deferred queue survives combat cleanly

- **Setup.** A party on EllesmereUI or Blizzard raid-style frames, with Target frames attached.
- **Steps.**
  1. Enter combat, and while in it, change `/pfe set target.offsetX 10`.
  2. Leave combat.
  3. Run `/pfe diagnostics`, then open the console.
- **Expected.** The target frames move to the new offset right after combat. The console shows `flushed N deferred write(s), 0 failed`. In the report, `secure: pending=0` and `flush listener armed=false`.
- **Pass/Fail.** Pass when the offset applies after combat and the flush line reports 0 failed.

### C-003: the stand-down unwrap continues past a refusal

- **Setup.** EllesmereUI raid frames in a party. No other addon wraps member frames, which is the ordinary case.
- **Steps.** Run `/pfe disable`, then `/pfe diagnostics`, then `/pfe enable`, then `/pfe diagnostics` again.
- **Expected.** While disabled, `follow: header=yes wrapped=0`. After enabling, `wrapped` is 5 or more. Neither step raises a Lua error.
- **Pass/Fail.** Pass when both reports print and no error pops.

### C-004: one unlocked flag

- **Steps.** Leave the party, run `/pfe unlock`, then `/pfe status`.
- **Expected.** The `Note:` line contains `unlocked (stand-in)` once and no bare `unlocked` after it.
- **Pass/Fail.** Pass when the word appears exactly once.

### C-005: `/pfe profile new` is one rebuild

- **Steps.** With the console open and logging on, run `/pfe profile new SmokeB`.
- **Expected.** One `[Profile] changed → SmokeB` line, and no `[Set] reset profile 'SmokeB'` line. All elements show defaults.
- **Pass/Fail.** Pass when exactly one profile line is logged.

### C-006: no visible change

- **Steps.** In a party, cycle `/pfe set visibility inCombat`, `outOfCombat` and `always`, entering and leaving combat with each.
- **Expected.** Target and pet frames show and hide exactly as before: shown only in combat, only out of combat, and always, respectively.
- **Pass/Fail.** Pass when all three modes behave as their names say.

## Regression suite

- `/reload` is clean, with no Lua errors.
- On login, ADDON_LOADED → PLAYER_LOGIN → PLAYER_ENTERING_WORLD produce no errors, and `/pfe status` lists the frame system.
- Enter and leave combat with all three features visible: cast bars draw real casts, and target and pet frames track.
- Run an in-combat re-sort on EllesmereUI (COMBAT-6). The target and pet frames follow their member.
- Switch profiles with `/pfe profile use Default` and back. Elements rebuild with no error.
- Open the settings panel and toggle every General option once.

## Taint-specific

- After C-001 and C-002, enter combat, click a target frame (`clickToTarget` on), and leave combat. No `Interface action failed because of an AddOn` line appears.

## Cross-addon (in-client half of the source-level pass)

- With several Ka0s addons loaded, type each of the eleven roots (`/at`, `/am`, `/bl`, `/cm`, `/kcd`, `/lh`, `/mm`, `/pm`, `/pfe`, `/pc`, `/wg`) and confirm each reaches its own addon. Then open Settings → AddOns and confirm each addon appears exactly once.

## Performance spot-check (C-006)

- Offline: the `visibilityFlip` scenario in `lua tests/perf.lua`, run before and after C-006 in the same session, shows bytes/iter going down. It is not a pass/fail gate.
- In client, optional: `/pfe perf` two-arm capture during a dummy pull. Read the `targetEvent` and `anchor` bucket figures rather than the frame-time delta, and record the capture as a `docs/perf-analysis/<stamp>/` bundle via `/dev-copilot:wow-perf-analysis`.

## Sign-off

| ID | Tested? | Pass/Fail | Notes |
|---|---|---|---|
| C-001 | | | |
| C-002 | | | |
| C-003 | | | |
| C-004 | | | |
| C-005 | | | |
| C-006 | | | |
