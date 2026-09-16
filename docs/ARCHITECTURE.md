# Architecture — Ka0s Party Frame Enhanced

The engineer's hub. Each section summarizes and links to its topic doc; the design record behind it is
[superpowers/specs/2026-09-15-party-frame-enhanced-design.md](superpowers/specs/2026-09-15-party-frame-enhanced-design.md),
and the build's progress is the ledger in
[superpowers/plans/2026-09-15-party-frame-enhanced-v0.1.0.md](superpowers/plans/2026-09-15-party-frame-enhanced-v0.1.0.md).

## Overview

Party Frame Enhanced adds a **cast bar**, a **target frame** and a **pet frame** for the player and
party1–party4. Each feature either attaches its five elements to the party frame currently showing
each unit — Blizzard classic, Blizzard raid-style or EllesmereUI, detected by a provider layer — or
stacks them in one movable free-placement group. What it deliberately leaves out is
[scope.md](scope.md).

It is **party-only**: solo or in a raid it shows nothing and registers nothing. `/pfe unlock` previews
it anyway, on the real party frames in a party and on a stand-in party frame out of one
([the design](superpowers/specs/2026-09-15-test-mode-design.md)).

Substrate: Ace3 (AceAddon, AceEvent, AceTimer, AceConsole, AceDB, AceGUI, AceConfig + AceDBOptions
for the Profiles page only), LibSharedMedia-3.0 and AceGUI-3.0-SharedMediaWidgets for media pickers,
and **LibKa0s v1.39.0** vendored whole, plus **LibDataBroker-1.1** and **LibDBIcon-1.0** for the
launcher. The addon consumes eight LibKa0s majors through one setup file each — Media
(`core/MediaSetup.lua`), Env (`core/EnvSetup.lua`), Core (`core/CoreSetup.lua`), Perf
(`core/PerfSetup.lua`), DebugLog (`core/DebugLogSetup.lua`), Launcher (`core/LauncherSetup.lua`),
Slash (`settings/Slash.lua`) and Options (`settings/OptionsSetup.lua`). **Pool, Item and Widgets are
vendored, not wired**: fifteen elements are
created once at enable and never churn (so no pool), the addon handles no items, and it orders nothing
(so no reorder list).

Build status: feature-complete for v0.1.0, with the offline perf pass, the release-candidate record
and the first standards audit done. What remains before the tag is in-game testing (plan P10).

## Module Map

Thirty-seven files load, in the fixed folder order `libs → locales → core → defaults → modules →
settings`. The load-bearing positions are Namespace (publishes `NS.PREFIX`), MediaSetup before
Constants (`FONT_MONO`), CoreSetup before anything that prints, PerfSetup before every module that
captures `NS.Perf`, DebugLogSetup after its three inputs, Providers first among the modules, Element
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
  rather than `defaults.profile`, and the profile-reset tally skips it.

Shapes, defaults and the migration ladder: [schema.md](schema.md). The panel tree:
[settings-panel.md](settings-panel.md). Profiles: [profiles.md](profiles.md).

## Message Bus

Closed bus on AceEvent messages (`core/Bus.lua`); each receiver registers on its own
`NS.NewBusTarget()`, and every message has exactly one sending file (`tests/test_bus.lua` reads the
source to check).

| Message | Sender | Payload | Consumers |
|---|---|---|---|
| `Ka0s_PartyFrameEnhanced_LayoutChanged` | `modules/Providers.lua` | none | Anchor (re-places every feature), CastBars, TargetFrames, PetFrames (re-decide visibility) |
| `Ka0s_PartyFrameEnhanced_ConfigChanged` | `settings/Schema.lua` (the write seam) | section: `master` / `general` / `castbar` / `target` / `pet` | CastBars, TargetFrames, PetFrames (their own section, `master`, `general`); Anchor (a feature's section, `master`, `general`); Providers (`general`, `master`) |
| `Ka0s_PartyFrameEnhanced_VisibilityChanged` | `core/PartyFrameEnhanced.lua` (`NS.PublishVisibility`) | none | CastBars, TargetFrames, PetFrames |
| `Ka0s_PartyFrameEnhanced_ProfileChanged` | `core/PartyFrameEnhanced.lua` | none | CastBars, TargetFrames, PetFrames, Providers, Anchor |

## Slash Commands

`/pfe` and `/partyframeenhanced`, seventeen verbs in `NS.COMMANDS` — the twelve reserved ones
(`enable` and `disable` among them, aliases for the `enabled` row and never a second switch) plus
`resetposition`, `lock`, `unlock`, `status` and `profile`. The dispatcher is registered in
`OnInitialize` and no verb gates on `enabled`, so it answers while the addon is disabled and the pair
is never one-way (slash-commands-§2). Table and behavior: [slash-dispatch.md](slash-dispatch.md).

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
| Left click | **rung (b)** — `NS.ToggleLock`, the addon's existing preview switch. Unlocking *is* the preview here (options-ui-§15's exemption), and the launcher drives the same `locked` row the Lock frame checkbox and `/pfe lock` / `/pfe unlock` drive, through `NS.SetByPath`, holding no copy of that state |
| Right click | **always** `NS.OpenOptionsPanel` — on this addon as on every other |
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
| `UNIT_SPELLCAST_*` ×13 (per unit, `RegisterUnitEvent`) | `modules/CastBars.lua` | cast bars |
| `UNIT_TARGET` (per owner, `RegisterUnitEvent`), `RAID_TARGET_UPDATE` (AceEvent) | `modules/TargetFrames.lua` | target frames; health comes from a gated repeating timer |
| `UNIT_PET` (owner), `UNIT_HEALTH` / `UNIT_MAXHEALTH` / `UNIT_NAME_UPDATE` (pet token), all `RegisterUnitEvent` | `modules/PetFrames.lua` | pet frames |
| `PLAYER_REGEN_DISABLED` (always), `GROUP_ROSTER_UPDATE` (registered only while preview is on) | `modules/Preview.lua` (AceEvent, own target) | re-lock before lockdown, so nothing clickable survives into the fight; switch between the stand-in and the real party frames |

The unit events above are registered only in a party (the party-only rule): each feature's
`syncEvents` re-runs on VISIBILITY, which the roster flip republishes.

Lifecycle, roster and Edit Mode events use AceEvent, each module on its own target. The per-unit
game events are registered with `RegisterUnitEvent` on each element's own frame, so the client filters
by unit in C rather than dispatching every unit's event into Lua — a recorded deviation, below.

## Taint Notes

- **Never touch the frames we attach to.** No `Hide`, `SetParent`, `SetPoint` or call into a Blizzard
  or EllesmereUI frame; change detection is `hooksecurefunc` and `HookScript` only. The preview
  stand-in (`modules/StandIn.lua`) reads another frame's size and position through getters only and
  is never anchored, parented or hooked to one. Imitating EllesmereUI, it takes EllesmereUI's
  configured party frame size, which `modules/Providers.lua` reads from EllesmereUI's saved settings
  (read-only, nil-guarded at every step): EllesmereUI's hidden party buttons carry its raid size
  until it lays out a party, so measuring one copies the wrong frame.
- **Secure buttons are created at `OnEnable`**, out of combat, never later: the ten
  `SecureUnitButtonTemplate` target and pet buttons (`modules/UnitButtons.lua`).
- **Their visibility is a state driver**, not Lua: `[@party1target,exists] show; hide`, with General
  visibility folded in as `[combat]`/`[nocombat]`. Lua re-issues a driver only when a setting, preview
  or frame presence changes, through `NS.RunSecure`.
- **A secure button's restyle (size, anchors) is one secure write** (`target:reskin`, `pet:reskin`);
  painting its regions is not protected and happens in combat.
- **Every secure write goes through `NS.RunSecure(key, fn)`**: run now out of combat, queued under its
  key in combat (the latest write per key wins), flushed on `PLAYER_REGEN_ENABLED`
  (events-frames-taint-§2). `tests/test_lifecycle.lua` pins the queue.
- **Settings refuse to open in combat** (the library's gate, options-ui-§2) — never deferred.
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
- The logo is a generated placeholder (#10).

Every deferred item is a GitHub issue labeled `state:triaged` (#1–#12); the spec's §10 is the list
they were filed from.

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
| `performance.md` | Buckets, the bracket idiom, suspend/resume, the offline scenarios |
| `automated-tests/README.md` | What the automated-test record is and how to produce it |
| `automated-tests/RESULTS.md` | One row per run; generated by the runner, never hand-edited apart from the watch list's `Disposition` column |

### Addon-specific (documentation-§3, Tier 3)

| Doc | Covers |
|---|---|
| `superpowers/` | The v0.1.0 design spec and the checkpointed build plan (directory) |

Frozen material named once as directories, never row by row: `automated-tests/<run>/`,
`perf-analysis/<run>/`, and — when they exist — `audits/` and `reviews/`.

## Documented deviations

| Rule | What differs | Why | Decided | Re-check trigger |
|---|---|---|---|---|
| `events-frames-taint-§1` | `UNIT_SPELLCAST_*`, `UNIT_TARGET` and the pet unit events are registered with `RegisterUnitEvent` on each element's own frame, not through AceEvent | AceEvent-3.0 has no unit filter: routed through it, every cast by every unit the client knows (nameplates, raid, target, focus) is dispatched into Lua to be discarded. `RegisterUnitEvent` filters in C, so a disabled or excluded unit costs nothing. The frames are the elements themselves, not frames made for events. | 2026-09-15 | AceEvent or LibKa0s gains a unit-filtered registration |
