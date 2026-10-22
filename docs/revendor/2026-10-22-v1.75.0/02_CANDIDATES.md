# 02 — Candidates (PartyFrameEnhanced)

Sources: `git -C ../LibKa0s log --oneline v1.71.0..v1.75.0`, the LibKa0s `CHANGELOG.md` blocks v1.72.0
through v1.75.0 and their *What a consumer owes* lists, and the API documents at the tag under
`docs/api/` for every major whose minor moved.

The run's owner scope (`OWNER_SCOPE.md`) gives PartyFrameEnhanced nothing to adopt. Every candidate
below is therefore recorded as not adopted in this run, with no interview and no GitHub issue.

- **Class A (delivered with the copy):** Perf 15's optional `false` bucket. Options 29's structural
  refresh, which now keeps a page's scroll position (no host change). DebugLog 20, DebugLogDiagnostics
  3, OptionsIdList 5, PerfPanel 7 and Core 11 as they stand. Kit 39-41: the unconditional-fire reach,
  the icon declaration gate and the crashed-lizard bucket.
- **Class B (needs a host change), not adopted:**
  - `O.Drawer` (OptionsDrawer 1, v1.73.0): a collapsible box of rows. No page here groups rows that
    way. The parity stub exempts it (01_DELTA 3g, blocker 1).
  - `W.SearchBox` (Widgets 13, v1.75.0): this addon has no search box.
  - `W.TestStrip` (Widgets 13, v1.75.0): this addon has no test mode with a strip to show.
  - `Item.BonusIDsFromLink` (Item 3, v1.75.0): this addon handles no items.
  - `W.StepPanel`: withdrawn upstream (LK-11 outcome B). The step-panel renderer is Sim-private, so
    there is nothing to adopt.
- **Class C (whole module), not adopted:**
  - `LibKa0s-Glow-1.0`: nothing in this addon glows.
  - `LibKa0s-Sim-1.0`: ruled out in LibKa0s#54. The addon draws on secure unit frames, which cannot
    show made-up units, so a simulator has nothing to drive.
