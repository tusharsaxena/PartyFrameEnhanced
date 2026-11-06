# Summary

**LibKa0s v1.85.0 -> v1.89.0** (item V89-PFE of Ka0sAddonsCommonTasks `docs/2026-11-06-REVENDOR_LIBKA0S_V1_89/`).
The base came from the `CLAUDE.md` provenance line and agrees with the last payload commit `1cb3864`.

| File | old | new |
|---|---|---|
| Toast.lua | 3 | 4 |
| Widgets.lua | 22 | 23 |
| DebugLogDiagnostics.lua | 6 | 7 |
| IconBrowserSources.lua / IconBrowserWindow.lua / IconBrowser.lua | (new) | 1 / 1 / 1 |
| Kit (`Kit.VERSION`) | 50 | 51 |

- **Span bundle:** none (3h printed nothing). **Base correction:** none (Step 0 row `ok`).
- **Delivered free (class A):** kit 51's CallbackHandler unregister guard (a flake fix); DebugLogDiagnostics 7's
  report header (names IconBrowser only where it runs); Widgets 23 draws flat menus as 22 did.
- **Contract blockers (3g):** none. Only DebugLog among the consumed majors moved, with no member change; no
  `__Attach*` site; no Toast stub; no pinned diagnostics minor.
- **Icons:** `LibKa0s icons:` line kept as is (12 names). The prune printed `kept 13 file(s), removed 5827` (the
  whole-catalog copy cut back to the declaration; the shipped set is the same as at v1.85.0, so no icon file in the
  repo changed). No provenance split. **README credits:** unchanged (Open Iconic only, as before).
  **Dead stub mirrors:** none (`__releaseChrome` finds nothing).
- **Adopted:** nothing (the plan names no adoption for this addon). **Declined / filed:** nothing, no issue.
- **Settled / not applicable:** IconBrowser (no icon chooser), Widgets 23 cascading fields (no `W.ContextMenu` site),
  Toast 4 stack (Toast not consumed).
- **Gate:** `ka0s-bounded luacheck .` 0 warnings / 0 errors in 92 files; `ka0s-bounded lua tests/run.lua` 647 passed,
  0 failed, 1 skipped (the diagnostics opt-out case, by design), 648 total, the three vendor-sync cases passing.
  Largest own Lua file 903 lines (`tests/test_skin_flip.lua`), under the 1500-line cap.
