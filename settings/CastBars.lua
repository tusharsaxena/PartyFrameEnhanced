-- settings/CastBars.lua — the Cast Bars page:
--
--     [ General ][ Size & Position ][ Bar ][ Border ][ Text ][ Icon ]
--
--     General          [Enable cast bars] (solo)            [Fade out]
--     Size & Position  settings/ElementRows.lua's Size & Position rows
--     Bar       -- Fill --        the canonical bar block (the fill is the plain-cast color)
--               -- Cast colors -- Channel · Empowered / Can't be interrupted · Interrupted
--               -- Background --  the background swatch and its class-color companion
--     Border    the canonical border block
--     Text      -- Font --        the canonical font block, then Show spell name · Show time left
--     Icon      Show spell icon · Icon side / Show shield · Show spark
--
-- The cast-state colors are a PALETTE — one color per cast state — so they carry no class-color
-- companion (options-ui-§17's one exemption).

local _, NS = ...

local L = NS.L
local ElementRows = NS.ElementRows
local D = NS.defaults.profile.castbar

local PAGE, P = "castbar", "castbar."

local function row(t)
    t.page = PAGE
    t.path = P .. t.path
    return t
end

local rows = {
    row{ path = "enabled", group = L["General"], order = 10, type = "bool", solo = true,
         label = L["Enable cast bars"],
         desc = L["Show a cast bar for each party member (and for you, when your own row is included)."],
         default = D.enabled },
    row{ path = "fadeOut", group = L["General"], order = 20, type = "bool",
         label = L["Fade out"], desc = L["Fade a finished cast out instead of hiding it at once."],
         default = D.fadeOut },
}

ElementRows.Append(rows, ElementRows.Position(PAGE, P, D))

ElementRows.Append(rows, ElementRows.Bar(PAGE, P, D, { barColor = L["Cast color"] }))
for i, spec in ipairs({
    { "channelColor", L["Channel color"], L["Fill color while channeling."] },
    { "empowerColor", L["Empowered color"], L["Fill color while charging an empowered spell."] },
    { "uninterruptibleColor", L["Can't be interrupted color"],
      L["Fill color for a cast that cannot be interrupted."] },
    { "failedColor", L["Interrupted color"], L["Fill color while an interrupted or failed cast is held."] },
}) do
    rows[#rows + 1] = row{ path = spec[1], group = L["Bar"], subgroup = L["Cast colors"],
                           order = 40 + i * 10, type = "color", hasAlpha = true,
                           label = spec[2], desc = spec[3], default = D[spec[1]] }
end
ElementRows.Append(rows, ElementRows.Background(PAGE, P, D, 100))

ElementRows.Append(rows, ElementRows.Border(PAGE, P, D))

ElementRows.Append(rows, ElementRows.Font(PAGE, P, D))
rows[#rows + 1] = row{ path = "showName", group = L["Text"], subgroup = L["Font"], order = 70,
                       type = "bool", label = L["Show spell name"],
                       desc = L["The spell's name on the bar."], default = D.showName }
rows[#rows + 1] = row{ path = "showTime", group = L["Text"], subgroup = L["Font"], order = 80,
                       type = "bool", label = L["Show time left"],
                       desc = L["Seconds left on the cast, at the bar's right end."], default = D.showTime }

for i, spec in ipairs({
    { "showIcon", "bool", L["Show spell icon"], L["The spell's icon at one end of the bar."] },
    { "iconSide", "string", L["Icon side"], L["Which end of the bar the icon sits at."],
      { LEFT = L["Left"], RIGHT = L["Right"] }, { "LEFT", "RIGHT" } },
    { "showShield", "bool", L["Show shield"], L["A small shield on a cast that cannot be interrupted."] },
    { "showSpark", "bool", L["Show spark"], L["A bright edge riding the fill."] },
}) do
    rows[#rows + 1] = row{ path = spec[1], group = L["Icon"], order = i * 10, type = spec[2],
                           label = spec[3], desc = spec[4], default = D[spec[1]],
                           values = spec[5], sorting = spec[6] }
end

NS.RegisterSchemaRows(rows)

if NS.RegisterOptionsPage then
    NS.RegisterOptionsPage(PAGE, "Cast Bars", ElementRows.BuildPage(PAGE,
        "PartyFrameEnhancedCastBarsPanel", "Cast Bars",
        L["Restore every Cast Bars setting on this profile to its addon default."]))
end
