# Summary: LibKa0s v1.54.2 -> v1.55.0

Step 8 of `revendor-libka0s`. Phase 5 ran the re-vendor (`01_DELTA.md`, commits `134d18c` and
`e331135`). This run decided and implemented the candidates under the owner's delegation
(`03_DECISIONS.md`).

## The tag and the minors

The tag moved from v1.54.2 to v1.55.0. Every existing file's LibStub minor is unchanged. Three
files are new: `Compat.lua` (`LibKa0s-Compat-1.0` minor 1), `Bus.lua` (`LibKa0s-Bus-1.0` minor 1)
and `Schema.lua` (`LibKa0s-Schema-1.0` minor 1). The kit moved from revision 24 to 25. The full
per-file table is in `01_DELTA.md`, 3b/3c.

## Delivered for free (class A)

- The layout-section-1 cap census gate, `tests/_kit/test_layout_cap.lua`, wired in `e331135`.
- The `.gitattributes` body case in `test_eol`, which passes with no edit.
- Suite declaration keyed by (basename, directory). No shadow or unreferenced report.
- The `test_prose` generated-data carve-out. Nothing to declare, since this addon has no generated
  data.
- The automated-test runner's commit SHA column, which takes effect on the next
  `/wow-addon:automated-tests` run.

## Contract blockers

None (`01_DELTA.md`, 3g).

## Adopted

| Candidate | Commit | What moved | Tests added |
|---|---|---|---|
| `LibKa0s-Bus-1.0` | `8a46028` | `core/Bus.lua`'s hand-written stand-down record becomes `Bus:New{ name, isDown }`, with `NS.NewBusTarget` / `NS.BusStandDown` / `NS.BusStandUp` kept as delegates. `NS.MSG` is `Bus.Catalog`. Without the library, the untracked-target stub. | `tests/test_bus.lua` +9 (3 characterization cases green on the old record first; the record-growth fix, the while-down deferral, the strict catalog, and 3 degraded cases); `tests/test_surface_parity.lua` +1 (Bus stub vs the major, by name) |
| `LibKa0s-Compat-1.0` | `d64703f` | `Compat.IsSecret` wired from the major, with the one-rung guard stub when it is absent | `tests/test_compat.lua` +4 (1 characterization case green on the host body first; live identity, degraded stub vs library under the same fixture, and `NS.Compat` parity with the 8 unwired members listed) |

Each commit also added the major's row to `tests/run.lua`'s `Kit.setSurfaceSource{}` map.
`docs/ARCHITECTURE.md` names each major (the Message Bus section, the Overview's consumed-major
list, and Known Limitations for the degraded bus). `docs/module-map.md` and `docs/compat-layer.md`
follow.

Live defect fixed by the Bus adoption: the hand-written record's `order` list gained an entry every
time a key was re-registered after an unregister (`core/Bus.lua:62-66` at `e331135`). RangeFade's
range-event toggle and Providers' Suspend/Resume grew it for the whole session. The new pin
("re-registering a key after forgetting it never grows the record") was red on the old record.

## Declined

| Candidate | Decision | Issue | Why |
|---|---|---|---|
| `LibKa0s-Schema-1.0` | not now (`state:triaged`, `severity:medium`) | [#14](https://github.com/tusharsaxena/PartyFrameEnhanced/issues/14) | One attempt went green on every existing suite, but it made `/pfe enable`, `/pfe disable` and `/pfe lock` stop writing on a library-less load. There the hollow Master controls composer leaves those paths without a row, and the prescribed stub refuses a row-less path. `settings/Slash.lua:147-150` and slash-commands-section-1 require the write to land. `tests/test_schema.lua:209` pins it and went red under the attempt. The code was rolled back. The characterization cases stayed as `3720782`. |

**[upstream] finding** (not patched locally): the Schema spec's JC-2 grep
(`Ka0sAddonsCommonTasks/.../3b-specs/schema.md:255-261`) and the Schema API document's stub
(`LibKa0s/docs/api/Schema/version-1-docs.md:308`) cover only the live build. They leave open what a
runtime-completing stub does with a path whose row a hollow composer did not emit. Every adopter
whose host verbs write a composed Master controls row shares this.

## Skipped or unreached

None unreached. `lizard` was not run: no candidate that landed moved a function's complexity
beyond one-line delegates, and the commit gate is the harness and `luacheck`.

## Gates

Every count below is from `ka0s-bounded lua tests/run.lua` and `ka0s-bounded luacheck .`, run from
the repo root.

| Point | Harness | `luacheck` |
|---|---|---|
| Baseline (`e331135`) | 268 passed, 0 failed, 0 skipped | 0 warnings / 0 errors in 71 files |
| Bus characterization, before the code moved | 271 passed, 0 failed | -- |
| `8a46028` Bus | 278 passed, 0 failed, 0 skipped | 0 / 0 in 71 files |
| Compat characterization, before the code moved | 279 passed, 0 failed | -- |
| `d64703f` Compat | 282 passed, 0 failed, 0 skipped | 0 / 0 in 71 files |
| Schema characterization, on the host seam | 288 passed, 0 failed | -- |
| Schema attempt, before the degraded pin | 288 passed, 0 failed | 1 warning (W212, stub `New`'s unused `self`) |
| Schema attempt, with the degraded pin | 288 passed, **1 failed** | -- |
| `3720782` characterization kept, attempt rolled back | 289 passed, 0 failed, 0 skipped | 0 / 0 in 71 files |

Perf (`ka0s-bounded lua tests/perf.lua`): `resolveUnchanged` was 0.0 bytes/iter at baseline and
0.0 under the Schema attempt. `settingsDrag`, which is reported but not asserted, went from 895.9
to 935.9, from the copy of a color table on write.

The bundle commit's own gate is reported in the run's chat summary, and in the commit that carries
this file.
