# 05 — Execution plan: Ka0s Party Frame Enhanced

Hand-off to the remediation engagement. Every step names its deviation ID(s). Gate after each
code-bearing step: `ka0s-bounded lua tests/run.lua` (454/455 or better, 0 failed) and
`ka0s-bounded luacheck .` (0/0). Doc-only steps run the suite once at the end of their sprint,
because `test_prose`, `test_eol` and `test_layout_cap` read docs and the tree.

Counts carried from `02_DEVIATIONS.md`: **10 roots** (5 Low, 5 Info) and **11 including
dependents**. **4 MUST roots**, all Low, and **5 MUST failures including dependents**.

## Sprint 1 — records (doc-only)

| # | Step | IDs | Done when |
|---|---|---|---|
| 1.1 | Write `docs/revendor/2026-10-07-v1.69.0-v1.70.0/` (`01_DELTA.md` line 1 `Delta: LibKa0s v1.69.0 -> v1.70.0 (span: v1.69.0 v1.70.0)`, `05_SUMMARY.md` one line per tag, nothing adopted), preferably via `/dev-copilot:wow-revendor-libka0s` | PFE-26 | The `AUDIT.md` re-vendor census prints an empty `UNRECORDED` list |
| 1.2 | Point `docs/ARCHITECTURE.md:23`, `:43`, `docs/smoke-tests.md:55` (INSTALL-4, Result left for the owner) and `DEPENDENCIES.md:32` at v1.70.0 / kit 37 | PFE-26a | The `v1.68.1` / `kit 36` sweep in `03_EVIDENCE.md` finds only historical rows |
| 1.3 | `docs/automated-tests/README.md:29` → kit 37; `docs/perf-analysis/README.md:70` → `/dev-copilot:wow-perf-analysis`; doc-map compat row → 14 by the standard's grep; `docs/compat-layer.md:17` `IsSecret` row → a one-line pointer | PFE-01 | `grep -rn 'wow-addon' docs --include='*.md'` finds hits only in frozen stores and `RESULTS.md:15` |
| 1.4 | Restore `### Addon-specific (documentation-§3, Tier 3)` with "None." after Verification and record | PFE-29 | The map has four tables in order |
| 1.5 | Trim Overview's re-vendor narrative to a pointer at `revendor/`. Optionally spill the disabled-state section to `data-flow.md` | PFE-27 | `wc -l docs/ARCHITECTURE.md` ≲ 400, and no line over ~600 characters in Overview |
| 1.6 | Row 2 **Why** cites PFE-15 (2026-09-23) and `79cd225` | PFE-28 (part) | Row cites a resolvable id |

## Sprint 2 — the one code change

| # | Step | IDs | Done when |
|---|---|---|---|
| 2.1 | Characterization first: a case in `tests/test_lifecycle.lua` (or `test_disabled.lua`) that queues a secure write in combat, stands down, and asserts exactly one live `PLAYER_REGEN_ENABLED` registration, which is gone after the event fires and the queue is flushed. Add `-- red under: leave PLAYER_REGEN_ENABLED registered after the flush` | PFE-25 | Green on the current frame-based code |
| 2.2 | Replace `regenWatch = CreateFrame("Frame")` with a private `AceEvent-3.0:Embed({})` target (not a bus target). Register through `NS.SafeRegisterEvent`, release in the handler and in `disarmPendingRegen`, and keep `NS.PendingRegenArmed` truthful (registry query or a local flag) | PFE-25 | 2.1 still green; `grep -n 'CreateFrame("Frame")' core/PartyFrameEnhanced.lua` is empty |
| 2.3 | Event Subscriptions row (`docs/ARCHITECTURE.md:199`): "its own AceEvent target (not a bus target)" | PFE-25 | Doc matches code |
| 2.4 | Optional: `runDebug` → `DebugVerb` + `Toggle` | PFE-31 | `tests/test_slash.lua` debug cases green, unchanged |

Smoke (owner): disable the addon in combat with the preview off, leave combat, and confirm the
`[Secure] flushed …` line appears with no Lua error. The existing COMBAT checks are unaffected.

## Sprint 3 — owner decisions and release-time items

| # | Step | IDs | Done when |
|---|---|---|---|
| 3.1 | Owner confirms row 1 (SecureFollow residue, D9). Delete "pending the owner's ratification" | PFE-28 (part) | Row reads as ratified |
| 3.2 | At the next settings change, reshape `docs/settings-panel.md` to `Page \| Covers` plus per-page headings | PFE-30 | Optional |
| 3.3 | Next release: `run-automated-tests.sh --release <v>`, the first sighted bundle (`blindFiles: 0`). `RESULTS.md:15` regenerates with the current command name | PFE-09, PFE-01 (RESULTS line) | Newest bundle's commit = the tagged commit |
| — | No action | PFE-08 | — |

## Not in scope

The two register rows stay accepted (02 → *Recorded deviations*). No SavedVariables migration, no
version bump, no re-vendor.
