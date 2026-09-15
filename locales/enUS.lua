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

-- Reset confirmation (options-ui-§12, verbatim)
L["Reset this profile to the addon's defaults? Everything you have configured or added in it is discarded \226\128\148 your other profiles are not affected."] =
    "Reset this profile to the addon's defaults? Everything you have configured or added in it is discarded \226\128\148 your other profiles are not affected."
L["Yes"] = "Yes"
L["No"] = "No"
L["Restore every General setting on this profile to its addon default."] =
    "Restore every General setting on this profile to its addon default."
