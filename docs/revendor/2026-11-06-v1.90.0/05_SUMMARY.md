# Summary

**LibKa0s v1.89.0 -> v1.90.0** (item SF1-RV-PFE of Ka0sAddonsCommonTasks `docs/2026-11-06-REVENDOR_LIBKA0S_V1_89/`,
from `SF1_SMOKE_FEEDBACK.md`). The tag is local, at library commit `4485b8f`. The base came from the `CLAUDE.md`
provenance line and agrees with the last payload commit `ddf71c8`.

| File | old | new |
|---|---|---|
| Core.lua | 15 | 16 |
| Skin.lua | 16 | 17 |
| SkinPaint.lua | 18 | 19 |
| SkinPaintExtras.lua | 17 | 18 |
| Widgets.lua | 23 | 24 |
| WidgetsAutocomplete.lua | 7 | 8 |
| OptionsAppearance.lua | 6 | 7 |
| Kit (`Kit.VERSION`) | 51 | 51 |

- **Span bundle:** none (3h printed nothing). **Base correction:** none (Step 0 row `ok`).
- **Delivered free (class A):** one-physical-pixel edges on the Widgets dropdown, search box, menus and
  autocomplete list (Core 16, Widgets 24, Autocomplete 8, SkinPaint 19, Extras 18); a skin copy that leaves a
  `keepScope` target's Scope alone (OptionsAppearance 7).
- **Contract blockers (3g):** none. Core, Skin and Options moved with no member change; `keepScope` is opt-in for a
  documented Scope deviation, which this addon has none of; no `__Attach*` site; no test pins a moved minor.
- **Icons:** `LibKa0s icons:` line kept as is (12 names). Content and byte diffs were empty against the whole copy
  before the prune; the prune printed `12 icon(s) declared; kept 13 file(s), removed 5827` (the whole-catalog copy
  cut back to the declaration; the shipped set is the same as at v1.89.0, so no icon file in the repo changed).
  No provenance split. **README credits:** unchanged (Open Iconic only). **Dead stub mirrors:** none.
- **Adopted:** nothing. **Declined / filed:** nothing, no issue. **Not applicable:** `keepScope`.
- **Gate:** `ka0s-bounded luacheck .` 0 warnings / 0 errors in 92 files (`.luacheckrc` excludes `libs/` and
  `tests/_kit/`; no seam file changed); `ka0s-bounded lua tests/run.lua` 647 passed, 0 failed, 1 skipped (the
  diagnostics opt-out case, by design), 648 total, the vendor-sync cases passing. Largest own Lua file 903 lines
  (`tests/test_skin_flip.lua`), under the 1500-line cap. No own Lua changed, so CCN is as before.
- **Column-header check (owner ruling SF1 #5):** not applicable. This addon draws no window of its own
  (`core/SkinSetup.lua:444`); its only `SortHeaderBar` mention is that name in the no-library facade's no-op list
  (`core/SkinSetup.lua:450`). Its own backdrops are unit-frame borders (`modules/Element.lua:66`,
  `modules/StandIn.lua:96`), not header dividers. No `SF1-PFE-HDR` commit.
