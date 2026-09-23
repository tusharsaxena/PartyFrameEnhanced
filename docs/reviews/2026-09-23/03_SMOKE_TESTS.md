# In-client smoke tests — PartyFrameEnhanced review (2026-09-23)

Run these **after** the changes in `02_PROPOSED_CHANGES.md` are applied. This file covers only what
the game client can verify. The headless suites already ran in Step 0 (see `01_FINDINGS.md` →
*Measurement run*).

**Headless pre-flight (one line):** from the repo root, run
`ka0s-bounded lua5.1 tests/run.lua && ka0s-bounded luacheck . && ka0s-bounded lua5.1 tests/perf.lua`.
Expect all green, the pass count equal to `docs/test-cases.md`'s Totals, and the README badge equal
to it too.

## Pre-flight (client)

1. **Build:** Retail, `## Interface: 120100`. Install the working tree as
   `Interface\AddOns\PartyFrameEnhanced` with `libs\` intact.
2. **Settings:** `/console scriptErrors 1`, then `/reload`. Open `/etrace` only where a step asks for
   it.
3. **Character:** a max-level character able to join a **5-player party**. Two accounts, or a
   follower dungeon party, will do; the party needs at least one member with a pet (hunter or
   warlock) for the pet steps. A target dummy area is needed for the combat steps (any capital's
   training dummies).
4. **Frames:** Blizzard party frames in the **raid-style** layout (Edit Mode → Party Frames → *Use
   Raid-Style Party Frames* ticked) unless a step says otherwise.
5. **Debug console:** turn logging on with `/pfe debug on` and leave the console open while testing.
6. **Profiles:** start from `/pfe profile use Default` and `/pfe resetall` so every step begins from
   defaults.

---

## Per-change tests

### S-001 — C-001: placement follows the NEW profile after switch, copy and reset (F-001)

- **Setup:** in a party.
  1. Run `/pfe profile new PlaceTest`. After C-002 it creates the profile, because the name is new.
  2. In PlaceTest, set **Cast Bars**, **Target Frames** and **Pet Frames** → *Size & Position* →
     *Anchor mode* = **Free placement**.
  3. `/pfe unlock`, drag each stack somewhere distinctive, then `/pfe lock`.
- **Steps:**
  1. Run `/pfe profile use Default`.
  2. Observe all three features.
  3. Run `/pfe profile use PlaceTest`.
  4. Observe all three features.
  5. Repeat steps 1–4 **five times**. Dispatch order is hash order, so a single pass can miss the bug.
  6. In PlaceTest, open General → Master controls → **Reset all settings** and accept the popup.
- **Expected:**
  - On Default, every element is **attached** to its party frame. No stack stays where you dragged it.
  - On PlaceTest, every element sits in its dragged free-placement stack.
  - After the reset, everything is attached again at default offsets.
  - No Lua error.
- **Pass/Fail:** pass only if all three features follow the active profile on **every** one of the
  ten switches and after the reset.

### S-002 — C-002: profile sub-verbs refuse bad names and never wipe (F-002, F-004)

- **Setup:** profiles `Default` and `PlaceTest` exist (from S-001). In PlaceTest, run
  `/pfe set castbar.width 222`.
- **Steps and expected results:**
  1. `/pfe profile use Default`, then `/pfe profile new PlaceTest` → one tagged refusal line (profile
     already exists). The current profile stays **Default**.
  2. `/pfe profile use PlaceTest`, then `/pfe get castbar.width` → `castbar.width = 222` (not wiped).
  3. `/pfe profile use Typo` → one refusal line pointing at `list`/`new`. `/pfe profile current`
     still reads `PlaceTest`, and `/pfe profile list` shows **no** `Typo`.
  4. `/pfe profile copy Nope` → one refusal line, **no Lua error popup**.
  5. `/pfe profile copy PlaceTest` while PlaceTest is current → one refusal line, no Lua error.
  6. `/pfe profile delete Nope` → one refusal line. There is **no** "Deleted profile 'Nope'".
  7. `/pfe profile new Fresh` → "Created and switched to new profile 'Fresh'", and
     `/pfe get castbar.width` = `140`.
- **Pass/Fail:** pass only if all seven steps behave as described, no Lua error appears, and 222 survives.

### S-003 — C-003: an in-combat revert of Click to target is honored (F-003)

- **Setup:** in a party. Party1 has a target, so the target frame shows. *Click to target* is on.
- **Steps:**
  1. Attack a training dummy to enter combat.
  2. Type `/pfe set target.clickToTarget false`, then immediately `/pfe set target.clickToTarget true`.
  3. Stop attacking and wait for combat to end.
  4. Left-click party1's target frame.
- **Expected:** after combat, the click targets party1's target (your target frame changes). With
  debug on, the `[Secure]` lines show the queued writes flushed at combat end.
- **Variant:**
  1. Create profiles `ClickOn` (default) and `ClickOff` (`/pfe set target.clickToTarget false`).
  2. In combat, run `/pfe profile use ClickOff` then `/pfe profile use ClickOn`.
  3. Leave combat and click.
  4. The click must target.
- **Pass/Fail:** pass only if the target frame is clickable after combat in both variants.

### S-004 — C-004: the Edit Mode callback stands down (F-005)

- **Setup:** in a party. `/pfe debug on`.
- **Steps:**
  1. Run `/pfe disable`.
  2. Open Edit Mode (Esc → Edit Mode) and close it.
  3. Watch the console for 2 s.
  4. Run `/pfe enable`, open Edit Mode, and close it.
- **Expected:** while disabled, closing Edit Mode produces **no** `[Provider]` lines. After enabling,
  closing Edit Mode produces `[Provider]` resolve lines again.
- **Pass/Fail:** pass only if the disabled pass is silent and the enabled pass is not.

### S-005 — C-005: secure state drivers are released while disabled, restored on enable (F-006)

- **Setup:** in a party. Every member's target and pet frames are visible.
- **Steps (out of combat):**
  1. Run `/pfe disable`.
  2. Run `/run print(PartyFrameEnhancedTarget_party1:IsShown())`.
  3. Change your own target a few times.
  4. Run `/pfe enable`.
- **Expected:**
  - After disable: `false`, and no target or pet frame appears when targets change.
  - After enable: the frames return and follow `[@partyNtarget,exists]`.
  - No `Interface action failed because of an AddOn` message.
- **Steps (in combat):**
  1. Enter combat with a dummy.
  2. Run `/pfe disable`. The frames stay drawn until combat ends, because protected writes are
     deferred.
  3. Leave combat. The frames hide within a second.
  4. Run `/pfe enable` out of combat. They return.
- **Pass/Fail:** pass only if both paths complete with no blocked-action message (check with
  `/etrace` filtered to `ADDON_ACTION_BLOCKED`).

### S-006 — C-006 / C-007: perf evidence (F-007, F-009)

This is headless-only and is covered by the pre-flight line. There is no in-client step beyond S-P1
below.

### S-008 — C-008: hygiene

1. **Wording:** run `/pfe resetall`, then click **Reset all settings** in the panel. Both
   acknowledgments must have identical wording (no trailing period on either).
2. **Layout cache (F-016):**
   1. Set Cast Bars to free placement, `/pfe unlock`, drag the stack, `/pfe lock`, then
      `/pfe resetposition`.
   2. Run `/reload`.
   3. **Expected:** after the reload, the stack is at the **default** spot (CENTER 0, -180), not
      the dragged one.
   4. Also check `WTF\Account\<acct>\<realm>\<char>\layout-local.txt`: there is no
      `PartyFrameEnhanced_castbar_Holder` entry.
3. **Registrations (F-017):**
   1. Solo, with `/pfe debug on`, change target five times.
   2. Run `/pfe status`.
   3. **Expected:** no `[Target]` lines while solo. In a party, the player's own target frame still
      updates on your target change.
4. **Packaging (F-018):** build the zip with the packager and confirm there is no `media/screenshots/`.

### S-009 — C-009: degraded Slash stub (F-010)

- **Setup:** a scratch copy of the addon with `libs\LibKa0s\` removed (never commit this).
- **Steps:** run `/pfe disable`, then `/pfe lock`.
- **Expected:** one plain line naming `/pfe enable`, and the element stays unchanged. `/pfe enable`
  restores it.
- **Pass/Fail:** pass only if there is one line and no Lua error. **Restore the full addon afterwards.**

---

## Regression suite

| # | Check | Expected |
|---|---|---|
| R-1 | `/reload` in a party | No Lua error. The `[Init]` console line reads `v1.0.1, schema v1, profile 'Default', frames 'Blizzard (raid-style)'` |
| R-2 | Fresh SV (rename `WTF\…\SavedVariables\PartyFrameEnhanced.lua`), log in | Defaults populate; the cast bars attach TOP to TOP over each party frame; target frames sit to the right; pet frames sit to the right, -20 |
| R-3 | ADDON_LOADED → PLAYER_LOGIN → PLAYER_ENTERING_WORLD | No errors. `/pfe status` lists five units |
| R-4 | Enter and leave combat with all features visible | Cast bars track casts. Target frames update health roughly 5×/s. The `[Combat] left:` rollup appears with debug on |
| R-5 | Profile switch (AceDBOptions Profiles page) | The same outcome as S-001, driven from the panel instead of chat |
| R-6 | Settings panel: open every page and toggle every option once, out of combat | Every change applies immediately. No error. *Defaults* on General leaves the minimap button's hidden state alone |
| R-7 | `/pfe unlock` solo | The stand-in party frame appears with placeholders. Entering combat re-locks with "Locked — combat started" |
| R-8 | Each Edit Mode layout switch (raid-style ↔ classic) | Elements re-attach within 0.5 s |
| R-9 | EllesmereUI installed (if available) | Provider reads `EllesmereUI`. Elements attach to its party buttons |

## Taint-specific

T-1 applies after C-003 and C-005.
1. Enter combat with a dummy.
2. Click party1's target frame, then party1's pet frame.
3. Expected: both target their unit, and no `Interface action failed because of an AddOn` appears.
4. Leave combat. Run `/pfe config` and confirm the panel opens.
5. In combat, run `/pfe config`. Expected: the library's combat refusal line, and no taint.

## Performance spot-check

**S-P1:** C-001 and C-003 touch placement and clicks, not the hot paths, so no capture is
**required** for them. To confirm C-005 did not move the ticker cost, run the standard's two-arm
protocol:
1. Run `/pfe perf`, then follow the guided steps. Use the clean arm first and the suspended arm
   second, with both windows opened on the player's combat *state*. Do not `/reload` between arms,
   and do not change the loaded addon set between arms.
2. Read the **bucket** figures (`targetTick`, `targetRender`, `castTick`) against the committed
   `docs/perf-analysis/20260918-104528/report.md`. That capture had `targetTick` 0.352 ms/s and
   `castTick` 0.197 ms/s. Do not read the frame-time delta; it sits below the harness's run-to-run
   spread.
3. Record the capture as a frozen `docs/perf-analysis/<YYYYMMDD-HHMMSS>/` bundle via
   `/wow-addon:perf-analysis`.

## Cross-addon (in-client half)

With several Ka0s addons loaded:
1. Type each root (`/at`, `/am`, `/bl`, `/cm`, `/kcd`, `/lh`, `/mm`, `/pm`, `/pfe`, `/pc`, `/wg`)
   and confirm each reaches its own addon.
2. Open Settings → AddOns and confirm each addon appears once. Also confirm PartyFrameEnhanced's
   pages (General, Cast Bars, Target Frames, Pet Frames, Profiles) each appear once.

---

## Sign-off

| ID | Tested? | Pass/Fail | Notes |
|---|---|---|---|
| C-001 (S-001) | | | |
| C-002 (S-002) | | | |
| C-003 (S-003) | | | |
| C-004 (S-004) | | | |
| C-005 (S-005) | | | |
| C-006/C-007 (headless) | | | |
| C-008 (S-008) | | | |
| C-009 (S-009) | | | |
| Upstream re-vendor (kit rev) | | | `tests/test_vendor_sync.lua` green after re-vendor |
| Regression R-1..R-9 | | | |
| Taint T-1 | | | |
| Perf S-P1 (optional) | | | |
| Cross-addon | | | |
