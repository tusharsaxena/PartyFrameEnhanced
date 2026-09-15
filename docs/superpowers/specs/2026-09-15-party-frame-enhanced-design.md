# Ka0s Party Frame Enhanced — tech and UX spec

| | |
|---|---|
| Status | **Draft v1**, written 2026-09-15 before any feature code |
| Addon | `PartyFrameEnhanced` — TOC title `Ka0s Party Frame Enhanced`, slash `/pfe` + `/partyframeenhanced` |
| Standard | Ka0s WoW Addon Standard v2.44.0 (2026-09-12) |
| Library | LibKa0s v1.36.1, vendored whole |
| Client | Retail, `## Interface: 120100` (the collection's current Live value) |
| Plan | [`../plans/2026-09-15-party-frame-enhanced-v0.1.0.md`](../plans/2026-09-15-party-frame-enhanced-v0.1.0.md) |

This is the design record for the first release. It is frozen once the plan starts executing; later
changes are recorded in the plan's ledger or in `docs/ARCHITECTURE.md`, not by editing this file.

---

## 1. What it is

The default party frames and EllesmereUI's party frames show a party member's health, power and
auras. They do not show three things a healer or a tank looks for every pull:

1. **What each party member is casting.** A cast bar per party member.
2. **What each party member is targeting.** A small target frame per party member: name, health,
   class or reaction color.
3. **Each party member's pet.** A small pet frame per party member: name, health.

Party Frame Enhanced adds those three **elements** for the player and party1–party4. Each element
either **attaches** to the party frame currently showing its unit, whichever frame system draws it,
or sits in a movable **free-placement** stack that doesn't need any party frames at all.

### Goals

- Works with **Blizzard's party frames** in both styles (the classic `PartyFrame` and the raid-style
  `CompactPartyFrame`) and with **EllesmereUI's party frames**, detected automatically, with a manual
  override.
- Includes the **player's own** row whenever the frame system shows the player (raid-style Blizzard,
  EllesmereUI with its self frame on), and in free placement when the option is on.
- Survives Midnight's **secret values**: nothing compares, formats or does arithmetic on a
  combat-protected value.
- Is **cheap**. Events are registered per unit on the client side, the only polling is a single
  gated ticker for target health, and every hot path is bracketed for `/pfe perf`.
- Is **born compliant** with the Ka0s standard: LibKa0s seams, schema-driven settings, the tabbed
  panel, the test harness, the doc set.

### Non-goals for v0.1.0 (each is a GitHub issue — §10)

- Raid frames. A raid group puts the addon to sleep, like SimplePartyTargets.
- Arena frames and other frame systems (ElvUI, Cell, Grid2, VuhDo, Danders). The provider interface
  makes them additive later.
- Target-of-target chains, focus frames, auras on the new elements, power bars on the new elements.
- Empowered-cast stage markers (the bar fills correctly; the pips are deferred).
- Per-unit styling. Every element of one feature shares one style; only position differs.
- Following a roster change **during combat** for the secure (clickable) target and pet frames. They
  re-anchor on `PLAYER_REGEN_ENABLED` (§6.4).
- Localization beyond enUS (the `NS.L` seam ships; no translations).

---

## 2. Research summary

Three reference points were read in full before design. Detail lives with the agents' reports in
this session; the conclusions that shaped the design are below.

### 2.1 SimplePartyTargets (a personal fork, `../SimplePartyTargets`)

- **Frame discovery** it gets right: read each member frame's unit per pass (`displayedUnit` →
  `unit` → `GetAttribute("unit")`), never assume index = unit; EllesmereUI keeps five
  SecureGroupHeader children (`ERFPartyHeader[i]` / `ERFPartyHeaderUnitButtonN`) plus a separate
  `ERFPartySelfButton`, and re-assigns units as the roster sorts.
- **Refresh triggers** that matter: `GROUP_ROSTER_UPDATE`, `EDIT_MODE_LAYOUTS_UPDATED` /
  `EDIT_MODE_LAYOUT_APPLIED`, the raid-style toggle, `ADDON_LOADED` for EllesmereUI, and Edit Mode
  hooks. A coalesced 0 s / 0.05 s burst handles frames that settle a frame late.
- **Perf lessons from real captures**: per-owner updates instead of full passes, an anchor memo so
  `SetPoint` runs only when the anchor key changes, event filtering, and an idle gate. It measured
  ~7 full passes/s × 11 blocks and 46 `SetPoint` calls per block per pass before those fixes.
- **Bugs to not copy**: creating secure buttons during combat (a latent `SetAttribute` in lockdown),
  a 2100-line file that hit Lua 5.1's 200-local / 60-upvalue limits, health shown full whenever it is
  secret.

### 2.2 PartyCastBars (third-party, All Rights Reserved — patterns only, no code)

- **The Midnight-correct cast timer**: `UnitCastingDuration` / `UnitChannelDuration` /
  `UnitEmpoweredChannelDuration` handed straight to `StatusBar:SetTimerDuration(duration,
  Enum.StatusBarInterpolation.Immediate, direction)`. Never read start/end times.
- **Provider registry** with priority, `IsAvailable` / `IsActive`, and EllesmereUI discovered by
  shape through `EllesmereUI._ModuleNS` (`_partyUnitToButton`, `_CollectTrackerFrames`), with
  `ERF*` global names as the fallback and `hooksecurefunc` on its notify functions.
- **What it leaves out** and we add: non-interruptible coloring and shield, cast time text,
  interrupted/failed feedback and fade, a spark, per-unit event registration (it registers globally
  and filters in Lua, and polls `UnitCastingInfo` every frame per bar), free placement, the player's
  row in classic party mode, and a debounced settings path (it fires an 8-step refresh burst per
  slider tick).

### 2.3 KickCD (the collection's own secret-safe cast bar)

`KickCD/docs/castbar.md` and `midnight-quirks.md` record what already failed in combat:

- `startTimeMS`/`endTimeMS`, `notInterruptible`, and even `name`/`texture` can be secret.
- Duration-object getters return secrets in combat; they are only safe as **direct arguments** to a
  C method (`SetMinMaxValues`, `SetValue`, `SetFormattedText`).
- `notInterruptible` is a secret boolean: never branch on it; feed it to
  `C_CurveUtil.EvaluateColorValueFromBoolean` or `Frame:SetAlphaFromBoolean`.
- The spark is anchored to the status-bar texture's fill edge once, never positioned per frame.
- End of cast is detected from events, never by comparing remaining time.
- `CastingBarFrameTemplate` pointed at another unit breaks (its OnUpdate compares a secret).

### 2.4 Blizzard and EllesmereUI frames

Read from the installed EllesmereUI source and Blizzard's live `wow-ui-source`. Items marked
*verify* are confirmed in-client during the smoke pass rather than assumed.

| System | Member frames | Player shown? | Unit read | Re-sorts in combat? |
|---|---|---|---|---|
| Blizzard raid-style | `CompactPartyFrame.memberUnitFrames[i]` / `CompactPartyFrameMember1..5` (the container is generated lazily) | yes | `displayedUnit` → `unit` | **yes** — `RefreshMembers` sorts with `flowSortFunc` |
| Blizzard classic | `PartyFrame.MemberFrame1..4` (pool-acquired, `layoutIndex = i`) | never | `frame:GetUnit()` / `unitToken` = `party<i>` | no — fixed per index |
| EllesmereUI | `ERFPartyHeaderUnitButton1..5` (= `ERFPartyHeader[i]`), plus `ERFPartySelfButton` when "self first" is on | unless its hide-self option is on | `GetAttribute("unit")` | **yes** — a real `SecureGroupHeader` re-assigns `unit` in the restricted environment |

Other facts that shaped the design:

- **Which system is live.** Blizzard: `EditModeManagerFrame:UseRaidStylePartyFrames()` (a per-layout
  Edit Mode setting; the old `useCompactPartyFrames` CVar is a fallback only). EllesmereUI owns the
  party when `ERFPartyHeader` or `ERFPartySelfButton` is visible; it then hides and reparents every
  Blizzard party frame, so anchoring to those is pointless.
- **EllesmereUI draws no party cast bars, target frames or pet frames**, so nothing we add
  duplicates it. It has no public layout callback: detection is events, `HookScript` on the header
  children (`OnAttributeChanged` filtered to `unit`, `OnShow`/`OnHide`) and a next-frame deferral.
- **Blizzard already draws pets** in both of its modes: classic member frames carry a `.PetFrame`
  (`partypetN`, CVar `showPartyPets`), and raid-style can show `CompactPartyFramePet1..5` as a separate
  sorted list below the members. Our pet frames matter most under EllesmereUI; under Blizzard they
  are an alternative the player can turn off.
- **Secrets on party units** (warcraft.wiki.gg *Secret Values*): cast info on any unit but the player
  and their pet is secret under restrictions, including `notInterruptible`, the names, the texture and
  the times; `castBarID` and `delayTimeMs` are never secret. Compound tokens (`party1target`) are
  secret whenever any link fails the identity test, and comparisons involving them are **always**
  secret — `UnitIsUnit("party1target", …)` can never be branched on. Code as if always secret.
- **APIs present in 12.0+**: `UnitCastingDuration`, `UnitChannelDuration`,
  `UnitEmpoweredChannelDuration`, `StatusBar:SetTimerDuration(d, interpolation, direction)` /
  `GetTimerDuration`, `UnitHealthPercent(unit, usePredicted, curve)`, `C_CurveUtil`,
  `SetAlphaFromBoolean` / `SetVertexColorFromBoolean`, `issecretvalue`. After
  `SetAlphaFromBoolean`, `GetAlpha()` answers a secret — track our own alpha state instead.
- **Interface.** EllesmereUI's client gate and both reference addons target 120100; so do we.

---

## 3. UX spec

### 3.1 What the player sees

Three kinds of element, five units each (player, party1–4):

**Cast bar.** A status bar with an optional spell icon (left or right), the spell name, and the time
remaining. Colors by cast type — cast, channel, empowered — with a distinct color and a small shield
for a cast that cannot be interrupted. On stop it hides; on **interrupted** or **failed** it holds
briefly in red with the word *Interrupted* / *Failed*, then fades. A spark rides the fill edge.

**Target frame.** A compact bar showing the member's current target: a health bar in the target's
class color (players) or reaction color (NPCs), the target's name, and an optional health
percentage. A raid marker if the target has one. Clicking it targets that unit (on by default).

**Pet frame.** A compact bar for the member's pet: health bar (pet color or the owner's class
color), the pet's name, optional health percentage. Clicking it targets the pet (on by default).

Nothing is drawn for a unit that doesn't exist, isn't casting, has no target or has no pet.

### 3.2 Where elements go — the anchoring model

Each feature has one **anchor mode**, chosen on its page:

**Attached** (default). Each unit's element is pinned to the party frame currently showing that
unit. Five controls describe the pin, shared by all five units of the feature:

- *Anchor point* — the point on the element (9-point dropdown).
- *Party frame point* — the point on the party frame it pins to (9-point dropdown).
- *X / Y offset* — pixels.
- *Match party frame width* — the element takes the party frame's width (height stays yours).

Defaults put the cast bar under the party frame, full width; the target frame to the right of it;
the pet frame under the cast bar area, left-aligned. When a unit has no visible party frame (classic
Blizzard mode for the player, hidden party frames, solo play) that unit's attached element is simply
not shown.

**Free placement.** The feature's five elements stack in one movable group, independent of any party
frame. Controls: *Growth direction* (down, up, right, left), *Spacing*, *Width*, *Height*, and
*Include player*. Unlock the addon and drag the group; its position is saved per profile.

A frame-system picker on the General page chooses **Automatic** (EllesmereUI when its party frames
are active, else Blizzard), **Blizzard**, or **EllesmereUI**, and shows which system was detected.

### 3.3 Unlock and preview

*Lock frame* on Master controls (and `/pfe lock` / `/pfe unlock`) toggles **preview mode**:

- Every enabled element shows placeholder content through the real render path: a cast bar
  mid-cast with a sample spell, a target frame with a sample hostile NPC at 65%, a pet frame at 80%.
- Attached elements preview on whichever party frames exist. With no party frames visible (solo,
  hidden), the preview uses the feature's free-placement stack so something is always draggable.
- Free-placement groups show a drag handle and can be moved.
- Re-locking clears every placeholder and returns to live data (preview-mode MUST).
- Unlocking in combat is refused with a gray notice, because the clickable frames are secure and
  their visibility drivers can't change in combat.

`/pfe preview` does the same thing without touching the lock (for checking a style mid-session).

### 3.4 Settings panel

Ka0s layout: landing page plus subcategories, every page tabbed (options-ui-§13).

- **Ka0s Party Frame Enhanced** (landing): logo, tagline, the slash command list.
- **General**
  - *Master controls*: Enable Party Frame Enhanced · General visibility / Master scale · Master alpha
    / Lock frame · Debug console / Reset position · Reset all settings.
  - *Party frames*: Frame system (Automatic / Blizzard / EllesmereUI) · Detected system (read-only
    label) / Include player's own row.
- **Cast Bars** — tabs *General* (enable, show when not casting in preview), *Position* (anchor mode,
  the attached pin, the free stack), *Bar* (bar group + cast/channel/empower/uninterruptible/failed
  colors), *Border* (border group), *Text* (font group + show spell name, show time, time format),
  *Icon* (show, side, size).
- **Target Frames** — *General* (enable, click to target, health refresh interval). No "hide when
  the target is me" option: `UnitIsUnit` on a compound token is always secret, so it cannot be
  decided in Lua. *Position*, *Bar* (bar group + color by class/reaction), *Border*, *Text* (font group + show name,
  show health %), *Marker* (show raid marker, size).
- **Pet Frames** — *General* (enable, click to target), *Position*, *Bar*, *Border*, *Text*.
- **Profiles** (AceDBOptions).

Font, border and bar blocks come from the library's composers. The cast-type colors are a palette
(one color per cast state) and so carry no class-color companion (options-ui-§17 exemption); the
target and pet bar colors do carry one, resolved to the **tracked unit's** class.

### 3.5 Slash commands

`/pfe` and `/partyframeenhanced`, through `LibKa0s-Slash-1.0`. Reserved verbs mean what they mean
everywhere: `help config list get set reset resetall debug perf version`. Addon verbs: `lock`,
`unlock`, `preview` (toggle), `resetposition`, `status` (detected frame system, unit → frame map,
element counts), `profile …` (the AbsorbTracker sub-verb set).

That is fourteen verbs, so `docs/slash-dispatch.md` ships (Tier 2 trigger: eight or more).

---

## 4. Module map

Modular layout (layout-§1). File names are the plan; one-line responsibilities.

| File | Responsibility |
|---|---|
| `core/Namespace.lua` | `NS.name`, `NS.version`, `NS.PREFIX` = cyan `[PFE]` |
| `core/Compat.lua` | Every version-variant client call: cast durations, curve/boolean helpers, secret checks, unit comparison, health percent, raid marker, EditMode raid-style query |
| `core/EnvSetup.lua` | `LibKa0s-Env-1.0` seam: `NS.Meta`, `NS.Version` |
| `core/MediaSetup.lua` | `LibKa0s-Media-1.0` seam: `NS.Icon`, `NS.MediaFont`, `RegisterLSM` — before Constants |
| `core/Constants.lua` | Fallback media, `FONT_MONO`, logo path, unit list, anchor point list, timings |
| `core/State.lua` | Session state: `debug`, `inCombat`, `preview` |
| `core/Bus.lua` | `NS.bus`, `NS.NewBusTarget`, the `NS.MSG` catalog, one publisher function per message |
| `core/CoreSetup.lua` | `LibKa0s-Core-1.0` seam: printer, stringifier, class-color resolver, `NS.MakeCloseButton` |
| `core/PoolSetup.lua` | Not wired in v0.1.0: 15 fixed elements are pre-created, nothing churns (§9 register) |
| `core/PerfSetup.lua` | `LibKa0s-Perf-1.0` seam: buckets, suspend/resume |
| `core/DebugLogSetup.lua` | `LibKa0s-DebugLog-1.0` seam: `NS.Debug` |
| `core/Units.lua` | The five tracked units, their target and pet tokens, labels, include rules |
| `core/Database.lua` | AceDB init, migrations, profile callbacks |
| `core/PartyFrameEnhanced.lua` | AceAddon promotion, lifecycle, combat flag, deferred secure-write queue, sleep gate |
| `defaults/Profile.lua` | Every profile default |
| `modules/Providers.lua` | Frame-system providers (Blizzard raid-style, Blizzard classic, EllesmereUI), detection, `unit → frame` map, refresh triggers; publishes `LAYOUT` |
| `modules/Anchor.lua` | The anchoring engine shared by the three features: attached pin, free stack, memoized `SetPoint`, drag, combat-deferred re-anchor for secure elements |
| `modules/Element.lua` | Shared element chrome: background, border, fonts, the preview contract |
| `modules/CastBars.lua` | Cast bar elements and their events |
| `modules/TargetFrames.lua` | Target frame elements, `UNIT_TARGET`, the health ticker |
| `modules/PetFrames.lua` | Pet frame elements, `UNIT_PET` / pet health events |
| `modules/Preview.lua` | Placeholder data and the preview toggle |
| `settings/Schema.lua` | Registry, lookup, the single write seam, validation |
| `settings/Slash.lua` | `NS.COMMANDS` + the Slash descriptor |
| `settings/OptionsSetup.lua` | Options descriptor + load-completing stub |
| `settings/About.lua` | Landing page body |
| `settings/General.lua`, `CastBars.lua`, `TargetFrames.lua`, `PetFrames.lua`, `Profiles.lua` | One page each |
| `settings/ElementRows.lua` | The shared Position / Border / Text row builders the three feature pages reuse |

A file past ~600 lines is split before it grows further; the standard's cap is ~1500.

---

## 5. Unit model and providers

### 5.1 Units

`NS.Units.LIST = { "player", "party1", "party2", "party3", "party4" }`. Each unit has:

- a **target token**: `target` for the player, `partyNtarget` otherwise;
- a **pet token**: `pet` for the player, `partypetN` otherwise;
- a label for the CLI and debug lines.

The player row is included when the General page's *Include player's own row* is on **and** either
the active frame system shows the player (attached) or the feature is in free placement.

### 5.2 Provider contract

```lua
Provider = {
  id = "blizzard-raid" | "blizzard-party" | "ellesmere",
  label = "…",
  priority = number,                 -- higher wins in Automatic
  IsAvailable = function() end,      -- the frames exist (addon loaded / globals present)
  IsActive = function() end,         -- its party frames are currently shown
  ForEachFrame = function(cb) end,   -- cb(frame) for each candidate member frame
  InstallHooks = function(onChange) end, -- hooksecurefunc/HookScript only; idempotent
}
```

`Providers.Resolve()` picks the provider (Automatic: highest-priority active one; manual: that one
if available), then builds `unitToFrame` by reading each visible frame's unit —
`frame.displayedUnit`, `frame.unit`, then `frame:GetAttribute("unit")`, each rejected if secret —
and normalizing a `raidN` token to `player`/`partyN` through a guarded `UnitIsUnit`
(`C_Secrets.CanCompareUnitTokens` first, where it exists). A frame is visible when `IsVisible()`
answers true and plain; a secret or erroring answer counts as visible (fail open, as both references
do).

If the new map differs from the last one, Providers publishes `Ka0s_PartyFrameEnhanced_LayoutChanged`
with no payload; consumers read `NS.Providers.FrameFor(unit)`.

### 5.3 When it resolves

A **coalesced request**: any trigger sets a flag and schedules one pass on the next frame, plus
follow-ups at 0.1 s and 0.5 s for frames that settle late. Triggers:

- `GROUP_ROSTER_UPDATE`, `PLAYER_ENTERING_WORLD`, `PLAYER_REGEN_ENABLED`;
- `EDIT_MODE_LAYOUTS_UPDATED`, and (pcall-registered) `EDIT_MODE_LAYOUT_APPLIED`;
- `ADDON_LOADED` for `EllesmereUI` / `EllesmereUIRaidFrames`;
- `hooksecurefunc` on `CompactPartyFrame.RefreshMembers`, `PartyFrame.UpdateMemberFrames` (where
  present) and EllesmereUI's notify/reload functions (by shape, never assumed);
- `OnShow` / `OnHide` hooked once per discovered member frame;
- the General page's frame-system setting.

It never calls a Blizzard update function itself (the PartyCastBars 1.0.2 taint lesson).

### 5.4 Sleep gate

In a raid (`IsInRaid()`), or while every feature is disabled or suspended, Providers stops
resolving and every element hides. Solo play is not asleep: free-placement elements for the player
still work (a player cast bar solo is legitimate), attached elements find no frames and stay hidden.

---

## 6. Features

### 6.1 Shared element model (`modules/Element.lua`)

Every element is a frame with: background texture, a `BackdropTemplate` border child, a status bar,
text regions, and a `preview` flag. Styling is applied by `Element.Reskin(el, cfg)` — config-driven
work only, memoized on a signature of the fields it reads (the KickCD F-015 lesson). Live data is
applied by each feature's `Render*` — no config reads on the hot path; config is cached into module
upvalues by `RefreshUpvalues()` on `CONFIG_CHANGED` (events-frames-taint-§7).

Master scale and alpha multiply into each element's own size/alpha at reskin.

### 6.2 Cast bars (`modules/CastBars.lua`)

- **Frames**: five non-secure `StatusBar`s, parented to UIParent, created at `OnEnable`.
- **Events**: one small event frame per unit with `RegisterUnitEvent` for `UNIT_SPELLCAST_START`,
  `_STOP`, `_FAILED`, `_INTERRUPTED`, `_DELAYED`, `_CHANNEL_START`, `_CHANNEL_STOP`,
  `_CHANNEL_UPDATE`, `_EMPOWER_START`, `_EMPOWER_STOP`, `_EMPOWER_UPDATE`, `_INTERRUPTIBLE`,
  `_NOT_INTERRUPTIBLE`. Registered only while the feature is enabled and the unit is included;
  unregistered on suspend. No global `UNIT_SPELLCAST_*` registration anywhere.
- **Start / update**: read `UnitCastingInfo` or `UnitChannelInfo` for name, texture and
  `notInterruptible` only; fetch the duration object through `Compat.CastDuration(unit, kind)`;
  `bar:SetTimerDuration(d, Immediate, Elapsed|Remaining)`. Pushback (`DELAYED`,
  `CHANNEL_UPDATE`, `EMPOWER_UPDATE`) re-fetches and re-applies.
- **Fallback** when `SetTimerDuration` is absent: KickCD's pattern, `SetMinMaxValues(0,
  d:GetTotalDuration())` once and `SetValue(d:GetElapsedDuration())` in a bar-local OnUpdate.
- **Time text**: a bar-local OnUpdate that exists only while casting **and** time text is on,
  throttled to 10 Hz, calling `SetFormattedText(fmt, d:GetRemainingDuration())` — the value is
  never bound to a local.
- **Interruptibility**: `shield:SetAlphaFromBoolean(notInterruptible, 1, 0)`; the fill color's four
  channels from `C_CurveUtil.EvaluateColorValueFromBoolean(notInterruptible, uninterruptibleX,
  normalX)` into `SetStatusBarColor`. Re-applied on the two interruptibility events. Nothing branches
  on the flag in Lua.
- **Stop / interrupted / failed**: plain events decide. Stop hides (fade-out optional); interrupted
  and failed hold 0.5 s in the failed color with the word, then fade.
- **Stale bars**: the reference polled every frame to catch a missed stop under CC. We instead
  re-check `UnitCastingInfo(unit) == nil and UnitChannelInfo(unit) == nil` (nil-ness is never
  secret) on the time-text tick and on `UNIT_SPELLCAST_STOP` siblings; a bar with neither hides.
- **Which cast an event is about**: the stored `castBarID` (never secret) — not `castID` or
  `spellID`, which can be.
- **Secret strings**: `name` and `texture` go straight to `SetText` / `SetTexture`. Truncation is
  skipped when the name is secret (KickCD's rule).

### 6.3 Target frames (`modules/TargetFrames.lua`)

- **Frames**: five `Button`s from `SecureUnitButtonTemplate`, created at `OnEnable` (out of combat,
  always — never lazily). Attributes: `unit = <targetToken>`, `*type1 = target`, `*type2 = togglemenu`
  (menu off by default? — *verify* the Midnight menu attribute). `RegisterForClicks("AnyUp")`.
- **Visibility**: a secure **state driver** per frame, not `RegisterUnitWatch`, so the addon's own
  gates fold into the macro condition — e.g. `[@party1target,exists] show; hide` for *Always*,
  prefixed with `[nocombat] hide;` for *Only in combat*. Built by one function from the current
  settings; applied out of combat only; queued for `PLAYER_REGEN_ENABLED` otherwise. Preview uses
  `show`.
- **Content** (insecure regions on the secure button are fine to update in combat): name, health bar,
  percent, raid marker, colors. Updated on `UNIT_TARGET` for the owner (per-unit registration on
  player/party1–4), on `RAID_TARGET_UPDATE`, and by the **health ticker**.
- **Health ticker**: `partyNtarget` tokens get no `UNIT_HEALTH`, so one shared `C_Timer.NewTicker`
  (default 0.2 s, a setting) refreshes health on the target frames that are shown. It is created
  when the first target frame shows and canceled when none is shown, when the feature is disabled
  and on suspend. Health goes to `SetMinMaxValues(0, UnitHealthMax(t))` + `SetValue(UnitHealth(t))`
  — secret-safe C methods; percent through `Compat.HealthPercent`. The ticker skips a frame whose
  target GUID is unchanged **and** whose health call returns the same plain value; secret values are
  always pushed (they cannot be compared).
- **Color**: players by class (`RAID_CLASS_COLORS` via the library resolver), NPCs by
  `UnitReaction` (hostile/neutral/friendly swatches), each guarded; unknown → the stored swatch.

### 6.4 Combat and the secure frames

The hard constraint: Blizzard raid-style and EllesmereUI **re-assign which frame shows which member
during combat** (a join, a leave, a role re-sort), in secure code we can't follow with secure code of
our own without wrapping another addon's frames.

- **Elements bind to a unit, not to a frame slot.** A unit-bound target frame always shows the right
  member's target (`party2target` is party2's target whatever frame shows party2). A slot-bound one
  would keep a stale `unit` attribute and show the wrong member's target — worse.
- **Cast bars are not secure and follow the live map in combat**: a `LAYOUT` message re-anchors them
  immediately.
- **Secure frames are anchored with `SetPoint` out of combat only.** A `LAYOUT` message during combat
  checks each secure element: if its anchor frame no longer shows its unit, the element's content is
  faded to alpha 0 (alpha is not a protected operation) and the element is marked dirty;
  `PLAYER_REGEN_ENABLED` re-anchors it and restores the alpha. So a mid-combat reshuffle costs a
  briefly missing frame, never a frame beside the wrong member. Blizzard classic mode never reshuffles.
- **Created at enable, never later.** All ten secure buttons exist from `OnEnable` (out of combat),
  whether or not the feature is on.
- Attribute and state-driver changes (a setting, lock/unlock, enable) go through one deferred-write
  queue in `core/PartyFrameEnhanced.lua` (events-frames-taint-§2).
- Deferred to an issue: `SecureHandlerWrapScript` on the frame system's member frames, so restricted
  code re-anchors in combat — possible in principle, untested for taint against EllesmereUI.

### 6.5 Pet frames (`modules/PetFrames.lua`)

Same secure-button pattern as target frames with pet tokens (`pet`, `partypet1..4`). Events:
`UNIT_PET` (owner-unit registration), and per pet token `UNIT_HEALTH`, `UNIT_MAXHEALTH`,
`UNIT_NAME_UPDATE` via `RegisterUnitEvent` on one small frame per pet unit. No ticker needed. Color:
a pet color swatch, with a class-color companion resolving to the **owner's** class.

### 6.6 Preview (`modules/Preview.lua`)

Owns `NS.State.preview`. Toggling publishes `VISIBILITY`; each feature's show-decision ladder reads
the flag and, when on, renders placeholder values through its normal render function. Preview for
secure frames switches their state driver to `show` (out of combat only).

### 6.7 The show-decision ladder

Evaluated per element, in this order; the first failing rung hides it.

0. `NS.Perf.suspended` — step 0, so nothing re-shows behind suspend's back (performance-§6).
1. Master *Enable*.
2. Feature *Enable*.
3. Preview → show (with placeholders) and stop here.
4. General visibility (`always` / `inCombat` / `outOfCombat` / `never`) against `NS.State.inCombat`
   (event-driven, from the regen events).
5. The unit is included (player rule) and exists.
6. Attached mode: `Providers.FrameFor(unit)` is non-nil and visible.
7. The feature's own condition: casting / has a target / has a pet.

For the secure features, rungs 4–7 are expressed in the state driver; rungs 0–3 decide which
driver string is installed.

---

## 7. Midnight secret-value rules (binding on every module)

1. Never compare, do arithmetic on, format in Lua, concatenate, or `tostring`-then-use a value from
   `UnitCastingInfo`, `UnitChannelInfo`, a duration object, `UnitHealth`, `UnitHealthMax`,
   `UnitName`, `UnitIsUnit`, `UnitReaction`, `UnitClass`, frame attributes read off another addon's
   secure frames, or `IsVisible`/`IsShown` on those frames.
2. Pass such values **directly** to C methods that accept them: `SetText`, `SetTexture`,
   `SetValue`, `SetMinMaxValues`, `SetTimerDuration`, `SetFormattedText`, `SetAlphaFromBoolean`,
   curve evaluators.
3. Where a branch is unavoidable (unit resolution, reaction color), test with `Compat.IsSecret(v)`
   first and treat a secret as *unknown*, falling back to the documented default.
4. Nil-ness is plain: `UnitCastingInfo(u) == nil` is safe.
5. Every debug line goes through `NS.Debug` with the format deferred; the library stringifier
   replaces secrets with `<secret>`.
6. `C_Secrets.*` is looked up at call time behind a nil guard (12.0.x may lack members 12.1 has).

---

## 8. Settings schema (profile)

Paths are flat per feature. Composed blocks keep the composer's canonical leaf names.

```text
enabled, visibility, scale, alpha, locked                       -- Master controls
general.provider   = "auto" | "blizzard" | "ellesmere"
general.includePlayer = true

castbar.enabled = true
castbar.anchorMode = "attached" | "free"
castbar.point = "TOP", castbar.relativePoint = "BOTTOM", castbar.offsetX = 0, castbar.offsetY = -2
castbar.matchWidth = true, castbar.width = 120, castbar.height = 14
castbar.growth = "DOWN", castbar.spacing = 4, castbar.position = {point, x, y}   -- free stack
castbar.barTexture, barAlpha, barColor, useClassColorBar                         -- BarGroup
castbar.channelColor, empowerColor, uninterruptibleColor, failedColor            -- palette
castbar.borderShow, borderStyle, borderSize, borderColor, useClassColorBorder    -- BorderGroup
castbar.font, fontSize, fontColor, useClassColorFont, fontFlags, fontShadow      -- FontGroup
castbar.showName = true, castbar.showTime = true, castbar.timeFormat = "remaining"
castbar.showIcon = true, castbar.iconSide = "LEFT", castbar.showShield = true
castbar.fadeOut = true

target.enabled = true, target.clickToTarget = true, target.tickInterval = 0.2
target.anchorMode, point, relativePoint, offsetX, offsetY, matchWidth, width, height,
       growth, spacing, position                                                 -- as castbar
target.bar* (BarGroup), target.colorBy = "classReaction" | "static"
target.hostileColor, neutralColor, friendlyColor                                 -- palette
target.border* (BorderGroup), target.font* (FontGroup)
target.showName = true, target.showPercent = true, target.showMarker = true

pet.enabled = true, pet.clickToTarget = true
pet.anchorMode … position                                                        -- as castbar
pet.bar* (BarGroup), pet.border* (BorderGroup), pet.font* (FontGroup)
pet.showName = true, pet.showPercent = false
```

- `*.position` is **named non-setting state** (architecture-§5): written only by the drag handler in
  `modules/Anchor.lua` and cleared by `Anchor.ResetPositions` (the *Reset position* button,
  `/pfe resetposition`). `docs/ARCHITECTURE.md` → Settings Schema names the key, the owner and the
  writers.
- `global.schemaVersion = 1`; the migration runner ships empty.
- The debug console row is `sessionOnly` (`state.debugConsole`).

---

## 9. Message bus, perf buckets, debug tags

### 9.1 Messages (`Ka0s_PartyFrameEnhanced_*`, one sender each)

| Message | Sender | Payload | Consumers |
|---|---|---|---|
| `LayoutChanged` | `modules/Providers.lua` | none | CastBars, TargetFrames, PetFrames (re-anchor via Anchor) |
| `ConfigChanged` | `settings/Schema.lua` write seam | section: `"castbar" \| "target" \| "pet" \| "general" \| "master"` | the three features, Providers (general) |
| `VisibilityChanged` | `core/PartyFrameEnhanced.lua` (combat, enable, profile, suspend/resume, preview via `NS.PublishVisibility`) | none | the three features |
| `ProfileChanged` | `core/PartyFrameEnhanced.lua` | none | the three features, Providers, Anchor |

Four messages, so `docs/message-bus.md` is *Not applicable* (Tier 2 trigger: more than ten).

### 9.2 Perf buckets (declared, with nesting)

| Bucket | Within | Where |
|---|---|---|
| `resolve` | — | `Providers.Resolve` |
| `anchor` | `resolve`? no — root | `Anchor.Apply` per feature pass after a LAYOUT |
| `castEvent` | — | cast event handler |
| `castRender` | `castEvent` | start/update render |
| `castTick` | — | time-text OnUpdate (throttled) |
| `targetEvent` | — | `UNIT_TARGET` handler |
| `targetTick` | — | the health ticker pass |
| `targetRender` | `targetTick` | per-frame refresh inside the ticker (also reached from `targetEvent`; declared under the ticker, the hotter parent) |
| `petEvent` | — | pet event handler |
| `reskin` | — | config-driven restyle |

`tests/perf.lua` pins every bucket reached, the zero-overhead scenario, allocation ceilings for the
hot paths (cast start burst, ticker pass, roster resolve), and the coalescing invariant (N triggers →
one resolve).

### 9.3 Debug tags

`[Init]`, `[Set]`, `[Profile]`, `[Migrate]`, `[Provider]` (one line per resolve that changed the
map: system, units found), `[Anchor]` (one summary line per pass), `[Cast]` (start/stop per unit,
gated), `[Target]`, `[Pet]`, `[Combat]` (enter/leave rollup: casts, ticker passes, deferred writes),
`[Secure]` (a deferred write queued/flushed), `[Preview]`.

---

## 10. Deferred work (filed as GitHub issues)

1. Raid-frame support (Blizzard `CompactRaidFrame*`, EllesmereUI raid headers) — sleep today.
2. More frame systems: ElvUI, Cell, Grid2, VuhDo, DandersFrames.
3. Re-anchor secure target/pet frames during combat via a secure-handler snippet.
4. Empowered-cast stage markers.
5. Per-unit style overrides.
6. Cast target name ("→ Tank") on the cast bar.
7. Auras (debuffs) on target frames; target-of-target.
8. Anchor the player's row to `PlayerFrame` in classic Blizzard mode.
9. Localization: deDE/frFR/… translations of the `NS.L` keys.
10. A logo with real art (v0.1.0 ships a generated placeholder).
11. Arena frames.
12. LibKa0s upstream candidates noticed during the build (none filed against LibKa0s itself — this
    effort makes no library changes; each becomes a PFE issue labeled for later promotion).

---

## 11. Risks

| Risk | Mitigation |
|---|---|
| A 12.x API named here doesn't exist on the player's build (`SetTimerDuration`, `UnitCastingDuration`, `C_Secrets`, `UnitHealthPercent`, `SetAlphaFromBoolean`) | Every one is reached through `core/Compat.lua` with a nil guard and a fallback; smoke-test step per API |
| EllesmereUI renames its frames or namespace | Discovery by shape plus global-name fallback; failure means "EllesmereUI not detected", never an error |
| Secure frame taint | Buttons created at enable, never in combat; attributes and drivers via the deferred queue; no Blizzard function called, only `hooksecurefunc`/`HookScript` |
| Target health cost | One gated ticker, only shown frames, change-skip on plain values; measured by `targetTick` |
| Blizzard classic party frames have no player frame | Documented; free placement covers it; issue #8 |
| Frame systems re-sort in combat | Unit-bound elements; insecure ones follow live, secure ones fade until regen (§6.4) |
| EllesmereUI has no public layout callback | Events + `HookScript` on its header children; smoke step per EllesmereUI option (self first, hide self, sort mode) |
