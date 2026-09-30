# Summary (PartyFrameEnhanced)

LibKa0s v1.62.0 -> v1.63.0 from the local tag; Slash 16 -> 17, every other file unchanged; `tests/_kit`
stays at kit revision 31 (copied whole, byte-identical). CLAUDE.md provenance and
`docs/ARCHITECTURE.md`'s two version-now lines rolled. The library-absent Slash stub gains
`CliProfile` and `ProfileSwitch` (route (b)) in the same commit, because the by-name parity case goes
red on the copy alone. Adoption of the profile verb itself is item SP-PF-02's second commit.

Gate after the copy, before the stub: 381 passed, 2 failed (the Slash parity case, and the vendor
case until the provenance line moved).

Gate at the commit:

- tests: 384 passed, 0 failed, 0 skipped, 384 total (383 before; one stub case added)
- `docs/test-cases.md` regenerated with `lua tests/run.lua --list`; README badge 384/384
- luacheck: Total: 0 warnings / 0 errors in 75 files
- lizard (excluding `libs/` and `tests/_kit/`): 0 functions above CCN 15, 1325 functions
- vendor gate (`tests/test_vendor_sync.lua`): both payloads byte-identical to the tag, runner 100755
