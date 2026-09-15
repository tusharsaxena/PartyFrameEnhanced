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

Substrate: Ace3 (AceAddon, AceEvent, AceTimer, AceConsole, AceDB, AceGUI, AceConfig + AceDBOptions
for the Profiles page only), LibSharedMedia-3.0 and AceGUI-3.0-SharedMediaWidgets for media pickers,
and **LibKa0s v1.36.1** vendored whole. The addon consumes seven LibKa0s majors through one setup file
each — Media (`core/MediaSetup.lua`), Env (`core/EnvSetup.lua`), Core (`core/CoreSetup.lua`), Perf
(`core/PerfSetup.lua`), DebugLog (`core/DebugLogSetup.lua`), Slash (`settings/Slash.lua`) and Options
(`settings/OptionsSetup.lua`). **Pool, Item and Widgets are vendored, not wired**: fifteen elements are
created once at enable and never churn (so no pool), the addon handles no items, and it orders nothing
(so no reorder list).

Build status: the standards skeleton (lifecycle, settings seam, bus, secure-write queue, slash, panel,
harness) is in the tree; providers, the anchor engine and the three features land in plan P2–P5.

## Module Map

Twenty-two files load today, in the fixed folder order `libs → locales → core → defaults → modules →
settings`. The load-bearing positions are Namespace (publishes `NS.PREFIX`), MediaSetup before
Constants (`FONT_MONO`), CoreSetup before anything that prints, PerfSetup before every module that
captures `NS.Perf`, DebugLogSetup after its three inputs, and OptionsSetup before every settings page;
the TOC comments each one and `tests/test_loadorder.lua` pins them. Full table:
[module-map.md](module-map.md).

## Settings Schema

One schema (`settings/Schema.lua`) drives the panel, the CLI and the resets, and **one write seam** —
`NS.SetByPath` — carries every write to a schema path: the panel (the Options descriptor's `set` /
`applyDefault`), `/pfe set`, `/pfe lock`/`unlock` and every reset. The seam stores the value, runs the
row's `onChange`, logs one `[Set]` line (one per bulk act), and publishes `CONFIG(<section>)`.

- **Structural registries:** none. The player creates and deletes nothing.
- **Named non-setting state:** `castbar.position`, `target.position` and `pet.position` — each
  feature's free-placement anchor, written only by a drag. Owner: `modules/Anchor.lua`; writers: its
  drag-stop handler and `Anchor.ResetPositions` (the *Reset position* button, `/pfe resetposition`).
  Arrives with the anchor engine (plan P2).
- **Session-only rows:** `state.debugConsole` (the console window's visibility).

Shapes, defaults and the migration ladder: [schema.md](schema.md). The panel tree:
[settings-panel.md](settings-panel.md). Profiles: [profiles.md](profiles.md).

## Message Bus

Closed bus on AceEvent messages (`core/Bus.lua`); each receiver registers on its own
`NS.NewBusTarget()`, and every message has exactly one sending file (`tests/test_bus.lua` reads the
source to check).

| Message | Sender | Payload | Consumers |
|---|---|---|---|
| `Ka0s_PartyFrameEnhanced_LayoutChanged` | `modules/Providers.lua` (P2) | none | the three features, through Anchor |
| `Ka0s_PartyFrameEnhanced_ConfigChanged` | `settings/Schema.lua` (the write seam) | section: `master` / `general` / `castbar` / `target` / `pet` | the three features; Providers (`general`) |
| `Ka0s_PartyFrameEnhanced_VisibilityChanged` | `core/PartyFrameEnhanced.lua` (`NS.PublishVisibility`) | none | the three features |
| `Ka0s_PartyFrameEnhanced_ProfileChanged` | `core/PartyFrameEnhanced.lua` | none | the three features, Providers, Anchor |

Consumers arrive with the modules (P2–P5); today the senders exist and the suite subscribes probe
receivers.

## Slash Commands

`/pfe` and `/partyframeenhanced`, thirteen verbs in `NS.COMMANDS` today — the ten reserved ones plus
`lock`, `unlock` and `profile`; `resetposition`, `preview` and `status` arrive with their modules. Table
and behavior: [slash-dispatch.md](slash-dispatch.md).

## Event Subscriptions

| Event | Where | Why |
|---|---|---|
| `PLAYER_ENTERING_WORLD` | `core/PartyFrameEnhanced.lua` | republish VISIBILITY |
| `PLAYER_REGEN_DISABLED` / `_ENABLED` | `core/PartyFrameEnhanced.lua` | the combat flag; ENABLED flushes the secure-write queue |
| `ADDON_ACTION_BLOCKED` / `_FORBIDDEN` | `core/PartyFrameEnhanced.lua` | log a blocked action blamed on this addon, ungated |
| roster, Edit Mode, EllesmereUI load | `modules/Providers.lua` (P2) | re-resolve the unit → frame map |
| `UNIT_SPELLCAST_*` (per unit, `RegisterUnitEvent`) | `modules/CastBars.lua` (P3) | cast bars |
| `UNIT_TARGET`, `RAID_TARGET_UPDATE` | `modules/TargetFrames.lua` (P4) | target frames |
| `UNIT_PET`, pet `UNIT_HEALTH`/`UNIT_MAXHEALTH`/`UNIT_NAME_UPDATE` | `modules/PetFrames.lua` (P5) | pet frames |

Lifecycle events use AceEvent. The per-unit game events will use one small frame per unit with
`RegisterUnitEvent`, so the client filters by unit in C rather than dispatching every unit's event into
Lua; that is recorded under *Documented deviations* when it lands, as the other addons in the
collection record it.

## Taint Notes

- **Never touch the frames we attach to.** No `Hide`, `SetParent`, `SetPoint` or call into a Blizzard
  or EllesmereUI frame; change detection is `hooksecurefunc` and `HookScript` only.
- **Secure buttons are created at `OnEnable`**, out of combat, never later (the target and pet frames,
  plan P4–P5).
- **Every secure write goes through `NS.RunSecure(key, fn)`**: run now out of combat, queued under its
  key in combat (the latest write per key wins), flushed on `PLAYER_REGEN_ENABLED`
  (events-frames-taint-§2). `tests/test_lifecycle.lua` pins the queue.
- **Settings refuse to open in combat** (the library's gate, options-ui-§2) — never deferred.
- **Secret values** are never compared, formatted or used in arithmetic; they are handed to C methods
  that accept them. The binding rules are the spec's §7.

## Known Limitations

- Party only; a raid group puts the addon to sleep.
- Blizzard's classic party layout never shows the player, so the player's attached elements have no
  frame there (free placement covers it).
- Secure target/pet frames can't move in combat; after a mid-combat roster reshuffle they fade until
  combat ends.
- English only.
- The logo is a generated placeholder.

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
| `slash-dispatch.md` | Present | 13 commands in `NS.COMMANDS` (trigger: eight or more) |
| `profiles.md` | Present | A profile control ships (`settings/Profiles.lua`) |
| `midnight-quirks.md` | Not applicable | No client-version workaround of the addon's own yet; the cast bars' secret-value handling (P3) fires it |
| `compat-layer.md` | Not applicable | `core/Compat.lua` publishes 1 shim (trigger: three or more); P2 adds the rest and fires it |
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

None.
