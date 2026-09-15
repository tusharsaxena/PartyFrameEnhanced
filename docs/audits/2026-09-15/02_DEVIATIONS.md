# 02 — Deviations: Ka0s Party Frame Enhanced v0.1.0

Audited against **Ka0s WoW Addon Standard v2.44.0 (2026-09-12)** at `master` `e215880`.
Prefix **`PFE`**, assigned on this first audit and to be kept stable in later runs.

## Tally

The **headline** counts root deviations only, and here it equals the total: no deviation was filed
as `derived from <ID>`.

| | High | Medium | Low | Info | Total |
|---|---|---|---|---|---|
| **Headline** (roots) | 0 | 0 | 7 | 4 | **11** |
| **Total including dependents** | 0 | 0 | 7 | 4 | **11** |
| **MUST failures** (roots; the recorded deviation PFE-10 is excluded) | 0 | 0 | 6 | 0 | **6** |
| **SHOULD failures** (roots) | 0 | 0 | 1 | 0 | **1** |

**Verdict: minor deviations.** Nothing a player, their SavedVariables or their session can hit today.
Six MUSTs fail, all of them doc-, config- or test-shaped, so all are graded **Low**. Each row below
still names its MUST.

## Deviations

| ID | Section | Grade | Rule strength | Description | Fix direction |
|---|---|---|---|---|---|
| **PFE-01** | `documentation-§5` (and `documentation-§7` for one site) | Low | MUST | The doc set lags the code at HEAD. Twelve statements in seven files still describe the pre-feature scaffold: "Twenty-two files load" (there are 34), "the offline perf pass remains", "Arrives … plan P2", "Stage 1 … features land in P2–P5", "Three `files[...]` stanzas" (there are 8), "(as they land)", and in the player README "the three elements are being built now". The Version History row also lists only "settings panel, slash commands, profiles". `DEPENDENCIES.md`'s `git` evidence omits the new spelling gate. | One `sync-docs` pass. Rewrite each statement to describe the tree, and apply the documentation-§1 de-AI pass to the README edits. |
| **PFE-02** | `toc-file-§5` | Low | MUST | The load-bearing position `settings\Schema.lua` (`PartyFrameEnhanced.toc:81`) carries no annotation. `Schema.lua` publishes `NS.RegisterSchemaRows`, which `settings/General.lua:68`, `settings/CastBars.lua:79`, `settings/TargetFrames.lua:79` and `settings/PetFrames.lua:49` call **at file load**. `tests/test_loadorder.lua` does not pin it either. | Add a `# LOAD-BEARING: publishes NS.RegisterSchemaRows, which every settings page calls at file load.` line above `:81`, and a load-order case pinning Schema before every page. |
| **PFE-03** | `architecture-§5` | Low | MUST | A schema-row write happens outside the single write seam. When an unlock is refused in combat, `modules/Preview.lua:37` puts `locked` back with the raw `NS.SetSetting("locked", true)`. That breaks `settings/Schema.lua:113`'s own contract ("Every caller outside this file uses NS.SetByPath") and `docs/ARCHITECTURE.md:40-41`'s claim that `/pfe lock`/`unlock` go through the seam. The debug console shows `[Set] locked = false` (`settings/Schema.lua:167`) for a write that was then reverted, with no line for the revert. The stored value itself ends up correct. | Give the seam a pre-store veto: a row `validate` called by `NS.SetByPath` before `NS.SetSetting`. Move the combat refusal there, so nothing is written and nothing is logged. |
| **PFE-04** | `debug-logging-§8` | Low | MUST (heading of §8; the adoption paragraph calls coverage a SHOULD) | The addon's core flows are untraced. `modules/CastBars.lua`, `modules/TargetFrames.lua`, `modules/PetFrames.lua`, `modules/UnitButtons.lua` and `modules/Element.lua` hold **zero** `NS.Debug` calls. Cast start/stop/interrupt, a target change, a pet swap, and the show-ladder rung that hid an element (the "why is nothing showing" answer) can only be inferred from per-combat counters. Provider, Anchor, Preview, Secure, Set, Profile and Migrate are traced. | Add one gated line per flow event, and one coalesced summary per pass where the path repeats. Log the no-op decisions, such as which rung hid an element. Keep every build behind the gate (§4, §9). |
| **PFE-05** | `localization-§1` (routing) / `localization-§3` (terminal states) | Low | SHOULD | User-facing strings are only partly routed. Every chat line in `settings/Slash.lua` (for example `:37`, `:89`), the `NS.COMMANDS` descriptions (`:19-59`), the landing heading `"Slash Commands"` (`settings/About.lua:16`) and the reset acknowledgments in `settings/General.lua:106-108` bypass `NS.L`. There is no English-only register row. Issue #9 ("Translate the addon", `state:triaged`) says routing is the intended state, so neither terminal state is reached. | Route those strings through `NS.L`, whole sentences with placeholders, and add their keys to `enUS.lua`. Alternatively, if translation is declined, add the English-only register row with the trigger `the first non-English locale file added to locales/` and close #9. |
| **PFE-06** | `testing-§8` | Low | MUST | Stub coverage is short of the section's shape for two of the seven adopted modules. **Env:** there is no degraded-path case; no test references `NS.Meta`, `NS.Version` or `core/EnvSetup.lua`. **Perf:** `tests/test_perfsetup.lua:44-51` hand-lists the members, names no grep in its comment, and has no stub-surface parity case against the live instance. The Core, DebugLog, Options and Slash parity cases in `tests/test_surface_parity.lua` are compliant. | Add a degraded Env case, asserting that `NS.Meta("Version")` and `NS.Version()` answer on a library-absent load. Add a Perf parity case (`T.assertSurfaceParity`) whose comment names the grep that lists the members reached. |
| **PFE-07** | `options-ui-§12` (Testing) | Low | MUST | The suite proves the veto (`tests/test_optionssetup.lua:33-42`) and one `PROFILE` on a counted reset (`tests/test_database.lua:30-36`). No case drives `Helpers.RestoreAllDefaults()` end to end, and none asserts that **the profile list is unchanged** and **the active profile is still the one you were on**, as the section requires. | Add one case that creates a second profile, changes rows, runs `RestoreAllDefaults`, then asserts four things: the profile list and the active profile are unchanged, the session row was swept, and exactly one `PROFILE` message was published. |
| **PFE-08** | `documentation-§6` | Info | — (the retired-notation rule is a SHOULD and does not bind here) | The mechanical dotted-notation sweep reports **17** hits. **All 17** cite the addon's own design spec (`spec §6.4`, `spec §3.2`, …), and **none** cite the standard, so no retired standard citation exists. A citation range check found 155 `filename-§N` references and 0 out-of-range, malformed or bare-file misuses. | None required. Optionally write "design spec §6.4" consistently, so a future automated sweep cannot mistake them for standard citations. |
| **PFE-09** | `automated-tests-§3` / `automated-tests-§6` | Info | — | The release-candidate record predates HEAD. Bundle `20260915-150853` measured `275f786`: 129 tests, 59 lint files, NLOC 4995. `e215880` committed that bundle together with `tests/test_spelling.lua`, so HEAD measures 131, 60 and 5084. No release has been cut, and the checkpoint is the release, not the commit. | Cut the tag only from a fresh `tests/_kit/run-automated-tests.sh --release 0.1.0` over the tree being tagged. |
| **PFE-10** | `events-frames-taint-§1` | Info | recorded deviation (accepted) | Per-unit game events use `RegisterUnitEvent` on each element's own frame, not AceEvent. The register row is `docs/ARCHITECTURE.md:172`, Decided 2026-09-15. The rule is unchanged in v2.44.0, the trigger ("AceEvent or LibKa0s gains a unit-filtered registration") has not fired, and there are no cited ids to resolve. | None. Re-check when the trigger fires. Not counted toward the MUST tally. |
| **PFE-11** | `library-stack-§8` (the SHOULD sweep beyond the mandated surfaces) | Info | SHOULD (sweep) | The cast bar's "can't be interrupted" mark draws Blizzard's `Interface\CastingBar\UI-CastingBar-Small-Shield` (`modules/Element.lua:16`) while the vendored catalog carries a white `shield.tga`. The spark and raid-marker textures have no catalog equivalent. The Blizzard shield is the in-game convention players read on every other cast bar. | None required. If the Blizzard art is the deliberate choice, say so in a comment at `modules/Element.lua:15-17`, so the next sweep reads it as a decision. |

## Not filed (checked and compliant)

These were each measured and each passed; `03_EVIDENCE.md` carries the commands.

- **Vendoring.** `diff -r` for both payloads against `v1.36.1` is empty.
- **Line endings.** The five properties hold, the body is canonical, and strays = 0.
- **Packaging.** The ignore list is complete.
- **Provenance and badge.** The provenance line is in `CLAUDE.md` only; the standard badge is bare.
- **Unpublished TOC.** `X-Curse-Project-ID` is an unpublished comment, which is compliant.
- **Close-button wrapper.** It is a single wrapper, and no call site bypasses it.
- **Stub coverage.** The degradation stubs answer every member the addon reaches.
- **options-ui content.** Checks (a)–(i) pass.
- **Architecture.** The closed bus is compliant, and the named non-setting state is complete.
- **Lint and tests.** Lint scope is correct (only `tests/_kit/` is excluded under `tests/`), and the
  suite-inventory pin covers both directions.
- **Complexity.** The watch list is empty, 0 functions exceed CCN 15, and the complexity refactor
  uses permitted shapes.
- **Spelling gate.** It carries the canonical lists whole.
- **Docs tier model and map.** Both are complete, with no retired docs, no `LEDGER.md` and no
  `[status]` prefixes.

## Dependents

None. Each finding above has its own cause, so there is no `derived from` row.
