# Candidates

Range `git -C ../LibKa0s log --oneline v1.89.0..v1.90.0`; sources: the library `CHANGELOG.md` block v1.90.0 and the
API documents under `docs/api/` for every major whose minor moved (Core 16, Widgets 24.5.12.6.8.5, Skin
17.1.27.8.19.18.17.4.9, Options …5.5.7.7…).

## A. Delivered on the copy (not offered)

- **Pixel edges, Core 16 + Widgets 24 + WidgetsAutocomplete 8 + SkinPaint 19 + SkinPaintExtras 18**
  (`docs/api/Core/version-16-docs.md`, *What changed at this version: pixel edges (SF1-L1)*; CHANGELOG v1.90.0
  *One physical pixel*): `W.Dropdown`, `W.SearchBox`, the shared menu and the autocomplete list draw one physical
  pixel edge at any UI scale. All internal; "A host calls none of them." This addon draws no window of its own
  (`core/SkinSetup.lua`, the degradation facade's comment "this addon draws no window of its own"), so the
  library surfaces it wires (debug console, perf panel, skin picker) carry whatever of these they use with no
  host change.
- **OptionsAppearance 7** (`docs/api/Options/version-37.4.44.2.7.2.9.15.2.4.19.13.5.5.7.7.11.1.1.4-docs.md`,
  *What changed at this version*): a skin copy leaves a `keepScope` target's Scope alone. This addon is a copy
  source and target like any other; it takes the Scope as before.

## B. Host change required

- **`RegisterOwner(owner, { keepScope = true })`** (Skin 17, `docs/api/Skin/version-17.1.27.8.19.18.17.4.9-docs.md`,
  *What changed at this version*). Only for a host whose Scope is a documented deviation. This addon's
  `RegisterOwner` (`core/SkinSetup.lua`) documents none. Recommendation: not applicable, no action.

## C. Whole-module adoption

No new major in this range.
