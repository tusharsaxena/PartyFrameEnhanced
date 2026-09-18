# Midnight quirks — secret values and the 12.x traps this addon works around

Read this before touching cast, target, pet or frame-detection code. Each entry is a client behavior
the addon carries a workaround for, where it lives, and what breaks if the workaround is "tidied" away.

## Secret values (12.0+)

In restricted contexts — combat, instances, encounters, PvP — the client hands addons opaque
**secret** values for many returns. A secret survives being stored and passed along, but **comparing
it, doing arithmetic on it, using it as a table key, or formatting it in Lua raises**. C methods that
render (`SetText`, `SetTexture`, `SetValue`, `SetMinMaxValues`, `SetTimerDuration`,
`SetFormattedText`, `SetAlphaFromBoolean`, the curve evaluators) accept them.

What this addon meets, and on which units:

| Return | Secret when | Where handled |
|---|---|---|
| `UnitCastingInfo` / `UnitChannelInfo` name, texture, times, `notInterruptible`, spellID, castID | any unit but the player and their pet, under restrictions | `core/Compat.lua` `CastInfo`; `modules/CastBars.lua` |
| duration-object getters (`GetRemainingDuration` …) | in combat | passed straight to `SetTimerDuration` / `SetFormattedText`, never bound to a local |
| `UnitIsUnit` on a compound token (`party1target`) | **always** | `Compat.UnitIsUnit` answers nil (unknown); no feature branches on it |
| a SecureGroupHeader child's `unit` attribute, `IsVisible` on other addons' frames | can be | `Compat.FrameUnit` rejects a secret; `Compat.FrameVisible` fails open |

Only `castBarID` and `delayTimeMs` in the cast returns are never secret. Nil-ness of a return is never
secret either, which is what makes `if name then` and the stale-bar check safe.

### The rules the code follows

1. **Test for secret before any comparison.** `Compat.FrameUnit` checks `IsSecret(u)` *before*
   `u == ""`, because the comparison itself would raise.
2. **A secret boolean never meets an `if`.** `notInterruptible` picks the fill's four channels through
   `Compat.BoolValue` (→ `C_CurveUtil.EvaluateColorValueFromBoolean`) and the shield through
   `Compat.AlphaFromBool` (→ `SetAlphaFromBoolean`). Each channel is computed from plain inputs first —
   `(u.a or 1) * fill` — because the chosen result may be secret and cannot be multiplied afterwards.
3. **After `SetAlphaFromBoolean`, `GetAlpha()` is secret.** Keep your own record of the alpha you asked
   for (`el.__alpha`); never read it back.
4. **The interruptibility events turn the flag plain.** `UNIT_SPELLCAST_(NOT_)INTERRUPTIBLE` set
   `notInterruptible` from the event's own name. Do not optimize the color path into an `if` because
   "it's plain now": the next cast start puts a secret back.
5. **Never compute the spark's position.** It is anchored once to the fill texture's right edge; the
   client moves it. `barWidth * (elapsed / total)` is a secret division.
6. **End of cast comes from events.** `if remaining <= 0` is a secret comparison. The stop, failed and
   interrupted events decide; a 0.1 s tick catches a stop the client never sent by checking nil-ness.

## A party member's target is a compound token

`party1target` is secret whenever any link in the chain fails the identity test, so its name, class,
player-ness, reaction, health and raid marker can each come back secret (SimplePartyTargets hit all of
them). The target frames:

- pass the name, health, max health and marker index straight to `SetText`, `SetMinMaxValues`,
  `SetValue` and `SetRaidTargetIconTexture`;
- render health percent as `UnitHealthPercent(token, true, CurveConstants.ScaleTo100)` into
  `SetFormattedText("%d%%", …)` — the client does the scaling;
- read the class **token** through `Compat.ClassToken`, which answers nil for a secret, so
  `RAID_CLASS_COLORS[secret]` can never run (the library's own resolver is not used here for that
  reason: it indexes the table with whatever `UnitClass` answered);
- treat an unknown player-ness or reaction as an NPC of unknown mood and use the hostile swatch;
- skip a repaint only when both health values are plain and unchanged — a secret cannot be compared,
  so a secret health is always pushed.

Compound tokens also get **no unit events**: `UNIT_HEALTH` never fires for `party1target`. Health is a
gated repeating timer (`general.tickInterval`, default 0.2 s) that runs only while at least one target
button is **shown**, and repaints only the shown ones. Lua never asks `UnitExists` about the token:
in combat that answer can be secret, and reading a secret as "exists" repainted every hidden button
five times a second (the first in-game capture, `perf-analysis/20260915-161824`: 4.89 renders per
pass, solo). The button's state driver `[@party1target,exists]` is resolved securely, so the
button's own visibility is the plain answer, and its `OnShow`/`OnHide` post-hooks start and stop the
timer.

The same gap covers a target the client has not streamed yet. `UNIT_NAME_UPDATE` never fires for
`party1target` either, so a button painted before its unit resolved (a nil name, and an unknown
reaction that reads as hostile) had nothing to repaint it: someone joining the party while targeting
a friendly NPC got a blank red frame until they changed target. A button painted with a plain nil
name is marked pending, and the same timer repaints it whole until the name arrives; it keeps the
timer running even with *Update health* off. A secret name counts as resolved.

`UnitIsUnit("party1target", …)` is always secret, which is why there is no "hide when my party member
targets me" option.

## Copying a party frame's out-of-range alpha

`UnitInRange` can answer a secret boolean in combat. EllesmereUI hands it straight to
`SetAlphaFromBoolean`, and Blizzard's raid-style frames turn it into `SetAlpha(0.5 or 1)` inside their
own code, where the number can itself be secret. `modules/RangeFade.lua` post-hooks both calls on the
member frame and replays them on its own per-unit fade frame:

- a secret **flag** goes to `SetAlphaFromBoolean` untouched, which takes it by design;
- a secret **number** is tried on `SetAlpha` under `pcall`. If the client refuses it, the raid-style
  frame's own `outOfRange` flag (possibly secret too) goes through `SetAlphaFromBoolean` instead.
  Which path runs in an instance is smoke step 47b;
- the fade frame's `GetAlpha` is never read back. After `SetAlphaFromBoolean` it is secret, and it
  never has to be multiplied with anything: the elements are the fade frame's children, so the
  client multiplies the two alphas itself.

## Stops re-derive instead of matching ids

A stop, fail or interrupt re-queries the unit before acting (`CastBars` `onEvent`): if the unit is
already casting again, the bar stays on the new cast. This replaces matching `castID`/`spellID`,
which can be secret, and handles the case where the next cast's START arrives before the previous
cast's STOP.

## Empowered casts

`UnitChannelInfo`'s ninth return, `isEmpowered`, is read only when it is plain; the triggering event
(`UNIT_SPELLCAST_EMPOWER_*`) decides otherwise. Empowered casts fill (ElapsedTime), channels drain
(RemainingTime). Stage pips are not drawn yet (GitHub issue).

## `CastingBarFrameTemplate` is not used

Pointed at another unit it compares `GetTime()` against a max value set from a secret end time and
raises in combat (KickCD's finding). The bars are plain `StatusBar`s driven by `SetTimerDuration`.

## Edit Mode owns the party layout choice

Raid-style vs classic party frames is a per-layout Edit Mode setting in 12.x:
`EditModeManagerFrame:UseRaidStylePartyFrames()`. The `useCompactPartyFrames` CVar is kept only as a
fallback (`Compat.UseRaidStyleParty`).

## Frame systems re-sort in combat

Blizzard's `CompactPartyFrame:RefreshMembers` and EllesmereUI's SecureGroupHeader both re-assign which
frame shows which unit in secure code, during combat. Cast bars follow at once; the secure target and
pet frames fade and re-anchor at `PLAYER_REGEN_ENABLED` (`modules/Anchor.lua`, spec §6.4).
