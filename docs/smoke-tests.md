# Ka0s Party Frame Enhanced — manual in-game smoke tests

Run on a live **Retail (Midnight 12.1.0 / Interface 120100)** client, in order: later steps assume the
addon loaded cleanly. Turn on Lua errors first (`/console scriptErrors 1`, or BugSack). Watch chat for
the cyan `[PFE]` prefix and for any error frame. The headless gate (`lua tests/run.lua`, `luacheck .`)
covers the pure logic; this suite covers what only runs against the live client.

**Section T is the exception**: it is the non-English-client pass and needs a deDE or frFR client.

## Completion record

One row per full pass. The newest row is the current iteration.

| Iteration | Date | Sections | Result |
|---|---|---|---|
| v0.1.0 | 2026-09-18 | A–K and T, every step | Complete. Marked done by the addon owner |

## Index

| Section | What it covers | Client needed |
|---|---|---|
| A | Load and bootstrap | any Retail |
| B | Slash surface | any Retail |
| C | Settings panel and the combat gate | any Retail, a target dummy |
| D | Resets and profiles | any Retail |
| E | Debug console and perf harness | any Retail |
| F | Cast bars | a party (a follower dungeon works), a target dummy |
| G | Target frames | a party, mobs to target |
| H | Pet frames | a party with a pet class (or a hunter/warlock of your own) |
| I | Preview, placement and status | any Retail; a party for the attached steps |
| J | Preview, the stand-in and the party-only rule | solo; a party; each of the three frame systems |
| K | The launcher: minimap button and broker plugin | any Retail; a broker display for step 56 |
| **T** | **Non-English client (locale)** | **deDE or frFR** — sub-steps T1 and T4 may be signed off on English |

## A. Load and bootstrap

1. **Fresh install.** Delete `WTF/Account/<ACCOUNT>/SavedVariables/PartyFrameEnhanced.lua`, log in →
   world reached, **zero Lua errors**. *Failure:* an error naming `PartyFrameEnhanced\core\…` or a
   missing `[PFE]` on every line.
2. **`/reload`** → no errors.
3. **AddOn list.** The character-select AddOn list shows **Ka0s Party Frame Enhanced** with its notes
   line and **the addon's own logo** as its icon — not a Blizzard achievement icon, and not a blank
   square. *Failure:* a blank square means `media/logos/partyframeenhanced.logo.128.tga` did not load;
   it draws nothing and raises nothing, so nothing else will tell you (anti-pattern #82).

## B. Slash surface

4. `/pfe` alone → the settings panel opens on the landing page (in combat: the gray refusal
   instead). `/pfe help` → the help block: a version line and seventeen verbs (help, config, enable,
   disable, list, get, set, reset, resetall, resetposition, lock, unlock, status, debug, perf,
   version, profile), each a gold `/pfe <verb>`, an em dash and a white description.
5. `/partyframeenhanced` and `/partyframeenhanced help` → the same as `/pfe` and `/pfe help`.
6. `/pfe wibble` → `unknown command 'wibble'` then help.
7. `/pfe version` → `[PFE] v1.0.1`.
8. `/pfe list` → a green header, `[general]` group, then `path = value` rows with gold paths and white
   values, no trailing colons.
9. `/pfe set general.provider blizzard` → `general.provider = blizzard`; `/pfe reset general.provider`
   → back to `auto`. `/pfe set scale abc` → an invalid-value line, nothing changed.
10. `/pfe unlock` → `Elements unlocked — drag them into place`; the General page's *Lock frame*
    unticks if open. `/pfe lock` → locked again.
10a. `/pfe disable` → `enabled = false` in the same gold/white shape `/pfe set` prints, everything
    the addon draws goes, and the General page's *Enable Party Frame Enhanced* unticks if open. Then,
    **while disabled**: `/pfe` still opens the panel, `/pfe help` still lists `enable`, `/pfe version`
    still answers, and `/pfe list` / `/pfe get` / `/pfe set` still read and repair settings.
    `/pfe enable` → `enabled = true` and it all comes back. *Failure:* any of those going quiet —
    the switch would only go one way (slash-commands-§2).
10b. Still **while disabled**, the three verbs that drive what the addon draws refuse instead of
    acting: `/pfe unlock`, `/pfe lock` and `/pfe resetposition` each answer on **one** tagged line
    naming `/pfe enable`, and nothing moves — no stand-in appears, no stack jumps back to its
    default position. *Failure:* a second line, a lecture about the state, or a verb that prints the
    refusal and then acts anyway.

10c. Still **while disabled**, the **stand-down is total**, which is the half a chat window cannot
    show you. `/pfe debug on` and watch: entering and leaving combat, joining and leaving a party,
    and switching target produce **no** `[Cast]`, `[Target]`, `[Pet]`, `[Party]` or `[Secure]` line,
    because nothing is registered to produce one. *Failure:* any line at all — the addon stopped
    reacting rather than stopping watching, and it is still paying the dispatch on every event the
    player switched it off to stop paying for.

10d. Still **while disabled**, **left-click the minimap button**: one tagged line naming
    `/pfe enable`, and nothing else — the elements do not unlock and no stand-in appears.
    **Right-click** it: the settings panel opens, exactly as it does when the addon is running.
    *Failure:* a left click that unlocks (it would be writing the stored tree of an addon the player
    switched off), or a right click that refuses.

10e. `/pfe enable` again, then `/reload`. Everything comes back, and it comes back from the settings
    **as they are now**: change a setting while the addon is disabled — `/pfe set castbar.enabled
    false` — then `/pfe enable`, and the cast bars stay off. *Failure:* the addon standing up into
    the state it had when it went down.

## C. Settings panel and the combat gate

11. `/pfe config` out of combat → Settings opens on **Ka0s Party Frame Enhanced**: the logo renders,
    the Notes line and the slash-command list show (the same rows as `/pfe help`).
12. **General** → a two-tab strip, **Master controls** then **Party frames**. Master controls holds, in
    order, *Enable Party Frame Enhanced* · *General visibility* / *Master scale* · *Master alpha* /
    *Lock frame* · *Debug console* / *Minimap button*, and then the button pair — **there is no Test mode
    checkbox** (options-ui-§15 exempts this addon; a box labeled *Test mode* here is the
    duplicate-switch finding, anti-pattern #80). Unticking *Lock frame* is what starts preview, and
    combat re-ticks it
    *Reset position* · *Reset all settings*.
    *General visibility* is a dropdown of four: Always, Only in combat, Only out of combat, Never.
13. **Party frames** tab → *Frame system* (Automatic / Blizzard / EllesmereUI) and *Include my own row*.
14. **The Defaults button** renders in the dark/gold options style, not as a red stone button (it is
    built on first show, after any UI skin loaded).
15. **Combat refusal.** On a target dummy, in combat: `/pfe config` → the panel does **not** open and
    chat shows the gray `cannot open settings during combat — Blizzard's category-switch is protected`.
    Repeat → the same refusal each time, no queue. Leave combat → nothing opens by itself.
16. **The combat lock.** Open **General**, pull a dummy → the whole page, tab strip included, goes under
    a gray *Settings are locked during combat.* cover; a click on a checkbox, a slider drag, a tab and
    Defaults change nothing, and one gray `settings are locked during combat — changes are refused
    until it ends` line prints for the whole combat. In combat, switch to **Cast Bars** and **Profiles**
    in the AddOns sidebar → each shows covered, the window stays open, no Lua error and no
    `ADDON_ACTION_BLOCKED`. `/pfe set alpha 0.8` in combat, then leave combat → the cover
    lifts and the page shows the new value. *Failure:* a window that closes itself, a value that
    changes under the cover, or a page that stays covered after combat.

## D. Resets and profiles

17. **Profiles** page → AceDBOptions' controls render **inside** the canvas; no error.
18. **Page Defaults.** Change *Master scale* and *Frame system*, press General's **Defaults** → both
    revert. With `/pfe debug on`, the console shows one `[Set] reset general: 2 rows` line, not two
    `[Set]` lines.
19. **Reset all settings.** Make a second profile on the Profiles page first. Change settings, press
    *Reset all settings* → a popup with, verbatim, *"Reset this profile to the addon's defaults?
    Everything you have configured or added in it is discarded — your other profiles are not
    affected."* → **Yes** → settings are back at defaults, you are still on the same profile, and the
    profile list is unchanged. The button's tooltip names *"the same thing Profiles → Reset Profile
    does"*. `/pfe resetall` does the same act.
20. `/pfe profile` → the sub-verb list; `/pfe profile new Test` → switched to a fresh `Test`;
    `/pfe profile use Default` → back.
20a. **Bad profile names are refused.** `/pfe profile new Healer`; `/pfe set castbar.width 222`;
    `/pfe profile use Default`; `/pfe profile new Healer` → one *already exists* line, and Healer
    still has width 222. `/pfe profile copy Nope` and `/pfe profile copy <current>` → one refusal line
    each, no Lua error frame. `/pfe profile use Typo` → refused, and `/pfe profile list` shows no
    `Typo`. `/pfe profile delete Nope` → refused, no *Deleted* line.

## E. Debug console and perf harness

21. `/pfe debug` → the console window opens (monospace font, the collection's close/copy/clear marks,
    not a `×` glyph); `/pfe debug` again → it closes. The logging flag is untouched by both.
22. `/pfe debug on` → an `[Init]` line naming `PartyFrameEnhanced v1.0.1`, the schema version, the
    profile and the detected frame system. `/reload` → logging is **off** again (session-only).
23. `/pfe perf` → a status line and the step panel, whose close mark matches the console's. Walk
    `start` → `measure a` (a pull) → `measure b` → `finish` → `report` → `dump` without a Lua error.
    During arm B the addon is inert; after `finish` it is active again without a `/reload`.
23a. **The capture worth recording.** In a party with at least one pet class, somewhere quiet (an
    instance, not a city), start with the setup in the label — `/pfe perf start party <frame system>
    <anchor mode>` — and pull the same pack for both arms. In the report, `petEvent` has calls and
    `targetRender` per `targetTick` pass is **at most the number of members with a target**. Paste the
    buffer into `/wow-addon:perf-analysis`. *Failure:* `targetRender` near 5 per pass while fewer
    members have targets (hidden buttons being repainted), or no `petEvent` row with a pet out.

## F. Cast bars

Run each step once on Blizzard's raid-style party frames, once on the classic layout and once on
EllesmereUI's, where noted.

24. **Attached over each frame.** On a fresh profile, in a party (a follower dungeon is enough), watch a
    healer cast → a bar appears **across the top of that member's own party frame**, as wide as the frame, with the spell's icon
    at the left, its name, and seconds counting down at the right. It fills left to right and hides
    when the cast lands. *Failure:* a bar on the wrong member (the unit → frame map is wrong), or a
    bar that never hides.
25. **Your own row.** Raid-style or EllesmereUI (self shown): cast something → your bar appears over
    your own frame. Classic layout: **no** player bar (the layout never shows you) — switch Cast Bars →
    Size & Position → *Anchor mode* to *Free placement* and cast again → your bar appears in the stack.
26. **Channels drain.** Watch a channel (Penance, Mind Flay on a dummy) → the bar starts full and drains.
27. **Interrupt.** Interrupt a dummy-adjacent party member's cast or have a mob interrupt one → the bar
    turns the interrupted color, shows the client's own word for *Interrupted*, holds about half a
    second, then fades.
28. **Can't be interrupted.** A cast flagged uninterruptible shows the gray fill and the shield icon.
    In a dungeon, in combat, **zero Lua errors** throughout (the flag is secret there). *Failure:* an
    error mentioning `secret` or `compare` from `CastBars.lua`.
29. **Frame system switches.** With EllesmereUI loaded, set General → *Frame system* to *Blizzard*
    while EllesmereUI hides Blizzard's frames → the bars disappear (no Blizzard frames on screen); back
    to *Automatic* → they return under EllesmereUI's frames.
30. **Re-sort in combat.** Raid-style or EllesmereUI sorted by role: have someone leave or join during
    combat → the cast bars follow the members to their new frames straight away.
31. **Settings.** Cast Bars page → six tabs (General, Size & Position, Bar, Border, Text, Icon). Change
    *Cast color*, *Height* and *Font size* → live bars restyle at once. Turn *Enable cast bars* off → no
    bar appears on the next cast.
31a. **Size & Position shows only what applies.** Cast Bars → Size & Position opens with the *Size*
    block (Width, Height), then *Placement*. With *Attach to party frames*: the *Attached to party
    frames* block is drawn and there is no *Free placement* heading at all; with *Match party frame
    width* ticked, *Width* is grayed. Switch to *Free placement* → the tab redraws at once with the
    *Free placement* block (Growth direction, Spacing) in place of the attached one, and *Match party
    frame width* grayed. `/pfe set castbar.anchorMode attached` with the page open → it redraws back.
    Repeat on the Target Frames and Pet Frames pages. *Failure:* the redraw lags one click behind, an
    empty heading is left behind, or the dropdown closes itself mid-choice with a Lua error.

## G. Target frames

32. **Beside each frame.** A party member targets a mob → a small frame appears to the right of their
    party frame with the mob's name, a red health bar (hostile) and its health percent. They clear
    target → it disappears. *Failure:* the frame beside the wrong member, or one that stays after they
    clear target.
33. **Health moves.** The member's target takes damage → the bar and percent drop within a fraction of
    a second (the 0.2 s refresh), in combat, with **zero Lua errors** in a dungeon. *Failure:* an error
    naming `secret`, `compare` or `index` from `TargetFrames.lua` or `UnitButtons.lua`.
34. **Colors.** A friendly NPC target → green; a neutral one → yellow. Tick *Use class color* on the
    Bar tab, have a member target a player → the player's class color.
34a. **A new member's target.** Invite someone who is already targeting a friendly NPC → their target
    frame shows the NPC's name in green within a fraction of a second, with no need for them to
    retarget. *Failure:* a red frame with no name that stays until they change target.
35. **Raid marker.** Mark a member's target with a skull → the skull appears on that target frame.
35a. **Marker placement.** `/pfe unlock` (the preview shows a skull on every target frame). Target
    Frames → Marker: set *Anchor point* to *Right* → the skull's center moves to the bar's right end;
    drag *X offset* and *Y offset* → it follows, live. Untick *Show raid marker* → the skull goes and
    the three placement controls gray out. *Failure:* the skull stays put until `/reload`.
35c. **Marker over the border.** Target Frames → Border: tick *Show border*; mark a member's target
    → the skull draws on top of the border's edge. Repeat on Pet Frames. *Failure:* the border's line
    cuts across the skull.
35d. **Pet raid marker.** Mark a member's pet with a skull → the skull appears on that pet frame;
    clear it → it goes. Pet Frames → Marker placement and *Show raid marker* behave as in 35a.
35b. **Health updates off.** General page → Health updates: untick *Update health* → *Health refresh*
    grays out, and so does Text → *Show health percent* on both Target Frames and Pet Frames. With a
    member targeting a mob, its bar sits full with no percent while the mob takes damage, and
    `/pfe debug on` shows no `[Target] health ticker started` line (one that is followed at once by
    `health ticker stopped` is the unresolved-target repaint, and is expected). Tick it back → the real health and
    percent return at once. With a target up, drag *Health refresh* to 1 → the bar updates about once
    a second straight away, with no need to retarget.
36. **Click to target.** Click a target frame → you target that unit, in combat too. Untick *Click to
    target* → clicks pass through; ticking it back in combat applies when combat ends.
37. **Combat rules.** In combat, change General visibility to *Only out of combat* → the frames hide
    at once (the driver's `[combat]` clause) — no Lua error, no blocked-action message. Move a frame in
    free placement: refused in combat, allowed out of it.
38. **Re-sort in combat.** Raid-style or EllesmereUI sorted by role: someone joins mid-pull → target
    frames whose party frame moved fade out, then reappear beside the right member when combat ends.
    `/pfe debug on` shows `[Secure] queued …` then `[Secure] flushed …`. *Failure:* a frame beside the
    wrong member during combat, or an `ADDON_ACTION_BLOCKED` line in the console.

## H. Pet frames

39. **A pet appears.** A hunter or warlock in the party → a small frame to the right of their party
    frame, under their target frame, with the pet's name and health. They dismiss it → the frame disappears. Summon another → it shows the new
    pet.
40. **Your own pet.** On a pet class with your own row included, raid-style or EllesmereUI: your pet's
    frame sits to the right of your party frame, under your target frame.
41. **Owner's class color.** Tick *Use class color* on Pet Frames → Bar → a hunter's pet takes hunter
    green, a warlock's warlock purple.
42. **Click to target.** Click a pet frame → you target the pet.
42a. **Health updates off, pets.** With the same General → Health updates switch off, a pet's bar sits
    full with no percent while the pet takes damage. Tick it back → the real health returns.

## I. Preview, placement and status

43. **Unlock previews.** `/pfe unlock` → every enabled element shows placeholder content: a cast bar
    drawn full (its whole size shows), a target frame at 65% with a skull, a pet frame at 80%. `/pfe lock` → all of it goes;
    live data returns. *Failure:* a placeholder left behind after locking (preview-mode MUST).
44. **Unlock refused in combat.** On a dummy, in combat: `/pfe unlock` → a gray *cannot unlock during
    combat* line, nothing previews, and *Lock frame* stays ticked on an open General page.
45. **Free placement drags.** Set Cast Bars → Size & Position → *Anchor mode* to *Free placement*, unlock → a
    translucent plate labeled *Cast bars* appears over the stack. Drag it; lock; `/reload` → the stack
    is where you left it. General → *Reset position* (or `/pfe resetposition`) → back to its default.
46. **Preview in a party.** In a party, `/pfe unlock` → placeholders on every element at the real
    party frames, no stand-in and no plate; `/pfe lock` → gone.
47. **Status.** `/pfe status` → the frame system in use, each unit with *frame* or a dash, each
    feature's state, and a *Note:* line when something is switched off (set General visibility to
    *Never* and run it again).
47a. **Range fade, EllesmereUI.** In a party with EllesmereUI's party frames, walk away from a member
    until EllesmereUI dims their frame → that member's cast bar, target frame and pet frame dim to
    the same opacity at the same moment; walk back → all return together. Change EllesmereUI's own
    out-of-range alpha → ours follows it. `/pfe status` → *Range fade: copied from EllesmereUI*.
    *Failure:* our elements stay bright, or dim to a different opacity from the frame.
47b. **Range fade, Blizzard raid-style, in an instance.** Raid-style party frames with Blizzard's
    *fade out of range* on: the same as 47a, at 0.5. Repeat **inside a dungeon, in combat**, where
    range can be secret → still no Lua error, and the elements still dim. *Failure:* an error naming
    `secret` from `RangeFade.lua`, or elements that stop dimming in the instance only (the secret
    fallback did not take).
47c. **Range fade, Blizzard classic.** Raid-style off: the classic frames themselves never dim, but a
    member past ~40 yards has their elements at half opacity. `/pfe status` → *Range fade: own range
    check (classic frames)*.
47d. **Range fade, off and preview.** General → Party frames: untick *Fade with party frames* → every
    element at full opacity at once, out of range or not. Tick it back → the far member dims again.
    `/pfe unlock` in a party with someone out of range → every placeholder at full opacity; lock →
    the fade returns. Mid-combat reshuffle (step 38) still fades the clickable frames as before.

## J. Preview, the stand-in and the party-only rule

48. **Party-only.** Solo: nothing shows, attached or free placement, and `/pfe status` ends with *not
    in a party — nothing shows until you join one (try /pfe unlock)*. Join a party → everything shows.
    Convert to a raid → it all goes again.
49. **Stand-in, EllesmereUI.** Solo, EllesmereUI loaded, Frame system Automatic: `/pfe unlock` → one
    stand-in party frame where EllesmereUI's first party frame sits, at its size, with a flat
    class-colored bar and a gray *(test)* after your name. The stand-in draws beneath what attaches
    to it: the cast bar's spell icon shows whole. Party1's cast bar, target frame (skull) and pet frame
    attach to it, and the Size & Position offsets move them. Drag it → they follow. *Failure:* a
    stand-in of a different size from your EllesmereUI party frames. `/pfe debug on`, then
    `/pfe unlock`, logs a `[Preview]` line naming where the size came from. For EllesmereUI it should
    read `settings` (your EllesmereUI party frame width and height); `frame` or `fallback` means
    EllesmereUI's settings could not be read.
50. **Stand-in, Blizzard raid-style.** Blizzard frames, Edit Mode raid-style party frames on: the same
    as 49 in the raid-bar look. Note whether the 72 × 36 fallback matched if the stand-in came up at
    screen center.
51. **Stand-in, Blizzard classic.** Raid-style off: the same as 49 with a portrait, a green health bar
    and a mana bar. Note whether the 120 × 53 fallback matched if the stand-in came up at screen
    center.
52. **Live switch and exits.** With the stand-in up, join a party → it goes and the placeholders move
    to the real frames; leave → it comes back. Pull a dummy → *Locked — combat started*, the *Lock
    frame* box ticks itself, nothing stuck on screen, no `ADDON_ACTION_BLOCKED` in `/pfe debug`.
    While unlocked `/pfe status` reads *unlocked (stand-in)* or *unlocked (your party frames)*.
    In combat, `/pfe unlock` → a gray *cannot unlock during combat* and nothing moves; `/pfe lock`
    still works. Disable the addon while unlocked → *Locked — the addon was disabled*.

## K. The launcher — minimap button and broker plugin

53. **The button is there, wearing the addon's own logo.** Log in → a round button on the minimap ring
    showing the Party Frame Enhanced logo, not a blank circle and not a Blizzard icon. Hover → nothing
    is required to appear (this addon supplies no tooltip yet). Drag it around the ring → it stays
    where you left it after `/reload`. *Failure:* a blank button is the 128 `.tga` not loading; a
    button that jumps back to its old angle on reload is `minimapPos` not being written to the table
    LibDBIcon was handed.
54. **Left-click is the preview switch (rung b).** Left-click → the elements unlock exactly as
    `/pfe unlock` unlocks them (stand-in out of a party, placeholders in one), and the General page's
    *Lock frame* unticks if open. Left-click again → locked. In combat, left-click → the same gray
    *cannot unlock during combat* and nothing moves. *Failure:* a left click that opens the settings
    panel — the panel is already on the right button, so that is the rule skipped, not a choice
    (launcher-§2, anti-pattern #81).
55. **Right-click always opens the settings.** Right-click, locked or unlocked → the settings panel
    opens on the landing page and the lock does not move. In combat → the same gray refusal `/pfe
    config` gives.
56. **The broker plugin is the same object.** With Titan Panel, ElvUI data texts or Bazooka installed,
    add **PartyFrameEnhanced** to the bar → the same logo and label, left-click unlocks, right-click
    opens the settings. *Failure:* an empty value cell beside the icon means the object was registered
    as a `data source` rather than a `launcher`.
57. **The Minimap button row, both ways.** General → Master controls → untick **Minimap button** → the
    button disappears **immediately**, not at the next reload. `/reload` → still gone. Tick it → back.
    Then hide it from **LibDBIcon's own right-click menu** instead and reopen the panel → the checkbox
    is already unticked. *Failure:* the two disagreeing is a second copy of one state
    (launcher-§3, anti-pattern #81).
58. **The button is account-wide furniture.** Hide the button, then: switch profiles (`/pfe profile
    new smoke`) → still hidden. Log in on a different character → still hidden. *Failure:* the button
    coming back on either means the table is profile-scoped, which launcher-§3 forbids.
59. **It survives BOTH resets.** Still hidden, run **Reset all settings** → still hidden. Then press
    General's **Defaults** button → **still hidden**, while the other rows on General do go back to
    their defaults in the same press. Tick it back on and repeat both → it stays shown. *Failure:*
    either reset moving the row in either direction. Whether the button is on the minimap is a
    per-installation display preference, like the position it was dragged to, and no reset may touch
    it (launcher-§3). `/pfe reset global.minimap.hide` is the deliberate exception and does reset it.

## T. Non-English client (locale)

What this addon touches that a client translates, enumerated from the code rather than assumed:

- **Localized `_G` reads:** two, both display-only — the client's `INTERRUPTED` and `FAILED` words
  on a stopped cast bar (`modules/CastBars.lua`), with `NS.L` English fallbacks. Nothing parses them.
  The only other `_G[...]` reads are frame names (`ERFPartyHeaderUnitButtonN`,
  `CompactPartyFrameMemberN`), which the client does not translate.
- **Tooltip lines:** none parsed.
- **Display strings where an id exists:** class colors are keyed on `UnitClass`'s second return (the
  class **token**, `MAGE`), never on the localized name; reaction is `UnitReaction`'s number; the frame
  systems are found by global frame names and the Edit Mode API, never by a label.
- **Strings this addon renders:** spell names and unit names come from the client and are only ever
  displayed; the addon's own words (*Interrupted*, *Failed*, labels) are `NS.L` keys with English
  values until a translation exists.
- **Headers or tokens another tool parses:** the `/pfe perf dump` record, whose keys are fixed English
  identifiers written by LibKa0s-Perf.

Steps, each naming its failure:

- **T1. Load on a German client.** Log in on deDE → zero Lua errors, `[PFE]` lines in chat, the settings
  panel in English (untranslated, as expected). *Failure:* an error frame, or a label reading as a raw
  key like `L["Frame system"]` (the fallback metatable missing). *May be signed off on English:* the
  fallback is exercised by every headless case that renders a label.
- **T2. Class colors from the token.** With *Use class color* on, have a party member target a
  German-named class-bearing player (a *Magier*) → the target frame takes mage blue. *Failure:* the
  stored swatch color instead of the class color on deDE only — the class was keyed on the localized
  name. *Headless stand-in:* `Compat.ClassToken` reads `UnitClass`'s second return only, and
  `tests/test_targetframes.lua` colors a `MAGE` target from the token.
- **T3. Spell names and the stop word render whole.** Watch a party member cast a spell whose German
  name has an umlaut or ß (*Blitzschlag*, *Gedankenschlag*) → the name renders without a `?` or
  replacement box at its end, and the time text has no stray `%s`/`%.1f`. Interrupt a cast → the bar
  shows *Unterbrochen*, not *Interrupted*. *Failure:* a truncated multi-byte character at the end of
  the name (the bar clips by width, never by byte count, so this should not happen), or the English
  word on a German client (the client global was not read). **The client is the only witness here**:
  the English client has no multi-byte spell names and its global is the English word.
- **T4. Frame-system detection.** With party frames shown, `/pfe debug on` → the `[Init]` line names
  the detected system, the same as on English. *Failure:* `frames 'none'` on deDE with party frames
  visibly on screen. *May be signed off on English:* detection reads no localized string.

T1 and T4 may be signed off on an English client for the reasons given. T2 is covered headlessly once
its case exists. T3 needs a deDE or frFR client.
