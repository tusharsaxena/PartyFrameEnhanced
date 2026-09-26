# Summary (PartyFrameEnhanced)

LibKa0s v1.61.0 -> v1.62.0 from the local tag; `tests/_kit` kit revision 27 -> 31; CLAUDE.md provenance
and `docs/ARCHITECTURE.md`'s two version-now lines rolled. No host code change, no stub change.

Gate after the copy:

- tests: 383 passed, 0 failed, 0 skipped, 383 total (383 before the copy)
- `docs/test-cases.md` regenerated with `lua tests/run.lua --list`: byte-identical, no case added, removed or renamed
- luacheck: Total: 0 warnings / 0 errors in 75 files
- lizard (excluding `libs/` and `tests/_kit/`): 0 functions above CCN 15, 1318 functions
- vendor gate (`tests/test_vendor_sync.lua`): both payloads byte-identical to the tag, runner 100755
