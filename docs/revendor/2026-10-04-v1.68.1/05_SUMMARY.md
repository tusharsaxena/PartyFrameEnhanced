# 05 — Summary (PartyFrameEnhanced)

LibKa0s v1.68.0 -> v1.68.1 from the local annotated tag (`9fb7956`, commit `9000cbd`); base v1.68.0 from
the CLAUDE.md provenance line, agreeing with the last payload commit `21021e2`. Kit revision 35 -> 36.
Provenance rolled in the same commit as the bytes, with the addon's version-now lines
(`docs/ARCHITECTURE.md`, `docs/debug.md`, `docs/smoke-tests.md` INSTALL-4 and its Pending row) and the
three "kit 35" lines (`DEPENDENCIES.md:32`, `docs/testing.md:93`, `tests/test_surface_parity.lua:200`
comment). Minors: no file moved (32 of 32 unchanged). No file added or deleted, no cross-major skew, no
span bundle (3h empty), no base correction (Step 0 all `ok`).

- Delivered free (class A): the kit names the dev-copilot plugin's commands; the next bundle-writing
  runner run rewrites the one `RESULTS.md` lead-in line to `/dev-copilot:bump-version`.
- Contract blockers (3g): none. No major moved; no `__Attach*` site in the addon.
- Adopted: nothing. Zero adoption candidates.
- Declined: nothing; no interview held, no issue filed.
- Unreached: none.
- Smoke: INSTALL-4 stays pending, now naming v1.68.1; the library bytes it loads are v1.68.0's.
- Gate after the copy, every run through `ka0s-bounded`: `lua tests/run.lua` 454 passed, 0 failed,
  1 skipped, 455 total, including `tests/test_vendor_sync.lua`'s three cases (libs/LibKa0s and
  tests/_kit match the v1.68.1 tag; runner 100755). `luacheck .` 0 warnings / 0 errors in 79 files
  (`.luacheckrc` excludes `libs/` and `tests/_kit/`; the one host Lua change is a comment). Sighted
  complexity (`tests/_kit/run-automated-tests.sh --suite complexity --no-bundle`): pass, 0 warnings,
  max CCN 14, 1602 functions. Case count unchanged, so `docs/test-cases.md` and the README badge stay
  at 454/455.
