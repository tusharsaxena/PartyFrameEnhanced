# 02 — Candidates (PartyFrameEnhanced, v1.83.0 -> v1.84.0)

Sources: `CHANGELOG.md`'s v1.84.0 block and `docs/api/` for each moved major this addon looks up.

## A. Delivered by the copy

Nothing a player sees on this addon. The eight peels are pure moves. WidgetsDragHandle 9 and 10 reach
no surface here, because the addon has no `DragHandle`. WoW Default's sizes did not move.

## B. Host change required

- **`opts.beforeGroup`, `opts.afterSubgroup` (OptionsFlow 2):** additive. No page draws a control
  between rows by hand, so nothing would use them.
- **`note` row (OptionsFlow 2, Schema 3, Slash 21):** additive. The pages explain themselves in row
  tooltips, and no owner note asks for a line.
- **`O.PositionBlock` (OptionsCompose 15):** would replace rows. `ElementRows.Position` splits its X
  and Y by anchor mode through `shownWhen`, with a free stack that has no X and Y, which the block
  does not fit.
- **`O.PageBanner{ acts }` (OptionsTabs 13):** additive. The addon draws no `PageBanner`
  (`tests/test_surface_parity.lua` lists it as having no caller).

## C. Whole module

- **`LibKa0s-Charts-1.0`:** the addon draws no charts.
- **`LibKa0s-Sim-1.0`:** settled, LibKa0s#54. The addon draws on secure unit frames, which cannot show
  made-up units. v1.84.0's SimPanel peel changes nothing about that premise.
