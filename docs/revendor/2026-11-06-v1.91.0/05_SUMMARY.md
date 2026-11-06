# Summary

**LibKa0s v1.90.0 -> v1.91.0** (item FU-RV-PFE of Ka0sAddonsCommonTasks `docs/2026-11-06-FOLLOWUPS_V1_91/`). The tag
is local, at library commit `55bfbb4`. The base came from the `CLAUDE.md` provenance line and agrees with the last
payload commit `2da8bb4`.

| File | old | new |
|---|---|---|
| Core.lua | 16 | 17 |
| CorePixel.lua | (new) | 1 |
| SkinPaintExtras.lua | 18 | 19 |
| SkinPaintHud.lua | (new) | 1 |
| SkinAceConfirm.lua | (new) | 1 |
| Widgets.lua | 25 | 26 |
| WidgetsDropdown.lua | (new) | 1 |
| WidgetsLineChart.lua | 6 | 7 |
| Kit (`Kit.VERSION`) | 51 | 51 |

- **Step 0:** skipped (the installed skill's roster regex matches nothing; fixed upstream in FU-DC1). **Span
  bundle:** none (3h printed nothing). **Base correction:** none.
- **Delivered free (class A):** the line chart's axis, grid, markers, crosshair and series in physical pixels
  (WidgetsLineChart 7; this addon draws no chart), and the four peels (CorePixel, WidgetsDropdown, SkinPaintHud,
  SkinAceConfirm), which move code with no member or behavior change.
- **Contract blockers (3g):** none. The Core, Skin and Widgets documents each state a pure move with an unchanged
  member manifest; no `__Attach*` site. The library file list is read from `LibKa0s.xml` by `Loader.xmlFiles`
  everywhere (`tests/run.lua:24` and three more), so the four new files load in the tag's order with no edit. No
  test pins a moved minor, and no stub mirrors a moved member.
- **Icons:** `LibKa0s icons:` line kept as is (12 names). Content and byte diffs were empty against the whole copy
  before the prune; the prune printed `12 icon(s) declared; kept 13 file(s), removed 5827` (the whole-catalog copy
  cut back to the declaration; no icon file in the repo changed). No provenance split. **README credits:** unchanged
  (Open Iconic only). **Dead stub mirrors:** none.
- **Adopted:** nothing. **Declined / filed:** nothing, no issue. **Unreached:** nothing.
- **Gate:** `ka0s-bounded luacheck .` 0 warnings / 0 errors in 92 files (`.luacheckrc` excludes `libs/` and
  `tests/_kit/`; no seam file changed); `ka0s-bounded lua tests/run.lua` 647 passed, 0 failed, 1 skipped (the
  diagnostics opt-out case, by design), 648 total, the vendor-sync cases passing. Largest own Lua file 903 lines
  (`tests/test_skin_flip.lua`), under the 1500-line cap. No own Lua changed, so CCN is as before.
