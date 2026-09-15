# 05 — Execution plan: Ka0s Party Frame Enhanced v0.1.0

This is the hand-off to the remediation session. Work is trunk-based on `master`, each checkbox is one
green commit (`lua tests/run.lua` passing and `luacheck .` at 0/0), and nothing is pushed or
version-bumped without an explicit instruction. Each step names its deviation ID from `02_DEVIATIONS.md`.

Headline: **11 root deviations**, of which 7 are Low and 4 are Info, and none has a dependent. **6 MUST
failures**, all Low. Nothing here blocks play-testing (P10). Sprint 1 should land before the v0.1.0 tag.

---

## Sprint 1 — code-shaped MUSTs (before the tag)

- [ ] **PFE-03** — the write-seam veto.
  1. Add a failing case: an unlock with `InCombatLockdown() == true` must leave `locked == true`,
     append no `[Set]` line, skip `onChange` and publish no CONFIG. Record the mutation that reddens
     it in the case's comment.
  2. Add the pre-store `row.validate` step to `NS.SetByPath` (`settings/Schema.lua:159`). First
     confirm there is no `validate` key in the vendored Options/Slash row fields.
  3. Attach `validate` to the `locked` row by path in `settings/General.lua`. Remove the
     `NS.SetSetting` revert from `modules/Preview.lua:35-41`.
  4. Green gate. Regenerate `docs/test-cases.md` and update the README `Tests` badge.
- [ ] **PFE-02** — annotate `settings\Schema.lua`.
  1. Add the `# LOAD-BEARING: publishes NS.RegisterSchemaRows, …` line above `PartyFrameEnhanced.toc:81`.
  2. Add the load-order case pinning Schema before every page and asserting the note.
  3. Green gate, test-cases.md and badge.
- [ ] **PFE-06** — the stub cases.
  1. Env: a degraded case covering `NS2.Version()` and `NS2.Meta("Version")`. If it is a new suite
     file, add it to `tests/run.lua`'s `suites` in the same commit.
  2. Perf: register `NS.Perf` in `Kit.setSurfaceSource` and add an `assertSurfaceParity` case with
     named live-only exclusions. Otherwise, name the member grep in `tests/test_perfsetup.lua:44`'s
     comment.
  3. Green gate, test-cases.md and badge.
- [ ] **PFE-07** — the global reset's blast radius.
  1. Add one case to `tests/test_optionssetup.lua`, covering a second profile, `RestoreAllDefaults`,
     the profile list and active profile unchanged, the session row swept, and one `PROFILE`. Extend
     `tests/wow_mock.lua` only if the AceDB fake lacks `SetProfile`/`GetProfiles`.
  2. Green gate, test-cases.md and badge.

## Sprint 2 — coverage and strings

- [ ] **PFE-04** — feature trace lines.
  1. Add gated `NS.Debug` lines per `04_TECHNICAL_DESIGN.md` for cast start/stop/interrupt, the show
     decision's hidden reasons (one per pass), target change, ticker transitions and pet swap. Keep
     list-building behind `NS.State.debug`.
  2. `lua tests/perf.lua` must keep `probeOverheadOff` within its ceiling. A test must show the debug
     console gains a `[Cast]` line on a mocked cast start with debug on.
  3. Green gate, test-cases.md and badge.
- [ ] **PFE-05** — route the strings, or record English-only.
  1. Decide (the maintainer): translate later (keep #9 open), or decline (close #9 `state:will-not-do`).
  2. If routing: move `settings/Slash.lua`'s chat literals, the `NS.COMMANDS` descriptions,
     `settings/About.lua:16` and `settings/General.lua:106-108` onto `L[...]`, as whole sentences
     with placeholders, and add the keys to `locales/enUS.lua`. Re-run the dead-key check
     (`03_EVIDENCE.md` §E17) and expect 0 dead keys.
  3. If declining: add the `localization-§1` row to `docs/ARCHITECTURE.md` → `## Documented deviations`,
     with the trigger `the first non-English locale file added to locales/`.
  4. Green gate.

## Sprint 3 — docs (last, after the counts above have moved)

- [ ] **PFE-01** — one doc sync.
  1. Fix every site listed in `02_DEVIATIONS.md` PFE-01 and `03_EVIDENCE.md` §E15:
     - `docs/ARCHITECTURE.md:25-26`, `:30`, `:48`;
     - `docs/schema.md:69`;
     - `docs/data-flow.md:51-54`;
     - `docs/testing.md:19-23`, `:34-35`;
     - `docs/common-tasks.md:29`;
     - `DEPENDENCIES.md:20`, `:29`;
     - `README.md:27-28`, `:96`.
  2. Re-derive every count from the tree rather than from this bundle.
  3. Run `/humanize` (or an equivalent de-AI audit) over the README edit and fix what it finds
     (documentation-§1).
  4. Green gate; the spelling gate covers the new prose.

## Optional (Info) — any time

- [ ] **PFE-11** — comment at `modules/Element.lua:15-17` that the Blizzard cast-bar shield is deliberate.
- [ ] **PFE-08** — write `design spec §N.M` in code comments that cite the spec.

## At the release (not a code change)

- [ ] **PFE-09** — cut v0.1.0 only from a fresh `tests/_kit/run-automated-tests.sh --release 0.1.0` bundle
  over the exact tree being tagged, with all four suites at `pass` and 0 functions above CCN 15. Write
  that bundle's `ANALYSIS.md`.
- [ ] **PFE-10** — nothing to do. Re-check the `events-frames-taint-§1` register row's trigger whenever
  AceEvent or LibKa0s is re-vendored.

## Verification after all sprints

- [ ] `lua tests/run.lua` all green, and `luacheck .` at 0/0 over the full test tree.
- [ ] `diff <(lua tests/run.lua --list) docs/test-cases.md` is empty, and the README badge equals its total.
- [ ] `grep -rn "SetSetting(" --include='*.lua' core modules settings` returns only `settings/Schema.lua`.
- [ ] Line-ending count (e) is still 0. Any new file written outside git's filters must be re-checked out
  (`rm <path> && git checkout -- <path>`) after staging, per `line-endings-§6`.
- [ ] The next audit is a new `docs/audits/<date>/` folder that reuses the `PFE-*` IDs above.
