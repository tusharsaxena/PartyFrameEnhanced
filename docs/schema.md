# Schema — what is persisted

## SavedVariables

| Global | What | Owner |
|---|---|---|
| `PartyFrameEnhancedDB` | the AceDB store: `profiles`, `profileKeys`, `global` | `core/Database.lua` |
| `PartyFrameEnhancedPerfDB` | the perf capture ring (last 10 runs), outside the AceDB tree | `LibKa0s-Perf-1.0` via `core/PerfSetup.lua` |

## Profile shape (v2)

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
general.strata        = "auto"   "auto" (each unit's party frame's strata, a level above it) | "background" | "low" | "medium" | "high" | "dialog"
general.updateHealth  = true     health updates on target AND pet frames (General > All elements > Health updates)
general.tickInterval  = 0.2      the target health ticker's pace, seconds (pets use their own events)
```

```text
skin.source      = "ka0s"   "ka0s" (the Ka0s skin below) | "eui" (EllesmereUI's look)
skin.skin        = NS.DEFAULT_SKIN   "forever" on WoW Forever, "ka0s" on Retail (LibKa0s v1.94.0, skinning-§2); every registered skin's key: ka0s | obsidian | azeroth | glass | contrast | ember | wow | midnight | forever
skin.ignorePanel = true     the Scope: keep the settings panel in the client's own look
skin.ignoreFonts = false    the Scope: keep every font as the client draws it (the skin still colors the text); the HUD keeps each section's own Font
skin.font        = ""       the Font override: an LSM font key, "" for the skin's own
skin.texture     = ""       the Texture override: an LSM statusbar key, "" for the skin's own
skin.outline     = "hud"    the Font outline (LibKa0s v1.82.0): "all" text | "hud" text only (the default since v1.83.0) | "off"
skin.pickerSeen  = false    the first-run skin picker was closed on this profile (drawn by nothing)
skin.fullSkinReset = false  this profile has been through the v4 step onto the skin (no schema row)
```

**The skin this addon wears** (skinning-§2, §3), per profile. Every `skin.*` row is a General-page
schema row in the Skin tab's group (`Appearance`) with `skipRender`, because the library's tab draws
the first seven itself; `pickerSeen` is drawn by nothing and written only by the picker's close. All
eight are written only through `NS.SetByPath`, so `/pfe get|set skin.skin` validates against the
registered skins, every reset reaches them (a profile reset puts the picker back to unseen, so it
shows again), and a write publishes `CONFIG("skin")`. Each row's `onChange` applies only its own half
(`core/SkinSetup.lua`). `skin.font` and `skin.texture` are free text, not a list, because a media
pack may register its keys after the settings files load; a key no pack registers is stored and the
skin's own face or texture is drawn. `skin.outline` is applied with `Skin:SetOutline` beside the
Scope and the overrides, at load and on every profile event; the write seam stores the Skin tab's
`media.outline` when it is not nil. A Font flags row on *From skin* draws through it.

```text
castbar.enabled = true                       castbar.fadeOut = true
castbar.anchorMode = "attached"              "attached" | "free"
castbar.point = "TOP"  castbar.relativePoint = "TOP"  castbar.offsetX = 0  castbar.offsetY = 0
castbar.matchWidth = true  castbar.width = 140  castbar.height = 16
castbar.growth = "DOWN"  castbar.spacing = 4  castbar.position = nil (named non-setting state)
castbar.barTexture = "Ka0s Default"  castbar.barTextureFromSkin = true  castbar.barAlpha = 1.0
castbar.barColor = {1, 0.7, 0, 1}  castbar.useClassColorBar = false  barColorFromSkin = true   (the plain-cast fill)
castbar.channelColor / empowerColor / uninterruptibleColor / failedColor   (palette, no companion)
castbar.bgColor = {0, 0, 0, 0.6}  castbar.useClassColorBg = false  bgColorFromSkin = true
castbar.borderShow = false  borderStyle = "Blizzard Tooltip"  borderStyleFromSkin = true  borderSize = 8
castbar.borderColor = {0, 0, 0, 1}  castbar.useClassColorBorder = false  borderColorFromSkin = true
castbar.font = "Ka0s Prototype"  fontFromSkin = true  fontSize = 11  fontColor = {1, 1, 1, 1}  fontColorFromSkin = true
castbar.useClassColorFont = false  fontFlags = "@skin"  fontShadow = false  fontShadowFromSkin = true
castbar.showName = true  showTime = true  showIcon = true  iconSide = "LEFT"
castbar.showShield = true  showSpark = true
```

```text
target.enabled = true  target.clickToTarget = true
target.anchorMode = "attached"  point = "TOPLEFT"  relativePoint = "TOPRIGHT"  offsetX = 4  offsetY = 0
target.matchWidth = false  width = 110  height = 20  growth = "DOWN"  spacing = 4  position = nil
target.barTexture = "Ka0s Default"  barTextureFromSkin = true  barAlpha = 1.0  barColor = {0.25, 0.75, 0.25, 1}  useClassColorBar = false  barColorFromSkin = true
target.colorReaction = true  hostileColor / neutralColor / friendlyColor   (palette, no companion)
target.bgColor = {0, 0, 0, 0.6}  useClassColorBg = false  bgColorFromSkin = true
target.borderShow = false  borderStyle  borderStyleFromSkin = true  borderSize = 8  borderColor  useClassColorBorder = false  borderColorFromSkin = true
target.font  fontFromSkin = true  fontSize = 10  fontColor  fontColorFromSkin = true  useClassColorFont = false  fontFlags = "@skin"  fontShadow = false  fontShadowFromSkin = true
target.showName = true  showPercent = true  showMarker = true
target.markerPoint = "TOP"  markerOffsetX = 0  markerOffsetY = 0

pet.enabled = true  pet.clickToTarget = true
pet.anchorMode = "attached"  point = "TOPLEFT"  relativePoint = "TOPRIGHT"  offsetX = 4  offsetY = -20
pet.matchWidth = false  width = 80  height = 14  growth = "DOWN"  spacing = 4  position = nil
pet.barTexture  barTextureFromSkin  barAlpha  barColor = {0.35, 0.70, 0.35, 1}  useClassColorBar = false  barColorFromSkin = true   (the OWNER's class)
pet.bgColor  useClassColorBg  pet.border…  pet.font…  (as target)
pet.showName = true  showPercent = false  showMarker = true
pet.markerPoint = "TOP"  markerOffsetX = 0  markerOffsetY = 0
```

**The HUD style that follows the skin** (skinning-§6). Each section's `barTextureFromSkin`,
`borderStyleFromSkin` and `fontFromSkin` are the composers' *Use the skin's texture / border / font*
companions (`fromSkin` in `settings/ElementRows.lua`), default **true**. While one is on its
picker is dimmed and `modules/Element.lua` draws the skin's `bar.texture` or `hud.font` through
`S.Resolve`, or the border through `S.BarBorder`; the stored pick beside it is kept and comes back
when it is turned off. `barColorFromSkin`, `bgColorFromSkin`, `borderColorFromSkin`, `fontColorFromSkin`
and `fontShadowFromSkin` do the same for the colors and the Font shadow, as `extra` rows (the owner's
ruling of 2026-11-01): the fill draws `pf.castFill`, `pf.targetFill` or `pf.petFill`, the background
`pf.barBg`, the border `bar.border`, the text `hud.text` and the shadow `hud.shadow`, each owner token
holding this addon's old color under Ka0s Default and following `bar.fill` or `bar.bg` elsewhere. The
swatch stays live and stored. A class color comes first, and the cast-state and reaction colors are
meaning colors with no companion. `borderShow` defaults off: a skin's `None`, Ka0s Default's
among them, defers to it and to the stored style and thickness, and a real style wins over all three
(`S.BarBorder`). Since LibKa0s v1.82.0 the size scales with the skin
while the face follows it (`S.HudFontSize`; the stored `fontSize` is never rewritten), and
`fontFlags` defaults to `"@skin"`, *From skin* (`flagsFromSkin = true`), drawn through the Skin tab's
Font outline (`S.FontFlags`); a picked flag wins. A skin switch restyles every element (each feature's `OnLooksChanged` listener runs its
reskin, the target and pet frames' through `NS.RunSecure`).

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
global.schemaVersion = 0                       -- default; the runner stamps NS.SCHEMA_VERSION (6)
global.minimap       = { hide = false }        -- LibDBIcon's own table
```

`global.minimap` is **LibDBIcon-1.0's own table**, handed straight to its `:Register` and written by
it too — `hide` when the Master-controls **Minimap button** row shows or hides the button
(`NS.Launcher:SetShown`; the right-click menu carries only *Enabled* and *Locked*), `minimapPos` when
the player drags the button
(architecture-§5 governs both). The declared default above is what materializes it.

It is **global rather than profile** because launcher-§3 fixes it there: a profile is how a player
configures what the addon *draws*, while the ring of buttons around the minimap is furniture they
arranged once, so a profile switch must not move it — and `minimapPos` has to live in the same place
for the same reason, which is why the two are one table.

**It also survives every reset this addon ships**, and that is a separate property rather than a
consequence of the scope above. Whether the button is shown is a per-installation display
preference, in the same class as the position the player dragged it to. So neither options-ui-§12's
*Reset all settings* nor the page-scoped **Defaults** button on General may move it, in either
direction. `settings/Schema.lua`'s `NS.IsGlobalSetting` is the single place that says so. Its set is
the `LibKa0s-Schema-1.0` instance's `resetExempt`, so `ApplyDefault` refuses the row while a bulk
bracket is open — and both panel resets run inside one — and `settings/OptionsSetup.lua` also vetoes
it from `skipRestoreAll`. `/pfe reset global.minimap.shown` is deliberately still live: it runs
outside a bracket, and a player naming one row is not a sweep.

`hide` is addressed by the Master-controls **Minimap button** row at the path `global.minimap.shown`,
which the composer takes verbatim (it is outside the block's profile prefix). The path reads in the
row's own sense (launcher-§3): the row's boolean says **shown** and the stored key says **hidden**, so
`settings/General.lua` stamps the inverting `get`/`set` onto the composed row by path, and the seam,
which honors a row's own storage, bridges them once. No `shown` key is ever stored (anti-pattern #81).
Because the path is not a storage path, `NS.ValidateSchema` skips its resolution check, and
`tests/test_schema.lua` pins the storage default `global.minimap.hide` directly.

**No migration.** The row's CLI path was `global.minimap.hide` until the launcher-§3 rename; the
stored key did not move, so a player who hid the button keeps it hidden with no SavedVariables step,
and `NS.SCHEMA_VERSION` stayed at 1. The old path answers `Setting not found`; a macro running
`/pfe set global.minimap.hide true` becomes `/pfe set global.minimap.shown false`.

## The write seam

The seam is `LibKa0s-Schema-1.0`'s (library-stack-§7): `settings/Schema.lua` builds one instance
over `NS.Schema` and binds `NS.SetByPath`, `NS.GetSetting`, `NS.FindSchemaRow`, `NS.ApplyDefault`,
`NS.Bulk` and the reset count onto it. What that means for what is persisted:

- **Only a declared row's path is written.** A path no row declares is refused and nothing is stored.
- **A table value is copied in**, so the caller's table and the profile never alias.
- **`writeThrough = { "enabled", "locked" }`.** On a load without LibKa0s the Master controls
  composer is hollow and those two paths have no row, yet the host verbs (`/pfe enable|disable|lock|
  unlock`) and `modules/Preview.lua`'s combat re-lock still write them. Both the instance and the
  host's degradation stub store a listed row-less path raw, with no row `onChange`, and refuse every
  other row-less path. With the library present the composed row always takes the write.
- The two rows whose value is not in the profile, `state.debugConsole` (session only) and
  `global.minimap.shown` (global, stored as `hide`), carry their own `get`/`set`, stamped on by
  `settings/General.lua`.

## Migrations

`NS:RunMigrations` (`core/Database.lua`) walks an ordered ladder of
`{ to = N, scope = "profile"|"global", apply = fn }` steps above `global.schemaVersion`, towards
`NS.SCHEMA_VERSION`, which is the ladder's highest step. v1 is the shape v0.1.0 ships. A stored-value
change — a type change, a rename, a moved key — adds its step in the same change as the row, and
records it here.

The rules the runner keeps (savedvariables-§1):

- **The default is 0, and the runner owns the stamp.** `defaults/Profile.lua` declares
  `global.schemaVersion = 0`, never the current version: AceDB strips a value equal to its default at
  logout, so a current-version default would never persist, and AceDB backfills a declared default onto
  a store with no stamp. A first run stamps `NS.SCHEMA_VERSION` (6) after the walk, and that value
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
| 2 | the HUD style follows the skin (skinning-§6, ruling R3; O2 of the 2026-10-29 skinning rollout): the one-time reset | `profile`: on each stored `castbar`, `target` and `pet` section, `barTextureFromSkin` and `fontFromSkin` become true, and `borderStyleFromSkin` becomes true unless the section draws a border (`borderShow = true`), where it is written false so the player's border survives Ka0s Default's `None` style. The picks are not touched, and a section never stored keeps the defaults, which already follow. Written directly, never through `Skin.ResetToSkin`, which on a raw profile without the companion would put the `@skin` sentinel into the pick. Runs once: the stamp holds a later choice. |
| 3 | the HUD Font flags follow the skin's Font outline (LibKa0s v1.82.0, ruling D-07; Addendum 01 of the 2026-10-30 skin fonts run) | `profile`: on each stored `castbar`, `target` and `pet` section, a `fontFlags` of `"OUTLINE"`, the previous default, becomes `"@skin"` (*From skin*), which draws OUTLINE under the default Font outline and follows the Skin tab from then on. Any other stored flag is the player's pick and stays; a flag never stored reads the new default. Runs once: an OUTLINE picked afterwards is kept. |
| 4 | every section's colors and shadow follow the skin (the owner's rulings of 2026-11-01, FS-PF-FLIP) | `profile`, through `NS.ResetProfileToSkin`: `Skin.FollowOnce` over `NS.SKIN_RESET_PATHS`, the eight companions of each stored section and its `fontFlags`, gated by the profile's own `skin.fullSkinReset`. It also runs at the end of every `RunMigrations` and on every profile event, so a companion turned off afterwards stays off. It moves a border v2 kept the player's. No stored color or pick is written. `skin.fullSkinReset` has no schema row, so no Defaults button can put it back; a profile reset does, and the step then runs against defaults. Without the library the same write by hand |
| 5 | spent: writes nothing | `profile`: none. An unreleased build wrote `borderShow` here and turned Show border on for players who had it off; no step writes a stored `borderShow`, as in AuraMaster (the owner's ruling of 2026-11-01). The number stays taken because that build stamped it on the clients that ran it. |
| 6 | the deleted Friz becomes Ka0s Ubuntu (R3-FRIZ): LibKa0s v1.85.0 deleted `Ka0s Friz Quadrata TT` (R3-L7) and WoW Default draws `Ka0s Ubuntu` in its place (R3-L6) | `profile`, through `NS.RetireFonts`: every stored string naming the deleted face, at any depth (a section's `font`, the skin's Font override), becomes `Ka0s Ubuntu`. Blizzard's own `Friz Quadrata TT` stays. Idempotent. |
