local _, NS = ...

-- settings/TargetFrames.lua — the Target Frames page:
--
--     [ General ][ Size & Position ][ Bar ][ Border ][ Text ][ Marker ]
--
--     General          [Enable target frames] (solo)   [Click to target]
--                      (health updates are shared with pet frames: General page → Health updates)
--     Size & Position  settings/ElementRows.lua's Size & Position rows
--     Bar              -- Fill --             the canonical bar block
--                      -- Reaction colors --  Color NPCs by reaction · Hostile / Neutral · Friendly
--                      -- Background --       the background swatch and its class-color companion
--     Border           the canonical border block
--     Text             -- Font --  the canonical font block, then Show name · Show health percent
--     Marker           Show raid marker (solo) / Anchor point (solo) / X offset · Y offset
--
-- The reaction colors are a palette (one color per reaction), so they carry no class-color companion
-- (options-ui-§17's exemption).

local L = NS.L
local ElementRows = NS.ElementRows
local D = NS.defaults.profile.target

local PAGE, P = "target", "target."

local function row(t)
    t.page = PAGE
    t.path = P .. t.path
    return t
end

local function healthOff() return NS.GetSetting("general.updateHealth") ~= true end
local function markerOff() return NS.GetSetting(P .. "showMarker") ~= true end

local rows = {
    row{ path = "enabled", group = L["General"], order = 10, type = "bool", solo = true,
         label = L["Enable target frames"],
         desc = L["Show what each party member is targeting, beside their party frame."],
         default = D.enabled },
    row{ path = "clickToTarget", group = L["General"], order = 20, type = "bool",
         label = L["Click to target"],
         desc = L["Left-click a target frame to target that unit yourself. Applied out of combat."],
         default = D.clickToTarget },
}

ElementRows.Append(rows, ElementRows.Position(PAGE, P, D))

ElementRows.Append(rows, ElementRows.Bar(PAGE, P, D))
rows[#rows + 1] = row{ path = "colorReaction", group = L["Bar"], subgroup = L["Reaction colors"],
                       order = 50, type = "bool", label = L["Color NPCs by reaction"],
                       desc = L["Color a non-player target by how it feels about you. When the game hides that, the hostile color is used."],
                       default = D.colorReaction }
for i, spec in ipairs({
    { "hostileColor", L["Hostile color"], L["Bar color for a hostile NPC."] },
    { "neutralColor", L["Neutral color"], L["Bar color for a neutral NPC."] },
    { "friendlyColor", L["Friendly color"], L["Bar color for a friendly NPC."] },
}) do
    rows[#rows + 1] = row{ path = spec[1], group = L["Bar"], subgroup = L["Reaction colors"],
                           order = 50 + i * 10, type = "color", hasAlpha = true,
                           label = spec[2], desc = spec[3], default = D[spec[1]] }
end
ElementRows.Append(rows, ElementRows.Background(PAGE, P, D, 100))

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
                       desc = L["The target's raid marker, when it has one."], default = D.showMarker }
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
    NS.RegisterOptionsPage(PAGE, "Target Frames", ElementRows.BuildPage(PAGE,
        "PartyFrameEnhancedTargetFramesPanel", "Target Frames",
        L["Restore every Target Frames setting on this profile to its addon default."]))
end
