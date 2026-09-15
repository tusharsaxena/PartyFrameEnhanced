# `/pfe test` — test mode with a stand-in party frame

- **Status:** approved design (brainstorming, 2026-09-15), not yet built
- **Addon:** Ka0s Party Frame Enhanced 0.1.0 (unreleased)
- **Approach chosen:** a PFE-owned stand-in frame (over "stand-in + Blizzard Edit Mode" and "a real
  Blizzard template instance"; see *Rejected approaches*)

## Goal

Let a player configure the attached cast bar, target frame and pet frame **when they are not in a
party**. Today, attached elements need a real party frame to pin to, and solo there is none, so the
*Size & Position* offsets can't be tuned by eye. `/pfe test` shows one stand-in party frame with
placeholder content attached to it, looking like the frame system the player would actually use.

## What the player sees

### Turning it on and off

- `/pfe test` toggles it.
- **Refused** to start:
  - in combat: the same gray refusal `/pfe unlock` prints;
  - while in a group, since the real frames are already there and `/pfe preview` is the tool for
    that. The line says so;
  - while the addon is disabled.
- **Ends by itself**, with one chat line naming why:
  - when combat starts. It is handled in `PLAYER_REGEN_DISABLED`, while secure writes are still
    allowed, so no clickable placeholder stays on screen through the fight;
  - on joining a group (`GROUP_ROSTER_UPDATE` with `IsInGroup()`);
  - when the master **Enable** switch is turned off;
  - when a `/pfe perf` run suspends the addon.
- `/pfe status` adds `test mode on` to its *Note:* line while it is on.

### The stand-in frame

- **Content:** one frame drawn like a party member's, showing the player's own name, their class color
  and a full health bar, plus a small gray **Test** tag so it can't be mistaken for a real player.
- **Size and position** are copied from the chosen frame system's **first member frame**, which exists
  but is hidden while solo, so offsets tuned in test mode are the ones a real group gets:

  | Frame system | Source frame (first that exists) | Fallback size |
  |---|---|---|
  | EllesmereUI | `ERFPartyHeader[1]`, `ERFPartyHeaderUnitButton1`, `ERFPartySelfButton` | 125 × 60 (EllesmereUI's default) |
  | Blizzard raid-style | `CompactPartyFrame.memberUnitFrames[1]`, `CompactPartyFrameMember1` | 72 × 36 |
  | Blizzard classic | `PartyFrame.MemberFrame1` | 120 × 53 |

  The size comes from `GetSize()` when both sides are above 0; otherwise the fallback is used. The
  position comes from `GetLeft()`/`GetTop()` converted through the two frames' effective scales, and
  becomes a `TOPLEFT` offset from `UIParent`. When either value is `nil` (possible on a frame that has
  never been laid out), the stand-in goes to the screen center. **Every read is a getter.** The stand-in
  is never anchored to, parented to, or hooked onto another addon's or Blizzard's frame.
- **Which frame system:** the **Frame system** setting when it names one. On **Automatic**:
  EllesmereUI if its raid-frames addon is loaded, otherwise Blizzard raid-style if Edit Mode uses
  raid-style party frames, otherwise Blizzard classic. The real resolve can't answer this while solo,
  because none of the systems is *on screen*.
- **Style presets**, one per family. They're approximations, and the smoke tests judge them by eye:
  - **EllesmereUI:** a flat `WHITE8X8` bar in class color over a dark background, with a 1 px black
    border and the name on the left.
  - **Blizzard raid-style:** Blizzard's raid bar and background textures
    (`Interface\RaidFrame\Raid-Bar-Hp-Fill` / `-Bg`), in class color, with the name top left in the
    small highlight font.
  - **Blizzard classic:** the player's portrait on the left (`SetPortraitTexture`), a green health bar
    and a power-colored mana bar, with the name above them.
- **Dragging:** left-drag moves it (movable, clamped to the screen). The position is **not saved**: the
  next `/pfe test` copies the source frame again.

### What attaches to it

- The stand-in stands in for **party1**, a unit that is always tracked, whatever *Include my own row*
  says. Attached features pin party1's cast bar, target frame and pet frame to it through the ordinary
  anchor path, using the *Size & Position* settings, and show the usual placeholders. The target frame
  shows a skull.
- A feature set to **free placement** shows its normal five-row placeholder stack, the same as
  `/pfe preview` (the player's choice during brainstorming).
- Test mode **turns preview on**. Leaving test mode turns preview off **unless** something else still
  holds it: being unlocked, or `/pfe preview`.
- Test mode **does not unlock** anything. Free-placement stacks are still dragged through
  `/pfe unlock`, and the two combine.

## How it fits into the code

### New files

- **`modules/StandIn.lua`:** builds the stand-in once, on first use: an insecure `Frame` on
  `UIParent`, never protected. It holds the three style presets and `Place(source)`, which does the
  size and position copy above, plus the drag handlers and `Show`/`Hide`. It reads the player's name
  and class; nothing it reads is secret.
- **`modules/TestMode.lua`:** a registered module. It owns `NS.State.test` and `TestMode.Toggle()`
  (the refusals, the start, the stop), the automatic exits (its own bus target registers
  `PLAYER_REGEN_DISABLED`, `GROUP_ROSTER_UPDATE` and `CONFIG`), and the `Suspend` hook that stops it.
  Every start and stop logs one `[Test]` debug line with the reason.

Both load **after `modules/Preview.lua`**, because TestMode calls Preview's hold API. The TOC comment
and `tests/test_loadorder.lua` pin that.

### Changes to existing files

- **`modules/Providers.lua`:**
  - `Providers.SetStandIn(frame | nil)` stores the frame and requests a resolve.
  - In `Resolve`, after the provider's frames are collected: if a stand-in is set and **no real frame
    claimed party1**, `scratch.party1 = standIn`. A real frame always wins.
  - `Providers.StandInSource()` returns `family, sourceFrame | nil` using the choice rule above. It is
    read-only, consistent with the file's header contract.
  - `asleep()` is unchanged. In a raid or with the addon disabled the map empties, and test mode has
    already ended in both cases.
- **`modules/Preview.lua`:** preview becomes **held**. `Preview.Hold(reason, on)` keeps a set of
  reasons (`unlock`, `command`, `test`), and `NS.State.preview` is true while any is held.
  - `NS.OnLockChanged` holds or releases `unlock`, `Preview.Toggle` flips `command`, and TestMode
    holds `test`.
  - **One visible behavior change:** `/pfe preview` while unlocked no longer hides the placeholders.
    Before, it could, which contradicted the lock.
  - The combat refusals are unchanged.
- **`settings/Slash.lua`:** a `test` verb after `preview` in `NS.COMMANDS`, and a `test mode on` flag in
  `statusFlags()`.
- **`locales/enUS.lua`:** the verb description, the on/off/refusal lines, the **Test** tag.
- **`PartyFrameEnhanced.toc`:** the two new files, with their load-bearing comment.

### Data flow

```
/pfe test ──► TestMode.Toggle ──► StandIn.Place(Providers.StandInSource()) ──► StandIn:Show()
                     │                                         │
                     ├─► Preview.Hold("test", true)             └─► Providers.SetStandIn(frame)
                     │        └─► VISIBILITY                              └─► Resolve: party1 → stand-in
                     │                                                             └─► LAYOUT
                     └─► every feature re-decides: party1 attached → pinned to the stand-in, placeholders
```

The stop runs the same path in reverse: `SetStandIn(nil)`, then `Preview.Hold("test", false)`, then
the stand-in is hidden.

### Clickable (secure) frames

Target and pet buttons are secure. They can anchor to the insecure stand-in **out of combat**, which
is the only time test mode runs. Leaving in `PLAYER_REGEN_DISABLED` lets `NS.RunSecure` apply the
state-driver and anchor changes at once. If a write does get queued, it lands at
`PLAYER_REGEN_ENABLED`, as every secure write does today. Dragging the stand-in moves pinned secure
buttons with it. That's legal out of combat, and test mode is never on in combat.

## Testing

**Headless** (`tests/test_testmode.lua` plus additions to the Providers and Preview suites):

- **Toggle:** `/pfe test` turns the stand-in on and off, `NS.State.test` flips, and preview follows.
- **Refusals:** in combat (`InCombatLockdown` true), in a group, and with the addon disabled. Each
  prints one line and changes nothing.
- **Each exit:** `PLAYER_REGEN_DISABLED`, `GROUP_ROSTER_UPDATE` into a group, master enable off, and
  `NS.SuspendAll()`. After each, the stand-in is hidden, party1 is unmapped, and preview is released.
- **The party1 rule:** a stand-in fills party1 only when no real frame holds it. It never takes
  another unit, and clearing it restores the real map.
- **Frame system choice:** a pinned setting, and Automatic with EllesmereUI loaded or not and
  raid-style on or off.
- **Size and position copy** from mocked hidden source frames: a real size, a zero size (fallback), and
  a nil position (center).
- **Preview holds:** unlock plus test, then test off, keeps preview on. Test alone, then off, turns it
  off. `/pfe preview` while unlocked no longer hides the placeholders.
- **Anchoring:** party1's target button is anchored to the stand-in while test mode is on, and is
  hidden (driver `hide`) after.
- **Status** carries `test mode on`, and **slash** has the `test` verb.

**Offline perf:** none of the hot paths change. The resolve gains one nil check, so the
`resolveUnchanged` scenario still has to read 0 API calls and 0 bytes.

**In game:** a new smoke step per frame system, run solo:

- The stand-in sits where the first party frame would, at its size, in its look.
- The three placeholders attach to it, and the offsets move them.
- Dragging carries them along.
- Pulling a dummy ends test mode with no stuck frames and no `ADDON_ACTION_BLOCKED`.
- Joining a group ends it.

## Documentation touched when built

- `docs/ARCHITECTURE.md`: the module count, and a sentence in the lifecycle and preview sections.
- `docs/module-map.md`: two rows.
- `docs/data-flow.md`: the stand-in as a source for stage 1.
- `docs/slash-dispatch.md`: the `test` verb.
- `docs/smoke-tests.md`: the new step, plus an index row.
- `README.md`: one Usage sentence, followed by a de-AI pass.
- `docs/test-cases.md` and the Tests badge: regenerated.

## Rejected approaches

- **Stand-in + Blizzard Edit Mode.** Blizzard force-shows party frames only while Edit Mode is open with
  the account option *Party Frames* ticked (`EditModeManagerFrame:ArePartyFramesForcedShown`). PFE can't
  open Edit Mode without tainting it, and which units those frames carry is unverified. It could be
  added later as a refinement.
- **A real Blizzard template instance** (`CompactUnitFrame` on unit `player`). It would be pixel-exact
  on raid-style, but it runs Blizzard's shared unit-frame code under PFE's taint, and there is no
  equivalent for EllesmereUI or the classic layout.

## Out of scope

- A settings-panel button for test mode. Slash only, as asked.
- Saving the stand-in's dragged position.
- More than one stand-in member.
- Driving EllesmereUI's own options preview.

## Risks

- **`GetLeft`/`GetTop` on a never-shown frame** can return `nil`. The fallback is the screen center, and
  the smoke step checks the normal case.
- **The style presets are approximations.** The smoke step judges them by eye per frame system;
  adjusting a preset is a local change inside `StandIn.lua`.
- **EllesmereUI's button names** are private to it. Every lookup is nil-guarded, and a missing source
  falls back to the default size and the screen center.
