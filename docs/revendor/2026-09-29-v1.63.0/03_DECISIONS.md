# Decisions (PartyFrameEnhanced)

- **No adoption interview and no GitHub issues.** The adoption was decided upstream of this item by
  the owner (decisions D1-D3 of the 2026-09-29 run). Only the Slash minor 17 profile surface is
  adopted, and only by item SP-PF-02: the `profiles` descriptor field, `CliProfile` and
  `ProfileSwitch`, wired in the item's second commit (`/pfe profile` via CliProfile).
- **Stub, in the re-vendor commit:** the library-absent Slash stub in `settings/Slash.lua` gains
  `CliProfile` and `ProfileSwitch` on route (b): each prints the one library-absent line for
  `/pfe profile` and switches nothing (`ProfileSwitch` answers `false`). A new case in
  `tests/test_surface_parity.lua` pins that, and the by-name parity case goes green again.
- **Suite inventory:** one case added (383 -> 384); `docs/test-cases.md` and the README badge
  regenerated.
- Plan: `Ka0sAddonsCommonTasks/docs/2026-09-29-SMOKE_REWORK_AND_PROFILE_VERB/` (item SP-PF-02, spec S3).
