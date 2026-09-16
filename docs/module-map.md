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
| 7 | `core/Bus.lua` | `NS.bus`, `NS.NewBusTarget`, the `NS.MSG` catalog | before anything that subscribes |
| 8 | `core/Util.lua` | LSM handle and fetch, deep copy, fill-defaults | conventional |
| 9 | `core/EnvSetup.lua` | `NS.Meta`, `NS.Version` over LibKa0s-Env | conventional |
| 10 | `core/CoreSetup.lua` | printer, stringifier, class-color resolver, skin, `NS.MakeCloseButton` | **load-bearing**: after Namespace, before anything that prints |
| 11 | `core/PerfSetup.lua` | `NS.Perf`: buckets, suspend/resume | **load-bearing**: before every module's `local Perf = NS.Perf` |
| 12 | `core/DebugLogSetup.lua` | `NS.DebugLog`, `NS.Debug` | **load-bearing**: after Constants, State, CoreSetup |
| 13 | `core/Units.lua` | the five units, their target and pet tokens, labels, the include rule, the party-only rule (`InParty`) | conventional |
| 14 | `core/Database.lua` | AceDB init, the migration ladder | conventional (called at OnInitialize) |
| 15 | `core/PartyFrameEnhanced.lua` | AceAddon promotion, lifecycle, combat flag, the party flip, secure-write queue, module registry, VISIBILITY/PROFILE sender | after the seams it reclaims and calls |
| 16 | `defaults/Profile.lua` | every profile default | before the settings pages that read it |
| 17 | `modules/Providers.lua` | the three frame-system providers, detection, the unit → frame map; sends LAYOUT | **load-bearing**: registers first, so the lifecycle enables it before the features |
| 18 | `modules/Anchor.lua` | attached pin (memoized), free stack, drag and the position owner, secure combat fade/defer | after Providers, before the features that register with it |
| 19 | `modules/Element.lua` | the shared element regions, the config-driven restyle, class-color resolvers, the ladder's shared rungs | **load-bearing**: features capture `NS.Element` at file scope |
| 20 | `modules/CastBars.lua` | cast bars: per-unit events, the secret-safe cast lifecycle, preview content | after Element and Anchor |
| 21 | `modules/UnitButtons.lua` | the secure unit buttons the target and pet frames share: creation, state drivers, click attributes, health/name painting | **load-bearing**: TargetFrames and PetFrames capture `NS.UnitButtons` at file scope |
| 22 | `modules/TargetFrames.lua` | target frames: `UNIT_TARGET`, colors under secrets, raid markers, the gated health ticker | after UnitButtons |
| 23 | `modules/PetFrames.lua` | pet frames: owner and pet-token events, the owner's class color | after UnitButtons |
| 24 | `modules/Preview.lua` | preview mode: named holds (unlock, test), the lock ↔ preview link, the combat refusal | after every feature: its OnEnable reads the lock once every feature has registered with Anchor |
| 25 | `modules/StandIn.lua` | the stand-in party frame preview raises out of a party: three looks, the size and position copy, drag | before Preview, which drives it |
| 26 | `modules/Preview.lua` | preview, with the lock as its only switch (options-ui-§15): the two shapes it takes, the live switch, the refusals and exits | **load-bearing**: after StandIn, Anchor and Providers, which it drives |
| 27 | `settings/Schema.lua` | schema registry, dotted paths, the write seam, the bulk bracket, validation | before every page |
| 28 | `settings/Slash.lua` | `NS.COMMANDS` (incl. `status`, `test`), the Slash descriptor, `/pfe` + `/partyframeenhanced` | before OptionsSetup (the landing page renders its rows) |
| 29 | `settings/OptionsSetup.lua` | `NS.Helpers` (the Options instance) + load-completing stub | **load-bearing**: before every page file |
| 30 | `settings/About.lua` | the landing page body | after OptionsSetup |
| 31 | `settings/General.lua` | Master controls + Party frames tabs, the reset popup | after OptionsSetup |
| 32 | `settings/ElementRows.lua` | the Size & Position rows and the composed Border / Font / Bar / Background blocks the feature pages share; the page builder | **load-bearing**: every feature page calls it at load |
| 33 | `settings/CastBars.lua` | the Cast Bars page | after ElementRows |
| 34 | `settings/TargetFrames.lua` | the Target Frames page | after ElementRows |
| 35 | `settings/PetFrames.lua` | the Pet Frames page | after ElementRows |
| 36 | `settings/Profiles.lua` | the AceDBOptions page | last |

## Tests

`tests/run.lua` (load list, lifecycle kick, suite list), `tests/wow_mock.lua` (thin extender: unit
classes, distinct recording regions and status bars, scripted casts, unit data by token, secure
attributes and state drivers), `tests/degraded_env.lua` (library-absent load), `tests/perf.lua`
(offline scenarios, outside the gate), and one `tests/test_*.lua` per module. `tests/_kit/` is
vendored and never edited.
