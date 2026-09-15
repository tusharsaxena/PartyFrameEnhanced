local _, NS = ...

-- defaults/Profile.lua — every profile default, and the only place one is written (savedvariables-§2).
-- Feature sections (castbar, target, pet) are added by the phase that builds each feature.

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
    },

    castbar = {
        enabled = true,

        -- Position (settings/ElementRows.lua). Attached: under the party frame, edge to edge.
        -- `position` is the free-placement holder's anchor, owned by modules/Anchor.lua; nil means
        -- the default spot.
        anchorMode = "attached", point = "TOP", relativePoint = "BOTTOM",
        offsetX = 0, offsetY = -2, matchWidth = true,
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
}

NS.defaults.global = {
    -- The account-wide schema stamp NS:RunMigrations walks from (savedvariables-§1). 1 is also the
    -- "pre-ladder" value: AceDB copies defaults into an absent key before the runner reads it, so any
    -- higher default would mark a stale store as already migrated.
    schemaVersion = 1,
}
