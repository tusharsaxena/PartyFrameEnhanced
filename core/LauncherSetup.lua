local addonName, NS = ...

-- core/LauncherSetup.lua -- the LibKa0s-Launcher-1.0 seam (launcher-§1): ONE LibDataBroker-1.1
-- object of `type = "launcher"`, handed to LibDBIcon-1.0. LibDBIcon draws the minimap button from
-- it and any broker display (Titan Panel, ElvUI data texts, Bazooka) draws its own row from the
-- very same object, so there is one OnClick, one icon, one label and one identity. Two objects with
-- two click handlers is the same feature written twice and is anti-pattern #81.
--
-- WHAT THIS FILE SUPPLIES, and it is only what is genuinely this addon's: the folder name, the
-- logo, what the left button does, how the settings panel opens, and the answers the status
-- tooltip asks for (enabled, locked, the version, the left-click hint). The library owns the rest --
-- the object, the registration, the idempotence, the pcall around the click, the disabled gate and
-- every line of the tooltip.
--
-- THE RUNG IS (b) (launcher-§2, ADDONS.md). This addon has no primary window, and its PREVIEW
-- SWITCH is the lock: unlocking raises the stand-in party frame and paints the placeholders
-- (modules/Preview.lua), which is why options-ui-§15 exempts it from a Test mode row. So left-click
-- toggles the lock -- through NS.ToggleLock, the SAME seam `/pfe lock`, `/pfe unlock` and the
-- Lock frame checkbox all go through, never a second copy of that state. Right-click ALWAYS opens
-- the settings panel, on this addon as on every other, which is what lets the left button be spent
-- on something better.
--
-- WHY THE LIBRARY IS TOLD OUR NAME. `name` is the addon's FOLDER name and is used for BOTH
-- registrations. It is not cosmetic: LibDBIcon keys the button's SAVED POSITION by it, so a second
-- spelling drops the angle the player dragged the button to and labels the broker plugin with the
-- other name. `addonName` is the first vararg every TOC-loaded file gets, so it cannot drift from
-- the folder the client actually loaded.
--
-- NO DEGRADATION STUB, and that is the convention here rather than an omission (compare
-- core/DebugLogSetup.lua and settings/OptionsSetup.lua, which both carry one). A stub exists where
-- the addon's own files CALL into the absent surface at load and would raise. Nothing calls back
-- into this module except this file and the write seam in settings/General.lua, and that seam
-- already guards on `NS.Launcher` -- so a build without LibKa0s keeps no launcher at all and there
-- is nothing to answer. The two broker libraries are a separate question and the library answers it
-- itself: it resolves both with `LibStub(..., true)` at Register time and reports what is missing
-- on one line, so a host with neither still loads.

local Launcher = LibStub and LibStub("LibKa0s-Launcher-1.0", true)

if not Launcher then return end

NS.Launcher = Launcher:New({
    name  = addonName,
    -- The same file the TOC's `## IconTexture` names (launcher-§4): one logo in the AddOns list, on
    -- the minimap and in a broker display, so a player who has seen the addon once recognizes it in
    -- all three. Never a Blizzard path and never a file id (anti-pattern #82). Absolute from
    -- Interface\AddOns\, built from `addonName` for the same reason core/MediaSetup.lua builds its
    -- paths that way -- a wrong path here draws nothing and raises nothing.
    icon  = "Interface\\AddOns\\" .. addonName .. "\\media\\logos\\"
            .. addonName:lower() .. ".logo.128.tga",
    -- What a broker display prints beside the icon, and the ONE field that decides whether the
    -- collection reads as one collection in Titan Panel. launcher-§1 fixes it at the BRAND NAME IN
    -- PLAIN TEXT -- `Ka0s <Name>` -- so this addon's row files beside the other ten under K rather
    -- than alone under P. Across eleven adoptions it came out three ways because nothing said what
    -- it was; that is anti-pattern #84.
    --
    -- DELIBERATELY NOT THE TOC'S `## Title`, and the two are never wired to each other: a Title may
    -- carry color escapes and one in the collection does, which a display drawing the string raw
    -- would splatter across a row of otherwise plain text. No escape sequence of any kind here.
    -- Not the folder name either -- that is the registration `name` above, an identifier LibDBIcon
    -- keys the saved position by and a player reads nowhere as prose. Two fields, two jobs.
    label = "Ka0s Party Frame Enhanced",

    -- A FUNCTION, never the table: `NS.db` does not exist when this file loads, and a table captured
    -- now is one AceDB replaces at InitDB. The library resolves it at Register time, which is why
    -- Register is called from the lifecycle rather than from here.
    minimap = function() return NS.db and NS.db.global and NS.db.global.minimap end,

    -- Resolved at CLICK time, both of them: settings/OptionsSetup.lua and settings/Slash.lua load
    -- long after this file, and either may be the degraded arm.
    openSettings = function() NS.OpenOptionsPanel() end,
    onClick      = function() NS.ToggleLock() end,

    -- THE DISABLED GATE (launcher-§2, Launcher minor 2). While the Master-controls *Enable* row is
    -- off the library refuses the left click itself and prints `disabledLine()`, so NS.ToggleLock is
    -- not reached; its own gate stays for any other caller. The line is the slash gate's, never
    -- re-spelled (slash-commands-§7), and the tooltip reads `/pfe enable` out of it.
    isEnabled    = function() return NS.GetSetting("enabled") == true end,
    disabledLine = function() return NS.DisabledLine() end,

    -- THE STATUS TOOLTIP (launcher-§1, Launcher minor 3). The library draws all of it -- title,
    -- Enabled, Locked, the two click hints -- on every hover, disabled or not; these only answer its
    -- questions, each asked on every show and never cached. The states passed are the ones this
    -- addon HAS: enabled, and the lock (the *Lock frame* row, read through the same NS.GetSetting
    -- the row reads; `locked` absent reads as locked, as modules/Preview.lua reads it). There is NO
    -- `isTestMode`: unlocking is this addon's preview and options-ui-§15 exempts it from a Test mode
    -- row, so a `Test mode: Off` line would describe a state it does not have. No `onTooltipShow`
    -- either -- there is nothing of the addon's own to add, and a title or hint of its own would be
    -- a second copy (anti-pattern #89).
    version      = function() return NS.Version() end,          -- the TOC's ## Version
    isLocked     = function() return NS.GetSetting("locked") ~= false end,
    -- Rung (b)'s hint names what the NEXT click does, so it is asked per show, in the words of the
    -- row it drives, through the addon's locale.
    leftClickLabel = function()
        return NS.GetSetting("locked") ~= false and NS.L["Unlock frame"] or NS.L["Lock frame"]
    end,

    -- Call-time forwarders: NS.Print is reclaimed from AceConsole in core/PartyFrameEnhanced.lua,
    -- and NS.Debug is the gated sink core/DebugLogSetup.lua binds.
    print = function(line) NS.Print(line) end,
    debug = function(tag, message) NS.Debug(tag, "%s", message) end,
})
