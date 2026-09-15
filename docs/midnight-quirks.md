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
