local addonName, NS = ...

-- core/Constants.lua — fixed values: fallback media, the monospace face, the landing-page logo
-- path, the SetPoint anchor list and the frame layering table (LAYERS).

NS.Constants = NS.Constants or {}
local C = NS.Constants

-- Fallback media — used when LibSharedMedia is absent or a stored key no longer resolves, so an
-- element always has a real texture, border and font.
C.FALLBACK_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
C.FALLBACK_BORDER  = "Interface\\Tooltips\\UI-Tooltip-Border"
C.FALLBACK_FONT    = "Fonts\\FRIZQT__.TTF"

-- The debug console's monospace face, from LibKa0s (debug-logging-§2). The last rung is the literal
-- above, never _G.STANDARD_TEXT_FONT: a fallback that can itself be nil is not a fallback.
C.FONT_MONO = NS.MediaFont and NS.MediaFont("JetBrains Mono") or C.FALLBACK_FONT
C.FONT_MONO_NAME = "JetBrains Mono"

-- Landing-page logo (options-ui-§5): a .tga, because the client cannot load .png.
C.LOGO_PATH = "Interface\\AddOns\\" .. addonName .. "\\media\\logos\\" .. addonName:lower() .. ".logo.tga"

-- The nine SetPoint anchors, in the order the anchor dropdowns list them.
C.POINTS = {
    "TOPLEFT", "TOP", "TOPRIGHT",
    "LEFT", "CENTER", "RIGHT",
    "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}

-- ── frame layering (frame-layering-§5) ────────────────────────────────────────────────────────
--
-- THE ADDON'S STACK, stated once. Every SetFrameStrata and SetFrameLevel under core/, modules/ and
-- settings/ reads this table; docs/ARCHITECTURE.md (Frame layering) points here rather than copying it.
--
--   T1h  fade frame, one per unit (modules/RangeFade.lua): the stacking root of that unit's cast
--        bar, target frame and pet frame. Host-matched: on *Match party frames* it READS its party
--        frame's strata and sits one level over that frame's highest readable descendant (a
--        measured level, relative by construction). Where no strata can be read it takes
--        STRATA.HOST_FALLBACK, at LEVEL.UNREADABLE (or LEVEL.NO_HOST with no frame at all) over
--        UIParent's level.
--   T1p  General → *Frame strata*: the player's fixed pick, PLAYER_STRATA below. Dialog shipped
--        before frame-layering-§1's BACKGROUND-to-HIGH rule and keeps its stored value; the row's
--        tooltip (O.StrataTooltip) says what Dialog covers.
--   T1   the elements: children of their fade frame, so they inherit its strata and stack at
--        fade + 1. Inside each element the ladder is inherited, never set: root regions (background,
--        icon) < LEVEL.FILL (the status bar) < LEVEL.BORDER (the border frame, a child of the bar)
--        < LEVEL.OVERLAY (the mouse-off overlay frame, a child of the border, holding both texts,
--        the spark, the shield and the raid marker).
--   T2b  free-placement holders (modules/Anchor.lua): the drag backplate behind a free stack, in the
--        strata of its stack's lowest fade frame and at that fade frame's level (LEVEL.BACKPLATE),
--        so the plate draws under every element and a mouse-enabled element above it keeps its click.
--        Its caption grip inherits holder + 1.
--   T1h  the out-of-party stand-in (modules/StandIn.lua): the imitated frame system's strata when it
--        can be read, else STRATA.HOST_FALLBACK, set when it is built and again when it is placed.
--
-- Library- and Blizzard-owned tiers it sits under: the LibKa0s debug console and perf panel at
-- DIALOG, toplevel; the library copy window at FULLSCREEN; the library and AceGUI menus at
-- FULLSCREEN_DIALOG; GameTooltip and the LSM pullouts at TOOLTIP; Blizzard's Settings panel at HIGH
-- and its StaticPopups at DIALOG; the settings combat cover, measured by LibKa0s over its page.
C.LAYERS = {
    STRATA = {
        -- Where Blizzard's own unit frames live: the strata used when the host's cannot be read.
        HOST_FALLBACK = "LOW",
    },
    -- general.strata's fixed choices, lowercase for the CLI, as the client spells them.
    PLAYER_STRATA = {
        background = "BACKGROUND", low = "LOW", medium = "MEDIUM", high = "HIGH", dialog = "DIALOG",
    },
    -- The client's strata, bottom to top: which of two stacks is lower, and which strings a strata
    -- read may answer.
    STRATA_RANK = {
        BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5,
        FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8,
    },
    LEVEL = {
        HOST_STEP  = 1,      -- a fade frame over its party frame's highest readable descendant
        NO_HOST    = 1,      -- over UIParent, when no frame of the active system exists
        UNREADABLE = 50,     -- over UIParent, clear of a party frame's children it cannot measure
        CEILING    = 9000,   -- the measured level's cap; the client's own is 10000
        BACKPLATE  = 0,      -- a holder over its stack's lowest fade frame
        FILL       = 1,      -- an element's status bar over its root (inherited)
        BORDER     = 2,      -- the border frame over the root (inherited, a child of the bar)
        OVERLAY    = 3,      -- the overlay frame over the root (inherited, a child of the border)
    },
}
