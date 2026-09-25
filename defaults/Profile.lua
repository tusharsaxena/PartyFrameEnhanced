local _, NS = ...

-- defaults/Profile.lua — every profile default, and the only place one is written (savedvariables-§2).
-- NS.defaults.profile holds the master controls and every feature section (general, castbar, target,
-- pet); NS.defaults.global below holds the account-wide rows.

NS.defaults = NS.defaults or {}

NS.defaults.profile = {
    -- Master controls (options-ui-§15). The debug console row is session state and stores nothing.
    -- Locked by default: unlocking turns on preview mode, which a first login must not start in.
    enabled    = true,
    visibility = "always",
    scale      = 1.0,
    alpha      = 1.0,
    locked     = true,

    general = {
        provider      = "auto",   -- "auto" | "blizzard" | "ellesmere"
        includePlayer = true,
        -- Fade each unit's elements with its party frame when the member is out of range
        -- (modules/RangeFade.lua).
        rangeFade     = true,
        -- Health updates, shared by target and pet frames. Off: their bars are drawn full with no
        -- percent, the target ticker never runs and no pet health event is registered.
        -- tickInterval paces the target ticker only: compound tokens (partyNtarget) get no
        -- UNIT_HEALTH (design spec §6.3); pets update from their own events.
        updateHealth  = true,
        tickInterval  = 0.2,
    },

    castbar = {
        enabled = true,

        -- Position (settings/ElementRows.lua). Attached: TOP to TOP at no offset, so the bar lies
        -- OVER the party frame rather than under it, spanning its width (matchWidth). Under the
        -- frame it competed for space with whatever the player has below their party; over it, the
        -- cast is read in the same glance as the health it belongs to.
        -- `position` is the free-placement holder's anchor, owned by modules/Anchor.lua; nil means
        -- the default spot.
        anchorMode = "attached", point = "TOP", relativePoint = "TOP",
        offsetX = 0, offsetY = 0, matchWidth = true,
        width = 140, height = 16, growth = "DOWN", spacing = 4,
        position = nil,

        -- Bar: the canonical block (the fill is the plain-cast color), then the cast-state palette.
        barTexture = "Blizzard", barAlpha = 1.0,
        barColor = { r = 1.0, g = 0.7, b = 0.0, a = 1.0 }, useClassColorBar = false,
        channelColor         = { r = 0.3, g = 0.7, b = 1.0, a = 1.0 },
        empowerColor         = { r = 0.8, g = 0.5, b = 1.0, a = 1.0 },
        uninterruptibleColor = { r = 0.6, g = 0.6, b = 0.6, a = 1.0 },
        failedColor          = { r = 0.9, g = 0.2, b = 0.2, a = 1.0 },
        bgColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.6 }, useClassColorBg = false,

        -- Border: off by default — a 16 px bar reads cleaner on its background alone.
        borderShow = false, borderStyle = "Blizzard Tooltip", borderSize = 8,
        borderColor = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 }, useClassColorBorder = false,

        -- Text
        font = "Friz Quadrata TT", fontSize = 11,
        fontColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }, useClassColorFont = false,
        fontFlags = "OUTLINE", fontShadow = false,
        showName = true, showTime = true,

        -- Icon and marks
        showIcon = true, iconSide = "LEFT", showShield = true, showSpark = true,

        -- Behavior
        fadeOut = true,
    },

    target = {
        enabled = true, clickToTarget = true,

        -- Attached: to the right of the party frame, its top edge level with the frame's.
        anchorMode = "attached", point = "TOPLEFT", relativePoint = "TOPRIGHT",
        offsetX = 4, offsetY = 0, matchWidth = false,
        width = 110, height = 20, growth = "DOWN", spacing = 4,
        position = nil,

        barTexture = "Blizzard", barAlpha = 1.0,
        barColor = { r = 0.25, g = 0.75, b = 0.25, a = 1.0 }, useClassColorBar = false,
        -- NPCs by their reaction to you; a secret reaction reads as hostile.
        colorReaction = true,
        hostileColor  = { r = 0.85, g = 0.20, b = 0.20, a = 1.0 },
        neutralColor  = { r = 0.90, g = 0.80, b = 0.20, a = 1.0 },
        friendlyColor = { r = 0.25, g = 0.75, b = 0.25, a = 1.0 },
        bgColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.6 }, useClassColorBg = false,

        borderShow = false, borderStyle = "Blizzard Tooltip", borderSize = 8,
        borderColor = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 }, useClassColorBorder = false,

        font = "Friz Quadrata TT", fontSize = 10,
        fontColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }, useClassColorFont = false,
        fontFlags = "OUTLINE", fontShadow = false,
        showName = true, showPercent = true,

        -- The marker's center sits on this point of the bar, nudged by the offsets (before Master
        -- scale). TOP, 0, 0 puts it half over the bar's top edge, centered, clear of the name.
        showMarker = true, markerPoint = "TOP", markerOffsetX = 0, markerOffsetY = 0,
    },

    pet = {
        enabled = true, clickToTarget = true,

        -- Attached: OUT TO THE RIGHT of the party frame, under the target frame that sits there.
        -- TOPLEFT to TOPRIGHT puts the column beside the frame instead of below it, and the -20
        -- drop clears the target frame's own row; the +4 is the gutter between the two columns.
        anchorMode = "attached", point = "TOPLEFT", relativePoint = "TOPRIGHT",
        offsetX = 4, offsetY = -20, matchWidth = false,
        width = 80, height = 14, growth = "DOWN", spacing = 4,
        position = nil,

        barTexture = "Blizzard", barAlpha = 1.0,
        barColor = { r = 0.35, g = 0.70, b = 0.35, a = 1.0 }, useClassColorBar = false,
        bgColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.6 }, useClassColorBg = false,

        borderShow = false, borderStyle = "Blizzard Tooltip", borderSize = 8,
        borderColor = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 }, useClassColorBorder = false,

        font = "Friz Quadrata TT", fontSize = 9,
        fontColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }, useClassColorFont = false,
        fontFlags = "OUTLINE", fontShadow = false,
        showName = true, showPercent = false,

        -- As the target frame's: the marker's center on this point of the bar, nudged by the offsets.
        showMarker = true, markerPoint = "TOP", markerOffsetX = 0, markerOffsetY = 0,
    },
}

NS.defaults.global = {
    -- The account-wide schema stamp NS:RunMigrations walks from (savedvariables-§1). 0, never the
    -- current version: AceDB strips a value equal to its default at logout, so a current-version
    -- default never persists, and AceDB backfills a declared default onto a store with no stamp,
    -- which would mark it as already migrated (WS-03). The runner owns the stamp and writes
    -- NS.SCHEMA_VERSION (core/Database.lua) after the walk.
    schemaVersion = 0,

    -- LibDBIcon's OWN table, and the only record of whether the minimap button is shown
    -- (launcher-§3). `hide` is the library's key and its sense is HIDDEN, while the Master controls
    -- row says SHOWN -- the inversion happens once, at the write seam settings/General.lua registers.
    -- A second `show` key beside it would be one state recorded twice, free to disagree the first
    -- time either was used (anti-pattern #81).
    --
    -- GLOBAL rather than profile, and that is the decision rather than an accident. The ring of
    -- buttons around the minimap is furniture the player arranged once: a profile switch must not
    -- move it, and options-ui-§12's *Reset all settings* -- a profile reset by definition -- must not
    -- un-hide a button they deliberately hid. Declaring the default here is what materializes the
    -- table; LibDBIcon writes `minimapPos` into the same table when the player drags the button, and
    -- architecture-§5 governs both writes.
    minimap = { hide = false },
}
