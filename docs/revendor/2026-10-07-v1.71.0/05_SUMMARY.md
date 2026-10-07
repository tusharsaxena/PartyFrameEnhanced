# 05 — Summary (PartyFrameEnhanced)

LibKa0s v1.70.0 -> v1.71.0 from the local annotated tag (`3bf1b97`, commit `cb274a4`); base v1.70.0 from
the CLAUDE.md provenance line, agreeing with the last payload commit `735a111`. Kit revision 37 -> 38.
Provenance rolled in the same commit as the bytes. Minors: Env 2, OptionsIdList 4, Slash 20,
SlashParse 2, WidgetsLineChart 3, WidgetsAutocomplete 2; the other 28 files unchanged. Kit gains
`secrets.lua`; nothing deleted, no cross-major skew. The unrecorded v1.69.0 and v1.70.0 re-vendors are
recorded in the span bundle `2026-10-07-v1.69.0-v1.70.0/`.

- Delivered free (class A): Env 2, OptionsIdList 4 and Slash 20.2 behaviour; kit 38's `--list` Totals.
- Contract blockers (3g): none.
- Adopted: nothing.
- Not adopted in this run: `Kit.secret` (kit 38), `WidgetsLineChart`, `WidgetsAutocomplete`.
- Declined: nothing; no interview held, no issue filed.
- Docs: `docs/test-cases.md` regenerated (Total 454, `Skipped | 1`), README badge 454/454; the live
  docs stop naming a tag or kit revision and point at the provenance line; the Overview re-vendor
  narrative is cut to one sentence pointing at `docs/revendor/`.
- Smoke: INSTALL-4 owes a run on v1.71.0 (clean load, `/pfe status`, `/pfe unlock`); the owner runs it.
- Gate after the copy, every run through `ka0s-bounded`: `lua tests/run.lua` 454 passed, 0 failed,
  1 skipped, including `tests/test_vendor_sync.lua`'s three cases (payloads match the v1.71.0 tag;
  runner 100755). `luacheck .` 0 warnings / 0 errors in 79 files. Complexity
  (`lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` and the sighted suite): 0 warnings, max CCN 14.
