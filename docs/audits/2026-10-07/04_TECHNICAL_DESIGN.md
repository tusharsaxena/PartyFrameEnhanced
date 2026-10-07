# 04 — Technical design: Ka0s Party Frame Enhanced

Remediation for the 2026-10-07 audit (standard v2.76.1). One code change (PFE-25); everything else
is records and docs. No change touches SavedVariables, the schema or the player-visible surface.

## PFE-25 — move the pending-regen listener onto an AceEvent target

**Files.** `core/PartyFrameEnhanced.lua` (`:106-138`), `docs/ARCHITECTURE.md` (Event Subscriptions
row at `:199`), and `tests/test_disabled.lua` / `tests/test_lifecycle.lua` (assertions only).

**Shape.**

```lua
local AceEvent = LibStub("AceEvent-3.0")
local regenWatch          -- a private AceEvent TARGET, never a bus target: NS.BusStandDown must not reach it

local function onRegenFlush()
    regenWatch:UnregisterEvent("PLAYER_REGEN_ENABLED")   -- released the moment it fires (slash-commands-§7)
    flushSecure()
end

function armPendingRegen()
    if #pendingOrder == 0 then return end
    regenWatch = regenWatch or AceEvent:Embed({})
    NS.SafeRegisterEvent(regenWatch, "PLAYER_REGEN_ENABLED", onRegenFlush, NS.RejectedEvents)
end

function disarmPendingRegen()
    if regenWatch then regenWatch:UnregisterEvent("PLAYER_REGEN_ENABLED") end
end

function NS.PendingRegenArmed()
    return regenWatch ~= nil and AceEvent.IsEventRegistered ~= nil
        and AceEvent:IsEventRegistered("PLAYER_REGEN_ENABLED", regenWatch) == true
end
```

**Why this target and not another.**
- It cannot be the addon object: its `PLAYER_REGEN_ENABLED` slot is `OnLeaveCombat`, and AceEvent keys
  a handler by `(event, target)`, which is the reason the existing comment gives.
- It cannot be `NS.NewBusTarget()`: the bus record stands every tracked target down at `NS.BusStandDown`
  (`core/PartyFrameEnhanced.lua:184`), and this listener has to survive exactly that stand-down
  (it is armed *after* it at `:188`).
- A bare `AceEvent:Embed({})` target is an AceEvent object, so the boundary event rides AceEvent as
  `events-frames-taint-§1` requires, while staying outside the bus record.

**Risks.**
- `NS.PendingRegenArmed` feeds the diagnostics report (`modules/Diagnostics.lua`). Confirm the kit's
  AceEvent fake answers `IsEventRegistered(event, target)`. If it does not, track a local `armed`
  boolean set in arm and cleared in disarm or on fire, instead of asking the registry.
- `tests/test_disabled.lua` step 3 reads the recording mock's registration set. The listener is
  armed only with a non-empty queue, so the baseline is unchanged, but a case that queues a secure
  write in combat and then stands down must still see exactly one survivor (`PLAYER_REGEN_ENABLED` on
  the private target) and see it go once fired. Add that assertion with a `-- red under:` comment
  (leave the event registered after flush).
- In the library-absent load the setup files already guard `LibStub("AceEvent-3.0")` through
  AceAddon. AceEvent is vendored and always present, so no stub is needed.

## PFE-26 / PFE-26a — record the v1.69.0–v1.70.0 span and sync its docs

**Files.** New `docs/revendor/2026-10-07-v1.69.0-v1.70.0/01_DELTA.md` and `05_SUMMARY.md`; edits to
`docs/ARCHITECTURE.md:23`, `:43`, `docs/smoke-tests.md:55` and `DEPENDENCIES.md:32`.

**Shape.** This is the consolidated span bundle `audit-review-history` defines. `01_DELTA.md` line 1
is exactly `Delta: LibKa0s v1.69.0 -> v1.70.0 (span: v1.69.0 v1.70.0)`, and the body is the payload
delta: `WidgetsLineChart.lua` (minor 2, v1.69.0), `WidgetsAutocomplete.lua` (minor 1, v1.70.0),
`LibKa0s.xml` +2 lines, and kit 36 → 37 at v1.69.0. `05_SUMMARY.md` gets one line per tag, "carried by
`547ac68` / `735a111`, nothing adopted: the addon wires no `LibKa0s-Widgets-1.0` member". Then point
the four doc sites at v1.70.0 and kit 37. INSTALL-4 owes a new smoke run on v1.70.0, so mark its
Result cell pending and leave the result to the owner.

**Better still:** run `/dev-copilot:wow-revendor-libka0s` in its span mode, which writes the bundle
and the doc sync together. That is the flow the two `chore:` commits bypassed.

## PFE-01 — the remaining doc drift

- `docs/automated-tests/README.md:29`: `kit 35` → `kit 37`.
- `docs/perf-analysis/README.md:70`: `/wow-addon:perf-analysis` → `/dev-copilot:wow-perf-analysis`.
- `docs/ARCHITECTURE.md:404`: restate the trigger as "14 shims by documentation-§3's grep
  (`grep -cE '^\s*function\s+[A-Za-z_][A-Za-z0-9_]*\.' core/Compat.lua`), plus `IsSecret` routed from
  `LibKa0s-Compat-1.0`", and drop the private grep.
- `docs/compat-layer.md:17`: reduce the `IsSecret` row to one line outside the shim table ("`IsSecret`
  is `LibKa0s-Compat-1.0`'s; see its API document"), because a library shim is not re-documented here.
- Do **not** hand-edit `docs/automated-tests/RESULTS.md:15`. The next runner pass regenerates it with
  the kit-37 wording.

## PFE-29 — restore the fourth map table

Insert after the Verification-and-record table (`docs/ARCHITECTURE.md:418`) and before the frozen
sentence:

```markdown
### Addon-specific (documentation-§3, Tier 3)

| Doc | Covers |
|---|---|

None.
```

## PFE-27 — bring the hub back under ~400 lines

- Replace Overview's build-status paragraph (`docs/ARCHITECTURE.md:35-57`) with two sentences: the
  current release and its gating run, and "LibKa0s re-vendor history and what each tag brought:
  [`revendor/`](revendor/)". The per-tag adoption notes (v1.65.0's debug sinks, v1.67.0's
  `addonName`) already live in `debug.md`, `module-map.md` and the revendor bundles. Confirm each
  survives in one of those before deleting it here.
- Optional: spill `## The disabled state is total` (79 lines) into `docs/data-flow.md` (a "Stand-down
  and stand-up" section), leaving roughly 10 lines and one link.
- Expected result: about 360–380 lines. Report the shape, and do not argue the arithmetic.

## PFE-28 — register-row text (owner decision)

- Row 1: the owner confirms the D9 decision, and then "pending the owner's ratification" is deleted.
  Ratifying is the owner's act, so the audit cannot make this edit. If the owner declines, the row
  goes and the residue becomes a fix item for `modules/SecureFollow.lua`.
- Row 2: append "(audit 2026-09-23 PFE-15; `79cd225`)" to **Why**.

## PFE-30, PFE-31, PFE-08, PFE-09 — optional or no action

- PFE-30: reshape `docs/settings-panel.md` to a `Page | Covers` table plus per-page headings the next
  time the settings change. It is not worth a standalone commit.
- PFE-31: `runDebug` → `if NS.DebugLog:DebugVerb(rest) then return end; NS.DebugLog:Toggle()`. This
  is behavior-preserving, and `tests/test_slash.lua` already pins all four branches. Run it before
  and after.
- PFE-08: none.
- PFE-09: the next release is cut from `run-automated-tests.sh --release <v>`, which writes the first
  sighted bundle.

## Ordering constraints

- PFE-26 (the bundle) before PFE-26a and PFE-27, because the hub rewrite points at the bundle.
- PFE-25 is independent and is the only change that needs the green gate's code half plus a
  combat-entry smoke check (queue a secure write by disabling in combat, then leave combat).
