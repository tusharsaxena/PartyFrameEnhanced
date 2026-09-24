# Architecture — Ka0s Party Frame Enhanced

The engineer's hub. Each section summarizes and links to its topic doc; the design record behind it is
[superpowers/specs/2026-09-15-party-frame-enhanced-design.md](superpowers/specs/2026-09-15-party-frame-enhanced-design.md),
and the build's progress is the ledger in
[superpowers/plans/2026-09-15-party-frame-enhanced-v0.1.0.md](superpowers/plans/2026-09-15-party-frame-enhanced-v0.1.0.md).

## Overview

Party Frame Enhanced adds a **cast bar**, a **target frame** and a **pet frame** for the player and
party1–party4. Each feature either attaches its five elements to the party frame currently showing
each unit — Blizzard classic, Blizzard raid-style or EllesmereUI, detected by a provider layer — or
stacks them in one movable free-placement group. Every element fades with its party member's frame
when that member is out of range (`modules/RangeFade.lua`). What it deliberately leaves out is
[scope.md](scope.md).

It is **party-only**: solo or in a raid it shows nothing and registers nothing. `/pfe unlock` previews
it anyway, on the real party frames in a party and on a stand-in party frame out of one
([the design](superpowers/specs/2026-09-15-test-mode-design.md)).

Substrate: Ace3 (AceAddon, AceEvent, AceTimer, AceConsole, AceDB, AceGUI, AceConfig + AceDBOptions
for the Profiles page only), LibSharedMedia-3.0 and AceGUI-3.0-SharedMediaWidgets for media pickers,
and **LibKa0s v1.55.0** vendored whole, plus **LibDataBroker-1.1** and **LibDBIcon-1.0** for the
launcher. The addon consumes eleven LibKa0s majors through one setup file each — Media
(`core/MediaSetup.lua`), Env (`core/EnvSetup.lua`), Core (`core/CoreSetup.lua`), Compat
(`core/Compat.lua`, the `IsSecret` guard only), Bus (`core/Bus.lua`), Lifecycle
(`core/LifecycleSetup.lua`), Perf (`core/PerfSetup.lua`), DebugLog (`core/DebugLogSetup.lua`),
Launcher (`core/LauncherSetup.lua`), Slash (`settings/Slash.lua`) and Options
(`settings/OptionsSetup.lua`). **Pool, Item and Widgets are vendored, not wired**: fifteen elements
are created once at enable and never churn (so no pool), the addon handles no items, and it orders
nothing (so no reorder list). **Schema is vendored and not adopted yet** (#14): the Schema document's
library-less stub refuses a path with no row. On that build the Master controls composer is hollow,
so `/pfe enable`, `/pfe disable` and `/pfe lock` would stop writing (`tests/test_schema.lua` pins
it). `settings/Schema.lua` keeps its own runtime until that is settled upstream.

Build status: v1.0.1 is the latest release, shipped with the offline perf pass, the release-candidate
record, the first standards audit, the in-game smoke pass and the first party perf captures done.
Master carries unreleased work since that tag, waiting for the next version bump: every element fades
with its party member's frame when they are out of range; the raid marker draws above the border,
pet frames get one, and its default anchor is Top; the Size & Position section draws only the
placement block the anchor mode uses; and LibKa0s is re-vendored, now at v1.55.0. What the addon
took from that run is v1.46.1's settings-page combat lock, and v1.55.0's Bus and Compat majors
([revendor/2026-09-23-v1.55.0/](revendor/2026-09-23-v1.55.0/05_SUMMARY.md)). v1.47.0 to v1.54.2 is the drag-handle
widget and the `O.IdList` / `O.IdInput` run, and this addon draws neither.

## Module Map

Thirty-eight files load, in the fixed folder order `libs → locales → core → defaults → modules →
settings`. The load-bearing positions are Namespace (publishes `NS.PREFIX`), MediaSetup before
Constants (`FONT_MONO`), CoreSetup before anything that prints, LifecycleSetup before PerfSetup (which requires the latch),
PerfSetup before every module that captures `NS.Perf`, DebugLogSetup after its three inputs, Providers first among the modules, RangeFade before the features that parent to it, Element
and UnitButtons before the features that capture them, StandIn before Preview and Preview after every
feature, Schema before
every settings file, and OptionsSetup and ElementRows before every page; the TOC comments each one and
`tests/test_loadorder.lua` pins the ones a mistake would break silently. Full table:
[module-map.md](module-map.md).

## Settings Schema

One schema (`settings/Schema.lua`) drives the panel, the CLI and the resets, and **one write seam** —
`NS.SetByPath` — carries every write to a schema path: the panel (the Options descriptor's `set` /
`applyDefault`), `/pfe set`, `/pfe lock`/`unlock` and every reset. The seam asks the row's `validate`
first (the lock refuses an unlock in combat there, before anything is stored), then stores the value,
runs the row's `onChange`, logs one `[Set]` line (one per bulk act), and publishes `CONFIG(<section>)`.

- **Structural registries:** none. The player creates and deletes nothing.
- **Named non-setting state:** `castbar.position`, `target.position` and `pet.position` — each
  feature's free-placement anchor, written only by a drag. Owner: `modules/Anchor.lua`; writers: its
  drag-stop handler and `Anchor.ResetPositions` (the *Reset position* button, `/pfe resetposition`).
- **Session-only rows:** `state.debugConsole` (the console window's visibility) — one row, not two.
  `state.testMode` was the second until options-ui-§15 exempted this addon from the Test mode row:
  unlocking already is its preview.
- **Global rows:** `global.minimap.hide` (the launcher's minimap button) — stored, not session-only,
  but in the **account-wide** store rather than the profile, because launcher-§3 fixes LibDBIcon's own
  table there. `settings/Schema.lua` carries a global registry beside the session one, and
  `settings/General.lua` registers the get/set that invert the row's SHOWN sense onto LibDBIcon's
  `hide` and call `NS.Launcher:SetShown`. The validator resolves such a path against `NS.defaults`
  rather than `defaults.profile`, and the profile-reset tally skips it. **A global row survives every
  reset the panel ships** — *Reset all settings* and a page's own **Defaults** button — because
  launcher-§3 makes that a property of the setting; `settings/OptionsSetup.lua`'s `exemptFromReset`
  is the one place that says so, and the descriptor's `applyDefault` is where it bites, that being
  the single call both resets make. `/pfe reset <path>` is unaffected.

Shapes, defaults and the migration ladder: [schema.md](schema.md). The panel tree:
[settings-panel.md](settings-panel.md). Profiles: [profiles.md](profiles.md).

## Message Bus

Closed bus on AceEvent messages (`core/Bus.lua`); each receiver registers on its own
`NS.NewBusTarget()`, and every message has exactly one sending file (`tests/test_bus.lua` reads the
source to check).

The stand-down record is **`LibKa0s-Bus-1.0`** (`libs/LibKa0s/Bus.lua`, `docs/api/Bus/version-1-docs.md`
in LibKa0s). `core/Bus.lua` builds one record with `Bus:New{ name, isDown }`, where `isDown` asks
`NS.IsStoodDown` at call time, and keeps the host's names as one-line delegates: `NS.NewBusTarget`
(a tracked target per receiver), `NS.BusStandDown` (events and messages down, the record kept) and
`NS.BusStandUp` (the record replayed as it is now; an entry the client refuses is named on the debug
console). A registration a receiver makes while the addon is stood down is recorded and goes live at
the stand-up. `NS.MSG` is `Bus.Catalog(addonName, {...})`: validated once at load, and strict, so a
mistyped key raises at the call site. The publisher `NS.bus` stays host code. Without the library,
`core/Bus.lua` falls back to the untracked-target stub the Bus document prescribes (see Known
Limitations).

| Message | Sender | Payload | Consumers |
|---|---|---|---|
| `Ka0s_PartyFrameEnhanced_LayoutChanged` | `modules/Providers.lua` | none | Anchor (re-places every feature), CastBars, TargetFrames, PetFrames (re-decide visibility), RangeFade (re-hooks and re-seeds each unit's fade) |
| `Ka0s_PartyFrameEnhanced_ConfigChanged` | `settings/Schema.lua` (the write seam) | section: `master` / `general` / `castbar` / `target` / `pet` | CastBars, TargetFrames, PetFrames (their own section, `master`, `general`); Anchor (a feature's section, `master`, `general`); Providers, RangeFade (`general`, `master`) |
| `Ka0s_PartyFrameEnhanced_VisibilityChanged` | `core/PartyFrameEnhanced.lua` (`NS.PublishVisibility`) | none | CastBars, TargetFrames, PetFrames, RangeFade |
| `Ka0s_PartyFrameEnhanced_ProfileChanged` | `core/PartyFrameEnhanced.lua` | none | CastBars, TargetFrames, PetFrames, Providers, Anchor, RangeFade |

## Slash Commands

`/pfe` and `/partyframeenhanced`, seventeen verbs in `NS.COMMANDS` — the twelve reserved ones
(`enable` and `disable` among them, aliases for the `enabled` row and never a second switch) plus
`resetposition`, `lock`, `unlock`, `status` and `profile`. The dispatcher is registered in
`OnInitialize` in either state, so `/pfe` answers while the addon is disabled and the pair is never
one-way (slash-commands-§2). What it answers then is the **whole reserved set, behaving normally** —
and the bare `/pfe` opens the settings panel, which is the case that settled the standard's v2.57.0
reversal of an earlier narrowing. The gate is `LibKa0s-Slash-1.0`'s: `settings/Slash.lua` hands it an
`isEnabled` reader, a `brandName` and the live set (`LIVE_WHILE_DISABLED`, the twelve plus this
addon's `status` and `profile`), and the library refuses everything else on one line it owns the
wording of. The three verbs that drive what this addon draws — `resetposition`, `lock`, `unlock` —
are what is left. Table and behavior: [slash-dispatch.md](slash-dispatch.md).

## Launcher

**One object, registered twice** (launcher-§1). `core/LauncherSetup.lua` builds a single
LibDataBroker-1.1 object of `type = "launcher"` through `LibKa0s-Launcher-1.0` and hands it to
LibDBIcon-1.0: LibDBIcon draws the minimap button from it and any broker display (Titan Panel,
ElvUI data texts, Bazooka) draws its own row from the very same object, so there is one `OnClick`,
one icon, one label and one identity.

| | |
|---|---|
| Owner | `core/LauncherSetup.lua` (`NS.Launcher`), an instance of `LibKa0s-Launcher-1.0` |
| Name | `PartyFrameEnhanced`, the **folder** name, on **both** registrations — LibDBIcon keys the button's saved position by it, so a second spelling would drop the angle the player dragged it to |
| Icon | `media/logos/partyframeenhanced.logo.128.tga`, the same file the TOC's `## IconTexture` names (launcher-§4, layout-§4): 128×128, uncompressed 32-bit |
| Label | `Ka0s Party Frame Enhanced` — the **brand name in plain text** (launcher-§1). It is what a broker display prints in its row, beside the collection's other ten, so it carries the shared `Ka0s ` prefix and **no escape sequence**. Deliberately not the TOC `## Title` (a Title may carry color escapes) and not the folder name (that is the registration *Name* above); the two are never wired to each other |
| Left click | **rung (b)** — `NS.ToggleLock`, the addon's existing preview switch. Unlocking *is* the preview here (options-ui-§15's exemption), and the launcher drives the same `locked` row the Lock frame checkbox and `/pfe lock` / `/pfe unlock` drive, through `NS.SetByPath`, holding no copy of that state. **Refused while the addon is disabled** (launcher-§2): a preview switch is a feature, so it prints `cli:DisabledLine()` — the same line the slash gate prints, never re-spelled — and does nothing else, writing no SavedVariables. Rung (c)'s carve-out does not reach it |
| Right click | **always** `NS.OpenOptionsPanel` — on this addon as on every other, in **either** state. The ruling narrows the *slash* surface and a mouse click is not a slash command; this click is one of the two routes that keep the panel reachable |
| Visibility | one Master-controls row, `global.minimap.hide` (see *Settings Schema* → Global rows) |
| Registered | from `addon:OnEnable`, because the library resolves `db.global.minimap` at `Register` time and AceDB builds that table in `OnInitialize`. Idempotent |
| Degradation | no stub. LibKa0s absent → no `NS.Launcher`, and its two callers already guard on it. LibDataBroker or LibDBIcon absent → the library reports it on one line and `Register` answers `false`; neither is a dependency, because LibKa0s is vendored into addons whose `libs/` folders are not identical |

There is deliberately **no** setting that disables the broker object and none that reassigns either
button: a broker display already offers its own per-plugin toggle, and the rung is a property of the
addon rather than a preference.

## Event Subscriptions

| Event | Where | Why |
|---|---|---|
| `PLAYER_ENTERING_WORLD` | `core/PartyFrameEnhanced.lua` | republish VISIBILITY |
| `PLAYER_REGEN_DISABLED` / `_ENABLED` | `core/PartyFrameEnhanced.lua` | the combat flag; ENABLED flushes the secure-write queue |
| `ADDON_ACTION_BLOCKED` / `_FORBIDDEN` | `core/PartyFrameEnhanced.lua` | log a blocked action blamed on this addon, ungated |
| `GROUP_ROSTER_UPDATE` | `core/PartyFrameEnhanced.lua` | the party-only flip (`NS.Units.InParty`): republish VISIBILITY |
| `GROUP_ROSTER_UPDATE`, `PLAYER_ENTERING_WORLD`, `EDIT_MODE_LAYOUTS_UPDATED`, `PLAYER_REGEN_ENABLED`, `ADDON_LOADED` (EllesmereUI) | `modules/Providers.lua` (AceEvent, own target) | re-resolve the unit → frame map |
| `EditMode.Exit` (EventRegistry callback) | `modules/Providers.lua` | re-resolve after Edit Mode closes |
| `UNIT_SPELLCAST_*` ×13 (per unit, `RegisterUnitEvent`) | `modules/CastBars.lua` | cast bars |
| `UNIT_TARGET` (per owner, `RegisterUnitEvent`); `PLAYER_TARGET_CHANGED` and `RAID_TARGET_UPDATE` (AceEvent, the module's own target) | `modules/TargetFrames.lua` | target frames. `UNIT_TARGET` never fires for the player's own target, hence `PLAYER_TARGET_CHANGED`; the client does not dispatch unit events (such as `UNIT_NAME_UPDATE`) for compound tokens, so the repeating timer also repaints whole any shown button whose unit was unresolved (nil name) when it was painted -- e.g. a new member's target. Health comes from the same gated repeating timer |
| `UNIT_PET` (owner), `UNIT_HEALTH` / `UNIT_MAXHEALTH` / `UNIT_NAME_UPDATE` (pet token), all `RegisterUnitEvent`; `RAID_TARGET_UPDATE` (AceEvent, the module's own target) | `modules/PetFrames.lua` | pet frames |
| `UNIT_IN_RANGE_UPDATE` (AceEvent, the module's own target; registered only while the fade is on, in a party, on Blizzard's classic frames) | `modules/RangeFade.lua` | the classic frames' own range check: `PartyMemberFrame` never fades for range, so there is nothing to copy. On EllesmereUI and raid-style frames the fade comes from post-hooks on each member frame's `SetAlpha` / `SetAlphaFromBoolean` instead, and no event is registered |
| `PLAYER_REGEN_DISABLED` (always), `GROUP_ROSTER_UPDATE` (registered only while preview is on) | `modules/Preview.lua` (AceEvent, own target) | re-lock before lockdown, so nothing clickable survives into the fight; switch between the stand-in and the real party frames |
| `PLAYER_REGEN_ENABLED` (armed only while a secure write is queued) | `core/PartyFrameEnhanced.lua`, its own frame | finish a secure write the stand-down could not make under lockdown. **The one registration a disabled addon keeps** (slash-commands-§7), and it is released the moment it fires |

**Every registration in this table except the last comes off while the addon is stood down** — for
either reason. Not gated: unregistered. See *The disabled state is total* below.

The unit events above are registered only in a party (the party-only rule): each feature's
`syncEvents` re-runs on VISIBILITY, which the roster flip republishes.

Lifecycle, roster and Edit Mode events use AceEvent, each module on its own target. The per-unit
game events are registered with `RegisterUnitEvent` on each element's own frame, so the client filters
by unit in C rather than dispatching every unit's event into Lua — a recorded deviation, below.

## The disabled state is total

**Disabled means the addon is not running.** Not hidden, not quiet, not skipping a repaint — not
running (slash-commands-§7, anti-pattern #85). A player who unticks *Enable Party Frame Enhanced*
has asked for the same outcome they would get by unticking the addon in Blizzard's own AddOns list,
minus the `/reload`.

### One latch, two named holds

`core/LifecycleSetup.lua` builds one `LibKa0s-Lifecycle-1.0` instance. The addon is stood down
whenever **at least one** hold is taken and stands up only when the **last** one is released.

| Hold | Taken by | Lifetime |
|---|---|---|
| `disabled` | the stored `enabled` path — the Master-controls checkbox, `/pfe enable`, `/pfe disable`, `/pfe set enabled`, and an AceDB profile switch, all through `NS.ApplyEnabled` | **persisted**; surviving a `/reload` is the whole point of the setting |
| `perf` | `LibKa0s-Perf-1.0` itself, for the capture's suspended arm. The host never writes it | **session-only**, never persisted |

Releasing one hold **never** stands up an addon the other is still holding down, and that is the one
sentence the latch exists for: `/pfe disable` and `/pfe enable` are both live, so a player can use
either *during* a suspended perf arm. A resume that called a bare stand-up would bring the addon back
mid-capture and silently ruin the run. There is no `:StandUp()` member to call.

`NS.Perf.suspended` is a **view** of the latch, not a second copy; the library refuses a write to it.
`NS.IsStoodDown()` is the one question every show ladder asks.

### What stands down

`NS.StandDown` (`core/PartyFrameEnhanced.lua`), in this order, and the order is load-bearing:

1. the lifecycle events come off the addon object;
2. every module's `Suspend` runs — every `RegisterUnitEvent` on every element frame actually
   **unregistered**, every timer and `OnUpdate` canceled, and the ten target and pet buttons' secure
   visibility state drivers **unregistered** (`UnitButtons.Release`), not replaced with `"hide"`:
   at once out of combat, deferred to `PLAYER_REGEN_ENABLED` in combat. A feature that is merely
   switched off keeps its `"hide"` driver; only the stand-down releases it. Providers also
   unregisters its `EditMode.Exit` EventRegistry callback, and its resolve burst arms nothing while
   suspended;
3. `VISIBILITY` is published, so every element's show ladder re-decides and answers no **at the
   source** — a hidden frame comes back on a combat transition or a settings change, so hiding
   imperatively is not enough;
4. every bus receiver is unregistered, events and messages both (`NS.BusStandDown`, `core/Bus.lua`).

A handler that merely early-returns does **not** satisfy any of this. An early return means the addon
did not stop watching, it stopped reacting, and it still pays the dispatch the player switched it off
to stop paying.

Secure work — a state driver, `SetAttribute`, a `SetPoint` on a secure button — is refused under
combat lockdown, so a stand-down that lands in combat holds the write pending and finishes it on
`PLAYER_REGEN_ENABLED`. That listener lives on its own frame, is armed only while something is
queued, and unregisters itself the moment it fires.

### What survives, because it is setup

The chat command registration, the dispatcher and the `COMMANDS` table; the settings-category
registration and the panel body; the AceDB handle, the single write seam and AceDB's
`OnProfileChanged` / `OnProfileCopied` / `OnProfileReset` callbacks (a profile switch can flip
`enabled` with nothing else touched, so `adoptProfile` re-evaluates the latch before it publishes
anything); and the launcher's registration. None of these is a feature, and keeping them live costs
nothing the stand-down was trying to reclaim.

### Standing back up

`NS.StandUp` replays the bus registrations, re-registers the lifecycle events, re-reads the combat
state, flushes any deferred secure write and runs every module's `Resume` — rebuilding from the
settings **as they are now**, never from a snapshot taken on the way down (performance-§6). A setting
changed while the addon was off comes back correctly.

### The evidence

`tests/test_disabled.lua` is the conformance suite slash-commands-§7 requires, and every negative
assertion in it reads the **registration set** out of the kit's recording mock rather than a
handler's return value — a suite written against an early return cannot tell a draw gate from a
stand-down. It carries the falsification comments on the three negative steps, and all three were
proven red by mutation: dropping the teardown from `NS.StandDown`, a raw frame that writes and prints
on entering combat while disabled, and replacing the latch with a boolean.

## Taint Notes

- **Never touch the frames we attach to.** No `Hide`, `SetParent`, `SetPoint` or call into a Blizzard
  or EllesmereUI frame; change detection is `hooksecurefunc` and `HookScript` only. The preview
  stand-in (`modules/StandIn.lua`) reads another frame's size and position through getters only and
  is never anchored, parented or hooked to one. Imitating EllesmereUI, it takes EllesmereUI's
  configured party frame size, which `modules/Providers.lua` reads from EllesmereUI's saved settings
  (read-only, nil-guarded at every step): EllesmereUI's hidden party buttons carry its raid size
  until it lays out a party, so measuring one copies the wrong frame.
- **Secure buttons are created at `OnEnable`**, out of combat, never later: the ten
  `SecureUnitButtonTemplate` target and pet buttons (`modules/UnitButtons.lua`). Their parent is
  their unit's fade frame (`modules/RangeFade.lua`), set at creation and never changed. The fade
  frame is plain, never moved or hidden; only its alpha changes, and alpha is not protected.
- **The out-of-range fade copies, it never calls in.** `modules/RangeFade.lua` post-hooks each member
  frame's `SetAlpha` and `SetAlphaFromBoolean` with `hooksecurefunc` and replays the call on its own
  fade frame. A secret flag goes to `SetAlphaFromBoolean` untouched; a secret number is tried on
  `SetAlpha` under `pcall`, falling back to a raid-style frame's own `outOfRange` flag.
- **Their visibility is a state driver**, not Lua: `[@party1target,exists] show; hide`, with General
  visibility folded in as `[combat]`/`[nocombat]`. Lua re-issues a driver only when a setting, preview
  or frame presence changes, through `NS.RunSecure`.
- **A secure button's restyle (size, anchors) is one secure write** (`target:reskin`, `pet:reskin`);
  painting its regions is not protected and happens in combat.
- **Every secure write goes through `NS.RunSecure(key, fn)`**: run now out of combat, queued under its
  key in combat (the latest write per key wins), flushed on `PLAYER_REGEN_ENABLED`
  (events-frames-taint-§2). `tests/test_lifecycle.lua` pins the queue.
- **Settings refuse to open in combat** (the library's gate, options-ui-§2) — never deferred. A page
  already on screen when combat starts, or reached through the AddOns sidebar in combat, goes under
  the library's gray cover and refuses every write, Defaults and tab click until combat ends (LibKa0s
  v1.46); nothing touches Blizzard's settings window, and the addon keeps no combat guard of its own.
- **Secret values** are never compared, formatted or used in arithmetic; they are handed to C methods
  that accept them. The binding rules are the spec's §7.

## Known Limitations

- Party only, by design: solo or in a raid of any size nothing shows (`/pfe unlock` previews it). Arena
  frames are not attached to (#11).
- Blizzard (both layouts) and EllesmereUI are the only frame systems detected; others use free
  placement (#2).
- Blizzard's classic party layout never shows the player, so the player's attached elements have no
  frame there (free placement covers it; #8).
- Secure target/pet frames can't move in combat; after a mid-combat roster reshuffle they fade until
  combat ends (#3).
- English only (#9).
- The out-of-range fade copies the party frame. On Blizzard's classic layout, which does not fade,
  it is the fixed ~40-yard `UnitInRange` check at 0.5. Spell-based ranges and a per-feature opacity
  are #13. Whether the client takes a **secret number** on `SetAlpha` is unverified, so the
  raid-style copy has a fallback through the frame's `outOfRange` flag (smoke step 47b).
- The logo is a generated placeholder (#10).
- On a load without LibKa0s the bus has no stand-down record: `core/Bus.lua` falls back to the
  untracked-target stub `LibKa0s-Bus-1.0`'s document prescribes, so each receiver still gets its own
  target, but a disable leaves the bus registrations live. The modules' own `Suspend` hooks and the
  show ladder's stood-down rung still apply. `tests/test_bus.lua` pins it.

Every deferred item is a GitHub issue (#1–#14, #13 still `state:untriaged`); the spec's §10 is the list
#1–#13 were filed from, and #14 is the deferred `LibKa0s-Schema-1.0` adoption.

## Documentation map

### Required (documentation-§3, Tier 1)

| Doc | Covers |
|---|---|
| `ARCHITECTURE.md` | This file — the hub |
| `scope.md` | What the addon does and, explicitly, what it leaves out |
| `module-map.md` | Every file, its responsibility, and the load order |
| `schema.md` | SavedVariables, defaults, named non-setting state, migrations |
| `settings-panel.md` | The `Tab \| Covers` table and the page → tab → row tree |
| `data-flow.md` | Frames found → elements placed → elements filled → shown or not |
| `common-tasks.md` | Recipes: a setting, a verb, a provider, a bracket, a string, a re-vendor |

### Conditional (documentation-§3, Tier 2)

| Doc | Status | Trigger |
|---|---|---|
| `perf-analysis/README.md` | Present | The performance harness is wired (`core/PerfSetup.lua`) |
| `slash-dispatch.md` | Present | 17 commands in `NS.COMMANDS` (trigger: eight or more) |
| `profiles.md` | Present | A profile control ships (`settings/Profiles.lua`) |
| `midnight-quirks.md` | Present | The cast bars' and providers' secret-value workarounds (at least one of the addon's own) |
| `compat-layer.md` | Present | `core/Compat.lua` publishes 15 shims (trigger: three or more) |
| `message-bus.md` | Not applicable | 4 messages (trigger: more than ten) |
| `debug.md` | Not applicable | No debug surface beyond the LibKa0s console |

### Verification and record (documentation-§3)

| Doc | Covers |
|---|---|
| `testing.md` | The harness, lint, the green commit gate, the release gate, the vendored-payload check |
| `smoke-tests.md` | The in-game smoke-test suite, including the non-English-client step |
| `test-cases.md` | The generated case inventory (authoritative pass count) |
| `performance.md` | Buckets, the bracket idiom, the latch the perf hold is taken on, the offline scenarios |
| `automated-tests/README.md` | What the automated-test record is and how to produce it |
| `automated-tests/RESULTS.md` | One row per run; generated by the runner, never hand-edited apart from the watch list's `Disposition` column |

### Addon-specific (documentation-§3, Tier 3)

| Doc | Covers |
|---|---|
| `superpowers/` | The v0.1.0 design spec and the checkpointed build plan (directory) |

Frozen material named once as directories, never row by row: `automated-tests/<run>/`,
`perf-analysis/<run>/`, `revendor/<date>/`, `audits/` and — when it exists — `reviews/`.

## Documented deviations

| Rule | What differs | Why | Decided | Re-check trigger |
|---|---|---|---|---|
| `events-frames-taint-§1` | `UNIT_SPELLCAST_*`, `UNIT_TARGET` and the pet unit events are registered with `RegisterUnitEvent` on each element's own frame, not through AceEvent | AceEvent-3.0 has no unit filter: routed through it, every cast by every unit the client knows (nameplates, raid, target, focus) is dispatched into Lua to be discarded. `RegisterUnitEvent` filters in C, so a disabled or excluded unit costs nothing. The frames are the elements themselves, not frames made for events. | 2026-09-15 | AceEvent or LibKa0s gains a unit-filtered registration |

### Files over the 1500-line cap

Nothing is over the cap today. `layout-§1` caps an authored `.lua` file at 1500 lines, and this
census is where a breach would be dispositioned; `libs/` and `tests/_kit/` are vendored and out of
scope. The kit's `tests/_kit/test_layout_cap.lua` holds this section against the tracked tree on
every run, so a file crossing the cap reddens the suite until it gets a row here.
