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
| Cast Bars | General | enable, fade out |
| Cast Bars | Position | anchor mode, match width, the attached pin (points, offsets), the free stack (growth, spacing), size |
| Cast Bars | Bar | the fill block, the cast-state palette, the background |
| Cast Bars | Border | the border block with *Show border* |
| Cast Bars | Text | the font block, spell name, time left |
| Cast Bars | Icon | spell icon and its side, the shield, the spark |
| Target Frames | General | enable, click to target, health refresh interval |
| Target Frames | Position | as Cast Bars |
| Target Frames | Bar | the fill block, NPC reaction colors, the background |
| Target Frames | Border | the border block with *Show border* |
| Target Frames | Text | the font block, name, health percent |
| Target Frames | Marker | the target's raid marker |
| Pet Frames | General | enable, click to target |
| Pet Frames | Position | as Cast Bars |
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
| Lock frame | `locked` | off = unlocked = preview mode; calls `NS.OnLockChanged` (plan P6) |
| Debug console | `state.debugConsole` | session-only; shows or hides the console window |
| Reset position | — (button) | `NS.Anchor.ResetPositions()` — the free-placement stacks back to defaults |
| Reset all settings | — (button) | confirms, then resets the active profile (options-ui-§12) |

## General → Party frames

| Control | Schema path | Behavior |
|---|---|---|
| Frame system | `general.provider` | Automatic / Blizzard / EllesmereUI; Providers re-resolves (CONFIG "general") |
| Include my own row | `general.includePlayer` | the player's elements, wherever the frame system shows the player and always in free placement |

## Cast Bars

Every path is under `castbar.`. The Position tab is shared by all three feature pages
(`settings/ElementRows.lua`); the Border, Text-font and Bar-fill blocks come from the library's
composers, and every companion there resolves to the **tracked unit's** class
(`classColorSource = "unit"`).

| Tab | Subgroup | Controls → path |
|---|---|---|
| General | — | Enable cast bars → `enabled` · Fade out → `fadeOut` |
| Position | Placement | Anchor mode → `anchorMode` · Match party frame width → `matchWidth` |
| Position | Attached to party frames | Anchor point → `point` · Party frame point → `relativePoint` · X/Y offset → `offsetX`/`offsetY` |
| Position | Free placement | Growth direction → `growth` · Spacing → `spacing` |
| Position | Size | Width → `width` · Height → `height` |
| Bar | Fill | Bar texture · Bar opacity · Cast color (`barColor`) · Use class color |
| Bar | Cast colors | Channel · Empowered · Can't be interrupted · Interrupted (palette: no companion) |
| Bar | Background | Background color → `bgColor` · Use class color → `useClassColorBg` |
| Border | — | Show border · Border style · Border thickness (px) · Border color · Use class color |
| Text | Font | Font · Font size · Font color · Use class color · Font flags · Font shadow · Show spell name → `showName` · Show time left → `showTime` |
| Icon | — | Show spell icon → `showIcon` · Icon side → `iconSide` · Show shield → `showShield` · Show spark → `showSpark` |

## Target Frames

Paths under `target.`. Position, Border and Text-font as on Cast Bars.

| Tab | Subgroup | Controls → path |
|---|---|---|
| General | — | Enable target frames → `enabled` · Click to target → `clickToTarget` · Health refresh (seconds) → `tickInterval` |
| Bar | Fill | Bar texture · Bar opacity · Bar color · Use class color (a **player** target's class) |
| Bar | Reaction colors | Color NPCs by reaction → `colorReaction` · Hostile · Neutral · Friendly (palette: no companion) |
| Bar | Background | Background color · Use class color |
| Text | Font | the font block · Show name → `showName` · Show health percent → `showPercent` |
| Marker | — | Show raid marker → `showMarker` |

*Click to target* and every size or position change are secure writes: made in combat, they apply
when combat ends.

## Pet Frames

Paths under `pet.`. Position, Border and Text-font as on Cast Bars.

| Tab | Subgroup | Controls → path |
|---|---|---|
| General | — | Enable pet frames → `enabled` · Click to target → `clickToTarget` |
| Bar | Fill | Bar texture · Bar opacity · Bar color · Use class color (the **owner's** class) |
| Bar | Background | Background color · Use class color |
| Text | Font | the font block · Show name → `showName` · Show health percent → `showPercent` |

## Resets

- **Defaults** (header button, per page): that page's rows only, one `[Set] reset <page>: N rows` line.
- **Reset all settings** / `/pfe resetall`: a **profile reset** of the active profile — the same act as
  Profiles → Reset Profile. The popup text is the collection's one wording, verbatim.
