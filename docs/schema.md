# Schema — what is persisted

## SavedVariables

| Global | What | Owner |
|---|---|---|
| `PartyFrameEnhancedDB` | the AceDB store: `profiles`, `profileKeys`, `global` | `core/Database.lua` |
| `PartyFrameEnhancedPerfDB` | the perf capture ring (last 10 runs), outside the AceDB tree | `LibKa0s-Perf-1.0` via `core/PerfSetup.lua` |

## Profile shape (v1)

Defaults are in `defaults/Profile.lua`, the only place a default is written.

```text
enabled    = true          Master controls: the addon-wide switch
visibility = "always"      "always" | "inCombat" | "outOfCombat" | "never"
scale      = 1.0           addon-wide multiplier on every element's size
alpha      = 1.0           addon-wide multiplier on every element's alpha
locked     = true          false = unlocked, which is preview mode
general.provider      = "auto"   "auto" | "blizzard" | "ellesmere"
general.includePlayer = true     the player's own row
```

```text
castbar.enabled = true                       castbar.fadeOut = true
castbar.anchorMode = "attached"              "attached" | "free"
castbar.point = "TOP"  castbar.relativePoint = "BOTTOM"  castbar.offsetX = 0  castbar.offsetY = -2
castbar.matchWidth = true  castbar.width = 140  castbar.height = 16
castbar.growth = "DOWN"  castbar.spacing = 4  castbar.position = nil (named non-setting state)
castbar.barTexture = "Blizzard"  castbar.barAlpha = 1.0
castbar.barColor = {1, 0.7, 0, 1}  castbar.useClassColorBar = false        (the plain-cast fill)
castbar.channelColor / empowerColor / uninterruptibleColor / failedColor   (palette, no companion)
castbar.bgColor = {0, 0, 0, 0.6}  castbar.useClassColorBg = false
castbar.borderShow = false  borderStyle = "Blizzard Tooltip"  borderSize = 8
castbar.borderColor = {0, 0, 0, 1}  castbar.useClassColorBorder = false
castbar.font = "Friz Quadrata TT"  fontSize = 11  fontColor = {1, 1, 1, 1}
castbar.useClassColorFont = false  fontFlags = "OUTLINE"  fontShadow = false
castbar.showName = true  showTime = true  showIcon = true  iconSide = "LEFT"
castbar.showShield = true  showSpark = true
```

The target and pet sections are added by the phases that build them (plan P4–P5); their shapes are
in the spec's §8.

The Master controls tab's **Debug console** row is `sessionOnly` at `state.debugConsole`: its value is
the console window's own visibility and never reaches the profile.

## Named non-setting state (architecture-§5)

- `castbar.position`, `target.position`, `pet.position` — each feature's free-placement anchor
  `{ point, x, y }`. Written only by a drag; no control sets it and no schema row addresses it. Owner:
  `modules/Anchor.lua`. Writers: its drag-stop handler and `Anchor.ResetPositions` (the *Reset
  position* button and `/pfe resetposition`). Arrives in plan P2.

## Global

```text
global.schemaVersion = 1
```

## Migrations

`NS:RunMigrations` (`core/Database.lua`) walks an ordered ladder of `{ to = N, apply = fn }` steps
above `global.schemaVersion`. **v1 is the shape v0.1.0 ships, so the ladder is empty.** A future
stored-value change — a type change, a rename, a moved key — adds its step in the same change as the
row, and records it here:

| Version | Change | Step |
|---|---|---|
| 1 | initial shape | — |
