Candidates: LibKa0s v1.58.0 -> v1.60.0

# Candidates

Step 5 of `revendor-libka0s`. Sources: `git -C ../LibKa0s log --oneline v1.58.0..v1.60.0` (18
commits), the CHANGELOG's v1.59.0 and v1.60.0 blocks, and the `Since` markers in
`docs/api/DebugLog/version-14.1-docs.md` and `docs/api/Slash/version-16-docs.md`. The stub parity,
the live-set host copy and the kit suite entry are contract items (`01_DELTA.md`, 3g) and landed in
the copy's commit, so they are not candidates.

## A. Delivered on the re-vendor alone

- **The console keeps 3000 lines** (`MAX_BUFFER` 1500 -> 3000, `BUFFER_SLACK` 64 -> 128;
  CHANGELOG v1.60.0, *DebugLog minor 14*). The copy window and `SetMaxLines` follow the constant.
  This is not an adoption (the plan says so explicitly).
- **`lib.TIME_COPY`**, the copy-timing switch, turned on by hand with `/run`. Nothing to wire.
- **`diagnostics` in `lib.LIVE_VERBS`** (Slash 16). This addon passes a literal list, so it arrives
  only through the host copy in the copy's commit.

## B. Host change required

| Candidate | Evidence | Would touch | Blast radius | Recommendation |
|---|---|---|---|---|
| The diagnostics report: `D:RunDiagnostics`, `brandName` and `diagnostics` descriptor fields, `D:DebugVerb`, and `Kit.diagnostics` for the kit contract | `version-14.1-docs.md:56-91`, `:525-526`; CHANGELOG v1.60.0 *DebugLogDiagnostics minor 1*, *Test kit revision 27* | `core/DebugLogSetup.lua`, a new `modules/Diagnostics.lua`, `settings/Slash.lua`, TOC, locales, tests | additive | **Adopt in DR-PF-03** (debug-logging-§14 makes it a MUST at standard v2.68.0), after DR-PF-02's read-only seams |
| Slash 16's `diagnostics` verb registered in `NS.COMMANDS` | `Slash/version-16-docs.md:713-722` | `settings/Slash.lua` | additive | **Adopt in DR-PF-03**, with the report |
| `WidgetsDragHandle` minor 3 close mark (`spec.onClose`) | CHANGELOG v1.59.0 | none | none | **Not a candidate**: this addon has no DragHandle strip (its own Anchor grips) |

## C. Whole-module adoption

None new. Pool, Item and Widgets stay vendored and unwired, for the reasons `docs/ARCHITECTURE.md`
records; nothing in this range changes those premises.
