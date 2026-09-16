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
general.updateHealth  = true     health updates on target AND pet frames (General → Health updates)
general.tickInterval  = 0.2      the target health ticker's pace, seconds (pets use their own events)
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

```text
target.enabled = true  target.clickToTarget = true
target.anchorMode = "attached"  point = "TOPLEFT"  relativePoint = "TOPRIGHT"  offsetX = 4  offsetY = 0
target.matchWidth = false  width = 110  height = 20  growth = "DOWN"  spacing = 4  position = nil
target.barTexture = "Blizzard"  barAlpha = 1.0  barColor = {0.25, 0.75, 0.25, 1}  useClassColorBar = false
target.colorReaction = true  hostileColor / neutralColor / friendlyColor   (palette, no companion)
target.bgColor = {0, 0, 0, 0.6}  useClassColorBg = false
target.borderShow = false  borderStyle  borderSize = 8  borderColor  useClassColorBorder = false
target.font  fontSize = 10  fontColor  useClassColorFont = false  fontFlags = "OUTLINE"  fontShadow = false
target.showName = true  showPercent = true  showMarker = true
target.markerPoint = "LEFT"  markerOffsetX = 0  markerOffsetY = 0

pet.enabled = true  pet.clickToTarget = true
pet.anchorMode = "attached"  point = "TOPLEFT"  relativePoint = "BOTTOMLEFT"  offsetX = 0  offsetY = -20
pet.matchWidth = false  width = 80  height = 14  growth = "DOWN"  spacing = 4  position = nil
pet.barTexture  barAlpha  barColor = {0.35, 0.70, 0.35, 1}  useClassColorBar = false   (the OWNER's class)
pet.bgColor  useClassColorBg  pet.border…  pet.font…  (as target)
pet.showName = true  showPercent = false
```

The Master controls tab carries two `sessionOnly` rows, neither of which reaches the profile.
**Debug console** is `state.debugConsole`, whose value is the console window's own visibility.
**Test mode** is `state.testMode`, whose value is whether test mode is running: its get reads
`NS.State.test` and its set calls `NS.TestMode.Toggle` (`settings/General.lua`), so a refused
start prints why and the box redraws unticked.

## Named non-setting state (architecture-§5)

- `castbar.position`, `target.position`, `pet.position` — each feature's free-placement anchor
  `{ point, x, y }`. Written only by a drag; no control sets it and no schema row addresses it. Owner:
  `modules/Anchor.lua`. Writers: its drag-stop handler and `Anchor.ResetPositions` (the *Reset
  position* button and `/pfe resetposition`).

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
