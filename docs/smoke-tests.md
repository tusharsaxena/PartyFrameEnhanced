# Smoke tests — Ka0s Party Frame Enhanced

These are the in-client checks the headless suite cannot make: what the live client draws, the secure
and secret-value paths, and the three frame systems the addon attaches to. The headless gate
(`lua tests/run.lua`, `luacheck .`) covers the pure logic. Run a pass on a live **Retail (Midnight
12.1.0 / Interface 120100)** client, starting from a clean `/reload`, theme by theme; turn logging on
(`/pfe debug on`) only where a check says so. Record each check on its `Result:` line: the date and
PASS, or FAIL and what you saw. A new pass overwrites the old results, and git keeps them. IDs are
`<THEME>-<n>`: a new check takes the next free number in its theme, and a retired number is not reused.

## Index

| ID range | Theme | What it covers |
|---|---|---|
| INSTALL-1 – 4 | Install and load | fresh install, `/reload`, the AddOn-list logo, a clean load on the vendored LibKa0s |
| SLASH-1 – 6 | Slash commands | help, the long alias, unknown verbs, version, list, set and reset |
| PANEL-1 – 7 | Settings panel | the landing page, the General tabs, the Defaults button, Size & Position, every page after the descriptor names the addon |
| PROFILE-1 – 10 | Profiles | the Profiles page, the `profile` verb and its sub-verbs, Reset all settings |
| STATE-1 – 9 | Enable, disable and stand-down | the live surface, refusals, the total stand-down |
| PREV-1 – 9 | Preview, placement and status | unlock, free placement, `/pfe status`, the party-only rule, the stand-in |
| CAST-1 – 7 | Cast bars | placement per member, channels, interrupts, the frame-system switch, settings |
| UNIT-1 – 11 | Target and pet frames | placement, health, colors, raid markers, health updates, click to target |
| FADE-1 – 4 | Out-of-range fade | EllesmereUI, Blizzard raid-style and classic, the switch and preview |
| LAUNCH-1 – 8 | Minimap button and broker | the logo, the tooltip, both clicks, the broker object, the account-wide row |
| COMBAT-1 – 12 | Combat | the panel refusal and lock, the combat re-lock, unlock refusal, visibility, the in-combat follow through a re-sort (join, leave, EllesmereUI, disabled, a placement changed in combat), toggles and moves |
| DIAG-1 – 17 | Debug console, diagnostics and perf | the console, the `[Init]` line, perf runs, the diagnostics report, resizing the three windows, the Diagnostics link, diagnostics turning logging on, the library's slash refusals and stand-down edges in the console, the launcher's login line |
| LOC-1 – 4 | Non-English client | load, class colors, spell names and detection on deDE or frFR |

## Before you start

- Turn on Lua errors: `/console scriptErrors 1`, or BugSack. "Zero Lua errors" means nothing reaches
  the error frame or BugSack during the check. Watch chat for the cyan `[PFE]` prefix.
- "In combat" means hitting a target dummy.
- Most checks need a party; a follower dungeon is enough. Pet checks need a hunter or warlock in the
  party (or your own). The fade and stand-in checks name the frame system they need: Blizzard
  raid-style (Edit Mode raid-style party frames on), Blizzard classic (raid-style off), or EllesmereUI.
  Run the CAST checks once on each of the three.
- Run the PROFILE checks in order: later ones use the profiles earlier ones make. LAUNCH-7 uses the
  `Test` profile from PROFILE-2.
- LAUNCH-5 needs a broker display (Titan Panel, ElvUI data texts or Bazooka).
- The LOC checks need a deDE or frFR client; LOC-1 and LOC-4 may be signed off on English.
- Some checks read `WTF/Account/<ACCOUNT>/SavedVariables/PartyFrameEnhanced.lua` after a logout.

## Install and load

- **INSTALL-1. Fresh install.** Delete `WTF/Account/<ACCOUNT>/SavedVariables/PartyFrameEnhanced.lua`
  and log in → the world is reached with zero Lua errors. *Failure:* an error naming
  `PartyFrameEnhanced\core\…`, or an addon line in chat without the `[PFE]` prefix. Result: pass (owner-marked 2026-10-10)
- **INSTALL-2. Reload.** `/reload` → no Lua errors. Result: pass (owner-marked 2026-10-10)
- **INSTALL-3. AddOn-list logo.** At character select, open the AddOn list → **Ka0s Party Frame
  Enhanced** with its notes line and the addon's own logo as its icon, not a Blizzard achievement icon
  and not a blank square. *Failure:* a blank square means `media/logos/partyframeenhanced.logo.128.tga`
  did not load; it draws nothing and raises nothing, so nothing else will tell you (anti-pattern #82).
  Result: pass (owner-marked 2026-10-10)
- **INSTALL-4. A clean load on the vendored LibKa0s.** With `libs/LibKa0s` at the tag `CLAUDE.md`'s provenance
  line names (v1.71.0: Env 2, OptionsIdList 4, Slash 20, SlashParse 2, WidgetsLineChart 3, WidgetsAutocomplete 2), log in, then `/reload` twice → no Lua error, and no chat line from LibKa0s
  about a missing or older module. `/pfe config` → every page draws as it did. `/pfe status` prints its summary, and `/pfe unlock` unlocks the frames. *Failure:* a page
  that comes up empty, or an error naming `PartyFrameEnhanced\libs\LibKa0s\…`. Result: pass (owner-marked 2026-10-10)

## Slash commands

- **SLASH-1. Bare slash and help.** Out of combat, `/pfe` alone → the settings panel opens on the
  landing page (in combat it refuses; see COMBAT-1). `/pfe help` → the help block: a version line and
  eighteen verbs (help, config, enable, disable, list, get, set, reset, resetall, resetposition, lock,
  unlock, status, debug, diagnostics, perf, version, profile), each a gold `/pfe <verb>`, an em dash
  and a white description. Result: pass (owner-marked 2026-10-10)
- **SLASH-2. The long alias.** `/partyframeenhanced` and `/partyframeenhanced help` → the same as
  `/pfe` and `/pfe help`. Result: pass (owner-marked 2026-10-10)
- **SLASH-3. Unknown verb.** `/pfe wibble` → `unknown command 'wibble'`, then the help block. Result: pass (owner-marked 2026-10-10)
- **SLASH-4. Version.** `/pfe version` → `[PFE] v<the TOC version>` (`[PFE] v1.2.0` on 1.2.0).
  Result: pass (owner-marked 2026-10-10)
- **SLASH-5. List.** `/pfe list` → a green header, the `[general]` group, then `path = value` rows
  with gold paths and white values, and no trailing colons. Result: pass (owner-marked 2026-10-10)
- **SLASH-6. Set, reset and a bad value.** `/pfe set general.provider blizzard` →
  `general.provider = blizzard`; `/pfe reset general.provider` → `general.provider = auto`.
  `/pfe set scale abc` → `Invalid value for scale`, then an indented `expected a number`, and nothing
  changes. Result: pass (owner-marked 2026-10-10)

## Settings panel

- **PANEL-1. Landing page.** Out of combat, `/pfe config` → Settings opens on **Ka0s Party Frame
  Enhanced**: the logo renders, and the Notes line and the slash-command list show (the same rows as
  `/pfe help`). Result: pass (owner-marked 2026-10-10)
- **PANEL-2. General → Master controls.** Open **General** → a three-tab strip, **Master controls**,
  **Party frames**, **Health updates** (UNIT-10 checks that tab's controls). Master controls holds,
  in order, *Enable Party Frame Enhanced* · *General visibility* / *Master scale* · *Master alpha* /
  *Lock frame* · *Debug console* / *Minimap button*, then the button pair *Reset position* · *Reset
  all settings*. *General visibility* is a dropdown of four: Always, Only in combat, Only out of
  combat, Never. *Failure:* a box labeled *Test mode* is the duplicate-switch finding (options-ui-§15
  exempts this addon; anti-pattern #80). Result: pass (owner-marked 2026-10-10)
- **PANEL-3. General → Party frames.** The **Party frames** tab → *Frame system* (Automatic / Blizzard
  / EllesmereUI), *Include my own row* and *Fade with party frames*. Result: pass (owner-marked 2026-10-10)
- **PANEL-4. The Defaults button.** It renders in the dark/gold options style, not as a red stone
  button (it is built on first show, after any UI skin loaded). Result: pass (owner-marked 2026-10-10)
- **PANEL-5. Page Defaults.** `/pfe debug on`. Change *Master scale* and *Frame system*, then press
  General's **Defaults** → both revert, and the console shows one `[Set] reset general: 2 rows` line,
  not two `[Set]` lines. Result: pass (owner-marked 2026-10-10)
- **PANEL-6. Size & Position shows only what applies.** Cast Bars → Size & Position opens with the
  *Size* block (Width, Height), then *Placement*. With *Attach to party frames*, the *Attached to party
  frames* block is drawn and there is no *Free placement* heading at all; with *Match party frame
  width* ticked, *Width* is grayed. Switch to *Free placement* → the tab redraws at once with the *Free
  placement* block (Growth direction, Spacing) in place of the attached one, and *Match party frame
  width* grayed. With the page open, `/pfe set castbar.anchorMode attached` → it redraws back. Repeat
  on the Target Frames and Pet Frames pages. *Failure:* the redraw lags one click behind, an empty
  heading is left behind, or the dropdown closes itself mid-choice with a Lua error. Result: pass (owner-marked 2026-10-10)
- **PANEL-7. Every page after the descriptor names the addon.** The Options descriptor now passes
  `addonName` (LibKa0s#42). `/reload` → no Lua error on load. `/pfe debug on`, then `/pfe config` and
  open every page (General and its three tabs, Cast Bars, Target Frames, Pet Frames, Profiles) → each
  renders exactly as before. This addon has no item list, so no help mark is drawn and the console
  shows no `[Cfg] help art:` line. Result: pass (owner-marked 2026-10-10)

## Profiles

- **PROFILE-1. Profiles page.** Open **Profiles** → AceDBOptions' controls render inside the canvas,
  with no error. Result: pass (owner-marked 2026-10-10)
- **PROFILE-2. Create a profile.** `/pfe profile new Test` → `Created and switched to new profile
  'Test'`, and its settings are at their defaults. Result: pass (owner-marked 2026-10-10)
- **PROFILE-3. The list.** `/pfe profile` → a green `Profiles` header with no trailing colon, one row
  per profile sorted by name ignoring case, the current one followed by `(current)`, the hint row
  `/pfe profile <name> switches profile`, then `Profile commands` and its seven sub-verb rows.
  `/pfe profile list` and `/pfe profile LIST` → the same list without the sub-verb rows.
  `/pfe profile current` → `Current profile: Test`. Result: pass (owner-marked 2026-10-10)
- **PROFILE-4. Switch by name.** In a party, on Test, set Cast Bars → Size & Position → *Anchor mode*
  to *Free placement*. `/pfe debug on`, then `/pfe profile Default` → `Switched to profile 'Default'.`,
  one `[Profile] changed → Default` line on the console, and the cast bars go back over the party
  frames with no `/reload`. `/pfe profile use Test` → the same switch the other way, and the bars go
  back to the free stack. `/pfe profile Test` again → `Already on profile 'Test'.` and nothing
  changes. Result: pass (owner-marked 2026-10-10)
- **PROFILE-5. Unknown name refused.** `/pfe profile Typo` → `No profile named 'Typo'.`, then the list.
  `/pfe profile test` → the same refusal, `Did you mean 'Test'?`, and the list. `/pfe profile use Typo`
  → the same refusal. `/pfe profile list` then shows no `Typo` and no `test`. Result: pass (owner-marked 2026-10-10)
- **PROFILE-6. Quotes and spaces.** `/pfe profile new Tank Two`, then `/pfe profile Default`.
  `/pfe profile "Tank Two"` → `Switched to profile 'Tank Two'.` `/pfe profile Default`, then
  `/pfe profile 'Tank Two'` → the same. `/pfe profile Default`, then `/pfe profile delete Tank Two` →
  `Deleted profile 'Tank Two'`. Result: pass (owner-marked 2026-10-10)
- **PROFILE-7. While disabled.** On Default, `/pfe disable`. `/pfe profile` → the list and the
  sub-verb help, with no refusal line. `/pfe profile Test` → `Switched to profile 'Test'.`, and
  because Test has the addon on, the addon stands back up and its elements return. `/pfe profile
  Default` → down again. `/pfe enable` afterwards. Result: pass (owner-marked 2026-10-10)
- **PROFILE-8. In combat.** On Default, on a target dummy, in combat: `/pfe profile Test` → `Can't
  switch profiles in combat.`, and `/pfe profile current` still reads `Default`. `/pfe profile use
  Test` → the same refusal. Leave combat, `/pfe profile Test` → it switches. Result: pass (owner-marked 2026-10-10)
- **PROFILE-9. Sub-verbs refuse bad names.** `/pfe profile new Healer`; `/pfe set castbar.width 222`;
  `/pfe profile Default`; `/pfe profile new Healer` → one *already exists* line, and Healer still has
  width 222 (`/pfe profile Healer`, then `/pfe get castbar.width`). `/pfe profile copy Nope` and
  `/pfe profile copy <current>` → one refusal line each, with no Lua error frame.
  `/pfe profile delete Nope` → refused, with no *Deleted* line. Result: pass (owner-marked 2026-10-10)
- **PROFILE-10. Reset all settings.** With a second profile on the list, change some settings and
  press General's *Reset all settings* → a popup reading, verbatim, *"Reset this profile to the addon's
  defaults? Everything you have configured or added in it is discarded — your other profiles are not
  affected."* → **Yes** → the settings are back at their defaults, you are still on the same profile,
  and the profile list is unchanged. The button's tooltip names *"the same thing Profiles -> Reset
  Profile does"*, with a plain `->` for the arrow. `/pfe resetall` does the same act. Result: pass (owner-marked 2026-10-10)

## Enable, disable and stand-down

- **STATE-1. Disable and enable.** `/pfe disable` → `enabled = false` in the same gold/white shape
  `/pfe set` prints, everything the addon draws goes, and the General page's *Enable Party Frame
  Enhanced* unticks if open. While disabled: `/pfe` still opens the panel, `/pfe help` still lists
  `enable`, `/pfe version` still answers, and `/pfe list`, `/pfe get` and `/pfe set` still read and
  repair settings. `/pfe enable` → `enabled = true` and it all comes back. *Failure:* any of those going
  quiet; the switch would only go one way (slash-commands-§2). Result: pass (owner-marked 2026-10-10)
- **STATE-2. Feature verbs refuse while disabled.** While disabled, `/pfe unlock`, `/pfe lock` and
  `/pfe resetposition` each answer on one tagged line naming `/pfe enable`, and nothing moves: no
  stand-in appears, no stack jumps back to its default position. *Failure:* a second line, a lecture
  about the state, or a verb that prints the refusal and then acts anyway. Result: pass (owner-marked 2026-10-10)
- **STATE-3. The stand-down is total.** While disabled, `/pfe debug on`, then enter and leave combat,
  join and leave a party, and switch target → no `[Cast]`, `[Target]`, `[Pet]`, `[Party]` or `[Secure]`
  line, because nothing is registered to produce one. *Failure:* any line at all: the addon stopped
  reacting rather than stopping watching, and it still pays the dispatch on every event. Result: pass (owner-marked 2026-10-10)
- **STATE-4. The launcher and Lock frame while disabled.** While disabled, left-click the minimap
  button → the settings panel opens, as it does while running, and nothing unlocks. Right-click it →
  the options menu with *Enabled* unticked and live, and *Locked (enable the addon first)* grayed;
  clicking the grayed entry does nothing. On the General page, untick *Lock frame* → one tagged line
  (*Ka0s Party Frame Enhanced is disabled — enable it with /pfe enable*), and the box snaps back to
  ticked. *Failure:* a menu entry that unlocks (it would write the stored tree of an addon the player
  switched off), a left click that refuses, or a gray *cannot unlock* line from the checkbox, which is
  a second wording of the one refusal (slash-commands-§7). Result: pass (owner-marked 2026-10-10)
- **STATE-5. Enable comes back from current settings.** While disabled, `/pfe set castbar.enabled
  false`, then `/pfe enable` → everything else comes back and the cast bars stay off. `/reload` → the
  same. `/pfe set castbar.enabled true` afterwards. *Failure:* the addon standing up into the state it
  had when it went down. Result: pass (owner-marked 2026-10-10)
- **STATE-6. Target and pet frames through a stand-down.** In a party with a pet out and a member
  targeting something, `/pfe disable` out of combat, then `/pfe enable` → the target and pet frames
  return. Then enter combat, `/pfe disable` (the panel refuses every write in combat, so the command is
  the route), and leave combat → no `ADDON_ACTION_BLOCKED` on the debug console, and the frames are
  gone. `/pfe enable` out of combat → they return. *Failure:* a blocked-action line (the state driver
  was touched under lockdown), or frames that stay gone after the re-enable. Result: pass (owner-marked 2026-10-10)
- **STATE-7. Edit Mode through a stand-down.** In a party, `/pfe disable` and `/pfe debug on`, then
  open and close Edit Mode, switching the party frames between raid-style and classic so a resolve has
  something to report → no `[Provider]` line. `/pfe enable` and do the same again → the resolve burst
  runs and a `[Provider]` line names the frames. *Failure:* a resolve line while disabled (the
  `EditMode.Exit` callback survived the stand-down), or none after the re-enable. Result: pass (owner-marked 2026-10-10)
- **STATE-8. Fade frames and holders through a stand-down in combat.** In a party, enter combat, then
  `/pfe disable`. Still in combat,
  `/run print(PartyFrameEnhanced_Fade_party1:IsShown(), PartyFrameEnhanced_castbar_Holder:IsShown())`
  → `true true` (the hide waits for the lockdown to lift). Leave combat and run it again →
  `false false`. `/pfe enable` → `true true`, and the elements come back where they were. *Failure:*
  `ADDON_ACTION_BLOCKED` on the debug console, frames still shown after combat, or frames still hidden
  after the re-enable. Result: pass (owner-marked 2026-10-10)
- **STATE-9. Disable while unlocked.** `/pfe unlock`, then `/pfe disable` → *Locked — the addon was
  disabled*, and no placeholder or stand-in is left on screen. `/pfe enable` afterwards. Result: pass (owner-marked 2026-10-10)

## Preview, placement and status

- **PREV-1. Unlock and lock.** `/pfe unlock` → `Elements unlocked — drag them into place`, the General
  page's *Lock frame* unticks if open, and every enabled element shows placeholder content: a cast bar
  drawn full (its whole size shows), a target frame at 65% with a skull, and a pet frame at 80%.
  `/pfe lock` → `Elements locked`, all of it goes, and live data returns. Unticking *Lock frame* on General
  starts the same preview. *Failure:* a placeholder left behind after locking (preview-mode MUST).
  Result: pass (owner-marked 2026-10-10)
- **PREV-2. Preview in a party.** In a party, `/pfe unlock` → placeholders on every element at the real
  party frames, with no stand-in and no plate; `/pfe lock` → gone. Result: pass (owner-marked 2026-10-10)
- **PREV-3. Free placement drags.** Set Cast Bars → Size & Position → *Anchor mode* to *Free
  placement* and unlock → a translucent plate labeled *Cast bars* appears over the stack. Drag it,
  lock, `/reload` → the stack is where you left it. General → *Reset position* (or
  `/pfe resetposition`) → back to its default. Result: pass (owner-marked 2026-10-10)
- **PREV-4. Status.** `/pfe status` → the frame system in use, each unit with *frame* or a dash, each
  feature's state, and a *Note:* line when something is switched off (set *General visibility* to
  *Never* and run it again). Result: pass (owner-marked 2026-10-10)
- **PREV-5. Party-only.** Solo: nothing shows, attached or free placement, and `/pfe status` ends with
  *not in a party — nothing shows until you join one (try /pfe unlock)*. Join a party → everything
  shows. Convert to a raid → it all goes again. Result: pass (owner-marked 2026-10-10)
- **PREV-6. Stand-in, EllesmereUI.** Solo, EllesmereUI loaded, *Frame system* Automatic, `/pfe debug
  on`: `/pfe unlock` → one stand-in party frame where EllesmereUI's first party frame sits, at its
  size, with a flat class-colored bar and a gray *(test)* after your name. It draws beneath what
  attaches to it, so the cast bar's spell icon shows whole. Party1's cast bar, target frame (skull) and
  pet frame attach to it, and the Size & Position offsets move them. Drag it → they follow. The console
  logs a `[Preview]` line naming where the size came from: `settings` (your EllesmereUI party frame
  width and height). *Failure:* a stand-in of a different size from your EllesmereUI party frames, or
  `frame` or `fallback` in the `[Preview]` line (EllesmereUI's settings could not be read). Result: pass (owner-marked 2026-10-10)
- **PREV-7. Stand-in, Blizzard raid-style.** Blizzard frames with Edit Mode raid-style party frames
  on → the same as PREV-6 in the raid-bar look. If the stand-in came up at screen center, note whether
  the 72 × 36 fallback matched. Result: pass (owner-marked 2026-10-10)
- **PREV-8. Stand-in, Blizzard classic.** Raid-style off → the same as PREV-6 with a portrait, a green
  health bar and a mana bar. If the stand-in came up at screen center, note whether the 120 × 53
  fallback matched. Result: pass (owner-marked 2026-10-10)
- **PREV-9. Live switch.** With the stand-in up, `/pfe status` reads *unlocked (stand-in)*. Join a
  party → the stand-in goes, the placeholders move to the real frames, and `/pfe status` reads
  *unlocked (your party frames)*. Leave → the stand-in comes back. Result: pass (owner-marked 2026-10-10)

## Cast bars

- **CAST-1. Attached over each frame.** On a fresh profile, in a party, watch a healer cast → a bar
  appears across the top of that member's own party frame, as wide as the frame, with the spell's icon
  at the left, its name, and seconds counting down at the right. It fills left to right and hides when
  the cast lands. *Failure:* a bar on the wrong member (the unit → frame map is wrong), or a bar that
  never hides. Result: pass (owner-marked 2026-10-10)
- **CAST-2. Your own row.** Raid-style or EllesmereUI (self shown): cast something → your bar appears
  over your own frame. Classic layout: no player bar (the layout never shows you); switch Cast Bars →
  Size & Position → *Anchor mode* to *Free placement* and cast again → your bar appears in the stack.
  Result: pass (owner-marked 2026-10-10)
- **CAST-3. Channels drain.** Watch a channel (Penance, Mind Flay on a dummy) → the bar starts full and
  drains. Result: pass (owner-marked 2026-10-10)
- **CAST-4. Interrupt.** Interrupt a party member's cast, or have a mob interrupt one → the bar turns
  the interrupted color, shows the client's own word for *Interrupted*, holds about half a second, then
  fades. Result: pass (owner-marked 2026-10-10)
- **CAST-5. Can't be interrupted.** A cast flagged uninterruptible shows the gray fill and the shield
  icon. In a dungeon, in combat, zero Lua errors throughout (the flag is secret there). *Failure:* an
  error mentioning `secret` or `compare` from `CastBars.lua`. Result: pass (owner-marked 2026-10-10)
- **CAST-6. Frame-system switch.** With EllesmereUI loaded, set General → *Frame system* to *Blizzard*
  while EllesmereUI hides Blizzard's frames → the bars disappear (no Blizzard frames on screen). Back
  to *Automatic* → they return under EllesmereUI's frames. Result: pass (owner-marked 2026-10-10)
- **CAST-7. Settings.** Cast Bars page → six tabs (General, Size & Position, Bar, Border, Text, Icon).
  Change *Cast color*, *Height* and *Font size* → live bars restyle at once. Turn *Enable cast bars*
  off → no bar appears on the next cast. Result: pass (owner-marked 2026-10-10)

## Target and pet frames

- **UNIT-1. Target frame beside each member.** A party member targets a mob → a small frame appears to
  the right of their party frame with the mob's name, a red health bar (hostile) and its health
  percent. They clear target → it disappears. *Failure:* the frame beside the wrong member, or one
  that stays after they clear target. Result: pass (owner-marked 2026-10-10)
- **UNIT-2. Health moves.** The member's target takes damage → the bar and percent drop within a
  fraction of a second (the 0.2 s refresh), in combat, with zero Lua errors in a dungeon. *Failure:* an
  error naming `secret`, `compare` or `index` from `TargetFrames.lua` or `UnitButtons.lua`. Result: pass (owner-marked 2026-10-10)
- **UNIT-3. A new member's target.** Invite someone who is already targeting a friendly NPC → their
  target frame shows the NPC's name in green within a fraction of a second, with no need for them to
  retarget. *Failure:* a red frame with no name that stays until they change target. Result: pass (owner-marked 2026-10-10)
- **UNIT-4. A pet appears.** A hunter or warlock in the party → a small frame to the right of their
  party frame, under their target frame, with the pet's name and health. They dismiss it → the frame
  disappears. Summon another → it shows the new pet. Result: pass (owner-marked 2026-10-10)
- **UNIT-5. Your own pet.** On a pet class with your own row included, raid-style or EllesmereUI →
  your pet's frame sits to the right of your party frame, under your target frame. Result: pass (owner-marked 2026-10-10)
- **UNIT-6. Colors.** A friendly NPC target → green; a neutral one → yellow. Tick *Use class color* on
  Target Frames → Bar and have a member target a player → the player's class color. Tick *Use class
  color* on Pet Frames → Bar → a hunter's pet takes hunter green, a warlock's warlock purple. Result: pass (owner-marked 2026-10-10)
- **UNIT-7. Raid markers.** Mark a member's target with a skull → the skull appears on that target
  frame. Mark a member's pet → the skull appears on that pet frame; clear it → it goes. Result: pass (owner-marked 2026-10-10)
- **UNIT-8. Marker placement.** `/pfe unlock` (the preview shows a skull on every target frame).
  Target Frames → Marker: set *Anchor point* to *Right* → the skull's center moves to the bar's right
  end; drag *X offset* and *Y offset* → it follows, live. Untick *Show raid marker* → the skull goes
  and the three placement controls gray out. Repeat on Pet Frames → Marker. *Failure:* the skull stays
  put until `/reload`. Result: pass (owner-marked 2026-10-10)
- **UNIT-9. Marker over the border.** Target Frames → Border: tick *Show border*, and mark a member's
  target → the skull draws on top of the border's edge. Repeat on Pet Frames. *Failure:* the border's
  line cuts across the skull. Result: pass (owner-marked 2026-10-10)
- **UNIT-10. Health updates off.** General → Health updates: untick *Update health* → *Health
  refresh* grays out, and so does Text → *Show health percent* on both Target Frames and Pet Frames.
  With a member targeting a mob, its bar sits full with no percent while the mob takes damage, and a
  pet's bar does the same while the pet takes damage. `/pfe debug on` shows no `[Target] health ticker
  started` line (one followed at once by `health ticker stopped` is the unresolved-target repaint, and
  is expected). Tick it back → the real health and percent return at once on both. With a target up,
  drag *Health refresh* to 1 → the bar updates about once a second straight away, with no need to
  retarget. Result: pass (owner-marked 2026-10-10)
- **UNIT-11. Click to target.** Click a target frame → you target that unit, in combat too. Click a pet
  frame → you target the pet. Out of combat, untick *Click to target* on Target Frames → clicks pass
  through; tick it back → clicks target again (toggling it in combat, through `/pfe set`, is
  COMBAT-7). Result: pass (owner-marked 2026-10-10)

## Out-of-range fade

- **FADE-1. EllesmereUI.** In a party with EllesmereUI's party frames, walk away from a member until
  EllesmereUI dims their frame → that member's cast bar, target frame and pet frame dim to the same
  opacity at the same moment; walk back → all return together. Change EllesmereUI's own out-of-range
  alpha → ours follows it. `/pfe status` → *Range fade: copied from EllesmereUI*. *Failure:* our
  elements stay bright, or dim to a different opacity from the frame. Result: pass (owner-marked 2026-10-10)
- **FADE-2. Blizzard raid-style, in an instance.** Raid-style party frames with Blizzard's *fade out of
  range* on → the same as FADE-1, at 0.5. Repeat inside a dungeon, in combat, where range can be
  secret → still no Lua error, and the elements still dim. *Failure:* an error naming `secret` from
  `RangeFade.lua`, or elements that stop dimming in the instance only (the secret fallback did not
  take). Result: pass (owner-marked 2026-10-10)
- **FADE-3. Blizzard classic.** Raid-style off: the classic frames themselves never dim, but a member
  past about 40 yards has their elements at half opacity. `/pfe status` → *Range fade: own range check
  (classic frames)*. Result: pass (owner-marked 2026-10-10)
- **FADE-4. The switch, and preview.** General → Party frames: untick *Fade with party frames* → every
  element at full opacity at once, out of range or not. Tick it back → the far member dims again.
  `/pfe unlock` in a party with someone out of range → every placeholder at full opacity; lock → the
  fade returns. Result: pass (owner-marked 2026-10-10)

## Minimap button and broker

- **LAUNCH-1. The button and its logo.** Log in → a round button on the minimap ring showing the Party
  Frame Enhanced logo, not a blank circle and not a Blizzard icon. Drag it around the ring, `/reload` →
  it stays where you left it. *Failure:* a blank button is the 128 `.tga` not loading; a button that
  jumps back to its old angle on reload is `minimapPos` not being written to the table LibDBIcon was
  handed. Result: pass (owner-marked 2026-10-10)
- **LAUNCH-2. The status tooltip.** Hover → `Ka0s Party Frame Enhanced  v<the TOC version>`,
  `Enabled: Yes` (green), `Locked: Yes` (green), `Left-click: Open settings`, `Right-click: Options
  menu`, and no `Test mode` line (launcher-§1). `/pfe unlock` and hover → `Locked: No` (red), the same
  hints. `/pfe disable` and hover → still shown, `Enabled: No` (red), the same hints; `/pfe enable`
  and `/pfe lock` after. *Failure:* no tooltip while disabled, a title or hint drawn twice, or a
  `Test mode` line (anti-pattern #89). Result: pass (owner-marked 2026-10-10)
- **LAUNCH-3. Left-click opens the settings.** Left-click, locked and then unlocked → the settings
  panel opens on the landing page each time, and the lock does not move. *Failure:* a left click that
  unlocks, the retired rung (b) (launcher-§2, standard v2.67.0). Result: pass (owner-marked 2026-10-10)
- **LAUNCH-4. Right-click opens the options menu.** Right-click → the client's context menu titled
  *Ka0s Party Frame Enhanced*, with exactly two checkboxes, *Enabled* (ticked) and *Locked* (ticked),
  and no *Test mode* or *Show window* entry. Click *Locked* → the elements unlock exactly as
  `/pfe unlock` unlocks them (stand-in out of a party, placeholders in one), the General page's *Lock
  frame* unticks if open, and the menu closes; right-click again → *Locked* unticked; click it →
  locked. Click *Enabled* → the same `enabled = false` echo `/pfe disable` prints and the addon goes
  down; right-click and click *Enabled* → back up with `/pfe enable`'s echo. *Failure:* an entry whose
  effect or message differs from its slash verb's (a second copy of the handler, anti-pattern #81).
  Result: pass (owner-marked 2026-10-10)
- **LAUNCH-5. The broker plugin is the same object.** With Titan Panel, ElvUI data texts or Bazooka,
  add **PartyFrameEnhanced** to the bar → the same logo and label; left-click opens the settings, and
  right-click opens the same options menu. *Failure:* an empty value cell beside the icon means the
  object was registered as a `data source` rather than a `launcher`. Result: pass (owner-marked 2026-10-10)
- **LAUNCH-6. The Minimap button row, both ways.** General → Master controls → untick **Minimap
  button** → the button disappears at once, not at the next reload. `/reload` → still gone. Tick it →
  back. (Right-click is the options menu, which carries no hide entry.) From the CLI, with the button
  visible: `/pfe get global.minimap.shown` → `global.minimap.shown = true`; `/pfe set
  global.minimap.shown false` → `global.minimap.shown = false`, and the button hides; `/reload` →
  still hidden, and the Master controls checkbox agrees. `/pfe get global.minimap.hide` → `Setting not
  found: global.minimap.hide`. After a logout the SavedVariables file's `minimap` table holds
  `["hide"] = true` and no `shown` key. *Failure:* the checkbox and the button disagreeing (a second
  copy of one state, launcher-§3, anti-pattern #81), a `shown` key in the file, or a button hidden
  before the upgrade coming back. Result: pass (owner-marked 2026-10-10)
- **LAUNCH-7. The button is account-wide.** Hide the button, then switch to another profile with
  `/pfe profile Test` (or `/pfe profile Default` if you are on Test) → `Switched to profile '<name>'.`,
  and the button is still hidden. Log in on a different character → still hidden. *Failure:* the
  button coming back on either means the table is profile-scoped, which launcher-§3 forbids. Result: pass (owner-marked 2026-10-10)
- **LAUNCH-8. It survives both resets.** With the button hidden, press *Reset all settings* → still
  hidden. Press General's **Defaults** → still hidden, while the other General rows go back to their
  defaults in the same press. Show it and repeat both → it stays shown. `/pfe reset
  global.minimap.shown` is the deliberate exception and does reset it. *Failure:* either reset moving
  the row in either direction; whether the button is on the minimap is a per-installation display
  preference, like its position, and no reset may touch it (launcher-§3). Result: pass (owner-marked 2026-10-10)

## Combat

- **COMBAT-1. The panel refuses in combat.** On a target dummy, in combat: `/pfe config` → the panel
  does not open, and chat shows the gray `cannot open settings during combat — Blizzard's
  category-switch is protected`. `/pfe` alone and a left-click on the minimap button → the same gray
  refusal. Repeat → the same refusal each time, with no queue. Leave combat → nothing opens by itself.
  Result: pass (owner-marked 2026-10-10)
- **COMBAT-2. The combat lock.** Open **General** and pull a dummy → the whole page, tab strip
  included, goes under a gray *Settings are locked during combat.* cover; a click on a checkbox, a
  slider drag, a tab and Defaults change nothing, and one gray `settings are locked during combat —
  changes are refused until it ends` line prints for the whole combat. In combat, switch to **Cast
  Bars** and **Profiles** in the AddOns sidebar → each shows covered, the window stays open, with no
  Lua error and no `ADDON_ACTION_BLOCKED`. `/pfe set alpha 0.8` in combat, then leave combat → the
  cover lifts and the page shows the new value. *Failure:* a window that closes itself, a value that
  changes under the cover, or a page that stays covered after combat. Result: pass (owner-marked 2026-10-10)
- **COMBAT-3. Combat locks an unlocked preview.** Solo, with the General page open, `/pfe unlock` so
  the stand-in is up, then pull a dummy → *Locked — combat started*, the *Lock frame* box ticks
  itself, nothing is stuck on screen, and no `ADDON_ACTION_BLOCKED` on the debug console. Result: pass (owner-marked 2026-10-10)
- **COMBAT-4. Unlock refused in combat.** In combat: `/pfe unlock` → a gray *cannot unlock during
  combat* line, nothing previews or moves, and *Lock frame* stays ticked on an open General page.
  Right-click the minimap button and click *Locked* → the same line, and nothing moves. `/pfe lock`
  still works. Result: pass (owner-marked 2026-10-10)
- **COMBAT-5. General visibility in combat.** The panel is locked in combat (COMBAT-2), so this check
  uses the command. In a party with a member targeting something, `/pfe debug on`, and out of combat
  `/pfe set visibility outOfCombat` → nothing changes yet. Pull a dummy → the target and pet frames
  hide at once (the state driver's `[combat]` clause), and no cast bar shows while members cast. Still
  in combat, `/pfe set visibility always` → cast bars show again on the next cast, the target and pet
  frames stay hidden, and the console shows `[Secure] queued driver:Target:…`. Leave combat → `[Secure]
  flushed …` and the target and pet frames come back. *Failure:* a Lua error, an
  `ADDON_ACTION_BLOCKED` line, or a target frame shown in combat while the setting is *Only out of
  combat*. Result: pass (owner-marked 2026-10-10)
- **COMBAT-6. Someone joins in combat (Blizzard raid-style).** Blizzard raid-style party frames sorted
  by role, `/pfe debug on`, out of combat first so `[Follow] wrapped N blizzard-raid frame(s)` shows
  (#3). Mid-pull, have someone join → their target and pet frames appear beside the right member **in
  combat**, and every other member's target and pet frames jump to their member's new frame at once,
  with no fade; the console's `[Anchor] … followed N` line counts them. The cast bars follow as
  before. With a member out of range, the clickable frames still fade with their party frame. Blizzard's
  own frames still sort and click normally. *Failure:* a target or pet frame beside the wrong member
  during combat, a fade where a jump was expected, an `ADDON_ACTION_BLOCKED` line, or a taint error on
  the debug console or in BugSack. If the frames fade and come back at regen instead, the client did
  not change the member frames' `unit` attribute in combat or refused the wrap: note which, with
  `/pfe diagnostics`. Result: pass (owner, 2026-10-02)
- **COMBAT-7. Click to target toggled in combat.** The panel is locked in combat (COMBAT-2), so this
  check uses the command. Out of combat, `/pfe set target.clickToTarget false` → a click on a target
  frame passes through. Pull a dummy, and in combat `/pfe set target.clickToTarget true` → clicks
  still pass through until combat ends, then target again. In the next combat, `/pfe set
  target.clickToTarget false` and then `/pfe set target.clickToTarget true` before combat ends; after
  combat, left-click a target frame → you target that unit. *Failure:* the frame ignores the click
  (the untick landed at regen and the re-tick was lost), which needs a third toggle to recover.
  Result: pass (owner-marked 2026-10-10)
- **COMBAT-8. Nothing moves in combat.** In a party, `/pfe set target.anchorMode free` and `/pfe
  unlock`, then pull a dummy → combat locks the preview (COMBAT-3). In combat, with a member
  targeting the dummy, left-drag their target frame → nothing moves, with no Lua error and no
  `ADDON_ACTION_BLOCKED`. Leave combat, `/pfe unlock`, and drag the *Target frames* plate → it moves
  (PREV-3). Then `/pfe lock`, `/pfe resetposition` and `/pfe set target.anchorMode attached`.
  *Failure:* the stack moving in combat. Result: pass (owner-marked 2026-10-10)
- **COMBAT-9. Someone leaves in combat (Blizzard raid-style re-sort).** As COMBAT-6, but have someone
  leave mid-pull → the remaining members' target and pet frames follow their members to their new
  frames in combat, with no fade and no `ADDON_ACTION_BLOCKED`. Leave combat → nothing jumps a second
  time (the regen pass re-pins to where they already are). Result: pass (owner, 2026-10-02)
- **COMBAT-10. EllesmereUI in combat, and taint.** EllesmereUI party frames, `/console taintLog 1`,
  `/reload`, then `/pfe debug on` → `[Follow] wrapped N ellesmere frame(s)`. Mid-pull, have someone
  join, then someone leave → the target and pet frames follow as in COMBAT-6 and COMBAT-9. EllesmereUI's
  own frames still sort, show and click normally. After the session, `Logs/taint.log` names no
  PartyFrameEnhanced taint on EllesmereUI's `SecureGroupHeader_Update` or Blizzard's sort, and there is
  no `ADDON_ACTION_BLOCKED`. Result: pass (owner, 2026-10-02)
- **COMBAT-11. Disabled, then a re-sort in combat.** EllesmereUI or Blizzard raid-style party frames.
  Out of combat, `/pfe disable` → no error. Mid-pull, have someone join or leave → our frames stay
  hidden, nothing of ours moves, and the party frames behave normally. Leave combat, `/pfe enable` → no
  error, the frames come back beside the right members, and `[Follow] wrapped …` shows again for any
  frame the disable unwrapped. Switch to Blizzard classic in Edit Mode and repeat a reshuffle in combat
  → the fade fallback still works there. Result: pass (owner, 2026-10-02)
- **COMBAT-12. A placement changed in combat, then a re-sort.** Blizzard raid-style or EllesmereUI
  party frames. Mid-pull, `/pfe set target.offsetX 10`, then have someone join or leave → the target
  frames follow their members at the OLD offset; leave combat → they correct to the new offset. Put it
  back with `/pfe reset target.offsetX`. Result: pass (owner, 2026-10-02)

## Debug console, diagnostics and perf

- **DIAG-1. The console.** `/pfe debug` → the console window opens (monospace font, the collection's
  close, copy and clear marks, not a `×` glyph); `/pfe debug` again → it closes. The logging flag is
  untouched by both. Result: pass (owner-marked 2026-10-10)
- **DIAG-2. The `[Init]` line.** `/pfe debug on` → an `[Init]` line naming `PartyFrameEnhanced
  v<the TOC version>`, the schema version, the profile, the detected frame system and whether
  EllesmereUI's raid frames are loaded. `/reload` → logging is off again (session-only). Result: pass (owner-marked 2026-10-10)
- **DIAG-3. The perf walk.** `/pfe perf` → a status line and the step panel, whose close mark matches
  the console's. Walk `start` → `measure a` (a pull) → `measure b` → `finish` → `report` → `dump`
  without a Lua error. During arm B the addon is inert; after `finish` it is active again without a
  `/reload`. Result: pass (owner-marked 2026-10-10)
- **DIAG-4. The capture worth recording.** In a party with at least one pet class, somewhere quiet (an
  instance, not a city), start with the setup in the label (`/pfe perf start party <frame system>
  <anchor mode>`) and pull the same pack for both arms. In the report, `petEvent` has calls and
  `targetRender` per `targetTick` pass is at most the number of members with a target. Paste the buffer
  into `/dev-copilot:wow-perf-analysis`. *Failure:* `targetRender` near 5 per pass while fewer members have
  targets (hidden buttons being repainted), or no `petEvent` row with a pet out. Result: pass (owner-marked 2026-10-10)
- **DIAG-5. The diagnostics report appends, ungated.** `/pfe debug on`, join or leave a party (or
  `/pfe unlock` and `/pfe lock`) so a few trace lines land, then `/pfe diagnostics`. The trace is still
  there, above `==== Ka0s Party Frame Enhanced diagnostics begin ====`; the report ends with
  `==== Ka0s Party Frame Enhanced diagnostics end: N line(s) ====`; one chat line reads `Diagnostic
  report written to the debug console: N lines. Use Copy to share it.` The sections run in the order
  [debug.md](debug.md) lists (`[State]`, `[Set]`, `[Party]`, `[Frames]`, `[Place]`, `[Elem]`, `[Fade]`,
  `[Secure]`, `[Events]`). Then `/pfe debug off`, close the console and run `/pfe debug diagnostics`:
  the console opens and the whole report lands again below the first, after the enable lines the run
  writes (DIAG-14). *Failure:* the console cleared, or a report cut short. Result: pass (owner-marked 2026-10-10)
- **DIAG-6. Copy, and the long alias.** Press **Copy** and paste into a text editor → the trace, both
  markers and the brand are there, with no `|c` color codes or `|T` textures in the text.
  `/partyframeenhanced diagnostics` and `/partyframeenhanced debug diagnostics` → the same report as the
  short slash. Result: pass (owner-marked 2026-10-10)
- **DIAG-7. In combat, and while disabled.** In a party, run `/pfe diagnostics` in combat, and once
  more inside a dungeon while a party member casts → no Lua error; a value the client keeps secret
  prints as `<secret>`, never as an error line. Then `/pfe disable` and run `/pfe diagnostics` and
  `/pfe debug diagnostics` → both write a full report whose state lines read `enabled=false
  stoodDown=true`, and `[Frames]` and `[Fade]` say stood down. `/pfe enable` afterwards. Result: pass (owner-marked 2026-10-10)
- **DIAG-8. No short name.** `/pfe diag` → `unknown command 'diag'` and the help; `/pfe debug diag` →
  shows or hides the console like any other word after `debug`. Neither writes a report. Result: pass (owner-marked 2026-10-10)
- **DIAG-9. The buffer cap.** With logging on, drive enough traced activity (party changes, unlock and
  lock, repeated `/pfe diagnostics`) to pass 3000 lines → the footer counter reads `N / 3000 lines` and
  pins at 3000, and **Copy** opens without a noticeable hitch. Result: pass (owner-marked 2026-10-10)
- **DIAG-10. The console resizes.** `/pfe debug on`, drive a few trace lines, then `/pfe debug` → the
  console opens at its default 700 × 344 with a size grip in its bottom-right corner. Drag the grip out
  and back → the window follows on both axes, the text reflows, the scrollbar and the `N / 3000 lines`
  counter stay in step, the buffer and scroll position are kept, and no digit of the counter sits under
  the grip. Drag it as small as it goes → it stops while the title and every title-bar control still fit
  and a few lines still show. Close the console and reopen it → the new size is kept. `/reload` and
  reopen → the default size is back. With another Ka0s addon loaded, open its console too → it keeps its
  own size, whatever this one was sized to. *Failure:* a control clipped or overlapping at the minimum,
  a counter that lags the resize, or a size that survives the `/reload`. Result: pass (owner-marked 2026-10-10)
- **DIAG-11. The copy window resizes.** Press the console's **Copy** → the copy window opens at its
  default size with a grip in its bottom-right corner. Drag it larger and smaller → both axes follow, the
  text box widens and narrows with the window, and the scroll bar's down button stays clickable above
  the grip. It stops at its minimum. Close it and press **Copy** again → the size is kept; `/reload` →
  the default is back. *Failure:* text that stays at the old width after a resize, or a size kept past
  the `/reload`. Result: pass (owner-marked 2026-10-10)
- **DIAG-12. The perf panel resizes in width only.** `/pfe perf` → the step panel opens at its default
  size with a grip in its bottom-right corner. Drag the grip → the width follows and every step row
  stretches to it, the height stays put, and it will not go narrower than its default. Close and reopen
  it (`/pfe perf`) → the width is kept; `/reload` → the default is back. *Failure:* rows that do not
  stretch, a panel that grows taller, or a width kept past the `/reload`. Result: pass (owner-marked 2026-10-10)
- **DIAG-13. The Diagnostics link.** `/pfe debug` → in the console's title bar, beside the Debug
  On/Off label and a small gap after it, an orange **Diagnostics** that reads as plain text, not a
  button, and brightens under the pointer. Toggle the label between On and Off → the gap holds for
  both words. Click **Diagnostics** → the report lands below what the console holds, with the same
  markers and one chat line as `/pfe diagnostics`. *Failure:* a framed button, a link that overlaps
  or drifts from the label, or a click that writes nothing. Result: pass (owner-marked 2026-10-10)
- **DIAG-14. Diagnostics turns logging on for the session.** `/reload`, then `/pfe debug` → the
  header reads Off. Click **Diagnostics** → a chat line says logging is on, the header reads On, and
  `[Debug] logging enabled` and the `[Init]` line land just above the report's begin marker. Join or
  leave a party → a trace line lands. Run `/pfe diagnostics` again → no second `logging enabled`
  line. `/reload`, then `/pfe diagnostics` → logging turns on again the same way; `/reload` once more
  → the header reads Off. *Failure:* the flag left off after a run, a second enable line with logging
  already on, or logging still on after the `/reload`. Result: pass (owner-marked 2026-10-10)
- **DIAG-15. A slash refusal shows in the console.** `/pfe debug on`, then `/pfe notaverb` → chat
  prints `unknown command 'notaverb'` and the help, and the console gains one `[Cmd] refused
  notaverb: unknown verb` line. `/pfe disable`, then `/pfe resetposition` → chat prints the one
  disabled line, and the console gains one `[Cmd] refused resetposition: disabled` line. `/pfe
  enable` afterwards. *Failure:* no `[Cmd]` line, the same refusal logged twice, or a chat line that
  changed. Result: pass (owner-marked 2026-10-10)
- **DIAG-16. A stand-down edge shows in the console.** `/pfe debug on`, then `/pfe disable` → the
  console gains one `[Lifecycle] stood down: added disabled (holds: disabled)` line and no `[State]
  stood down` line. `/pfe enable` → one `[Lifecycle] stood up: released disabled (holds: none)`
  line. `/pfe disable` a second time while already disabled (the checkbox or the verb) → no new
  `[Lifecycle]` line. `/pfe enable` afterwards. *Failure:* no `[Lifecycle]` line, two lines for one
  edge, or a line for a disable that changed nothing. Result: pass (owner-marked 2026-10-10)
- **DIAG-17. The launcher's login line lands.** `/reload`, then `/pfe debug on` → after `[Debug]
  logging enabled` and the `[Init]` line, one `[Launcher] registered` line (or, with no broker
  library installed, the `absent` line naming it). `/pfe debug off` and `/pfe debug on` again → no
  second `[Launcher]` line. *Failure:* no `[Launcher]` line at all, or one per enable. Result: pass (owner-marked 2026-10-10)

## Non-English client

What this addon touches that a client translates, enumerated from the code rather than assumed:

- **Localized `_G` reads:** two, both display-only: the client's `INTERRUPTED` and `FAILED` words on
  a stopped cast bar (`modules/CastBars.lua`), with `NS.L` English fallbacks. Nothing parses them. The
  only other `_G[...]` reads are frame names (`ERFPartyHeaderUnitButtonN`, `CompactPartyFrameMemberN`),
  which the client does not translate.
- **Tooltip lines:** none parsed.
- **Display strings where an id exists:** class colors are keyed on `UnitClass`'s second return (the
  class token, `MAGE`), never on the localized name; reaction is `UnitReaction`'s number; the frame
  systems are found by global frame names and the Edit Mode API, never by a label.
- **Strings this addon renders:** spell names and unit names come from the client and are only ever
  displayed; the addon's own words (*Interrupted*, *Failed*, labels) are `NS.L` keys with English
  values until a translation exists.
- **Headers or tokens another tool parses:** the `/pfe perf dump` record, whose keys are fixed English
  identifiers written by LibKa0s-Perf.

Checks:

- **LOC-1. Load on a German client.** Log in on deDE → zero Lua errors, `[PFE]` lines in chat, and the
  settings panel in English (untranslated, as expected). *Failure:* an error frame, or a label that
  reads as a raw key like `L["Frame system"]` (the fallback metatable missing). May be signed off on
  English: every headless case that renders a label exercises the fallback. Result: pass (owner-marked 2026-10-10)
- **LOC-2. Class colors from the token.** With *Use class color* on, have a party member target a
  player whose class has a German name (a *Magier*) → the target frame takes mage blue. *Failure:* the
  stored swatch color instead of the class color, on deDE only (the class was keyed on the localized
  name). Headless stand-in: `Compat.ClassToken` reads `UnitClass`'s second return only, and
  `tests/test_targetframes.lua` colors a `MAGE` target from the token; its mock returns the token for
  both values, so the client is the witness for a translated name. Result: pass (owner-marked 2026-10-10)
- **LOC-3. Spell names and the stop word render whole.** Watch a party member cast a spell whose German
  name has an umlaut or ß (*Blitzschlag*, *Gedankenschlag*) → the name renders without a `?` or a
  replacement box at its end, and the time text has no stray `%s` or `%.1f`. Interrupt a cast → the
  bar shows *Unterbrochen*, not *Interrupted*. *Failure:* a truncated multi-byte character at the end
  of the name (the bar clips by width, never by byte count, so this should not happen), or the English
  word on a German client (the client global was not read). The client is the only witness here: the
  English client has no multi-byte spell names, and its global is the English word. Result: pass (owner-marked 2026-10-10)
- **LOC-4. Frame-system detection.** With party frames shown, `/pfe debug on` → the `[Init]` line
  names the detected system, the same as on English. *Failure:* `frames 'none'` on deDE with party
  frames visibly on screen. May be signed off on English: detection reads no localized string. Result: pass (owner-marked 2026-10-10)

## Pending sign-off

None. On 2026-10-10 the owner marked every check in this file as passed, recorded on its
`Result:` line as `pass (owner-marked 2026-10-10)`; a check that already carried a dated owner pass
keeps it. A check added or rewritten after that date is listed here until its `Result:` line records
a pass.
