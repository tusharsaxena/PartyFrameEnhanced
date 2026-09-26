# Decisions (PartyFrameEnhanced)

- **No adoption in this item.** The candidate-adoption interview is out of scope for the automated-tests
  sweep, and the release offers no new surface.
- **Stub:** unchanged. The four new files add no member to an Options instance, so the library-absent stub
  in `settings/OptionsSetup.lua` already mirrors the full surface, and the surface-parity case stays green.
- **Suite inventory:** unchanged. `tests/run.lua` derives the library load list from `LibKa0s.xml`, and no
  suite was added or removed.
- Plan: `Ka0sAddonsCommonTasks/docs/2026-09-26-AUTOMATED_TESTS_SWEEP/` (item PFE-ATS-RV; ATS-20, ATS-21).
