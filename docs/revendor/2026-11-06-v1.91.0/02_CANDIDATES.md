# Candidates

Range `git -C ../LibKa0s log --oneline v1.90.0..v1.91.0`; sources: the library `CHANGELOG.md` block v1.91.0 and the
API documents under `docs/api/` for every major whose minor moved (Core 17.1, Skin 17.1.27.8.19.19.1.1.17.4.9,
Widgets 26.1.6.13.7.8.5).

## A. Delivered on the copy (not offered)

- **Line-chart lines in physical pixels, WidgetsLineChart 7** (`docs/api/Widgets/version-26.1.6.13.7.8.5-docs.md`,
  *The line chart's lines in physical pixels (FU-L1)*): axis, grid, markers, crosshair and series are physical pixels
  and re-size on a scale change. "What a host owes: nothing." This addon draws no LineChart, so nothing changes on
  its screens.
- **The four peels, Core 17 + CorePixel 1, Widgets 26 + WidgetsDropdown 1, SkinPaintExtras 19 + SkinPaintHud 1 +
  SkinAceConfirm 1** (`docs/api/Core/version-17.1-docs.md:23-27`, the Widgets and Skin documents' *What changed at
  this version*): pure moves with no member or behavior change. They arrive through the XML-driven loader with no
  host edit.

## B. Host change required

None. No member, option or field is added in this range.

## C. Whole-module adoption

No new major in this range.
