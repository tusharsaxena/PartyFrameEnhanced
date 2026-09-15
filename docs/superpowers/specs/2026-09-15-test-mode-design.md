# `/pfe test` and the party-only rule

- **Status:** approved design (brainstorming, 2026-09-15; revised the same day), built the same day
  (plan `docs/superpowers/plans/2026-09-15-test-mode.md`); the in-game smoke steps are open
- **Addon:** Ka0s Party Frame Enhanced 0.1.0 (unreleased)
- **Approach chosen:** a PFE-owned stand-in frame (over "stand-in + Blizzard Edit Mode" and "a real
  Blizzard template instance"; see *Rejected approaches*)
- **Revision:** the first version refused test mode in a group and ended it on joining one. This one
  makes the addon **party-only**, folds `/pfe preview` into `/pfe test`, and keeps test mode on
  through joins and leaves.

## Goal

Two changes that belong together:

1. **The addon is active only in a party.** Solo or in a raid it shows nothing and costs nothing.
2. **`/pfe test` lets a player configure it anyway.** In a party it puts placeholders on the real
   party frames, as `/pfe preview` did. Out of a party (solo, or in a raid) there are no party
   frames to pin to, so it shows one **stand-in party frame** with party1's cast bar, target frame and
   pet frame attached, and the *Size & Position* offsets can be tuned by eye.

## 1. The party-only rule

PFE is active **only in a party of 2 to 5**: `IsInGroup() and not IsInRaid()`. `IsInGroup()` with no
argument covers home and instance groups, so a dungeon-finder party counts.

- **Solo, or in a raid of any size:** nothing shows, attached or free placement. No unit events are
  registered and the health ticker never starts.
- **Blizzard raid-style party frames (`CompactPartyFrame`) and EllesmereUI's party frames still
  count.** They are party frames in a party-sized group; "raid-style" is only their look.
- **The `raidN` → `partyN` normalization in `modules/Providers.lua` goes.** It existed only for
  raid-shaped groups (EllesmereUI's small-raid mode, raid-group arenas), which the rule now excludes.
  A member frame whose unit is a `raidN` token maps to no unit. `Compat.UnitIsUnit`, used by nothing
  else, is removed with it.
- **Accepted consequence:** solo, the player's own free-placement cast bar no longer shows.
- **Test mode and unlock skip the rule** for what they show (placeholders); they never register unit
  events.

### One check, three places

`NS.Units.InParty()` in `core/Units.lua` answers `IsInGroup() and not IsInRaid()`, read live on every
call (two C calls, no allocation). It is the only place the rule is written. Its three readers:

| Where | What it gates |
|---|---|
| `Providers.Resolve` (`asleep()`) | not in a party → the provider map is empty (a stand-in may still fill party1, §3) |
| The show decision: `CastBars` `shouldShow`, `UnitButtons.Allowed` (target and pet) | not in a party → hidden, **unless preview is on** |
| Each feature's `syncEvents` (cast, target, pet) | not in a party → no unit events registered |

`shouldShow` keeps its order: master and feature switches, then preview (which short-circuits to
shown), then the new party rung, then visibility, inclusion and frame presence. `hiddenReason` gains
"not in a party". `UnitButtons.Allowed` reads `NS.State.preview` itself for the bypass.

### Noticing the change

`core/PartyFrameEnhanced.lua` registers `GROUP_ROSTER_UPDATE` with its lifecycle events. When
`InParty()` differs from the last answer (kept in `NS.State.inParty`, seeded at `OnEnable`), it logs
one `[Party]` debug line and calls `NS.PublishVisibility()`. The three features' `VISIBILITY` handlers
now run `syncEvents()` before `refreshAll()`, so events come on and off with the party. The providers
already re-resolve on the same event.

### What the player reads

- `/pfe status` adds, when not in a party and test mode is off: **"not in a party — nothing shows
  until you join one (try /pfe test)"**.
- The README FAQ says plainly that the addon is party-only (today it says "Not yet" for raids).
- Known Limitations in `docs/ARCHITECTURE.md` reword "a raid group puts the addon to sleep" as the
  party-only rule. Issue #1 (*Support raid frames*) now describes something the design rules out;
  whether to close it as `state:will-not-do` is the user's call, raised at the end of the build.

## 2. One verb: `/pfe test`

`/pfe test` replaces `/pfe preview`. The `preview` verb is removed, with no alias.

| Where the player is | What `/pfe test` shows |
|---|---|
| **In a party** | Placeholders on every enabled element, at the real party frames (the old preview). |
| **Not in a party** (solo, or in a raid) | A PFE-owned **stand-in party frame** for party1, with party1's cast bar, target frame and pet frame attached, showing placeholders. Free-placement features show their normal five-row placeholder stack. |

- **It switches live** between the two when the party state changes: joining a party hides the
  stand-in and the placeholders move to the real frames; leaving brings the stand-in back. Test mode
  stays on through joins and leaves.
- **Refused to start** (one gray line each, nothing changes):
  - in combat (`InCombatLockdown()`);
  - with the addon disabled (master **Enable** off);
  - while a `/pfe perf` run has the addon suspended.
- **Ends by itself**, in both modes, with one chat line naming why:
  - at `PLAYER_REGEN_DISABLED`, while secure writes are still allowed, so no clickable placeholder or
    stand-in anchor survives into the fight;
  - when the master **Enable** switch goes off (`CONFIG("master")`, or a new profile that is off);
  - when a `/pfe perf` run suspends the addon (its `Suspend` hook).
- `/pfe test` while on turns it off.
- **General → Master controls carries a *Test mode* checkbox** (after the first in-game walk; first
  drawn as a `leadButton`, then made a checkbox on the owner's call): the session-only row
  `state.testMode`, on its own line below *Lock frame* / *Debug console*. The standard made that row
  canonical at v2.46.0 (`options-ui-§15`, anti-pattern #80) and LibKa0s composes it from
  `testModePath` since v1.37.0. Its set calls the same `TestMode.Toggle` as the verb; TestMode refreshes
  the panel on every start and stop, so the box follows combat and `/pfe test`.
- **`/pfe unlock` is unchanged:** placeholders plus draggable free-placement stacks. It creates no
  stand-in, so solo an unlocked attached feature has nothing to show. Unlock and test combine.
- `/pfe status` shows **"test mode on (stand-in)"** or **"test mode on (your party frames)"** in its
  *Note:* line, replacing today's "preview on" flag. Unlocked still reads as its own flag
  ("unlocked").

## 3. The stand-in frame

- **Content:** one frame drawn like a party member's: the player's own name, their class color, a
  full health bar, and a small gray **Test** tag so it can't be mistaken for a real player.
- **Which frame system it imitates:** the **Frame system** setting when it is pinned to EllesmereUI;
  pinned to Blizzard, raid-style if Edit Mode uses raid-style party frames, otherwise classic. On
  **Automatic**: EllesmereUI if its raid-frames addon is loaded, otherwise raid-style if Edit Mode
  uses it, otherwise classic. (The real resolve can't answer this out of a party: no system is on
  screen.)
- **Size and position** are copied from that system's **first member frame**, which exists but is
  hidden out of a party, so offsets tuned in test mode are the ones a real party gets:

  | Frame system | Source frame (first that exists) | Fallback size |
  |---|---|---|
  | EllesmereUI | `ERFPartyHeader[1]`, `ERFPartyHeaderUnitButton1`, `ERFPartySelfButton` | EllesmereUI's configured party frame size (`partyFrameWidth` × `partyFrameHeight` in `EllesmereUIDB.profiles[activeProfile].addons.EllesmereUIRaidFrames`), else 125 × 60 |
  | Blizzard raid-style | `CompactPartyFrame.memberUnitFrames[1]`, `CompactPartyFrameMember1` | 72 × 36 (a guess, checked in the smoke step) |
  | Blizzard classic | `PartyFrame.MemberFrame1` | 120 × 53 (a guess, checked in the smoke step) |

  - Size: for EllesmereUI, its configured party frame size first (`partyFrameWidth` ×
    `partyFrameHeight`, or its own defaults of 125 × 60). Its five party buttons exist solo, but it
    styles them at the **raid** frame size (`_StyleButtonSecure`) and gives them the party size only
    in `ReloadPartyFrames`, so measuring the hidden button copied the raid size (found in game:
    the stand-in came up the wrong shape against real 200 × 80 frames). Otherwise, and for both
    Blizzard systems, `GetSize()` when both sides are numbers above 0; otherwise the fallback. A
    `[Test]` debug line says which of the three it used.
  - Position: `GetLeft()`/`GetTop()`, converted by the ratio of the two frames' effective scales, as a
    `TOPLEFT` → `UIParent` `BOTTOMLEFT` offset. When either is not a number (a frame never laid out),
    the stand-in goes to the screen center.
  - **Every read is a getter** (`GetSize`, `GetLeft`, `GetTop`, `GetEffectiveScale`), each checked
    with `type(...) == "number"`. The stand-in is never anchored to, parented to, or hooked onto
    another addon's or Blizzard's frame.
- **Style presets**, one per frame system. They are approximations; the smoke steps judge them by eye:
  - **EllesmereUI:** a flat `WHITE8X8` bar in class color over a dark background, a 1 px black
    border, the name on the left.
  - **Blizzard raid-style:** Blizzard's raid bar and background textures
    (`Interface\RaidFrame\Raid-Bar-Hp-Fill` / `-Bg`) in class color, the name top left in the small
    highlight font.
  - **Blizzard classic:** the player's portrait on the left (`SetPortraitTexture`), a green health bar
    and a power-colored mana bar, the name above them.
- **Dragging:** left-drag moves it (movable, clamped to the screen, never in combat). The position is
  **not saved**: each time the stand-in comes up it copies the source frame again.
- **A Frame system change** (`CONFIG("general")`) while the stand-in is up re-places it in the new
  system's look and size.

### What attaches to it

- The stand-in fills **party1**, a unit that is always tracked. Attached features pin party1's cast
  bar, target frame and pet frame to it through the ordinary anchor path and *Size & Position*
  settings, and show the usual placeholders (the target frame shows a skull).
- It is party1's frame **only when no real frame holds party1**. A real frame always wins.
- Free-placement features show their five-row stack, as with any preview.

## 4. How it fits into the code

### New files

- **`modules/StandIn.lua`** (not a registered module; publishes `NS.StandIn`): builds the stand-in
  once, on first use: an insecure `Frame` named `PartyFrameEnhancedStandIn` on `UIParent`, never
  protected. It holds the three presets, `StandIn.Place(id, source)` (the preset, size and position
  copy), the drag handlers, `Show`/`Hide`, and `StandIn.Frame()` for tests. It reads the player's name
  and class, neither of which is secret.
- **`modules/TestMode.lua`** (a registered module; publishes `NS.TestMode`): owns `NS.State.test`
  (`nil`, `"standin"` or `"party"`), `TestMode.Toggle()` (refusals, start, stop), the live switch,
  and the automatic exits. Its own bus target registers `PLAYER_REGEN_DISABLED`,
  `GROUP_ROSTER_UPDATE`, `CONFIG` and `PROFILE`; its `Suspend` hook stops it. Every start, stop and
  switch logs one `[Test]` debug line with the reason.

Both load **after `modules/Preview.lua`** (TestMode calls `Preview.Hold`; StandIn before TestMode,
which captures it). The TOC comment says so and `tests/test_loadorder.lua` pins it. Preview is then
no longer the last module; its "last module" comment moves to say it loads after every feature.

### Changes to existing files

- **`core/Units.lua`:** `Units.InParty()`.
- **`core/State.lua`:** `test` and `inParty` fields, documented.
- **`core/PartyFrameEnhanced.lua`:** `GROUP_ROSTER_UPDATE` → the party flip → `PublishVisibility`.
- **`modules/Providers.lua`:**
  - `asleep()` becomes `not Units.InParty() or NS.GetSetting("enabled") ~= true`.
  - `normalize` loses the `raidN` branch.
  - `Providers.SetStandIn(frame | nil)` stores the frame and **resolves at once**, not next frame, so
    a stop in `PLAYER_REGEN_DISABLED` lands its anchor writes before lockdown. Clearing it also
    drops it from the published map directly, because a resolve while suspended does nothing.
  - In `Resolve`, after the provider's frames are collected, whether or not asleep:
    `if standIn and scratch.party1 == nil then scratch.party1 = standIn end`.
  - `Providers.StandInSource()` → `id, sourceFrame | nil` (`id` is a provider id: `ellesmere`,
    `blizzard-raid`, `blizzard-party`), by the choice rule in §3. Read-only, as the file's header
    requires.
- **`modules/Preview.lua`:** preview becomes **held**. `Preview.Hold(reason, on)` keeps a set of
  reasons (`unlock`, `test`); `NS.State.preview` is true while any is held, and VISIBILITY goes out
  only when that answer changes. `NS.OnLockChanged`, `OnEnable` and the `PROFILE` handler hold or
  release `unlock`. `Preview.Toggle` is removed. The unlock refusal is unchanged.
- **`modules/CastBars.lua`, `TargetFrames.lua`, `PetFrames.lua`, `UnitButtons.lua`:** the party rung
  in the show decision and in `syncEvents`; `syncEvents` on `VISIBILITY`.
- **`core/Compat.lua`:** `Compat.UnitIsUnit` removed, with its test.
- **`settings/Slash.lua`:** the `preview` verb out, a `test` verb in its place; `statusFlags()` gains
  the test-mode, unlocked and not-in-a-party flags and loses "preview on".
- **`locales/enUS.lua`:** the verb description, the on/off/switch/exit/refusal lines, the status
  flags, the **Test** tag; the preview-verb keys removed.
- **`PartyFrameEnhanced.toc`:** the two new files and their comment.
- **`.luacheckrc`:** a `212/self` stanza for `modules/TestMode.lua` if its colon hooks need one.

### Data flow

```
/pfe test ──► TestMode.Toggle ──► Preview.Hold("test", true) ──► VISIBILITY ──► placeholders
                   │
                   └─ not in a party ─► StandIn.Place(Providers.StandInSource()) ─► StandIn:Show()
                                              └─► Providers.SetStandIn(frame) ─► Resolve: party1 → stand-in
                                                                                     └─► LAYOUT ─► pinned

GROUP_ROSTER_UPDATE ─► core: party flip ─► VISIBILITY ─► features: syncEvents + refresh
                   └─► TestMode (if on): join → SetStandIn(nil), hide · leave → place, show, SetStandIn
```

The stop runs in reverse: `SetStandIn(nil)`, then `Preview.Hold("test", false)`, then the stand-in is
hidden.

### Clickable (secure) frames

Target and pet buttons are secure. They can anchor to the insecure stand-in **out of combat**, the
only time test mode runs. Ending in `PLAYER_REGEN_DISABLED` runs `NS.RunSecure`'s anchor and driver
writes at once, since lockdown has not begun. A write that does get queued lands at
`PLAYER_REGEN_ENABLED`, as every secure write does today. Dragging the stand-in moves pinned secure
buttons with it, which is legal out of combat.

## 5. Testing

**The test world defaults to a party.** The kit's mock starts solo (`inGroup = false`), which the
party rule would turn into "nothing shows" for every existing feature suite. `tests/run.lua` and
`tests/perf.lua` set `mocks.__context.inGroup = true` before `OnEnable`; the party-only cases change it
and restore it.

**Headless** (`tests/test_testmode.lua`, `tests/test_party.lua`, plus Providers, Preview, Compat and
slash changes):

- **The party-only gate:** solo, in a raid and in a party. Solo and in a raid, nothing shows (free
  placement included), no unit events are registered and the ticker stays off. In a party the same
  setup shows. A roster flip republishes VISIBILITY and re-syncs events; an unchanged roster sends
  nothing.
- **Providers:** solo puts the map to sleep; a `raidN` token maps to nothing.
- **Toggle:** `/pfe test` on and off, `NS.State.test` and preview following.
- **Refusals:** combat, disabled, suspended. Each prints one line and changes nothing.
- **Each exit:** `PLAYER_REGEN_DISABLED`, master enable off, `NS.SuspendAll()`. After each, the
  stand-in is hidden, party1 unmapped and the `test` hold released, in both modes.
- **The live switch:** solo → party hides the stand-in and unmaps it (placeholders stay); party →
  solo brings it back.
- **The party1 rule:** the stand-in fills party1 only when no real frame holds it, never another unit,
  and clearing it restores the real map.
- **Frame-system choice:** pinned EllesmereUI; pinned Blizzard with raid-style on and off; Automatic
  with EllesmereUI loaded or not and raid-style on or off.
- **Size and position copy** from mocked hidden source frames: real values, a zero size (fallback), a
  non-number position (center), and an effective-scale ratio.
- **Preview holds:** unlock + test, then test off, keeps preview on; test alone, then off, turns it
  off; unlock alone behaves as today.
- **Secure anchoring:** party1's target button is pinned to the stand-in while test mode is on, and
  after the stop its driver is `hide` and `mocks.__runStateDrivers()` hides it.
- **Status and slash:** the three new flags; `test` is in `NS.COMMANDS`, `preview` is not.

**Offline perf:** the resolve gains one `InParty()` read and one nil check. `resolveUnchanged` must
still read 0 API calls and 0 bytes; every other scenario keeps its ceiling.

**In game:** a new smoke step per frame system, run solo: the stand-in sits where the first party
frame would, at its size and in its look; the three placeholders attach and the offsets move them;
dragging carries them; joining a party moves the placeholders to the real frames and leaving brings
the stand-in back; pulling a dummy ends test mode with no stuck frames and no `ADDON_ACTION_BLOCKED`.
Plus a party-only step: solo and in a raid nothing shows; in a party everything does.

## 6. Documentation touched when built

- `docs/ARCHITECTURE.md`: the module count, the lifecycle, the preview text, the event table (core's
  and TestMode's `GROUP_ROSTER_UPDATE`), the slash paragraph, Known Limitations, the Compat count.
- `docs/module-map.md`: two rows and the new load-bearing position.
- `docs/data-flow.md`: the party rule as stage 0 and the stand-in as a stage-1 source.
- `docs/slash-dispatch.md`: `preview` → `test`.
- `docs/compat-layer.md`: `UnitIsUnit` out.
- `docs/settings-panel.md`, `docs/scope.md`: if they mention preview or raids.
- `docs/smoke-tests.md`: a step per frame system, a party-only step, and index rows.
- `README.md`: Usage and FAQ, then a de-AI pass.
- `docs/test-cases.md` and the README Tests badge: regenerated together.

## Rejected approaches

- **Stand-in + Blizzard Edit Mode.** Blizzard force-shows party frames only while Edit Mode is open
  with the account option *Party Frames* ticked. PFE can't open Edit Mode without tainting it, and
  which units those frames carry is unverified.
- **A real Blizzard template instance** (`CompactUnitFrame` on unit `player`). Pixel-exact on
  raid-style, but it runs Blizzard's shared unit-frame code under PFE's taint, and there is no
  equivalent for EllesmereUI or the classic layout.
- **Keeping `/pfe preview` beside `/pfe test`.** Two verbs whose only difference is where the player
  stands. The standard's preview section names `test` as an accepted spelling of the verb
  (preview-mode: "an explicit `/<slash> preview` (a.k.a. `test`) verb"), so one verb conforms.

## Out of scope

- Saving the stand-in's dragged position.
- More than one stand-in member.
- Driving EllesmereUI's own options preview.
- Raid frames (issue #1), now excluded by design rather than deferred.

## Risks

- **`GetLeft`/`GetTop` on a never-shown frame** can return `nil`. The fallback is the screen center,
  and the smoke step checks the normal case.
- **The presets and two fallback sizes are approximations.** Judged by eye per frame system; a fix is
  local to `StandIn.lua`.
- **EllesmereUI's button names** are private to it. Every lookup is nil-guarded.
- **A player who liked the solo free-placement cast bar loses it.** Accepted in brainstorming; the
  FAQ says so.
