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
| Cast Bars | *(plan P3)* | General · Position · Bar · Border · Text · Icon |
| Target Frames | *(plan P4)* | General · Position · Bar · Border · Text · Marker |
| Pet Frames | *(plan P5)* | General · Position · Bar · Border · Text |
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

## Resets

- **Defaults** (header button, per page): that page's rows only, one `[Set] reset <page>: N rows` line.
- **Reset all settings** / `/pfe resetall`: a **profile reset** of the active profile — the same act as
  Profiles → Reset Profile. The popup text is the collection's one wording, verbatim.
