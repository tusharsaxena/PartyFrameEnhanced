# Settings panel

The panel is `LibKa0s-Options-1.0`'s, built from `settings/OptionsSetup.lua`'s descriptor: a Blizzard
canvas landing page plus one canvas subcategory per page, every page tabbed (options-ui-§13), a lazily
built body and Defaults button, a panel-open that refuses in combat (options-ui-§2), and a gray cover over any page on screen in
combat that refuses every write until combat ends (LibKa0s v1.46).

Derived from the schema — `group` declares each tab, in first-registration order. The landing page,
**Ka0s Party Frame Enhanced**, is the parent category rather than a subcategory page: the logo, the TOC
Notes line and the slash command list, with no tabs. Under it are five pages:

| Page | Covers |
|---|---|
| General | **Master controls**: enable, general visibility, master scale / alpha, lock, debug console, minimap button, reset position, reset all<br>**All elements**, what the three features share: *Party frames* (which frame system elements attach to; whether your own row is included; fading with the party frames out of range; the frame strata), then *Health updates* (one *Update health* switch and the *Target health refresh* pace, shared by target and pet frames)<br>**Skin** (the library's tab, last): the skin source, the nine skins, the Font and texture overrides, the Scope, *Copy to every Ka0s addon…* |
| Cast Bars | **General**: enable, fade out when a cast ends<br>**Size and position**: size (width, height), then anchor mode, match width, the attached pin (points, offsets), the free stack (growth, spacing); only the block the anchor mode uses is drawn (`shownWhen`, LibKa0s v1.45.0)<br>**Bar**: the fill block and the spark, the cast-state palette, the background, the border block with *Show border*<br>**Text**: the shown text (spell name, time left), then the font block<br>**Icon**: spell icon and its side, the shield |
| Target Frames | **General**: enable, click to target<br>**Size and position**: as Cast Bars<br>**Bar**: the fill block, NPC reaction colors, the background, the border block<br>**Text**: the shown text (name, health percent), then the font block<br>**Marker**: the target's raid marker, its point on the bar, X/Y offsets |
| Pet Frames | **General**: enable, click to target<br>**Size and position**: as Cast Bars<br>**Bar**: the fill block (*Use class color* = the owner's class), the background, the border block<br>**Text**: the shown text (name, health percent), then the font block<br>**Marker**: the pet's raid marker, its point on the bar, X/Y offsets |
| Profiles | AceDBOptions: create, switch, copy, reset, delete profiles |

## General

### Master controls

Composed by the library's `MasterControls` (options-ui-§15), not typed out. Not frameless: the
free-placement stacks are movable, so every row applies.

| Control | Schema path | Behavior |
|---|---|---|
| Enable Party Frame Enhanced | `enabled` | addon-wide switch; publishes VISIBILITY |
| General visibility | `visibility` | Always / Only in combat / Only out of combat / Never; publishes VISIBILITY |
| Master scale | `scale` | multiplies every element's size (CONFIG "master") |
| Master alpha | `alpha` | multiplies every element's alpha (CONFIG "master") |
| Lock frame | `locked` | **The addon's one preview switch**, and its tooltip says so: the composer's `lockIsPreview` sentence (LibKa0s compose minor 9), then the host's `notes.locked`, *Unlocking is refused in combat, and combat locks it again.* (options-ui-§15, which is why there is no Test mode row). Off = unlocked = preview mode, grabbable free-placement stacks, placeholders on the real party frames in a party and `modules/StandIn.lua`'s stand-in raised in party1's place out of one (`NS.OnLockChanged` → `modules/Preview.lua`). Unlocking is refused in combat, with the addon disabled, or during a perf-run suspend, and the box snaps back; locking is never refused, and entering combat forces it |
| Debug console | `state.debugConsole` | session-only; shows or hides the console window |
| Minimap button | `global.minimap.shown` | shows or hides the launcher's minimap button (launcher-§3). **The row and its path say SHOWN and the stored key (LibDBIcon's `global.minimap.hide`) says HIDDEN**, so its get/set invert at the single write seam (`settings/General.lua` stamps them onto the composed row) and call `NS.Launcher:SetShown`, so the button follows the checkbox immediately. Stored in the **global** store, not the profile: a profile switch must not move the player's buttons. It also **survives both resets** — *Reset all settings* and this page's own *Defaults* button — because the choice is a per-installation display preference, like the button's position; see *Resets* below. LibDBIcon owns the same table and writes `hide` from its own menu and `minimapPos` when the button is dragged. **The button's tooltip** (launcher-§1) is drawn by `LibKa0s-Launcher-1.0` on every hover, the addon disabled or not: the label and `v<version>`, `Enabled: Yes\|No` (this page's *Enable* row), `Locked: Yes\|No` (the *Lock frame* row), `Left-click: Open settings` and `Right-click: Options menu`. There is no `Test mode` line, because the addon has no Test mode row. **The button's clicks** (launcher-§2): left-click opens this panel in either state; right-click opens the options menu, *Enabled* (this page's *Enable* row, through the `/pfe enable\|disable` handler) and *Locked* (the *Lock frame* row, through `NS.ToggleLock`), with *Locked* grayed while the addon is disabled |
| Reset position | — (button) | `NS.Anchor.ResetPositions()` — the free-placement stacks back to defaults |
| Reset all settings | — (button) | confirms, then resets the active profile (options-ui-§12) |

#### Resets

The two reset rows above, and each page's **Defaults** header button.

- **Defaults** (header button, per page): that page's rows only, one `[Set] reset <page>: N rows` line.
- **Reset all settings** / `/pfe resetall`: a **profile reset** of the active profile — the same act as
  Profiles → Reset Profile. The popup text is the collection's one wording, verbatim.
- **One row is exempt from both** (launcher-§3): **Minimap button**, `global.minimap.shown`. Whether
  the button is on the minimap is a per-installation display preference, in the same class as the
  position the player dragged it to, so no reset may move it in either direction.
  `settings/Schema.lua`'s `NS.IsGlobalSetting` names that once. Its set is the schema instance's
  `resetExempt`, which `ApplyDefault` honors inside the bulk bracket that *Reset all settings* and
  **Defaults** both open, and Reset All's `skipRestoreAll` vetoes the row as well. It matters most
  for **Defaults**: `O.RestoreDefaults` vetoes nothing on its own, so without the exemption the
  composed row's `default = true` put a hidden button back on the minimap.
  `/pfe reset global.minimap.shown` still works — the exemption is for sweeps.

### All elements

Two subsections on one tab, both on the General page, so General's **Defaults** resets them.

#### Party frames

| Control | Schema path | Behavior |
|---|---|---|
| Frame system | `general.provider` | Automatic / Blizzard / EllesmereUI; Providers re-resolves (CONFIG "general") |
| Include my own row | `general.includePlayer` | the player's elements, wherever the frame system shows the player and always in free placement |
| Fade with party frames | `general.rangeFade` | each unit's cast bar, target frame and pet frame fade with its party frame when the member is out of range: copied from EllesmereUI's and Blizzard raid-style's own fade, or on Blizzard classic (which does not fade) a ~40-yard `UnitInRange` check at 0.5. Off: every fade frame at full alpha (`modules/RangeFade.lua`) |
| Frame strata | `general.strata` | the layer every element draws on, set on each unit's fade frame. *Match party frames* (default) copies the unit's party frame's strata and sits one level above the highest frame in it, so an attached cast bar draws over the party frame and windows that cover the party frames cover the elements too; with no party frame, any member frame of the active system, else LOW; a party frame that cannot be read (forbidden, or a refused read) lands on LOW, 50 levels over UIParent. Forbidden children (Blizzard's aura buttons), and any child whose level read is refused, are skipped in the level walk with everything under them. Background / Low / Medium / High / Dialog fix the strata. The free-placement holders follow, at their stack's lowest fade level. Written through `NS.RunSecure("fade:strata")`: the fade frames parent secure buttons. The tooltip ends with the library's strata tooltip (`O.StrataTooltip`), which says what Dialog covers |

#### Health updates

One switch and one pace for both unit-button features, so target and pet frames cannot disagree.

| Control | Schema path | Behavior |
|---|---|---|
| Update health | `general.updateHealth` | off: target and pet bars are drawn full with no percent; the target ticker runs only to repaint a target that had not resolved yet, and no pet health event is registered. *Show health percent* on both Text tabs dims with it |
| Target health refresh (seconds) | `general.tickInterval` | the target health ticker's pace (0.1–1.0); a new pace restarts a running ticker. Pets update from the game's own health events, so it does not apply to them. Dimmed while *Update health* is off |

### Skin

The library's tab (`O.AppearanceTab`, LibKa0s OptionsAppearance; skinning-§3), keyed `Appearance` and
labeled **Skin**, handed to `RenderTabbedSchema` as a host tab with this addon's read and write seams
(`NS.SkinChoice`, `NS.WriteSkinChoice`). It is the page's **last** tab, since General has no
Keybindings tab. The library draws every control; the rows below are schema rows with `skipRender`,
so General's **Defaults**, *Reset all settings* and `/pfe set` all reach them.

| Control | Schema path | Behavior |
|---|---|---|
| Skin source | `skin.source` | Ka0s skins / EllesmereUI. EllesmereUI is disabled while the library's gate is closed (skinning-§5), with each condition and its fix listed. Ka0s to EllesmereUI applies live; back offers one reload |
| Skin (under a **Look** heading) | `skin.skin` | the nine skins, each with its swatches, name and one line; a pick repaints this addon live: the HUD's bar texture, border style and font where a *Use the skin's …* companion is on, the free-placement holders, the settings pages (unless *Ignore settings panel*), the debug console and the perf panel |
| Font · Texture (*Font and texture*) | `skin.font` · `skin.texture` | an override of the skin's face (`font.body`, `font.title`, `hud.font`) and bar texture (`bar.texture`); *Skin's default* is `""`. The HUD takes them wherever its companions are on |
| Font outline (under the reset buttons) | `skin.outline` | All text / HUD text only (default) / Off: where the skin outlines this addon's text. Every HUD Font flags row on *From skin* follows it (OUTLINE under All and HUD, none under Off); a picked flag wins. Ignore fonts grays it out |
| Ignore settings panel · Ignore fonts (the Scope) | `skin.ignorePanel` · `skin.ignoreFonts` | keep this addon's settings panel in the client's look (on in a new profile; the tool windows, the picker, the holders and the HUD keep the skin); keep every font as the client draws it, the HUD keeping each section's own *Font* |
| Copy to every Ka0s addon… | — (button) | the library's: confirms, naming the loaded Ka0s addons that use skins, then writes this choice into each through its own write seam; disabled, with a hint, while no other loaded addon has adopted |

`skin.pickerSeen`, the first-run skin picker's memory, is a row in the same group that nothing draws
([schema.md](schema.md)). The picker's gear opens this tab, and since LibKa0s v1.83.0 the picker
carries this tab's Font, Texture, Font outline and Scope rows too. The Font and Texture rows here and
there are the library's `Ka0sMedia_*` pickers: each entry draws in its own face or beside its swatch.

## Cast Bars

Every path is under `castbar.`. The Size and position tab is shared by all three feature pages
(`settings/ElementRows.lua`); the Border, Text-font and Bar-fill blocks come from the library's
composers, and every companion there resolves to the **tracked unit's** class
(`classColorSource = "unit"`).

### General

| Subgroup | Controls → path |
|---|---|
| — | Enable cast bars → `enabled` · Fade out when a cast ends → `fadeOut` (every ended cast, an interrupted one after its hold) |

### Size and position

| Subgroup | Controls → path |
|---|---|
| Size | Width → `width` (dimmed while attached with *Match party frame width* on; its tooltip says so) · Height → `height` |
| Placement | Anchor mode → `anchorMode` · Match party frame width → `matchWidth` (dimmed in free placement; its tooltip says so) |
| Attached to party frames | Anchor point → `point` · Party frame point → `relativePoint` · X/Y offset → `offsetX`/`offsetY` (all dimmed in free placement) |
| Free placement | Growth direction → `growth` · Spacing → `spacing` (both dimmed while attached) |

Dimming is the library's `disabledIf`, re-evaluated on every write, so switching the anchor mode dims
the other block on the same frame. A dimmed row keeps its stored value, and `/pfe set` still writes it.

### Bar

| Subgroup | Controls → path |
|---|---|
| Fill | Bar texture · Bar opacity · Normal cast color (`barColor`) · Use class color · Use the skin's texture → `barTextureFromSkin` · Show spark → `showSpark` (the bar block's one `extra`: the spark rides the fill) |
| Cast state colors | Channel · Empowered · Can't be interrupted · Interrupted (palette: no companion) |
| Background | Background color → `bgColor` · Use class color → `useClassColorBg` |
| Border | Show border · Border style · Border thickness (px) · Border color · Use class color · Use the skin's border → `borderStyleFromSkin` (order 120, after Background) |

### Text

| Subgroup | Controls → path |
|---|---|
| Shown text | Show spell name → `showName` · Show time left → `showTime` |
| Font | Font · Font size · Font color · Use class color · Font flags (leads with *From skin*, the default) · Font shadow · Use the skin's font → `fontFromSkin` |

The three *Use the skin's …* companions (skinning-§6) are on by default; while one is on, the picker
it governs is dimmed and shows the skin's value, and the element draws the skin's bar texture, border
style or HUD font. Colors and the shadow never follow the skin. While the font follows it, the drawn
size scales with the skin's HUD size and the stored size is kept; Font flags on *From skin* follow the
Skin tab's Font outline, and a picked flag wins.

### Icon

| Subgroup | Controls → path |
|---|---|
| — | Show spell icon → `showIcon` · Icon side → `iconSide` · Show shield → `showShield` |

## Target Frames

Paths under `target.`. Size and position, Border and Text-font as on Cast Bars.

With the shared *Update health* (General → All elements → Health updates) off, the bar is drawn full with no percent
and the ticker runs only while a shown target is still unresolved (no name yet).

*Click to target* and every size or position change are secure writes: made in combat, they apply
when combat ends.

### General

| Subgroup | Controls → path |
|---|---|
| — | Enable target frames → `enabled` · Click to target → `clickToTarget` |

### Size and position

As on Cast Bars.

### Bar

| Subgroup | Controls → path |
|---|---|
| Fill | Bar texture · Bar opacity · Bar color · Use class color (a **player** target's class) · Use the skin's texture |
| Reaction colors | Color NPCs by reaction → `colorReaction` · Hostile · Neutral · Friendly (palette: no companion; each swatch's tooltip ends *Needs Color NPCs by reaction.*) |
| Background | Background color · Use class color |
| Border | the border block, as on Cast Bars |

### Text

| Subgroup | Controls → path |
|---|---|
| Shown text | Show name → `showName` · Show health percent → `showPercent` (dimmed while Update health is off; its tooltip ends *Needs Update health (the General page > All elements).*) |
| Font | the font block |

### Marker

| Subgroup | Controls → path |
|---|---|
| — | Show raid marker → `showMarker` · Bar anchor point → `markerPoint` · X/Y offset → `markerOffsetX`/`markerOffsetY` (the last three dimmed while the marker is off) |

The marker's center sits on *Bar anchor point* of the bar; the default, *Top*, is half over the bar's top edge, centered.

## Pet Frames

Paths under `pet.`. Size and position, Border and Text-font as on Cast Bars.

With the shared *Update health* (General → All elements → Health updates) off, the bar is drawn full with no percent
and the pet's health events are unregistered.

### General

| Subgroup | Controls → path |
|---|---|
| — | Enable pet frames → `enabled` · Click to target → `clickToTarget` |

### Size and position

As on Cast Bars.

### Bar

| Subgroup | Controls → path |
|---|---|
| Fill | Bar texture · Bar opacity · Bar color · Use class color (the **owner's** class) · Use the skin's texture |
| Background | Background color · Use class color |
| Border | the border block, as on Cast Bars |

### Text

| Subgroup | Controls → path |
|---|---|
| Shown text | as on Target Frames: Show name → `showName` · Show health percent → `showPercent` |
| Font | the font block |

### Marker

| Subgroup | Controls → path |
|---|---|
| — | as on Target Frames: Show raid marker → `showMarker` · Bar anchor point → `markerPoint` · X/Y offset → `markerOffsetX`/`markerOffsetY` |

## Profiles

AceDBOptions' table, rendered by AceConfigDialog (`settings/Profiles.lua`): create, switch,
copy, reset, delete profiles. It registers no schema rows. The tree AceConfigDialog draws is painted
for this addon's skin after every Open (`NS.SkinPaintAceTree`), and left stock while *Ignore settings
panel* is on. A switch wears the new profile's skin; a new or reset profile starts on Ka0s Default with the
picker unseen, and a copy carries the source's. See [profiles.md](profiles.md).
