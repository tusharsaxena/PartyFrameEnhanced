# Midnight quirks — secret values and the 12.x traps this addon works around

Read this before touching cast, target, pet or frame-detection code. Each entry is a client behavior
the addon carries a workaround for, where it lives, and what breaks if the workaround is "tidied" away.
The first part below is the collection's client-quirks catalog, vendored from the standard and
replaced wholesale on every re-vendor, so never edit inside its markers; this addon's own entries follow it.

<!-- BEGIN VENDORED: quirks catalog v2.102.2 (source: WowAddonStandards) -->
> Part of the **[Ka0s WoW Addon Standard](https://github.com/tusharsaxena/WowAddonStandards/blob/master/standards/STANDARDS.md)** — the split standard. This section is vendored whole into every addon's `docs/midnight-quirks.md` (§1), so its links are absolute. Cross-references use the `filename-§N` form (see the index's section map).

## Client quirks

The client behaviors the collection paid for more than once. Each entry here was discovered
**independently in two or more Ka0s repositories**, written up in each, and promoted by a harvest so the
next addon reads it instead of rediscovering it. A behavior one repo found stays in that repo's
`docs/midnight-quirks.md` until a second repo meets it.

*Why this section exists.* By 2026-11-06 eleven addons kept a private `docs/midnight-quirks.md`, 2,073
lines and about 133 entries between them, and about 81 of those entries were 21 behaviors written up
independently two to eight times. Nine of the eleven opened with their own restatement of the 12.0 secret
rules. Three write-ups contradicted this standard, and one contradiction was this standard's own error
(events-frames-taint-§2, *The combat-start edge*). A catalog was proposed and deferred twice, on
2026-08-25 and 2026-09-22, because an inventory rots; the build stamp per entry (§1) is the answer to that
objection (WowAddonStandards `harvests/2026-11-06/02_FINDINGS.md`, F3-01; every write-up quoted in
`harvests/2026-11-06/03_EVIDENCE.md`, Part A).

### 1. How an entry is written, and how it expires (MUST)

Every entry **MUST** carry:

- **The behavior**, stated as what the client does, not as advice.
- **Measured:** the client build or date it was observed on, where any write-up recorded one. An entry with
  no measurement says *not measured*; that is a weaker entry, not a missing field.
- **Cost:** what happened to an addon that did not know it.
- **Do:** the workaround, as a rule an addon can follow.
- **Source:** the deepest write-up — the repo and document that probed furthest — and the harvest that
  promoted it. Every version is quoted in that harvest's `03_EVIDENCE.md`.

**Expiry.** An entry describes a client, and clients move. When the retail interface number moves past the
newest *Measured* stamp in an entry and an addon observes otherwise, the entry is corrected in a standard
release — not worked around in the addon. An entry nobody can reproduce moves to §6 as an open probe rather
than being deleted, because the behavior may only have moved.

**What an addon does with this section (MUST): carry it as a vendored block.** This section is the one
part of the standard an addon carries a **copy** of, because it is reference data about the game client
that a working addon needs offline, next to the code that works around it — not a rule, which is only ever
pointed at. Every addon's `docs/midnight-quirks.md` (documentation-§3) is two parts: the vendored block,
opened by a `BEGIN VENDORED` HTML comment naming the catalog's version and source and closed by an
`END VENDORED` HTML comment, each spelled exactly as `/dev-copilot:wow-revendor-standards` writes it; then
the addon's own section. The markers are described here rather than shown, because this text travels
inside them: a literal marker in the vendored copy would give the file a second end marker for the next
re-vendor to cut at.

```markdown
[the BEGIN VENDORED comment, stamped quirks catalog v<X.Y.Z>]
… this section, whole …
[the END VENDORED comment]

## <Addon>-specific quirks

… the addon's own quirks: one no second repo has met, its per-event costs, its own probe tables …
```

- The block is **copied whole and replaced wholesale** by `/dev-copilot:wow-revendor-standards`, stamped with
  the standard version it came from, under the same discipline as `libs/LibKa0s/` (anti-pattern #45): never
  a subset, **never edited inside the markers**. A local edit inside them is reverted by the next revendor,
  and the behavior it fixed comes back with no cause in the addon's history; a correction belongs in the
  addon's own section, where the next harvest finds it.
- The addon's own section **MUST NOT** restate a behavior the block carries. When a harvest promotes an
  entry, the revendor prunes the addon's copy: the upstream entry is the deeper write-up, and two live
  copies of one finding is the shape that drifted three times into contradiction.
- An addon with no quirks of its own still carries the block, with an empty own section.

**Contested behaviors are not rules.** Where two repos recorded opposite behavior and nobody has probed
the difference, the entry goes in §6 with both sides and the probe that would settle it.

Behaviors this standard already states elsewhere are not repeated here: the unknown-event raise
(events-frames-taint-§1), `Settings.OpenToCategory`'s numeric ID and collapsed parent (options-ui-§2),
the protected category switch in combat (options-ui-§2, anti-pattern #88), a secret through `tostring` and
`..` (events-frames-taint-§8), lockdown at `PLAYER_REGEN_DISABLED` (events-frames-taint-§2), the spec
readers' move to `C_SpecializationInfo` (compat, `LibKa0s-Compat-1.0`) and `SendChatMessage`'s move to
`C_ChatInfo` (compat).

### 2. Secret values

**A secret boolean cannot be tested at all.** `if`, `not`, `==` and `and`/`or` on a secret boolean raise
("attempt to compare … (a secret boolean value)"); the value is unusable in Lua, not merely unprintable.
`DurationObject`'s `HasExpired`, `HasStarted`, `IsActive` and `IsZero` come back secret in combat, and an
engine button's `IsShown` has answered a secret boolean out of combat. *Measured:* 12.0.7 (probe table);
12.1 (`IsShown`). *Cost:* a raise on every refresh tick of the path that tests it. *Do:* check
`issecretvalue` before any test; route a secret boolean to a C-side consumer
(`C_CurveUtil.EvaluateColorValueFromBoolean`, `SetAlphaFromBoolean`), or treat it as the cautious answer
(a secret lockdown reads as locked, a secret restriction as active, a secret claim as no claim). Two repos
disagree on whether to gate before the C-side call; that disagreement is recorded in `LibKa0s`
`docs/api/Compat` and is not ruled here. *Source:* KickCD `docs/midnight-quirks.md`, "Secret booleans are
unusable"; seven repos (harvest 2026-11-06, Q6).

**A secret cannot be a table key.** Indexing or assigning with a secret key raises "attempted to perform
indexed assignment on a table that cannot be indexed with secret keys". `UnitGUID` on a follower-dungeon
pet (`party3pet`) answers a secret string. *Cost:* a raise on every refresh tick for a roster keyed by
GUID. *Do:* guard a key with `IsSafeKey` (`LibKa0s-Compat-1.0`) or `issecretvalue` before keying; a
secret GUID is never a handle. *Source:* MultiMeters `docs/midnight-quirks.md`, the follower-dungeon pet
GUID; seven repos (Q7).

**A secret never reaches SavedVariables, and one that does is written as `nil`.** A value captured as
secret stays secret after combat ends, and the client writes a secret to SavedVariables as `nil` — or,
where it was a key, loses the entry. *Measured:* a reload probe, 2026-10-25. *Cost:* silent data loss on
the next reload. *Do:* store a plain value or nothing; never store a captured secret to read later.
*Source:* DpsRace `docs/known-limitations.md`, the reload probe; three repos (Q21).

**A frame handed a secret has secret geometry, and so does everything anchored to it.** After
`StatusBar:SetValue(secret)` (or `SetAlphaFromBoolean`, or anchoring to an aura engine container) the
frame `HasSecretValues`: its width, points and frame level read secret, out of combat too, and the
taint runs down the anchor chain to every frame anchored to it; a tooltip showing hidden information has
secret geometry. A secret size's `type` is `"number"`, so a type check lets it through, and
`BackdropTemplate`'s own arithmetic on a secret size raises. *Cost:* a raise inside Blizzard code, or a
layout computed from a secret. *Do:* compute layout from configuration and never read geometry back from a
frame that was handed a value; keep a record of the alpha you set rather than calling `GetAlpha()`; read a
frame level under a restricted anchor through a secret-safe guard (frame-layering). *Source:* AuraMaster
`docs/midnight-quirks.md`, the aura engine container entries (measured and dated); six repos and
`LibKa0s` `docs/api/Widgets` (Q8).

**A restricted spell's cooldown: branch on `isActive`, paint with the duration object.** In a restricted
state `C_Spell.GetSpellCooldown`'s timings are secret while `isEnabled` and `isActive` stay plain
(documented NeverSecret). `GetSpellCooldownDuration` answers a **zeroed** object, not `nil`, when there is
no cooldown, and a fresh object per call. *Cost:* raw `SetCooldown` with a secret start or duration raises;
a nil check passes the zeroed object. *Do:* decide from `isActive`; paint with
`Cooldown:SetCooldownFromDurationObject`, which accepts the object from tainted code. *Source:* KickCD
`docs/midnight-quirks.md`, the cooldown probe table; four repos (Q9).

**`notInterruptible` is secret, and the interruptibility events make it plain.** The cast info's
`notInterruptible` is secret; `UNIT_SPELLCAST_INTERRUPTIBLE` / `_NOT_INTERRUPTIBLE` deliver it plain.
`CastingBarFrameTemplate`'s built-in `OnUpdate` compares `GetTime()` with a secret `maxValue` and raises
when the bar shows another unit. *Do:* split the gate — the color path takes the secret C-side, the logic
path takes the event's plain value; do not inherit `CastingBarFrameTemplate` for a unit other than the
player. *Source:* KickCD `docs/midnight-quirks.md`, "split the gate in two"; two repos (Q13).

**`InChatMessagingLockdown` can answer a secret.** *Do:* read it through a guard and treat a secret as
locked. *Source:* DropWatcher and QuickComms `core/Compat.lua` (byte-identical), DpsRace; three repos (Q27).

### 3. Events

**A valid event can register without complaint and never fire.** `GUILDBANKFRAME_OPENED` registers and
never fires (*Measured:* 12.0.7); `UNIT_SPELLCAST_SUCCEEDED` is suppressed for protected interrupts;
`UNIT_HEALTH` and `UNIT_NAME_UPDATE` never fire for compound tokens such as `party1target`;
`GET_ITEM_INFO_RECEIVED` does not fire for an item already cached. This is the inverse of the
unknown-event raise (events-frames-taint-§1) and it is silent: nothing errors. *Cost:* a feature that
never runs, with nothing in the log. *Do:* confirm a new event fires in game before building on it, and
prefer an edge with a second source (a frame's `OnShow`, a gated timer) where the event is known to be
silent. *Source:* BankLedger `docs/midnight-quirks.md`, `GUILDBANKFRAME_OPENED`; four repos (Q20).

**Client state can lag its own event, or change with no event at all.** `IsMounted()` has flipped by the
time `PLAYER_MOUNT_DISPLAY_CHANGED` arrives while `C_PlayerInfo.GetGlidingInfo`'s `canGlide` sometimes has
not; after `INSPECT_READY` some slots still answer an item id with no link; switching bank tabs fires no
event, and the live warband tab has taken over a second to catch up; chat lockdown clears with no event.
*Cost:* a read at the edge answers the old state, and the display stays wrong until the next unrelated
event. *Do:* answer at the edge **and once more after a short settle** (a fraction of a second, a bounded
retry), never a poll. *Source:* MultiMeters `docs/midnight-quirks.md`, "some client state lags its own
event"; six repos (Q19).

**An empowered cast fires `UNIT_SPELLCAST_EMPOWER_*`, not the channel events.** `UnitChannelInfo`
reports it, but `UNIT_SPELLCAST_CHANNEL_START` / `_STOP` do not fire for it, and its release fires
`UNIT_SPELLCAST_SUCCEEDED` with the same cast GUID. *Do:* register the `EMPOWER_*` events wherever channels
are tracked. *Source:* KickCD `docs/midnight-quirks.md`, empowered casts; three repos (Q12).

**`ADDON_RESTRICTION_STATE_CHANGED` fires *before* enforcement.** The `Activating` state arrives before the
restriction begins, and access is still permitted during that dispatch; a dungeon restriction type has
gone active on entry and not cleared. Read the restriction type by its `Enum.AddOnRestrictionType` member
name — a member can be missing on some builds. *Measured:* 12.1.0, 2026-09-18. *Do:* treat `Activating`
as the last moment to read, not as the start of the restriction. The payload's second argument is
contested (§6). *Source:* AuraMaster `docs/midnight-quirks.md`, the restriction types; six repos (Q10).

### 4. Combat and secure frames

**Blizzard's aura buttons are forbidden to addon code, and `IsForbidden()` can say otherwise.** In
combat every call on a Blizzard aura button's objects raises "Attempt to access forbidden object from code
tainted by an AddOn"; in an instance (seen in Mythic+) the same buttons answer `IsForbidden()` `false` and
still refuse every read, `GetChildren` included. *Do:* never read Blizzard aura buttons; where a frame
must be inspected, `pcall` the read and treat a failure as forbidden. *Source:* PartyFrameEnhanced
`docs/midnight-quirks.md`, forbidden aura buttons; three repos (Q14).

**Escape runs a protected `Hide()` in combat.** A secure or protected frame listed in `UISpecialFrames` is
hidden by `CloseSpecialWindows`, which is a protected action in combat. *Do:* list a non-secure proxy in
`UISpecialFrames` and hide the protected frame from it out of combat, or keep protected frames out of the
list. *Source:* WhatGroup `docs/midnight-quirks.md`, the escape proxy; two repos (Q24).

### 5. Item, tooltip, enum and realm data

**Item data is nil until cached, and the load event has holes.** `GetItemInfo` answers nothing for an
uncached item; `GET_ITEM_INFO_RECEIVED` does not fire on an addon's first scan for an item the client
already holds; an uncached item's tooltip is not empty but a legible `RETRIEVING_ITEM_INFO` line; a failed
load drops its wait and nothing asks again. *Cost:* a blank or wrong row that never repairs. *Do:* load
through `LibKa0s-Item-1.0`'s cache-then-callback path (library-stack-§7), treat `RETRIEVING_ITEM_INFO` as
not-yet-loaded, and re-ask after a failed load. *Source:* ConsumableMaster `docs/midnight-quirks.md`, the
first-scan hole; seven repos (Q15).

**`C_TooltipInfo` returns raw templates.** Tooltip lines can carry the unexpanded plural grammar
`|4singular:plural;` (*Measured:* 12.1.5, "for the next 3 |4hour:hrs; 49 min") and a no-break space that
Lua's `%s` does not match. *Cost:* a parser that knew only the expanded words read no duration and called a
tradeable drop expired. *Do:* expand `|4…;` before matching, and match the no-break space explicitly.
*Source:* DropWatcher `docs/midnight-quirks.md`, the trade window; two repos (Q16).

**Tooltip line text can be secret** under an addon restriction, including through `TooltipDataProcessor`.
*Do:* guard each line before matching. *Source:* DropWatcher `docs/midnight-quirks.md`; two repos (Q17).

**Blizzard renumbers enums; resolve a member by name, never by number.** One build's
`Enum.TooltipDataLineType` and bank-tab values are not the next build's, and a member can be absent on a
build. *Cost:* a numeric guess for a member the build does not expose landed on an unrelated bank
container. *Do:* read `Enum.X.Member`, and handle its absence; localization-§4 already forbids the string
spelling. *Source:* DropWatcher `docs/midnight-quirks.md`, the research's enum values; five repos (Q18).

**`GetNormalizedRealmName` is nil early in login.** *Cost:* a stored `Name-` key with no realm. *Do:* never
build a `Name-Realm` key before the realm is known; defer, or fall back to `GetRealmName` with its spaces
and hyphens removed. *Source:* DropWatcher `docs/midnight-quirks.md`, realm names; four repos (Q25).

**A template-less `FontString` with no font raises on `SetText`.** "Font not set" from a `FontString`
created without a template or `SetFontObject` takes the addon down at load; a mock that does not enforce it
passes every test. *Do:* give every bare `FontString` a font object before its first `SetText`; the kit's
mock enforces it. *Source:* MultiMeters `tests/mock_frame.lua`, the font-not-set guard; three repos and
`LibKa0s` (Q22).

### 6. Open probes — contested behaviors (not rules)

Each needs an in-game probe, recorded with the build, before any section of this standard changes.

- **`string.format` on a secret.** events-frames-taint-§8 says it raises, with three repos; two say it
  works, one with a mid-combat observation. The likely difference is the specifier (`%s` against `%d` and
  `%.1f`) or that the result is itself a secret string. Probe each specifier, in combat, on a damage-meter
  value and a `UnitHealth` value. Until then §8's rule stands.
- **`ADDON_RESTRICTION_STATE_CHANGED`'s second argument.** One repo documents an
  `Enum.AddOnRestrictionState` value; three (one measured) record a boolean as well. Handle both shapes.
  The 2026-09-22 harvest called this settled, and it is not.
- **`SetAllPoints(parent)` on a secure button at load.** One repo records "Cannot anchor protected frames
  to regions" and uses the implicit-parent form; another anchors its secure rows with `SetAllPoints(row)`
  at birth and treats it as working, with its in-game smoke check still owed.
<!-- END VENDORED -->

## PartyFrameEnhanced-specific quirks

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
  Which path runs in an instance is smoke check FADE-2;
- the fade frame's `GetAlpha` is never read back. After `SetAlphaFromBoolean` it is secret, and it
  never has to be multiplied with anything: the elements are the fade frame's children, so the
  client multiplies the two alphas itself.

## Blizzard's party frames hold forbidden children

Blizzard's raid-style member frames carry **forbidden** aura buttons
(`Blizzard_AuraContainerFrameProviders.lua`). Any method on a forbidden frame except `IsForbidden`
raises "Attempt to access forbidden object from code tainted by an AddOn". The strata code in
`modules/RangeFade.lua` walks a party frame's children to find the highest level, and it skips any
child whose `IsForbidden()` is `true`, along with everything under that child. The level and strata
reads are `pcall`'d too. In an instance (seen in M+) the same aura buttons answer `IsForbidden()`
`false` and still refuse every read, `GetChildren` included, so a refused level read also ends the
walk at that frame, and the `GetChildren` read is `pcall`'d. A party frame that cannot be read at
all puts its unit's elements on LOW (Blizzard's unit-frame strata) at a fixed level of 50.
*Breaks if tidied:* drop the `IsForbidden` check, or let the walk descend past a refused level
read, and the strata pass raises on every LAYOUT and VISIBILITY.

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
frame shows which unit in secure code, during combat. Cast bars follow at once. The secure target and
pet frames cannot be moved by Lua under lockdown, so `modules/SecureFollow.lua` wraps a restricted
pre-body on each protected member frame's `OnAttributeChanged` (out of combat, once per frame), and
the member's `unit` change moves its target and pet buttons in restricted code (#3). Anything not
wrapped (a frame the header creates in combat, an unprotected or refused frame) and Blizzard classic,
which never re-sorts, keep the fade and re-anchor at `PLAYER_REGEN_ENABLED` (`modules/Anchor.lua`,
spec §6.4). Verified in the client on 2026-10-02 (smoke checks COMBAT-6, COMBAT-9, COMBAT-10):
that these frames change the `unit` ATTRIBUTE in combat (a frame that sets only the Lua `frame.unit`
fires no wrap, and the fade stays), and that a third-party header may wrap them.

## An unknown event name raises

The client raises `Attempt to register unknown event "<NAME>"` on a name it does not know, and a block
of bare `RegisterEvent` lines loses every line after the one that raised. So every registration here
goes through LibKa0s-Core's `NS.SafeRegisterEvent` / `SafeRegisterUnitEvent` / `SafeRegisterEvents`
(`core/CoreSetup.lua`), which records a refused name once in `NS.RejectedEvents` and lets the rest of
the block register; `/pfe status` prints the list when it is not empty. The probing trade-off: the
library asks `C_EventUtils.IsEventValid` (or a private probe frame) before the target sees the name,
because an AceEvent target only raises for an event's first registrant in the client-wide registry.
That front gate is optional, not the guard. The pcall around the target's own call is what keeps one
bad name from taking the block down, and it is the only rung the library-absent stub carries. Every
name registered today is valid on 12.1.0, so this is insurance against a patch retiring one.
