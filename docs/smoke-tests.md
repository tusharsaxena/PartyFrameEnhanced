# Ka0s Party Frame Enhanced — manual in-game smoke tests

Run on a live **Retail (Midnight 12.1.0 / Interface 120100)** client, in order: later steps assume the
addon loaded cleanly. Turn on Lua errors first (`/console scriptErrors 1`, or BugSack). Watch chat for
the cyan `[PFE]` prefix and for any error frame. The headless gate (`lua tests/run.lua`, `luacheck .`)
covers the pure logic; this suite covers what only runs against the live client.

**Section T is the exception**: it is the non-English-client pass and needs a deDE or frFR client.

Sections for the three features (cast bars, target frames, pet frames), the frame systems and preview
mode are added by the phases that build them (plan P2–P6).

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
| **T** | **Non-English client (locale)** | **deDE or frFR** — sub-steps T1 and T4 may be signed off on English |

## A. Load and bootstrap

1. **Fresh install.** Delete `WTF/Account/<ACCOUNT>/SavedVariables/PartyFrameEnhanced.lua`, log in →
   world reached, **zero Lua errors**. *Failure:* an error naming `PartyFrameEnhanced\core\…` or a
   missing `[PFE]` on every line.
2. **`/reload`** → no errors.
3. **AddOn list.** The character-select AddOn list shows **Ka0s Party Frame Enhanced** with its notes
   line and icon.

## B. Slash surface

4. `/pfe` alone → the help block: a version line and sixteen verbs (help, config, list, get, set,
   reset, resetall, resetposition, lock, unlock, preview, status, debug, perf, version, profile), each
   a gold `/pfe <verb>`, an em dash and a white description.
5. `/partyframeenhanced` → the identical block.
6. `/pfe wibble` → `unknown command 'wibble'` then help.
7. `/pfe version` → `[PFE] v0.1.0`.
8. `/pfe list` → a green header, `[general]` group, then `path = value` rows with gold paths and white
   values, no trailing colons.
9. `/pfe set general.provider blizzard` → `general.provider = blizzard`; `/pfe reset general.provider`
   → back to `auto`. `/pfe set scale abc` → an invalid-value line, nothing changed.
10. `/pfe unlock` → `Elements unlocked — drag them into place`; the General page's *Lock frame*
    unticks if open. `/pfe lock` → locked again.

## C. Settings panel and the combat gate

11. `/pfe config` out of combat → Settings opens on **Ka0s Party Frame Enhanced**: the logo renders,
    the Notes line and the slash-command list show (the same rows as `/pfe help`).
12. **General** → a two-tab strip, **Master controls** then **Party frames**. Master controls holds, in
    order, *Enable Party Frame Enhanced* · *General visibility* / *Master scale* · *Master alpha* /
    *Lock frame* · *Debug console*, then the button pair *Reset position* · *Reset all settings*.
    *General visibility* is a dropdown of four: Always, Only in combat, Only out of combat, Never.
13. **Party frames** tab → *Frame system* (Automatic / Blizzard / EllesmereUI) and *Include my own row*.
14. **The Defaults button** renders in the dark/gold options style, not as a red stone button (it is
    built on first show, after any UI skin loaded).
15. **Combat refusal.** On a target dummy, in combat: `/pfe config` → the panel does **not** open and
    chat shows the gray `cannot open settings during combat — Blizzard's category-switch is protected`.
    Repeat → the same refusal each time, no queue. Leave combat → nothing opens by itself.
16. **The sidebar refuses too.** In combat, Esc → Options → AddOns → **Ka0s Party Frame Enhanced**, then
    **General** and **Profiles** → each closes the Settings window with the same gray notice; nothing
    draws. Out of combat they render normally.

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

## E. Debug console and perf harness

21. `/pfe debug` → the console window opens (monospace font, the collection's close/copy/clear marks,
    not a `×` glyph); `/pfe debug` again → it closes. The logging flag is untouched by both.
22. `/pfe debug on` → an `[Init]` line naming `PartyFrameEnhanced v0.1.0`, the schema version, the
    profile and the detected frame system. `/reload` → logging is **off** again (session-only).
23. `/pfe perf` → a status line and the step panel, whose close mark matches the console's. Walk
    `start` → `measure a` (a pull) → `measure b` → `finish` → `report` → `dump` without a Lua error.
    During arm B the addon is inert; after `finish` it is active again without a `/reload`.

## F. Cast bars

Run each step once on Blizzard's raid-style party frames, once on the classic layout and once on
EllesmereUI's, where noted.

24. **Attached under each frame.** In a party (a follower dungeon is enough), watch a healer cast → a
    bar appears **under that member's own party frame**, as wide as the frame, with the spell's icon
    at the left, its name, and seconds counting down at the right. It fills left to right and hides
    when the cast lands. *Failure:* a bar under the wrong member (the unit → frame map is wrong), or a
    bar that never hides.
25. **Your own row.** Raid-style or EllesmereUI (self shown): cast something → your bar appears under
    your own frame. Classic layout: **no** player bar (the layout never shows you) — switch Cast Bars →
    Position → *Anchor mode* to *Free placement* and cast again → your bar appears in the stack.
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
31. **Settings.** Cast Bars page → six tabs (General, Position, Bar, Border, Text, Icon). Change *Cast
    color*, *Height* and *Font size* → live bars restyle at once. Turn *Enable cast bars* off → no bar
    appears on the next cast.

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
35. **Raid marker.** Mark a member's target with a skull → the skull appears on that target frame.
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

39. **A pet appears.** A hunter or warlock in the party → a small frame under their party frame with
    the pet's name and health. They dismiss it → the frame disappears. Summon another → it shows the new
    pet.
40. **Your own pet.** On a pet class with your own row included, raid-style or EllesmereUI: your pet's
    frame sits under your party frame.
41. **Owner's class color.** Tick *Use class color* on Pet Frames → Bar → a hunter's pet takes hunter
    green, a warlock's warlock purple.
42. **Click to target.** Click a pet frame → you target the pet.

## I. Preview, placement and status

43. **Unlock previews.** `/pfe unlock` → every enabled element shows placeholder content: a cast bar
    mid-cast, a target frame at 65% with a skull, a pet frame at 80%. `/pfe lock` → all of it goes;
    live data returns. *Failure:* a placeholder left behind after locking (preview-mode MUST).
44. **Unlock refused in combat.** On a dummy, in combat: `/pfe unlock` → a gray *cannot unlock during
    combat* line, nothing previews, and *Lock frame* stays ticked on an open General page.
45. **Free placement drags.** Set Cast Bars → Position → *Anchor mode* to *Free placement*, unlock → a
    translucent plate labeled *Cast bars* appears over the stack. Drag it; lock; `/reload` → the stack
    is where you left it. General → *Reset position* (or `/pfe resetposition`) → back to its default.
46. **Preview without unlocking.** `/pfe preview` → placeholders, but no plate and nothing draggable;
    again → gone.
47. **Status.** `/pfe status` → the frame system in use, each unit with *frame* or a dash, each
    feature's state, and a *Note:* line when something is switched off (set General visibility to
    *Never* and run it again).

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
