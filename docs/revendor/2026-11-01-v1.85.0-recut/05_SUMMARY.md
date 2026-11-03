# Summary

The tag v1.85.0 was re-cut for the owner's rulings of 2026-11-01 and the gate, at library commit `2ad1a50`. Both payloads were copied whole by hand, `media/icons/` left as this addon's declaration prunes it; kit revision 49 -> 50.

- **Step 8 owed here:** the degraded facade's `BarBorder` and `HoverArt`; the kit's `test_skin_values` and `test_skin_switch` declared, with `tests/skin_facts.lua` and `tests/test_skin_literals.lua` retired (its glyph case moved to `tests/test_skin_fonts.lua`); `S.BarBorder` read in `Element.MediaKeys`, as AuraMaster's rule; `S.IconBorder` on the icon Texture, `el.iconEdge` gone; `borderShow` shipped false with schema v5 keeping a picked border.
- **Not owed:** `Skin.FollowOnce` takes no numeric path here (`castbar`, `target`, `pet` only), so no repair; no `S.Mark` on a pooled AceGUI widget; no Solid border registration of this addon's.
