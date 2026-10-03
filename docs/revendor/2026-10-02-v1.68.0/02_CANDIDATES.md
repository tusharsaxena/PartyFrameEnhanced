# Candidates (PartyFrameEnhanced, LibKa0s v1.68.0)

Sources: `git -C ../LibKa0s log --oneline v1.67.0..v1.68.0`, the CHANGELOG's `v1.68.0` block, and the
`Since` markers in `docs/api/Widgets/version-12.1.4-docs.md` against `version-12.1.3-docs.md`. Only
Widgets moved (key 12.1.3 -> 12.1.4, WidgetsDragHandle minor 4).

## A. Delivered on the re-vendor alone (not offered)

- **The drag handle's split tooltip drawing** (`dhTooltipLines` / `dhDrawTooltip`). With no hook in
  force, a host gets minor 3's calls in minor 3's order (CHANGELOG v1.68.0, "Without a hook nothing
  changes"). This addon builds no drag handle, so there is nothing on screen for it to change here.

## B. Host change required (candidates)

1. **`spec.tooltipPlace` / a descriptor's own `place` (WidgetsDragHandle minor 4, AuraMaster#22).**
   `function(tip, frame) -> true`; with it set, the strip's tooltip is owned by `UIParent` at
   `ANCHOR_NONE`, drawn, shown, then placed by the host under `pcall`; any answer but `true` falls back
   to the cursor owner. Evidence: `docs/api/Widgets/version-12.1.4-docs.md` (LibKa0s, the
   `tooltipPlace` row), `LibKa0s/WidgetsDragHandle.lua` (`dhPlacer`, `dhShowPlaced`, and the spec
   docblock row "tooltipPlace function|nil minor 4"), CHANGELOG v1.68.0.
   - Files it would touch here: none exist to touch. The addon calls no `DragHandle` constructor and
     looks up no `LibKa0s-Widgets-1.0`
     (`grep -rn 'DragHandle\|tooltipPlace\|LibKa0s-Widgets' --include='*.lua' . --exclude-dir=libs --exclude-dir=_kit`:
     none). Its party frames move through its own anchor mode and the Options panel, not a labeled
     drag strip.
   - Blast radius: additive, but there is no host surface for it to attach to.
   - **Recommendation: decline, not applicable.** See `03_DECISIONS.md`.

## C. Whole-module adoption

None new: v1.68.0 adds no major. Widgets, Pool and Item remain reached through the library only, as
before; nothing in this release changes the premise of that.
