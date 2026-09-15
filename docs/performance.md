# Performance

How much Party Frame Enhanced costs, how to measure it, and what the instruments can and cannot
resolve. The shared protocol and the record contract live with `LibKa0s-Perf-1.0`; this page is the
addon's own half.

## The harness is wired

`core/PerfSetup.lua` builds one `LibKa0s-Perf-1.0` instance at load (`NS.Perf`), with a degradation
stub when the library is absent. `/pfe perf` is the reserved verb (performance-§4), dispatched through
`NS.COMMANDS`; the library returns lines and the addon prints them. Captures persist in
`PartyFrameEnhancedPerfDB`, a ring outside the AceDB tree (performance-§5).

## Buckets

Declared in `core/PerfSetup.lua`, in report order, with nesting declared rather than explained:

| Bucket | Within | What it brackets |
|---|---|---|
| `resolve` | — | one unit → party-frame resolve pass (`modules/Providers.lua`) |
| `anchor` | — | one feature's placement pass (`modules/Anchor.lua`) |
| `castEvent` | — | one `UNIT_SPELLCAST_*` handler |
| `castRender` | `castEvent` | the start/update render inside it |
| `castTick` | — | the throttled cast time-text tick |
| `targetEvent` | — | a `UNIT_TARGET` / raid-marker handler |
| `targetTick` | — | one pass of the target-health ticker |
| `targetRender` | `targetTick` | one target frame's refresh inside that pass |
| `petEvent` | — | a pet unit event |
| `reskin` | — | any feature's config-driven restyle |

Build status: the buckets are declared now; the brackets land with their modules (plan P2–P5), and
`tests/perf.lua` gains a case that every declared bucket is reached (plan P7). Until then an in-game
capture reports none of them.

## The bracket idiom

Hot paths use the gated Shape A form, reading the load-time upvalue (performance-§2):

```lua
local Perf = NS.Perf                         -- at file scope, never an NS lookup per call
local t0 = Perf.on and debugprofilestop()
-- … work …
if t0 then Perf.Note("castRender", debugprofilestop() - t0, "castEvent") end
```

Capture off costs one upvalue read, one field read and one boolean test. The offline zero-overhead
scenario (below) is the evidence, not this sentence.

## Suspend and resume

`suspend` calls `NS.SuspendAll()`: every registered module unregisters its event frames and cancels
its timers, the lifecycle events come off, and `VISIBILITY` is published — every element's
show-decision ladder checks `NS.Perf.suspended` as step 0, so nothing re-shows behind suspend's back.
`resume` calls `NS.ResumeAll()`, which re-registers from **current** settings, re-reads the combat
state, flushes any deferred secure write, and republishes (performance-§6).

## Offline scenarios (`lua tests/perf.lua`)

Outside the green gate, asserting only API calls and bytes per iteration. Planned scenarios (plan P7),
with SimplePartyTargets' measured fixes as the reference point — its captures showed ~7 full passes/s
× 11 blocks and 46 `SetPoint` calls per block per pass before per-owner updates, an anchor memo and
event filtering brought them down:

| Scenario | Asserts |
|---|---|
| resolve coalescing | N layout triggers in one frame → exactly one resolve |
| anchor memo | a pass with unchanged anchor keys makes zero `SetPoint` calls |
| cast burst | start/stop per unit allocates under a measured ceiling |
| ticker pass | five shown target frames: fixed API calls, bounded bytes |
| settings drag | a color drag on a feature skips the structural reskin |
| zero overhead | capture off allocates no more than capture on, and no more than a ceiling |

Today `tests/perf.lua` loads the addon and reports zero scenarios.

## In-game captures

Protocol, bundle shape and the capture index: [perf-analysis/README.md](./perf-analysis/README.md).
Read the **bucket** figures as the addon's cost; treat `fps.deltaMsPerFrame` below ~0.5 ms/frame as
unresolved, not as zero.
