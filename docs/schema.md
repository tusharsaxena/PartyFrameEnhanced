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
general.rangeFade     = true     fade each unit's elements with its party frame when out of range
general.updateHealth  = true     health updates on target AND pet frames (General → Health updates)
general.tickInterval  = 0.2      the target health ticker's pace, seconds (pets use their own events)
```

```text
castbar.enabled = true                       castbar.fadeOut = true
castbar.anchorMode = "attached"              "attached" | "free"
castbar.point = "TOP"  castbar.relativePoint = "TOP"  castbar.offsetX = 0  castbar.offsetY = 0
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
target.markerPoint = "TOP"  markerOffsetX = 0  markerOffsetY = 0

pet.enabled = true  pet.clickToTarget = true
pet.anchorMode = "attached"  point = "TOPLEFT"  relativePoint = "TOPRIGHT"  offsetX = 4  offsetY = -20
pet.matchWidth = false  width = 80  height = 14  growth = "DOWN"  spacing = 4  position = nil
pet.barTexture  barAlpha  barColor = {0.35, 0.70, 0.35, 1}  useClassColorBar = false   (the OWNER's class)
pet.bgColor  useClassColorBg  pet.border…  pet.font…  (as target)
pet.showName = true  showPercent = false  showMarker = true
pet.markerPoint = "TOP"  markerOffsetX = 0  markerOffsetY = 0
```

The Master controls tab carries **one** `sessionOnly` row, which does not reach the profile.
**Debug console** is `state.debugConsole`, whose value is the console window's own visibility.

There were two until options-ui-§15 exempted this addon from the **Test mode** row: unlocking
already is its preview — it raises the stand-in out of a party and paints placeholders in one — so a
second switch for the same state was the finding (anti-pattern #80). `state.testMode` and
`NS.State.test` are both gone; the three refusals that row carried (combat, disabled, suspended) are
now the `locked` row's validate.

## Named non-setting state (architecture-§5)

- `castbar.position`, `target.position`, `pet.position` — each feature's free-placement anchor
  `{ point, x, y }`. Written only by a drag; no control sets it and no schema row addresses it. Owner:
  `modules/Anchor.lua`. Writers: its drag-stop handler and `Anchor.ResetPositions` (the *Reset
  position* button and `/pfe resetposition`).

## Global

```text
global.schemaVersion = 0                       -- default; the runner stamps NS.SCHEMA_VERSION (1)
global.minimap       = { hide = false }        -- LibDBIcon's own table
```

`global.minimap` is **LibDBIcon-1.0's own table**, handed straight to its `:Register` and written by
it too — `hide` from the button's right-click menu, `minimapPos` when the player drags the button
(architecture-§5 governs both). The declared default above is what materializes it.

It is **global rather than profile** because launcher-§3 fixes it there: a profile is how a player
configures what the addon *draws*, while the ring of buttons around the minimap is furniture they
arranged once, so a profile switch must not move it — and `minimapPos` has to live in the same place
for the same reason, which is why the two are one table.

**It also survives every reset this addon ships**, and that is a separate property rather than a
consequence of the scope above. Whether the button is shown is a per-installation display
preference, in the same class as the position the player dragged it to. So neither options-ui-§12's
*Reset all settings* nor the page-scoped **Defaults** button on General may move it, in either
direction. `settings/OptionsSetup.lua`'s `exemptFromReset` is the single place that says so: it
answers on `NS.IsGlobalSetting(row.path)`, vetoes the row from `skipRestoreAll`, and — the half that
actually bites — drops it from the descriptor's `applyDefault`, which is the one call *both* panel
resets make. `/pfe reset global.minimap.hide` is deliberately still live: a player naming one row is
not a sweep.

`hide` is addressed by the Master-controls **Minimap button** row at the path `global.minimap.hide`,
which the composer takes verbatim (it is outside the block's profile prefix). The row's boolean says
**shown** and the key says **hidden**, so `settings/General.lua` registers the inverting get/set with
`NS.RegisterGlobalSetting` and the seam bridges them once. **No migration:** this addon never stored
a minimap table anywhere else, so the path is new rather than moved and `NS.SCHEMA_VERSION` stays at 1.

## Migrations

`NS:RunMigrations` (`core/Database.lua`) walks an ordered ladder of
`{ to = N, scope = "profile"|"global", apply = fn }` steps above `global.schemaVersion`, towards
`NS.SCHEMA_VERSION`. **v1 is the shape v0.1.0 ships, so the ladder is empty.** A future stored-value
change — a type change, a rename, a moved key — adds its step and raises `NS.SCHEMA_VERSION` in the
same change as the row, and records it here.

The rules the runner keeps (savedvariables-§1):

- **The default is 0, and the runner owns the stamp.** `defaults/Profile.lua` declares
  `global.schemaVersion = 0`, never the current version: AceDB strips a value equal to its default at
  logout, so a current-version default would never persist, and AceDB backfills a declared default onto
  a store with no stamp. A first run stamps `NS.SCHEMA_VERSION` (1) after the walk, and that value
  persists because it differs from the default.
- **A profile step runs over every stored profile**, not just the active one: `apply` is called with
  each table in AceDB's raw `profiles` (the active one included), or with the one profile on the
  no-AceDB path. A global step is called with `global`. A raw stored profile has its defaults
  stripped, so every step reads with a fallback and is idempotent against a fresh default profile.
- **The stamp advances only past a step that returned without raising.** A step runs under `pcall`;
  on failure the runner logs it to the debug console, prints one line, and stops with the stamp where
  it was, so the next login retries it.

| Version | Change | Step |
|---|---|---|
| 1 | initial shape | — |
