# Module map

Every non-vendored file, its one-line responsibility, and why it sits where it does in the load order.
The TOC is the source of truth for order; `tests/test_loadorder.lua` pins the load-bearing positions.

## Load order

`libs/*` → `locales/*` → `core/*` → `defaults/*` → `modules/*` → `settings/*` (layout-§1).

| # | File | Responsibility | Why here |
|---|---|---|---|
| 1 | `locales/enUS.lua` | `NS.L` with the enUS keys and a key-returning fallback | first: every later file may read `NS.L` |
| 2 | `core/Namespace.lua` | `NS.name`, `NS.version`, `NS.PREFIX` | **load-bearing**: CoreSetup and PerfSetup read them at load |
| 3 | `core/Compat.lua` | every version-variant client call and secret guard ([compat-layer.md](compat-layer.md)) | conventional: reached at call time |
| 4 | `core/MediaSetup.lua` | `NS.Icon`, `NS.MediaFont`, the one `Media.RegisterLSM` | **load-bearing**: before Constants |
| 5 | `core/Constants.lua` | fallback media, `FONT_MONO`, logo path, the nine anchor points | reads NS.MediaFont at load |
| 6 | `core/State.lua` | session state: `debug`, `inCombat`, `preview`, `inParty`, `test` | conventional |
| 7 | `core/Bus.lua` | `NS.bus`, the `NS.busRecord` stand-down record (`LibKa0s-Bus-1.0`), `NS.NewBusTarget` / `NS.BusStandDown` / `NS.BusStandUp`, the `NS.MSG` catalog (`Bus.Catalog`) | before anything that subscribes |
| 8 | `core/Util.lua` | LSM handle and fetch, deep copy, fill-defaults | conventional |
| 9 | `core/EnvSetup.lua` | `NS.Meta`, `NS.Version` over LibKa0s-Env | conventional |
| 10 | `core/CoreSetup.lua` | printer, stringifier, class-color resolver, skin, `NS.MakeCloseButton` | **load-bearing**: after Namespace, before anything that prints |
| 11 | `core/LifecycleSetup.lua` | `NS.lifecycle`: the one `LibKa0s-Lifecycle-1.0` latch, its `disabled` / `perf` holds, `NS.IsStoodDown`, `NS.ApplyEnabled` | **load-bearing**: `core/PerfSetup.lua` requires `descriptor.lifecycle`, so the instance must exist before it |
| 12 | `core/PerfSetup.lua` | `NS.Perf`: buckets, and the latch the harness takes its `perf` hold on | **load-bearing**: before every module's `local Perf = NS.Perf` |
| 13 | `core/DebugLogSetup.lua` | `NS.DebugLog`, `NS.Debug` | **load-bearing**: after Constants, State, CoreSetup |
| 14 | `core/LauncherSetup.lua` | `NS.Launcher`: the one LibDataBroker object, its icon, its rung-(b) left click and the right click that always opens the panel (launcher-§1/§2) | conventional: every seam is reached at click or `Register` time, and `Register` runs in `addon:OnEnable` |
| 15 | `core/Units.lua` | the five units, their target and pet tokens, labels, the include rule, the party-only rule (`InParty`) | conventional |
| 16 | `core/Database.lua` | AceDB init, the migration ladder | conventional (called at OnInitialize) |
| 17 | `core/PartyFrameEnhanced.lua` | AceAddon promotion, lifecycle, combat flag, the party flip, secure-write queue, module registry, VISIBILITY/PROFILE sender | after the seams it reclaims and calls |
| 18 | `defaults/Profile.lua` | every profile default | before the settings pages that read it |
| 19 | `modules/Providers.lua` | the three frame-system providers, detection, the unit → frame map; sends LAYOUT | **load-bearing**: registers first, so the lifecycle enables it before the features |
| 20 | `modules/Anchor.lua` | attached pin (memoized), free stack, drag and the position owner, secure combat fade/defer | after Providers, before the features that register with it |
| 21 | `modules/RangeFade.lua` | one fade frame per unit that every element is parented to; copies the party frame's own out-of-range alpha (EllesmereUI, Blizzard raid-style, by post-hooking `SetAlpha` / `SetAlphaFromBoolean`) or, on Blizzard classic, runs its own `UnitInRange` check | **load-bearing**: after Providers, before every feature — the features parent their elements to `NS.RangeFade.Parent(unit)` at OnEnable |
| 22 | `modules/Element.lua` | the shared element regions, the config-driven restyle, class-color resolvers, the ladder's shared rungs | **load-bearing**: features capture `NS.Element` at file scope |
| 23 | `modules/CastBars.lua` | cast bars: per-unit events, the secret-safe cast lifecycle, preview content | after Element and Anchor |
| 24 | `modules/UnitButtons.lua` | the secure unit buttons the target and pet frames share: creation, state drivers, click attributes, health/name painting | **load-bearing**: TargetFrames and PetFrames capture `NS.UnitButtons` at file scope |
| 25 | `modules/TargetFrames.lua` | target frames: `UNIT_TARGET`, colors under secrets, raid markers, the gated health ticker (which also repaints an unresolved target) | after UnitButtons |
| 26 | `modules/PetFrames.lua` | pet frames: owner and pet-token events, the owner's class color, raid markers | after UnitButtons |
| 27 | `modules/StandIn.lua` | the stand-in party frame preview raises out of a party: three looks, the size and position copy, drag | before Preview, which drives it |
| 28 | `modules/Preview.lua` | preview, with the lock as its only switch (options-ui-§15): the two shapes it takes, the live switch, the refusals and exits | **load-bearing**: after StandIn, Anchor and Providers, which it drives |
| 29 | `settings/Schema.lua` | the `LibKa0s-Schema-1.0` seam: the instance (registry, write seam, bracket, reset count, validation) bound onto the host names, and its degradation stub | before every page |
| 30 | `settings/Slash.lua` | `NS.COMMANDS` (incl. `enable` / `disable`, `lock` / `unlock`, `status`), the Slash descriptor, `/pfe` + `/partyframeenhanced` | before OptionsSetup (the landing page renders its rows) |
| 31 | `settings/OptionsSetup.lua` | `NS.Helpers` (the Options instance) + load-completing stub | **load-bearing**: before every page file |
| 32 | `settings/About.lua` | the landing page body | after OptionsSetup |
| 33 | `settings/General.lua` | Master controls + Party frames tabs, the reset popup | after OptionsSetup |
| 34 | `settings/ElementRows.lua` | the Size & Position rows and the composed Border / Font / Bar / Background blocks the feature pages share; the page builder | **load-bearing**: every feature page calls it at load |
| 35 | `settings/CastBars.lua` | the Cast Bars page | after ElementRows |
| 36 | `settings/TargetFrames.lua` | the Target Frames page | after ElementRows |
| 37 | `settings/PetFrames.lua` | the Pet Frames page | after ElementRows |
| 38 | `settings/Profiles.lua` | the AceDBOptions page | last |

## Tests

`tests/run.lua` (load list, lifecycle kick, suite list), `tests/wow_mock.lua` (thin extender: unit
classes, distinct recording regions and status bars, scripted casts, unit data by token (range
included), secure attributes and state drivers, and every frame's alpha calls), `tests/degraded_env.lua` (library-absent load), `tests/perf.lua`
(offline scenarios, outside the gate), and one `tests/test_*.lua` per module. `tests/_kit/` is
vendored and never edited.
