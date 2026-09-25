# Summary: LibKa0s v1.58.0 -> v1.60.0

Step 8 of `revendor-libka0s`, for plan item DR-PF-01 of the 2026-09-25 diagnostics rollout. One
commit carries both payloads, the `CLAUDE.md` provenance line, and the host edits the copy needs to
stay green. Nothing was adopted in this run: the report is DR-PF-03's, so this bundle has no
`04_EXECUTION_PLAN.md`.

## The tag and the minors

v1.58.0 to v1.60.0 (read with `git archive` from `../LibKa0s`, tag at `bed0eb1`), spanning v1.59.0,
which this addon skipped. **WidgetsDragHandle 2 -> 3**, **DebugLog 13 -> 14**, the new
**DebugLogDiagnostics 1**, **Slash 15 -> 16**, and the test kit **26 -> 27**. Every other file is
unchanged. Detail in `01_DELTA.md`.

## Delivered for free (class A)

- The debug console keeps 3000 lines instead of 1500.
- `lib.TIME_COPY`, the hand-set copy-timing switch.

## Contract items, fixed in the copy's commit

- **The DebugLog stub** in `core/DebugLogSetup.lua` gains `RunDiagnostics` (prints
  `L["%s is unavailable: the LibKa0s library did not load."]` with `/pfe diagnostics`, writes nothing,
  returns 0), `BuildDiagnostics` (an empty report) and `DebugVerb` (routes `diagnostics`, `on` and
  `off`, else `false`), so `test_surface_parity`'s DebugLog case stays green. A new case in
  `tests/test_surface_parity.lua` pins the stub's behavior on a real library-absent load.
- **`LIVE_WHILE_DISABLED`** in `settings/Slash.lua` gains `diagnostics`, because this addon passes a
  literal `liveVerbs` and Slash 16's default does not reach it. The verb is not registered yet, so it
  answers the unknown-command line until DR-PF-03.
- **`tests/run.lua`** lists the kit's `test_diagnostics_contract`, which is one declared skip until
  `Kit.diagnostics` is wired in DR-PF-03.

No host suite wrote a 1500 literal, so no test re-pins for the buffer. The value in the
`core/DebugLogSetup.lua:4` comment is left for DR-PF-05, which makes that comment value-free.

## Adopted, declined, unreached

Nothing adopted in this run. The report and the verb are planned for DR-PF-03 (`03_DECISIONS.md`).
No decline issues were filed, as the plan directs. The DragHandle close mark is not a candidate here.

## Docs

`CLAUDE.md` provenance line, the README `Tests` badge (353 -> 354; the kit skip is not counted, per
testing-§5), `docs/test-cases.md` regenerated, and the vendored version and the live-set sentences in
`docs/ARCHITECTURE.md` and `docs/slash-dispatch.md`.

## Gates

Every run through `/home/tushar/.claude/wow-addon/bin/ka0s-bounded`, from the repo root.

| Point | Harness | `luacheck` | `lizard` (CCN > 15) |
|---|---|---|---|
| Baseline (v1.58.0 payload) | 353 passed, 0 failed | 0 / 0 in 73 files | not run |
| After the copy alone | stopped by the kit inventory: `test_diagnostics_contract` not declared | not run | not run |
| After the host edits | 354 passed, 0 failed, 1 skipped (355) | 0 / 0 in 73 files | none |
