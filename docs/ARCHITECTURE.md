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

It is **party-only**: solo or in a raid it shows nothing and registers nothing. `/pfe test` previews
it anyway, on the real party frames in a party and on a stand-in party frame out of one
([the design](superpowers/specs/2026-09-15-test-mode-design.md)).

Substrate: Ace3 (AceAddon, AceEvent, AceTimer, AceConsole, AceDB, AceGUI, AceConfig + AceDBOptions
for the Profiles page only), LibSharedMedia-3.0 and AceGUI-3.0-SharedMediaWidgets for media pickers,
and **LibKa0s v1.38.0** vendored whole. The addon consumes seven LibKa0s majors through one setup file
each — Media (`core/MediaSetup.lua`), Env (`core/EnvSetup.lua`), Core (`core/CoreSetup.lua`), Perf
(`core/PerfSetup.lua`), DebugLog (`core/DebugLogSetup.lua`), Slash (`settings/Slash.lua`) and Options
(`settings/OptionsSetup.lua`). **Pool, Item and Widgets are vendored, not wired**: fifteen elements are
created once at enable and never churn (so no pool), the addon handles no items, and it orders nothing
(so no reorder list).

Build status: feature-complete for v0.1.0, with the offline perf pass, the release-candidate record
and the first standards audit done. What remains before the tag is in-game testing (plan P10).

## Module Map

Thirty-six files load, in the fixed folder order `libs → locales → core → defaults → modules →
settings`. The load-bearing positions are Namespace (publishes `NS.PREFIX`), MediaSetup before
Constants (`FONT_MONO`), CoreSetup before anything that prints, PerfSetup before every module that
captures `NS.Perf`, DebugLogSetup after its three inputs, Providers first among the modules, Element
and UnitButtons before the features that capture them, Preview after every feature, Preview and
StandIn before TestMode, Schema before
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
- **Session-only rows:** `state.debugConsole` (the console window's visibility) and
  `state.testMode` (whether test mode is running; its set is `NS.TestMode.Toggle`,
  `settings/General.lua`).

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

`/pfe` and `/partyframeenhanced`, sixteen verbs in `NS.COMMANDS` — the ten reserved ones plus
`resetposition`, `lock`, `unlock`, `test`, `status` and `profile`. Table and behavior:
[slash-dispatch.md](slash-dispatch.md).

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
| `PLAYER_REGEN_DISABLED`, `GROUP_ROSTER_UPDATE` (registered only while test mode is on) | `modules/TestMode.lua` (AceEvent, own target) | end test mode before lockdown; switch between the stand-in and the real party frames |

The unit events above are registered only in a party (the party-only rule): each feature's
`syncEvents` re-runs on VISIBILITY, which the roster flip republishes.

Lifecycle, roster and Edit Mode events use AceEvent, each module on its own target. The per-unit
game events are registered with `RegisterUnitEvent` on each element's own frame, so the client filters
by unit in C rather than dispatching every unit's event into Lua — a recorded deviation, below.

## Taint Notes

- **Never touch the frames we attach to.** No `Hide`, `SetParent`, `SetPoint` or call into a Blizzard
  or EllesmereUI frame; change detection is `hooksecurefunc` and `HookScript` only. Test mode's
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

- Party only, by design: solo or in a raid of any size nothing shows (`/pfe test` previews it). Arena
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
| `slash-dispatch.md` | Present | 16 commands in `NS.COMMANDS` (trigger: eight or more) |
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
