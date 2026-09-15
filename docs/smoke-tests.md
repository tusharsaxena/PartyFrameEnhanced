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
| **T** | **Non-English client (locale)** | **deDE or frFR** — sub-steps T1 and T4 may be signed off on English |

## A. Load and bootstrap

1. **Fresh install.** Delete `WTF/Account/<ACCOUNT>/SavedVariables/PartyFrameEnhanced.lua`, log in →
   world reached, **zero Lua errors**. *Failure:* an error naming `PartyFrameEnhanced\core\…` or a
   missing `[PFE]` on every line.
2. **`/reload`** → no errors.
3. **AddOn list.** The character-select AddOn list shows **Ka0s Party Frame Enhanced** with its notes
   line and icon.

## B. Slash surface

4. `/pfe` alone → the help block: a version line and fourteen verbs (help, config, list, get, set,
   reset, resetall, resetposition, lock, unlock, debug, perf, version, profile), each a gold
   `/pfe <verb>`, an em dash and a white description.
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

## T. Non-English client (locale)

What this addon touches that a client translates, enumerated from the code rather than assumed:

- **Localized `_G` reads:** none. `grep -rn "_G\[" core modules settings` returns nothing, and no
  `ITEM_*`, chat format or tooltip constant is read.
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
- **T2. Class colors from the token** (arrives with target frames, P4). Target a German-named
  class-bearing player (a *Magier*) from a party member → the target frame takes mage blue. *Failure:*
  the stored swatch color instead of the class color on deDE only — the class was keyed on the localized
  name. *Headless stand-in:* `tests/test_targetframes.lua` feeds `UnitClass` a localized first return
  and asserts the token decides (P4).
- **T3. Spell names render whole** (arrives with cast bars, P3). Watch a party member cast a spell whose
  German name has an umlaut or ß (*Blitzschlag*, *Gedankenschlag*) → the name renders without a `?` or
  replacement box at its end, and the time text has no stray `%s`/`%.1f`. *Failure:* a truncated
  multi-byte character at the end of the name. **The client is the only witness here**: the English
  client has no multi-byte spell names.
- **T4. Frame-system detection.** With party frames shown, `/pfe debug on` → the `[Init]` line names
  the detected system, the same as on English. *Failure:* `frames 'none'` on deDE with party frames
  visibly on screen. *May be signed off on English:* detection reads no localized string.

T1 and T4 may be signed off on an English client for the reasons given. T2 is covered headlessly once
its case exists. T3 needs a deDE or frFR client.
