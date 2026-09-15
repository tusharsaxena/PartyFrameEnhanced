-- settings/PetFrames.lua — the Pet Frames page:
--
--     [ General ][ Position ][ Bar ][ Border ][ Text ]
--
--     General   [Enable pet frames] (solo)   [Click to target]
--     Position  settings/ElementRows.lua's Position rows
--     Bar       -- Fill --        the canonical bar block (Use class color = the OWNER's class)
--               -- Background --  the background swatch and its class-color companion
--     Border    the canonical border block
--     Text      -- Font --  the canonical font block, then Show name · Show health percent

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
                       default = D.showPercent }

NS.RegisterSchemaRows(rows)

if NS.RegisterOptionsPage then
    NS.RegisterOptionsPage(PAGE, "Pet Frames", ElementRows.BuildPage(PAGE,
        "PartyFrameEnhancedPetFramesPanel", "Pet Frames",
        L["Restore every Pet Frames setting on this profile to its addon default."]))
end
