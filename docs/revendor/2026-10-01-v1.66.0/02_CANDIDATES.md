# Candidates (PartyFrameEnhanced, LibKa0s v1.66.0)

Listed, **not interviewed** this cycle. Spec S4 of the 2026-10-01 GitHub issue pass defers every
adoption decision to `GI-LK-13`, the collection-wide consumer census, which runs after every addon has
re-vendored. Nothing below is adopted or declined, and no issue is filed for any of it.

## A. Delivered on the re-vendor alone (not offered)

- **Slash 19, the host's `L` in the dispatcher's own parse refusals.** The instance passes `Sl:Text`, so
  a `/pfe set` refusal and the `(none)` rendering read this addon's `L` first. This addon's locale
  carries none of those keys today, so the wording is unchanged. CHANGELOG v1.66.0, "Slash minor 19".
- **Perf 14, declared parents in the record (LibKa0s#12).** A parent bucket that never fired still
  appears with zero counts when a child names it. CHANGELOG v1.66.0, "Perf minor 14".
- **The four peels** (`WidgetsReorder.lua`, `SlashParse.lua`, `PerfSampler.lua`, `PerfCommands.lua`) and
  DebugLog 19's helper split: no member moves.
- **Kit 35, the sighted complexity suite.** Wired in `tests/run.lua` in the re-vendor commit, as the kit
  document's Adoption section requires.

## B. Host change required (candidates)

1. **`NS.FormatSchemaValue` passes the resolver.** `settings/Schema.lua:366` calls
   `SlashLib.FormatValue(row, v)`; passing `NS.Slash`'s text resolver would let the `[Set]` debug line
   and `/pfe get` render `NONE` in the host's wording. Evidence: `docs/api/Slash/version-19.1-docs.md`
   (LibKa0s), CHANGELOG v1.66.0 "Slash minor 19". Touches `settings/Schema.lua`. Additive. Low value:
   the locale carries no override for `NONE`.
2. **Perf budgets (LibKa0s#1).** `core/PerfSetup.lua` could declare `budget = { msPerSec, maxMs }` per
   top-level bucket, derived from the committed captures under `docs/perf-analysis/`, with a
   test_perfsetup case asserting every top-level bucket has one (the design in the 2026-10-01 bundle's
   `02a_ISSUE_DESIGNS.md`, LibKa0s#1). Report-only. Additive.
3. **`RenderTabbedSchema`'s opt-in fields** (`untabbedSkipRender`, `disabledReplaces`, `rerender`):
   `settings/General.lua:235` and `settings/ElementRows.lua:149` draw tabbed pages; whether any of the
   three removes host code here needs a read of those pages. Evidence:
   `docs/api/Options/version-27.2.34.2.2.8.1.7.4.2-docs.md`. Probably no fit.
4. **`RenderGrid(ctx, items, parent, opts)`**: this addon does not call `RenderGrid` directly (it is only
   named in the Options stub's member list, `settings/OptionsSetup.lua:137`). No fit.

## C. Whole-module adoption

None new: v1.66.0 adds no major. Pool, Item and Widgets remain reached through the library only.
