-- settings/PetFrames.lua — the Pet Frames page:
--
--     [ General ][ Size & Position ][ Bar ][ Border ][ Text ][ Marker ]
--
--     General          [Enable pet frames] (solo)   [Click to target]
--                      (health updates are shared with target frames: General page → Health updates)
--     Size & Position  settings/ElementRows.lua's Size & Position rows
--     Bar              -- Fill --        the canonical bar block (Use class color = the OWNER's class)
--                      -- Background --  the background swatch and its class-color companion
--     Border           the canonical border block
--     Text             -- Font --  the canonical font block, then Show name · Show health percent
--     Marker           Show raid marker (solo) / Anchor point (solo) / X offset · Y offset

local _, NS = ...

local L = NS.L
local ElementRows = NS.ElementRows
local D = NS.defaults.profile.pet

local PAGE, P = "pet", "pet."

local function row(t)
    t.page = PAGE
    t.path = P .. t.path
    return t
end

local function healthOff() return NS.GetSetting("general.updateHealth") ~= true end
local function markerOff() return NS.GetSetting(P .. "showMarker") ~= true end

local rows = {
    row{ path = "enabled", group = L["General"], order = 10, type = "bool", solo = true,
         label = L["Enable pet frames"],
         desc = L["Show each party member's pet, beside their party frame."], default = D.enabled },
    row{ path = "clickToTarget", group = L["General"], order = 20, type = "bool",
         label = L["Click to target"],
         desc = L["Left-click a pet frame to target that pet. Applied out of combat."],
         default = D.clickToTarget },
}

ElementRows.Append(rows, ElementRows.Position(PAGE, P, D))
ElementRows.Append(rows, ElementRows.Bar(PAGE, P, D))
ElementRows.Append(rows, ElementRows.Background(PAGE, P, D, 50))
ElementRows.Append(rows, ElementRows.Border(PAGE, P, D))
ElementRows.Append(rows, ElementRows.Font(PAGE, P, D))
rows[#rows + 1] = row{ path = "showName", group = L["Text"], subgroup = L["Font"], order = 70,
                       type = "bool", label = L["Show name"], desc = L["The unit's name."],
                       default = D.showName }
rows[#rows + 1] = row{ path = "showPercent", group = L["Text"], subgroup = L["Font"], order = 80,
                       type = "bool", label = L["Show health percent"],
                       desc = L["The unit's health as a percentage, at the right end."],
                       default = D.showPercent, disabledIf = healthOff }

rows[#rows + 1] = row{ path = "showMarker", group = L["Marker"], order = 10, type = "bool", solo = true,
                       label = L["Show raid marker"],
                       desc = L["The pet's raid marker, when it has one."], default = D.showMarker }
rows[#rows + 1] = row{ path = "markerPoint", group = L["Marker"], order = 20, type = "string",
                       solo = true, label = L["Anchor point"],
                       desc = L["The point on the bar the marker's center sits on."],
                       default = D.markerPoint, values = ElementRows.POINT_LABELS,
                       sorting = NS.Constants.POINTS, disabledIf = markerOff }
rows[#rows + 1] = row{ path = "markerOffsetX", group = L["Marker"], order = 30, type = "number",
                       label = L["X offset"], desc = L["Horizontal nudge of the marker, in pixels."],
                       default = D.markerOffsetX, min = -100, max = 100, step = 1,
                       disabledIf = markerOff }
rows[#rows + 1] = row{ path = "markerOffsetY", group = L["Marker"], order = 40, type = "number",
                       label = L["Y offset"], desc = L["Vertical nudge of the marker, in pixels."],
                       default = D.markerOffsetY, min = -100, max = 100, step = 1,
                       disabledIf = markerOff }

NS.RegisterSchemaRows(rows)

if NS.RegisterOptionsPage then
    NS.RegisterOptionsPage(PAGE, "Pet Frames", ElementRows.BuildPage(PAGE,
        "PartyFrameEnhancedPetFramesPanel", "Pet Frames",
        L["Restore every Pet Frames setting on this profile to its addon default."]))
end
