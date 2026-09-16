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
| `castTick` | — | one `OnUpdate` frame while a bar is casting, holding or fading. It counts **frames**, not text refreshes: the 0.1 s time-text throttle sits inside it, so ~40 calls/s at 40–60 fps is normal |
| `targetEvent` | — | a `UNIT_TARGET` / raid-marker handler |
| `targetTick` | — | one pass of the target-health ticker |
| `targetRender` | `targetTick` | one target frame's refresh inside that pass |
| `petEvent` | — | a pet unit event |
| `reskin` | — | any feature's config-driven restyle |

Every declared bucket is reached by a real bracket, and each nested one is noted inside the parent it
declares — `tests/test_perf_buckets.lua` pins both, inside the green gate, along with "capture off
calls the sink zero times".

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

Outside the green gate. It builds the worst realistic case — five units in a party, all three features
on, attached to Blizzard's raid-style frames — and asserts only deterministic quantities: API calls on
the addon's own elements and bytes allocated per iteration, each isolated by a full collect. Timings
print for orientation only.

**Reference point: SimplePartyTargets.** Its in-game captures showed ~7 full passes a second over 11
blocks and **46 `SetPoint` calls per block per pass** before per-owner updates, an anchor memo and event
filtering brought them down. The scenarios below pin the same properties here from the first release.

| Scenario | What it runs | API calls / iter | Bytes / iter | Asserted |
|---|---|---|---|---|
| resolve coalescing | 40 layout requests in one frame | — | — | exactly **1** resolve |
| `resolveUnchanged` | a resolve that finds the frames it had | 0 | 0 | 0 API calls; ≤ 24 bytes |
| `anchorUnchanged` | all three features' placement, nothing changed | 0 (**0 `SetPoint`**) | 0 | 0 `SetPoint`; ≤ 24 bytes |
| `castStartStop` | start + stop on all five cast bars | 55 | 16.6 | ≤ 41 bytes |
| `castTick` | five casting bars at the 0.1 s text refresh | 10 | 0 | ≤ 24 bytes |
| `targetTickUnchanged` | a ticker pass, five targets, health unchanged | 0 | 0 | 0 API calls; ≤ 24 bytes |
| `targetTickMoving` | a ticker pass, five targets, health changing | 15 | 0 | ≤ 24 bytes |
| `settingsDrag` | one color-picker commit on the cast bars | 25 (0 `SetPoint`) | 596 | reported only |
| `probeOverheadOff` / `On` | one cast cycle, capture off vs on | 11 / 11 | 0 / 0.5 | off ≤ on + 1; same API count; off ≤ 24 bytes |

Figures from 2026-09-15 (Lua 5.1.5, WSL2). Every ceiling is the measured figure plus 24 bytes — less
than the 64 bytes one extra table costs, so the smallest allocation added to a hot path fails the run.

### What the pass changed (2026-09-15)

The first run of these scenarios found four real costs; each fix is in the tree and pinned above.

| Finding | Before | After | Fix |
|---|---|---|---|
| Every dotted setting read built a `gmatch` iterator — hit per element per pass by the show decision (`general.includePlayer`) and per resolve (`general.provider`) | resolve: 88 bytes | 0 | `NS.ResolvePath` walks with `find`/`sub`, which yield already-interned strings |
| Every restyle re-laid-out every region, so a color drag re-anchored five bars per 50 ms commit | drag: 115 API calls, **40 `SetPoint`**, 3.9 KB | 25 calls, **0 `SetPoint`**, 596 B | `Element.Reskin` memoizes a structure signature and skips layout when only colors moved (the KickCD F-015 lesson) |
| A color-resolver closure was built on every paint | a closure per paint | one per element / per class | `Element.UnitResolver`, cached `Element.ClassResolver` |
| Measurement noise: cast records, mock duration objects, the kit's AceTimer queue entries and the mock's color recorder were counted as the addon's garbage | cast cycle: 917 B; ticker: 240 B | 16.6 B; 0 | the scenarios build client data outside the measured loop; the ticker pass is called directly; the mock recorders reuse their tables |

## In-game captures

Protocol, bundle shape and the capture index: [perf-analysis/README.md](./perf-analysis/README.md).
Read the **bucket** figures as the addon's cost; treat `fps.deltaMsPerFrame` below ~0.5 ms/frame as
unresolved, not as zero.
