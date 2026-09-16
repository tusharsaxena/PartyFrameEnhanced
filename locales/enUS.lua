-- locales/enUS.lua — the canonical locale (localization-§1).
--
-- A metatable fallback returns the key itself, so an unlisted English string still renders and a
-- missing key never errors. Keys are the English source strings; the right-hand side is identical
-- until a translation file (deDE.lua, …) copies this one, gates on GetLocale() and changes it.
--
-- Every label and tooltip this addon authors has its key here. Labels the library's composers emit
-- (Master controls, font/border/bar groups) are the library's own strings and are not listed.
local _, NS = ...

local L = setmetatable(NS.L or {}, { __index = function(_, k) return k end })
NS.L = L

-- General page
L["Party frames"] = "Party frames"
L["Frame system"] = "Frame system"
L["Which party frames the elements attach to. Automatic uses EllesmereUI's party frames when they are shown and Blizzard's otherwise."] =
    "Which party frames the elements attach to. Automatic uses EllesmereUI's party frames when they are shown and Blizzard's otherwise."
L["Automatic"] = "Automatic"
L["Blizzard"] = "Blizzard"
L["EllesmereUI"] = "EllesmereUI"
L["Include my own row"] = "Include my own row"
L["Show a cast bar, target frame and pet frame for yourself too, wherever your party frames show you (and always in free placement)."] =
    "Show a cast bar, target frame and pet frame for yourself too, wherever your party frames show you (and always in free placement)."

-- Shared element rows (settings/ElementRows.lua)
for _, key in ipairs({
    "General", "Position", "Placement", "Attached to party frames", "Free placement", "Size",
    "Border", "Text", "Font", "Bar", "Fill", "Background", "Background color", "Icon",
    "Top left", "Top", "Top right", "Left", "Center", "Right", "Bottom left", "Bottom", "Bottom right",
    "Attach to party frames", "Down", "Up",
    "Anchor mode", "Attach each element to its party member's frame, or keep all five in one stack you place yourself.",
    "Match party frame width", "Attached: stretch each element across its party frame, edge to edge. Its Width setting is then ignored.",
    "Anchor point", "The point on the element that is pinned.",
    "Party frame point", "The point on the party frame it is pinned to.",
    "X offset", "Horizontal nudge from the pin, in pixels.",
    "Y offset", "Vertical nudge from the pin, in pixels.",
    "Growth direction", "Which way the stack grows from its first element.",
    "Spacing", "Gap between elements in the stack, in pixels.",
    "Width", "Element width in pixels, before Master scale.",
    "Height", "Element height in pixels, before Master scale.",
}) do L[key] = key end

-- Cast bars (settings/CastBars.lua, modules/CastBars.lua)
for _, key in ipairs({
    "Enable cast bars", "Show a cast bar for each party member (and for you, when your own row is included).",
    "Fade out", "Fade a finished cast out instead of hiding it at once.",
    "Cast color", "Cast colors",
    "Channel color", "Fill color while channeling.",
    "Empowered color", "Fill color while charging an empowered spell.",
    "Can't be interrupted color", "Fill color for a cast that cannot be interrupted.",
    "Interrupted color", "Fill color while an interrupted or failed cast is held.",
    "Show spell name", "The spell's name on the bar.",
    "Show time left", "Seconds left on the cast, at the bar's right end.",
    "Show spell icon", "The spell's icon at one end of the bar.",
    "Icon side", "Which end of the bar the icon sits at.",
    "Show shield", "A small shield on a cast that cannot be interrupted.",
    "Show spark", "A bright edge riding the fill.",
    "Restore every Cast Bars setting on this profile to its addon default.",
    -- Fallbacks for the client's own localized INTERRUPTED / FAILED globals.
    "Interrupted", "Failed",
    "Preview cast",
}) do L[key] = key end

-- Target and pet frames (settings/TargetFrames.lua, settings/PetFrames.lua, the modules)
for _, key in ipairs({
    "Enable target frames", "Show what each party member is targeting, beside their party frame.",
    "Click to target", "Left-click a target frame to target that unit yourself. Applied out of combat.",
    "Health refresh (seconds)",
    "Reaction colors", "Color NPCs by reaction",
    "Color a non-player target by how it feels about you. When the game hides that, the hostile color is used.",
    "Hostile color", "Bar color for a hostile NPC.",
    "Neutral color", "Bar color for a neutral NPC.",
    "Friendly color", "Bar color for a friendly NPC.",
    "Show name", "The unit's name.",
    "Show health percent", "The unit's health as a percentage, at the right end.",
    "Marker", "Show raid marker", "The target's raid marker, when it has one.",
    "Restore every Target Frames setting on this profile to its addon default.",
    "Enable pet frames", "Show each party member's pet, beside their party frame.",
    "Left-click a pet frame to target that pet. Applied out of combat.",
    "Restore every Pet Frames setting on this profile to its addon default.",
    "Preview target", "Preview pet",
}) do L[key] = key end

-- Preview mode and the holders' labels (modules/Preview.lua, modules/Anchor.lua)
for _, key in ipairs({
    "cannot unlock during combat \226\128\148 the clickable frames cannot move until it ends",
    "Cast bars", "Target frames", "Pet frames",
}) do L[key] = key end

-- Preview and its stand-in party frame (modules/Preview.lua, modules/StandIn.lua). The lock is the
-- only switch (options-ui-§15), so every string here is worded around locking and unlocking.
for _, key in ipairs({
    "(test)",
    "cannot unlock \226\128\148 the addon is disabled",
    "cannot unlock \226\128\148 a perf run has the addon suspended",
    "Locked \226\128\148 combat started",
    "Locked \226\128\148 the addon was disabled",
    "Locked \226\128\148 a perf run suspended the addon",
    "unlocked (stand-in)", "unlocked (your party frames)",
}) do L[key] = key end

-- Size & Position tab, health updates and marker placement (settings/ElementRows.lua, the Target and
-- Pet pages)
for _, key in ipairs({
    "Size & Position", "Update health", "Health updates",
    "Track health on target and pet frames. Off: their bars stay full with no percent, and no health updates run.",
    "How often a shown target frame's health updates. Lower is smoother and costs more. Pet frames update on the game's own health events.",
    "The point on the bar the marker's center sits on.",
    "Horizontal nudge of the marker, in pixels.", "Vertical nudge of the marker, in pixels.",
}) do L[key] = key end

-- Slash surface, chat replies and unit labels (settings/Slash.lua, settings/About.lua, core/Units.lua)
for _, key in ipairs({
    "List available commands", "Open the settings panel", "List every setting and its current value",
    "Turn the addon on", "Turn the addon off without unloading it",
    "Print a setting's current value \226\128\148 `/pfe get <path>`",
    "Set a setting \226\128\148 `/pfe set <path> <value>` (try /pfe list)",
    "Reset one setting to its default \226\128\148 `/pfe reset <path>`",
    "Reset every setting to defaults",
    "Move every free-placement stack back to its default position",
    "Lock the elements in place and leave preview mode",
    "Unlock the elements to drag them, with placeholder content",
    "Show which party frames were found and what each feature is doing",
    "Toggle the debug console \226\128\148 `on`/`off` enable/disable logging",
    "Measure performance \226\128\148 try `/pfe perf` for the workflow",
    "Print the addon version",
    "Profile management \226\128\148 try `/pfe profile` for the list",
    "Positions reset",
    "All settings reset to defaults", "All settings reset to defaults.",
    "Cannot reset settings \226\128\148 the settings helpers failed to load",
    "Cannot reset settings \226\128\148 the settings helpers failed to load.",
    "Elements locked", "Elements unlocked \226\128\148 drag them into place",
    "off", "on, free placement", "on, attached", "addon disabled", "visibility %s", "unlocked",
    "suspended by a perf run", "Frame system: %s",
    "not in a party \226\128\148 nothing shows until you join one (try /pfe unlock)", "none found", "frame", "Note: %s",
    "List all profiles", "Show current profile name", "Switch to profile",
    "Create new profile with defaults", "Copy settings from another profile", "Delete a profile",
    "Reset current profile to defaults", "Profile commands", "Usage: /pfe profile %s <name>",
    "Available profiles", "(current)", "Current profile: %s", "Switched to profile '%s'",
    "Created and switched to new profile '%s'", "Copied settings from profile '%s'",
    "Cannot delete the current profile", "Deleted profile '%s'", "Profile reset to defaults",
    "Profile system requires AceDB-3.0", "Unknown profile subcommand '%s'",
    "is unavailable.", "v%s \226\128\148 slash commands", "unknown command '%s'",
    "Slash Commands",
    "Player", "Party 1", "Party 2", "Party 3", "Party 4",
}) do L[key] = key end

-- Reset confirmation (options-ui-§12, verbatim)
L["Reset this profile to the addon's defaults? Everything you have configured or added in it is discarded \226\128\148 your other profiles are not affected."] =
    "Reset this profile to the addon's defaults? Everything you have configured or added in it is discarded \226\128\148 your other profiles are not affected."
L["Yes"] = "Yes"
L["No"] = "No"
L["Restore every General setting on this profile to its addon default."] =
    "Restore every General setting on this profile to its addon default."
