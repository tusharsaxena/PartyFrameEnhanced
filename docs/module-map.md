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
| 5 | `core/Constants.lua` | fallback media, `FONT_MONO`, logo path, the nine anchor points, the frame layering table `LAYERS` | reads NS.MediaFont at load |
| 6 | `core/State.lua` | session state: `debug`, `inCombat`, `preview`, `inParty`, `followRefused` | conventional |
| 7 | `core/Bus.lua` | `NS.bus`, the `NS.busRecord` stand-down record (`LibKa0s-Bus-1.0`), `NS.NewBusTarget` / `NS.BusStandDown` / `NS.BusStandUp`, the `NS.MSG` catalog (`Bus.Catalog`) | before anything that subscribes |
| 8 | `core/Util.lua` | LSM handle and fetch, deep copy, fill-defaults | conventional |
| 9 | `core/EnvSetup.lua` | `NS.Meta`, `NS.Version` over LibKa0s-Env | conventional |
| 10 | `core/CoreSetup.lua` | printer, stringifier, class-color resolver, `NS.MakeCloseButton` (the owner bound); no window skin of its own, which is `core/SkinSetup.lua`'s | **load-bearing**: after Namespace, before anything that prints |
| 11 | `core/SkinSetup.lua` | the `LibKa0s-Skin-1.0` seam (skinning-§1, §3): registers the owner `"PartyFrameEnhanced"` at file load with its brand, its read and write seams (`NS.SkinChoice`, `NS.WriteSkinChoice`, through `NS.SetByPath`), the debug console as the provider's log and the owner token `pf.mover` (`NS.SKIN_TOKENS`); publishes `NS.Skin` (the owner's facade), `NS.ApplySkinChoice` / `NS.ApplySkinIgnore` / `NS.ApplySkinOverride` (`Skin:SetChoice` / `SetIgnore` / `SetOverride`: no argument the stored values, one half nil only the other), `NS.SkinOverride`, `NS.SkinPaintAceTree` (the Profiles page's tree), the first-run picker's `NS.MaybeShowSkinPicker` / `NS.ScheduleSkinPicker` / `NS.HideSkinPicker` / `NS.SkinPickerSpec`, the Skin tab rows' values (`NS.SKIN_SOURCE_VALUES` / `_SORTING`, `NS.SKIN_VALUES` / `_SORTING`) and `NS.SKIN_FALLBACK`; without the library a degraded facade that answers every vocabulary name and draws Ka0s Default from the fallback copy | **load-bearing**: after CoreSetup (`NS.Print`), before PerfSetup, DebugLogSetup and every module (`NS.Skin`) and before `settings/General.lua` (the rows' values at load); at file load so the EllesmereUI provider offers the owner before EllesmereUI dispatches its skins |
| 12 | `core/LifecycleSetup.lua` | `NS.lifecycle`: the one `LibKa0s-Lifecycle-1.0` latch, its `disabled` / `perf` holds, `NS.IsStoodDown`, `NS.ApplyEnabled` | **load-bearing**: `core/PerfSetup.lua` requires `descriptor.lifecycle`, so the instance must exist before it |
| 13 | `core/PerfSetup.lua` | `NS.Perf`: buckets, and the latch the harness takes its `perf` hold on | **load-bearing**: before every module's `local Perf = NS.Perf` |
| 14 | `core/DebugLogSetup.lua` | `NS.DebugLog`, `NS.Debug`, and the console's change gates `NS.DebugOnce` / `NS.DebugChanged` / `NS.DebugForget` and at-enable queue `NS.DebugAtEnable` (no-op stubs when the library is absent); the console descriptor, including the diagnostics report's brand, its one localized chat line and the call-time `diagnostics` hook that asks `modules/Diagnostics.lua` for its sections; the library-absent stub, whose `RunDiagnostics` prints the one library-absent line | **load-bearing**: after Constants, State, CoreSetup |
| 15 | `core/LauncherSetup.lua` | `NS.Launcher`: the one LibDataBroker object, its icon, the left click's `openSettings`, and the accessor-and-toggle pairs the library's status tooltip and right-click options menu read (enabled + `NS.SetEnabled`, locked + `NS.ToggleLock`, version) (launcher-§1/§2) | conventional: every seam is reached at click or `Register` time, and `Register` runs in `addon:OnEnable` |
| 16 | `core/Units.lua` | the five units, their target and pet tokens, labels, the include rule, the party-only rule (`InParty`) | conventional |
| 17 | `core/Database.lua` | AceDB init (ending with the stored skin applied, `NS.ApplySkinChoice`), the migration ladder (v2: the HUD companions' one-time reset) | conventional (called at OnInitialize) |
| 18 | `core/PartyFrameEnhanced.lua` | AceAddon promotion, lifecycle, combat flag, the party flip, secure-write queue, module registry, VISIBILITY/PROFILE sender; the skin picker's login fuse and its take-down on the stand-down; every profile adopt applies the new profile's skin first | after the seams it reclaims and calls |
| 19 | `defaults/Profile.lua` | every profile default | before the settings pages that read it |
| 20 | `modules/Providers.lua` | the three frame-system providers (which re-sort: `resorts`), detection, the unit → frame map, `ForEachActiveFrame`; sends LAYOUT; read-only | **load-bearing**: registers first, so the lifecycle enables it before the features |
| 21 | `modules/Anchor.lua` | attached pin (memoized), free stack, drag and the position owner, secure combat fade/defer (or follow, when `SecureFollow.Covers`), `PlacementOf`, `ForEachHolder`; the holders' plate (owner token `pf.mover`) and caption (`S.Text` accent), repainted on `NS.Skin.OnLooksChanged` | after Providers, before the features that register with it |
| 22 | `modules/RangeFade.lua` | one fade frame per unit that every element is parented to; copies the party frame's own out-of-range alpha (EllesmereUI, Blizzard raid-style, by post-hooking `SetAlpha` / `SetAlphaFromBoolean`) or, on Blizzard classic, runs its own `UnitInRange` check; also sets each fade frame's strata and level (`general.strata`: by default the party frame's strata, one level over its highest child) and each free-placement holder's (its stack's lowest fade frame's), through `NS.RunSecure("fade:strata")` | **load-bearing**: after Providers, before every feature — the features parent their elements to `NS.RangeFade.Parent(unit)` at OnEnable |
| 23 | `modules/Element.lua` | the shared element regions and their inherited layer ladder (the overlay frame over the border), the config-driven restyle (the bar texture, border style and font resolved through `NS.Skin.Resolve` and each `…FromSkin` companion, memoized on the resolved keys), class-color resolvers, the ladder's shared rungs | **load-bearing**: features capture `NS.Element` at file scope |
| 24 | `modules/CastBars.lua` | cast bars: per-unit events, the secret-safe cast lifecycle, preview content | after Element and Anchor |
| 25 | `modules/UnitButtons.lua` | the secure unit buttons the target and pet frames share: creation, state drivers, click attributes, health/name painting | **load-bearing**: TargetFrames and PetFrames capture `NS.UnitButtons` at file scope |
| 26 | `modules/TargetFrames.lua` | target frames: `UNIT_TARGET`, colors under secrets, raid markers, the gated health ticker (which also repaints an unresolved target) | after UnitButtons |
| 27 | `modules/PetFrames.lua` | pet frames: owner and pet-token events, the owner's class color, raid markers | after UnitButtons |
| 28 | `modules/SecureFollow.lua` | the in-combat follow (#3): one `SecureHandlerBaseTemplate` header holding a frame ref to every target and pet button and the placement attributes its restricted snippet reads, synced out of combat only; the snippet wrapped lazily on each protected member frame of a re-sorting provider (EllesmereUI, Blizzard raid-style); `Covers`, which Anchor asks before an in-combat fade; the stand-down unwrap where ours is outermost | **load-bearing**: after Providers (reads `NS.Providers.__list` at load) and after TargetFrames and PetFrames, whose buttons its OnEnable takes frame refs to |
| 29 | `modules/StandIn.lua` | the stand-in party frame preview raises out of a party: three looks, the size, position and strata copy, drag | before Preview, which drives it |
| 30 | `modules/Preview.lua` | preview, with the lock as its only switch (options-ui-§15): the two shapes it takes, the live switch, the refusals and exits | **load-bearing**: after StandIn, Anchor and Providers, which it drives |
| 31 | `modules/Diagnostics.lua` | `NS.Diagnostics.Sections()`: the sections of `/pfe diagnostics` (identity, settings, party, frames, placement, elements, rangefade, secure, events), read-only ([debug.md](debug.md)) | conventional: `core/DebugLogSetup.lua` asks for the sections at run time, and every seam they read is reached through NS then |
| 32 | `settings/Schema.lua` | the `LibKa0s-Schema-1.0` seam: the instance (registry, write seam, bracket, reset count, validation) bound onto the host names, and its degradation stub | before every page |
| 33 | `settings/Slash.lua` | `NS.COMMANDS` (incl. `enable` / `disable`, `lock` / `unlock`, `status`, `diagnostics` and `profile`; `runDebug` hands `debug diagnostics` to the same report, and `runProfile` routes the profile list and every switch through the library's `cli:CliProfile` / `cli:ProfileSwitch`), the Slash descriptor, `/pfe` + `/partyframeenhanced` | before OptionsSetup (the landing page renders its rows) |
| 34 | `settings/OptionsSetup.lua` | `NS.Helpers` (the Options instance) + load-completing stub | **load-bearing**: before every page file |
| 35 | `settings/About.lua` | the landing page body | after OptionsSetup |
| 36 | `settings/General.lua` | Master controls + All elements tabs, the seven `skin.*` rows and the library's Skin tab (`H.AppearanceTab`, last), the reset popup | after OptionsSetup; **load-bearing** as a block with the pages below: each registers its options page at load, and the sidebar lists them in registration order |
| 37 | `settings/ElementRows.lua` | the Size and position rows and the composed Border / Font / Bar / Background blocks the feature pages share; the page builder | **load-bearing**: every feature page calls it at load |
| 38 | `settings/CastBars.lua` | the Cast Bars page | after ElementRows; sidebar order |
| 39 | `settings/TargetFrames.lua` | the Target Frames page | after ElementRows; sidebar order |
| 40 | `settings/PetFrames.lua` | the Pet Frames page | after ElementRows; sidebar order |
| 41 | `settings/Profiles.lua` | the AceDBOptions page, its AceConfigDialog tree painted for the skin owner after every Open (`NS.SkinPaintAceTree`) | last, so it is the sidebar's last page |

## Tests

`tests/run.lua` (load list, lifecycle kick, suite list), `tests/wow_mock.lua` (thin extender: unit
classes, distinct recording regions and status bars, scripted casts, unit data by token (range
included), secure attributes and state drivers, every frame's alpha calls, and the SecureHandler surface: the template-gated header, the wrap / unwrap recorder, `__changeAttribute` and the restricted environment the follow's snippets run in), `tests/degraded_env.lua` (library-absent load), `tests/launcher_env.lua` (a second whole-tree load against fake LibDataBroker-1.1 / LibDBIcon-1.0 majors, for `tests/test_launcher.lua`), `tests/mock_menu.lua` (the library's client-menu fake, copied verbatim), `tests/perf.lua`
(offline scenarios, outside the gate), and one `tests/test_*.lua` per module, the skin seam's included
(`test_skinsetup.lua`, `test_skin_holders.lua`, `test_skin_hud.lua`, `test_skin_picker.lua`, and
`test_skin_literals.lua`, the color literal gate). `tests/_kit/` is
vendored and never edited.
