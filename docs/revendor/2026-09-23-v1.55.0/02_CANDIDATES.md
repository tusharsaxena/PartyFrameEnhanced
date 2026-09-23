# Candidates: LibKa0s v1.54.2 -> v1.55.0

Step 5 of `revendor-libka0s`. Sources, in the playbook's order: the `CHANGELOG.md` v1.55.0 block
(`git -C ../LibKa0s log --oneline v1.54.2..v1.55.0`), the three new majors' version-1 API documents,
and, as the owner's delegation directs, the per-consumer adoption deltas in the suite sweep's design
specs (`Ka0sAddonsCommonTasks/docs/2026-09-22-SUITE_STANDARDS_AND_LIBKA0S_SWEEP/3b-specs/`).

No existing major moved a minor (`01_DELTA.md`, 3c), so there are no `Since` markers to diff on a
consumed major. Every candidate below is class C: a whole major this addon does not consume today
(`01_DELTA.md`, 3e).

## Recorded declines searched first

```sh
gh issue list --search "LibKa0s" --state all --json number,title,state,labels     # []
grep -rn 'LibKa0s' docs --include='*.md' | grep -iE 'declin|not adopt|no combat|exempt'   # nothing outside frozen bundles
```

No settled decline exists for any of the three.

## Class A: delivered by the re-vendor alone (not offered)

| Item | Evidence | Where it landed |
|---|---|---|
| Kit revision 25: `test_layout_cap.lua` (the layout-section-1 cap census) | CHANGELOG v1.55.0, "`test_layout_cap.lua` -- the cap gate, in the kit" | wired in `tests/run.lua` by commit `e331135`; census heading by `134d18c` |
| `test_eol` second case (the `.gitattributes` body) | CHANGELOG v1.55.0, "`test_eol.lua` -- a second case" | passes with no edit ("Nothing is owed") |
| Suite declaration keyed by (basename, directory) | CHANGELOG v1.55.0, "The declaration is the pair" | the runner already uses the pair form; no shadow report |
| `test_prose` generated-data carve-out (`Kit.prose.exempt`) | CHANGELOG v1.55.0, "`test_prose.lua` -- the generated-data carve-out" | this addon has no generated data; nothing to declare |
| Automated-test runner names the commit SHA | CHANGELOG v1.55.0, "The automated-test runner names the commit every row measured" | takes effect on the next `/wow-addon:automated-tests` run |

## Class B: host change required

None. The CHANGELOG block names no new descriptor field, row type or seam on a major this addon
consumes.

## Class C: whole-major adoption

### C1. `LibKa0s-Bus-1.0`: the stand-down record and the message catalog

- **What:** replace `core/Bus.lua`'s hand-written stand-down record with `Bus:New{...}` and
  `Bus.Catalog`, keeping `NS.NewBusTarget`, `NS.BusStandDown`, `NS.BusStandUp` and `NS.MSG`.
- **Evidence:** `LibKa0s/docs/api/Bus/version-1-docs.md:93-100` (instance surface), `:257-313`
  (worked example and stub), `:184-220` (`Catalog`); spec `bus.md:549-560` ("PartyFrameEnhanced --
  the reference design moves upstream almost verbatim").
- **Live defects it fixes here:** `core/Bus.lua:62-66` `remember` appends an `order` entry every
  time a key is re-registered after `forget`, so `order` grows without bound on every toggle.
  `modules/RangeFade.lua:163-172` toggles `UNIT_IN_RANGE_UPDATE`; `modules/Providers.lua:348-359`
  forgets five events at every Suspend and re-adds them at every Resume. `core/Bus.lua:25,34,36,110`
  carry double-encoded mojibake in comments. CallbackHandler's optional `arg` is dropped on replay
  (latent: no site passes one).
- **Files:** `core/Bus.lua`, `tests/test_bus.lua`, `tests/test_surface_parity.lua`, `tests/run.lua`
  (surface-source row), `docs/ARCHITECTURE.md` (Message Bus, Known Limitations).
- **Blast radius:** replaces host code (the record, 108 lines). Two semantics move: a registration
  made while stood down is recorded and not live until stand-up, and a stand-up is refused while the
  latch reads down. Both are the direction `slash-commands-section-7` asks for. The degraded build
  loses the record (the untracked-target stub), which the spec says the host's Known Limitations
  names.
- **Recommendation:** adopt.

### C2. `LibKa0s-Compat-1.0`: the secret guard `IsSecret`

- **What:** `Compat.IsSecret` wired from the major, with the guard stub (the one-rung body)
  when the library is absent. Every other `NS.Compat` member is addon-specific and stays.
- **Evidence:** `LibKa0s/docs/api/Compat/version-1-docs.md:169-241` (guard stub, wiring, the gate);
  spec `compat.md:537-540`.
- **Files:** `core/Compat.lua:11-16`, `tests/test_compat.lua`, `tests/run.lua` (surface-source row).
- **Blast radius:** replaces 4 lines of host code. The guard's answer is normalized to
  `fn(v) and true or false` (was `fn(v) == true`): identical for the client's boolean answer.
- **Recommendation:** adopt.

### C3. `LibKa0s-Schema-1.0`: the settings schema runtime (full adopter)

- **What:** `settings/Schema.lua` becomes the setup file: `SchemaLib:New{...}` or a
  runtime-completing host stub, instance stashed as `NS.SchemaRuntime`, the host's public names
  (`NS.SetByPath`, `NS.FindSchemaRow`, `NS.RegisterSchemaRows`, `NS.ApplyDefault`, `NS.Bulk`,
  `NS.ResolvePath`, `NS.SetPath`, `NS.ProfileRowsOffDefault`, `NS.ResetProfileCounted`,
  `NS.ConsumeResetCount`, `NS.ValidateSchema`) bound to instance members.
- **Evidence:** `LibKa0s/docs/api/Schema/version-1-docs.md:115-221` (instance surface, `Set`
  pipeline, bracket, count, `Validate`), `:284-358` (the degradation stub), `:385-406` (adoption
  notes); spec `schema.md:507-518` ("PartyFrameEnhanced -- full adopter").
- **Files:** `settings/Schema.lua`, `settings/General.lua` (session and global registries become
  row `get`/`set`), `settings/OptionsSetup.lua`, `settings/Slash.lua`, `tests/test_schema.lua`,
  `tests/test_surface_parity.lua`, `tests/run.lua`, `docs/ARCHITECTURE.md`, `docs/schema.md`.
- **Blast radius:** the largest of the three. Replaces the registry, the path primitives, the write
  seam, the bracket, the reset count and the validator (about 300 lines), and changes on purpose:
  an unknown path is refused instead of stored, a table value is copied into the store, the
  `"%s refused"` debug line is dropped, `SetByPath` answers `false, err` on refusal, the minimap
  row's reset exemption becomes bracket-scoped `resetExempt`, and `Validate` requires `group` on
  every row and reports duplicates. `tests/perf.lua` `resolveUnchanged` (0 bytes/iter) must hold.
- **Recommendation:** adopt, after one honest attempt; decline as "not now" if it cannot land green
  without an unplanned behavior change a test pins or a player would see.
