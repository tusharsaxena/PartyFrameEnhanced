# Settings panel

The panel is `LibKa0s-Options-1.0`'s, built from `settings/OptionsSetup.lua`'s descriptor: a Blizzard
canvas landing page plus one canvas subcategory per page, every page tabbed (options-ui-§13), a lazily
built body and Defaults button, and a panel-open that refuses in combat (options-ui-§2).

## Pages and tabs

Derived from the schema — `group` declares each tab, in first-registration order.

| Page | Tab | Covers |
|---|---|---|
| Ka0s Party Frame Enhanced | — (landing page) | logo, the TOC Notes line, the slash command list |
| General | Master controls | enable, general visibility, master scale / alpha, lock, debug console, reset position, reset all |
| General | Party frames | which frame system elements attach to; whether your own row is included |
| General | Health updates | one *Update health* switch and *Health refresh* pace, shared by target and pet frames |
| Cast Bars | General | enable, fade out |
| Cast Bars | Size & Position | size (width, height), then anchor mode, match width, the attached pin (points, offsets), the free stack (growth, spacing); the block the anchor mode does not use is dimmed |
| Cast Bars | Bar | the fill block, the cast-state palette, the background |
| Cast Bars | Border | the border block with *Show border* |
| Cast Bars | Text | the font block, spell name, time left |
| Cast Bars | Icon | spell icon and its side, the shield, the spark |
| Target Frames | General | enable, click to target, update health, health refresh interval |
| Target Frames | Size & Position | as Cast Bars |
| Target Frames | Bar | the fill block, NPC reaction colors, the background |
| Target Frames | Border | the border block with *Show border* |
| Target Frames | Text | the font block, name, health percent |
| Target Frames | Marker | the target's raid marker, its point on the bar, X/Y offsets |
| Pet Frames | General | enable, click to target, update health |
| Pet Frames | Size & Position | as Cast Bars |
| Pet Frames | Bar | the fill block (*Use class color* = the owner's class), the background |
| Pet Frames | Border | the border block with *Show border* |
| Pet Frames | Text | the font block, name, health percent |
| Profiles | — (AceDBOptions) | create, switch, copy, reset, delete profiles |

## General → Master controls

Composed by the library's `MasterControls` (options-ui-§15), not typed out. Not frameless: the
free-placement stacks are movable, so every row applies.

| Control | Schema path | Behavior |
|---|---|---|
| Enable Party Frame Enhanced | `enabled` | addon-wide switch; publishes VISIBILITY |
| General visibility | `visibility` | Always / Only in combat / Only out of combat / Never; publishes VISIBILITY |
| Master scale | `scale` | multiplies every element's size (CONFIG "master") |
| Master alpha | `alpha` | multiplies every element's alpha (CONFIG "master") |
| Lock frame | `locked` | off = unlocked = preview mode and grabbable free-placement stacks (`NS.OnLockChanged` holds preview for `unlock`, `modules/Preview.lua`); unlocking in combat is refused and the box snaps back |
| Debug console | `state.debugConsole` | session-only; shows or hides the console window |
| Reset position | — (button) | `NS.Anchor.ResetPositions()` — the free-placement stacks back to defaults |
| Reset all settings | — (button) | confirms, then resets the active profile (options-ui-§12) |

## General → Party frames

| Control | Schema path | Behavior |
|---|---|---|
| Frame system | `general.provider` | Automatic / Blizzard / EllesmereUI; Providers re-resolves (CONFIG "general") |
| Include my own row | `general.includePlayer` | the player's elements, wherever the frame system shows the player and always in free placement |

## General → Health updates

One switch and one pace for both unit-button features, so target and pet frames cannot disagree.

| Control | Schema path | Behavior |
|---|---|---|
| Update health | `general.updateHealth` | off: target and pet bars are drawn full with no percent; the target ticker never runs and no pet health event is registered. *Show health percent* on both Text tabs dims with it |
| Health refresh (seconds) | `general.tickInterval` | the target health ticker's pace (0.1–1.0); a new pace restarts a running ticker. Pets update from the game's own health events, so it does not apply to them. Dimmed while *Update health* is off |

## Cast Bars

Every path is under `castbar.`. The Size & Position tab is shared by all three feature pages
(`settings/ElementRows.lua`); the Border, Text-font and Bar-fill blocks come from the library's
composers, and every companion there resolves to the **tracked unit's** class
(`classColorSource = "unit"`).

| Tab | Subgroup | Controls → path |
|---|---|---|
| General | — | Enable cast bars → `enabled` · Fade out → `fadeOut` |
| Size & Position | Size | Width → `width` (dimmed while attached with *Match party frame width* on) · Height → `height` |
| Size & Position | Placement | Anchor mode → `anchorMode` · Match party frame width → `matchWidth` (dimmed in free placement) |
| Size & Position | Attached to party frames | Anchor point → `point` · Party frame point → `relativePoint` · X/Y offset → `offsetX`/`offsetY` (all dimmed in free placement) |
| Size & Position | Free placement | Growth direction → `growth` · Spacing → `spacing` (both dimmed while attached) |
| Bar | Fill | Bar texture · Bar opacity · Cast color (`barColor`) · Use class color |
| Bar | Cast colors | Channel · Empowered · Can't be interrupted · Interrupted (palette: no companion) |
| Bar | Background | Background color → `bgColor` · Use class color → `useClassColorBg` |
| Border | — | Show border · Border style · Border thickness (px) · Border color · Use class color |
| Text | Font | Font · Font size · Font color · Use class color · Font flags · Font shadow · Show spell name → `showName` · Show time left → `showTime` |
| Icon | — | Show spell icon → `showIcon` · Icon side → `iconSide` · Show shield → `showShield` · Show spark → `showSpark` |

Dimming is the library's `disabledIf`, re-evaluated on every write, so switching the anchor mode dims
the other block on the same frame. A dimmed row keeps its stored value, and `/pfe set` still writes it.

## Target Frames

Paths under `target.`. Size & Position, Border and Text-font as on Cast Bars.

| Tab | Subgroup | Controls → path |
|---|---|---|
| General | — | Enable target frames → `enabled` · Click to target → `clickToTarget` |
| Bar | Fill | Bar texture · Bar opacity · Bar color · Use class color (a **player** target's class) |
| Bar | Reaction colors | Color NPCs by reaction → `colorReaction` · Hostile · Neutral · Friendly (palette: no companion) |
| Bar | Background | Background color · Use class color |
| Text | Font | the font block · Show name → `showName` · Show health percent → `showPercent` (dimmed while Update health is off) |
| Marker | — | Show raid marker → `showMarker` · Anchor point → `markerPoint` · X/Y offset → `markerOffsetX`/`markerOffsetY` (the last three dimmed while the marker is off) |

With the shared *Update health* (General → Health updates) off, the bar is drawn full with no percent
and the health ticker never starts. The marker's
center sits on *Anchor point* of the bar; the default, *Left*, is half over the bar's left end.

*Click to target* and every size or position change are secure writes: made in combat, they apply
when combat ends.

## Pet Frames

Paths under `pet.`. Size & Position, Border and Text-font as on Cast Bars.

| Tab | Subgroup | Controls → path |
|---|---|---|
| General | — | Enable pet frames → `enabled` · Click to target → `clickToTarget` |
| Bar | Fill | Bar texture · Bar opacity · Bar color · Use class color (the **owner's** class) |
| Bar | Background | Background color · Use class color |
| Text | Font | the font block · Show name → `showName` · Show health percent → `showPercent` (dimmed while Update health is off) |

With the shared *Update health* (General → Health updates) off, the bar is drawn full with no percent
and the pet's health events are unregistered.

## Resets

- **Defaults** (header button, per page): that page's rows only, one `[Set] reset <page>: N rows` line.
- **Reset all settings** / `/pfe resetall`: a **profile reset** of the active profile — the same act as
  Profiles → Reset Profile. The popup text is the collection's one wording, verbatim.
