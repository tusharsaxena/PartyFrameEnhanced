# 02 — Deviations: Ka0s Party Frame Enhanced v1.1.0

Audited against **Ka0s WoW Addon Standard v2.76.1 (2026-10-07)** at `fb5c0b9`. The prefix is **`PFE`**,
unchanged since 2026-09-15. Recurring findings keep their IDs, and new ones start at PFE-25.

## Tally

**Basis.** The *headline* counts **root** deviations only. The *total* adds the one dependent filed as
`derived from PFE-26`. The two ratified register rows (below) are **accepted** and appear in neither
count.

| | High | Medium | Low | Info | Total |
|---|---|---|---|---|---|
| **Headline** (roots only) | 0 | 0 | 5 | 5 | **10** |
| **Total including dependents** | 0 | 0 | 6 | 5 | **11** |
| **MUST failures — roots** (PFE-25, PFE-26, PFE-01, PFE-29) | 0 | 0 | 4 | 0 | **4** |
| **MUST failures — including dependents** (+ PFE-26a) | 0 | 0 | 5 | 0 | **5** |
| **SHOULD failures — roots** (PFE-27) | 0 | 0 | 1 | 0 | **1** |

None of the five Info roots fails a MUST or a SHOULD.

**Verdict: minor deviations.** Nothing a player, their SavedVariables or their session can reach. The
2026-09-23 run's one Medium (PFE-12, the `EditMode.Exit` survivor) and every disabled-state item are
closed. The stand-down is now a real unregister across every module, and the conformance suite sees
the callback. What remains is one structural item (a private event frame in an AceEvent addon), one
record-keeping lapse (two re-vendors with no bundle), and documentation drift.

## Deviations (roots)

| ID | Section | Grade | Rule strength | Description | Fix direction |
|---|---|---|---|---|---|
| **PFE-25** | `events-frames-taint-§1` (*The boundary watcher*; first bullet's MUST NOT) | Low | MUST NOT | The pending-secure-write listener is a private `CreateFrame("Frame")` (`core/PartyFrameEnhanced.lua:117-129`, created at `:122`) that registers `PLAYER_REGEN_ENABLED` (`:128`). The addon embeds AceEvent-3.0 (`core/PartyFrameEnhanced.lua:8`), and §1 grants the boundary-watcher frame only to an addon that embeds **no** AceEvent: "An addon that embeds AceEvent-3.0 gets no such carve-out … a watcher frame beside it is the per-module event frame the first bullet forbids." It is not the unit-filter carve-out either, because `PLAYER_REGEN_ENABLED` is not a unit event. Behavior is correct (lazy creation, released on fire, listed in Event Subscriptions), so no user can reach this. The comment's reason (`:113-116`, AceEvent keys by `(event, target)`) is answered by a second AceEvent target, not by a raw frame. | Replace the frame with a dedicated AceEvent target that is **not** a bus target, because `NS.BusStandDown` would take it down with the rest: `local regenWatch = LibStub("AceEvent-3.0"):Embed({})`. Register through `NS.SafeRegisterEvent(regenWatch, "PLAYER_REGEN_ENABLED", onRegen, NS.RejectedEvents)`, release it with `regenWatch:UnregisterEvent("PLAYER_REGEN_ENABLED")` inside the handler and in `disarmPendingRegen`, and keep `NS.PendingRegenArmed` answering from AceEvent's registry. Update the Event Subscriptions row (`docs/ARCHITECTURE.md:199`) to say "its own AceEvent target". |
| **PFE-26** | `audit-review-history` (*A re-vendor commit implies a bundle*) | Low | MUST | Two vendored tags have no `docs/revendor/` bundle and no register row: **v1.69.0** (`547ac68`, 2026-10-06) and **v1.70.0** (`735a111`, 2026-10-07). Both were plain `chore:` re-vendors that bypassed `/dev-copilot:wow-revendor-libka0s`. Doc-only, so Low. | One consolidated span bundle, `docs/revendor/2026-10-07-v1.69.0-v1.70.0/`, holding `01_DELTA.md` (line 1: `Delta: LibKa0s v1.69.0 -> v1.70.0 (span: v1.69.0 v1.70.0)`) and `05_SUMMARY.md`. One line per tag: `WidgetsLineChart.lua` (Widgets/LineChart minor 2) and `WidgetsAutocomplete.lua` (minor 1) arrived, and nothing was adopted because this addon wires no Widgets major. |
| **PFE-01** | `documentation-§5` (plus `documentation-§3`, the compat shim count) | Low | MUST | Doc drift unrelated to PFE-26: (1) `docs/automated-tests/README.md:29` says "kit 35" where `docs/testing.md:93` and the vendored kit say 37. (2) `docs/perf-analysis/README.md:70` names `/wow-addon:perf-analysis`, a plugin retired at standard v2.76.0 (now `/dev-copilot:wow-perf-analysis`). (3) The doc-map row for `compat-layer.md` (`docs/ARCHITECTURE.md:404`) states "15 shims" by its own grep, counting `Compat.IsSecret`. `documentation-§3` fixes the count to `grep -cE '^\s*function\s+[A-Za-z_][A-Za-z0-9_]*\.' core/Compat.lua` (**14**) and says library-supplied shims "are **not** counted and **MUST NOT** be re-documented". `docs/compat-layer.md:17` documents `IsSecret` as a row of the shim table. The trigger fires at either count, so this is wording only. (The 2026-09-23 run filed the same 15-against-14 item, and its remediation adopted the opposite count.) | One `sync-docs` pass: `kit 37` in the automated-tests README; `/dev-copilot:wow-perf-analysis`; the doc-map row restated as "14 shims (the standard's grep), plus `IsSecret` routed from `LibKa0s-Compat-1.0`"; and the `IsSecret` row in `compat-layer.md` reduced to one sentence pointing at the library. `docs/automated-tests/RESULTS.md:15` (`/wow-addon:bump-version`) is runner-generated and refreshes on the next run, so do not hand-edit it. |
| **PFE-29** | `documentation-§3` (`## Documentation map`, four tables) | Low | MUST | The map has **three** tables: Required (`:384`), Conditional (`:396`) and Verification and record (`:408`). `### Addon-specific (documentation-§3, Tier 3)` was deleted in `bc3c941` (SD-FIN-01) when its only row (`superpowers/`) correctly moved to the frozen-directories sentence. The standard fixes four tables, with the third "placed after `### Conditional` and before `### Addon-specific`". No `.md` file is unregistered, so nothing is lost. | Restore the heading after Verification and record, with a `| Doc | Covers |` header and the word "None." beneath, as the register does for an empty section. |
| **PFE-27** | `documentation-§3` (hub spill rule) | Low | SHOULD | The hub is **435 lines**, past the "roughly 400" SHOULD (it was 359 on 2026-09-23). Every mandated section is under 60 lines. The growth sits in Overview's build-status paragraph, where `docs/ARCHITECTURE.md:55` is one 1609-character line narrating every re-vendor from v1.64.0 to v1.68.1. That is a second copy of `docs/revendor/`, and it went stale at the first re-vendor that skipped it (PFE-26a). The non-mandated `## The disabled state is total` section is 79 lines. | Cut Overview's re-vendor narrative to one sentence ("LibKa0s history: `docs/revendor/`") and keep only what the addon *adopted* in the module-map or debug docs it concerns. Optionally move the disabled-state section's detail into `docs/data-flow.md` or `performance.md`, leaving a summary and one link. |
| **PFE-28** | `audit-review-history` (register MUST 3, evidence) / `documentation-§3` (**Why** SHOULD cite an issue or bundle) | Info | — | Both register rows are **accepted** (see below), with two text nits. Row 1 (`docs/ARCHITECTURE.md:427`) describes itself as "owner default D9 … **pending the owner's ratification**". A row in the register *is* the ratification, and #3 closed after the owner's combat smoke checks passed on 2026-10-02, so the qualifier is stale self-doubt. Row 2 (`:428`) cites no issue or bundle in **Why**. | Have the owner confirm row 1 and drop "pending the owner's ratification". Cite the 2026-09-23 audit's PFE-15 and the PF-22 commit (`79cd225`) in row 2's **Why**. |
| **PFE-30** | `documentation-§3` (Tier 1 `settings-panel.md` shape) | Info | — | `docs/settings-panel.md:12` is a `Page \| Tab \| Covers` table with one row per tab, and the tree beneath has one heading per page→tab pair (`## General → Master controls`, `:38`). The standard specifies a `Page \| Covers` table, "one row per settings subcategory page … the tabs belong to the tree below", and a tree with one heading per page. The content is a superset and agrees with the schema. | Optional reshape at the next settings change: a five-row `Page \| Covers` table, then `## <Page>` headings with the tabs beneath. |
| **PFE-31** | `slash-commands-§3` / `debug-logging-§5` (observation) | Info | — | `runDebug` (`settings/Slash.lua:243-254`) hand-routes `diagnostics` → `on`/`off` → `Toggle`. The order and the seams are correct, but this repeats `NS.DebugLog:DebugVerb(rest)` (`libs/LibKa0s/DebugLogDiagnostics.lua:413`), which the standard's example uses and which both arms of `core/DebugLogSetup.lua` already answer (the stub's member at `:71-75`). It is a small second copy of library routing, not a defect. | `if NS.DebugLog:DebugVerb(rest) then return end; NS.DebugLog:Toggle()`. |
| **PFE-08** | `documentation-§6` (observation) | Info | — | The retired-notation sweep finds **18** hits. All 18 cite the addon's own design spec (`design spec §6.4` and similar), none cites the standard, and 2 sit inside the frozen spec itself. The `filename-§N` range check over 362 citations (70 distinct) finds 0 out of range and 0 malformed. | None required. |
| **PFE-09** | `automated-tests-§3/§4/§6` (observation) | Info | — | The newest record `20260927-030324` (release 1.1.0, `692cec2`, clean) is **47 commits** behind HEAD and predates the sighted complexity suite, so its manifest carries no `suites.complexity.blindFiles`. The first sighted measurement today: 1602 functions (1318 then), max CCN 14, 0 warnings, 0 band files. No drift crossed a threshold. No release has been cut since, and the checkpoint is the release. | Cut the next tag only from a fresh `run-automated-tests.sh --release <v>`, which becomes the first sighted bundle. |

## Dependents (excluded from the headline)

| ID | Derived from | Section | Grade | Rule strength | Description |
|---|---|---|---|---|---|
| **PFE-26a** | PFE-26 | `documentation-§5` | Low | MUST | The bypassed re-vendor flow also skipped its doc sync, so four live docs still name the previous payload: `docs/ARCHITECTURE.md:23` ("**LibKa0s v1.68.1** vendored whole") and `:43` ("now at v1.68.1"), `docs/smoke-tests.md:55` (INSTALL-4, "With `libs/LibKa0s` at v1.68.1"), and `DEPENDENCIES.md:32` ("kit 36"). It does not graduate: the grade equals the root's, no user can reach it, and running the re-vendor flow for the span repairs it. |

## Recorded deviations (accepted; not counted)

| Register row | Rule | Decided | Check result |
|---|---|---|---|
| `docs/ARCHITECTURE.md:427` | `slash-commands-§7`: SecureFollow leaves its wrap attached and gated off where another addon's wrap is outermost | 2026-10-01 (#3, GI-PF-02 = `abfd7e9`, D9) | The rule is unchanged: §7 still confines gating to undoable hooks, and `SecureHandlerUnwrapScript` pops the outermost wrap. The trigger has not fired. The ids resolve. **Accepted.** Text nit in PFE-28 |
| `docs/ARCHITECTURE.md:428` | `library-stack-§6`: `ellesmereConfiguredSize()` reads `EllesmereUIDB` (`modules/Providers.lua:314-324`) | 2026-09-24 | The rule is unchanged ("MUST NOT read a suite's … SavedVariables"). No EllesmereUI API for the configured party size has been observed, so the trigger has not fired. **Accepted.** Citation nit in PFE-28 |

## Checked and compliant (not filed)

Run, with commands in `03_EVIDENCE.md`: the vendoring `diff -r` at v1.70.0 (both payloads empty,
159/159 and 22/22 files); the provenance line in CLAUDE.md only; the bare standard badge; no README
logo, numbered list or library inventory; `## Reporting a bug` verbatim; line endings (canonical
84-line body, 0 strays, gate wired); packaging (a)/(b)/(c); the bus literal and casing greps; the
close-button grep; the settings-window combat grep; the launcher (one object, menu pairs matching
ADDONS.md, tooltip, label, `.shown` row, reset exemption); `enable`/`disable` as aliases; the disabled
state (latch, real unregisters, EventRegistry callback, hidden fades and holders, no game-event SV
write, `liveVerbs` ⊇ the reserved set, the conformance suite with both diagnostics forms); the
diagnostics checks 1–7; the library debug sink passed to every descriptor that takes it;
`SafeRegister*` everywhere, with rejects reachable; architecture-§5 write classification; stub
coverage (surface-parity suite); the `IconTexture` TGA header; the over-cap census and its gate; lint
scope; the test inventory byte-identical to `--list`; no raised kit budgets; the complexity watch
list (empty); no `LEDGER.md` and no `[status]` prefixes; and the dead-key check (210 keys, 0 unread).
