-- settings/ElementRows.lua — the row sets the three feature pages share: the Position tab, and thin
-- wrappers over the library's border and font composers so every page declares them the same way.
-- Loads after settings/OptionsSetup.lua (the composers live on NS.Helpers) and before the pages.

local _, NS = ...

local L = NS.L
local H = NS.Helpers
local C = NS.Constants

local ElementRows = {}
NS.ElementRows = ElementRows

local POINT_LABELS = {
    TOPLEFT = L["Top left"], TOP = L["Top"], TOPRIGHT = L["Top right"],
    LEFT = L["Left"], CENTER = L["Center"], RIGHT = L["Right"],
    BOTTOMLEFT = L["Bottom left"], BOTTOM = L["Bottom"], BOTTOMRIGHT = L["Bottom right"],
}

local ANCHOR_MODES = { attached = L["Attach to party frames"], free = L["Free placement"] }
local GROWTH = { DOWN = L["Down"], UP = L["Up"], RIGHT = L["Right"], LEFT = L["Left"] }

-- The composed blocks describe one unit's element each, so every class-color companion resolves to
-- the TRACKED unit's class (options-ui-§17).
local UNIT_CLASS = { source = "unit" }
ElementRows.UNIT_CLASS = UNIT_CLASS

--- The Position tab: the anchor mode, the attached pin, the free stack, and the size.
function ElementRows.Position(page, prefix, D)
    local group = L["Position"]
    local function row(t)
        t.page, t.group = page, group
        t.path = prefix .. t.path
        return t
    end
    return {
        row{ path = "anchorMode", subgroup = L["Placement"], order = 10, type = "string",
             label = L["Anchor mode"],
             desc = L["Attach each element to its party member's frame, or keep all five in one stack you place yourself."],
             default = D.anchorMode, values = ANCHOR_MODES, sorting = { "attached", "free" } },
        row{ path = "matchWidth", subgroup = L["Placement"], order = 20, type = "bool",
             label = L["Match party frame width"],
             desc = L["Attached: stretch each element across its party frame, edge to edge. Its Width setting is then ignored."],
             default = D.matchWidth },
        row{ path = "point", subgroup = L["Attached to party frames"], order = 30, type = "string",
             label = L["Anchor point"], desc = L["The point on the element that is pinned."],
             default = D.point, values = POINT_LABELS, sorting = C.POINTS },
        row{ path = "relativePoint", subgroup = L["Attached to party frames"], order = 40, type = "string",
             label = L["Party frame point"], desc = L["The point on the party frame it is pinned to."],
             default = D.relativePoint, values = POINT_LABELS, sorting = C.POINTS },
        row{ path = "offsetX", subgroup = L["Attached to party frames"], order = 50, type = "number",
             label = L["X offset"], desc = L["Horizontal nudge from the pin, in pixels."],
             default = D.offsetX, min = -200, max = 200, step = 1 },
        row{ path = "offsetY", subgroup = L["Attached to party frames"], order = 60, type = "number",
             label = L["Y offset"], desc = L["Vertical nudge from the pin, in pixels."],
             default = D.offsetY, min = -200, max = 200, step = 1 },
        row{ path = "growth", subgroup = L["Free placement"], order = 70, type = "string",
             label = L["Growth direction"], desc = L["Which way the stack grows from its first element."],
             default = D.growth, values = GROWTH, sorting = { "DOWN", "UP", "RIGHT", "LEFT" } },
        row{ path = "spacing", subgroup = L["Free placement"], order = 80, type = "number",
             label = L["Spacing"], desc = L["Gap between elements in the stack, in pixels."],
             default = D.spacing, min = 0, max = 40, step = 1 },
        row{ path = "width", subgroup = L["Size"], order = 90, type = "number",
             label = L["Width"], desc = L["Element width in pixels, before Master scale."],
             default = D.width, min = 40, max = 400, step = 1 },
        row{ path = "height", subgroup = L["Size"], order = 100, type = "number",
             label = L["Height"], desc = L["Element height in pixels, before Master scale."],
             default = D.height, min = 8, max = 60, step = 1 },
    }
end

--- The canonical border block (options-ui-§16), with its Show border toggle.
function ElementRows.Border(page, prefix, D)
    return H.BorderGroup({
        prefix = prefix, page = page, group = L["Border"], order = 10, show = true,
        classColor = UNIT_CLASS,
        defaults = {
            borderShow = D.borderShow, borderStyle = D.borderStyle, borderSize = D.borderSize,
            borderColor = D.borderColor, useClassColorBorder = D.useClassColorBorder,
        },
    })
end

--- The canonical font block (options-ui-§16) opening the Text tab.
function ElementRows.Font(page, prefix, D)
    return H.FontGroup({
        prefix = prefix, page = page, group = L["Text"], subgroup = L["Font"], order = 10,
        classColor = UNIT_CLASS,
        defaults = {
            font = D.font, fontSize = D.fontSize, fontColor = D.fontColor,
            useClassColorFont = D.useClassColorFont, fontFlags = D.fontFlags,
            fontShadow = D.fontShadow,
        },
    })
end

--- The canonical bar block (options-ui-§16) under a Fill subgroup of the Bar tab.
function ElementRows.Bar(page, prefix, D, labels)
    return H.BarGroup({
        prefix = prefix, page = page, group = L["Bar"], subgroup = L["Fill"], order = 10,
        classColor = UNIT_CLASS, labels = labels,
        defaults = {
            barTexture = D.barTexture, barAlpha = D.barAlpha, barColor = D.barColor,
            useClassColorBar = D.useClassColorBar,
        },
    })
end

--- The background swatch and its class-color companion — a background is not a bar group.
function ElementRows.Background(page, prefix, D, order)
    return H.ColorPair({
        prefix = prefix, page = page, group = L["Bar"], subgroup = L["Background"], order = order,
        key = "bgColor", companionKey = "useClassColorBg", label = L["Background color"],
        classColor = UNIT_CLASS,
        defaults = { bgColor = D.bgColor, useClassColorBg = D.useClassColorBg },
    })
end

--- Append every row of `block` to `rows`.
function ElementRows.Append(rows, block)
    for _, r in ipairs(block) do rows[#rows + 1] = r end
    return rows
end

--- A feature page's builder: a tabbed page over `page`'s rows, with a page-scoped Defaults button.
function ElementRows.BuildPage(page, frameName, title, defaultsTooltip)
    return function(mainCategory)
        if not (Settings and Settings.RegisterCanvasLayoutSubcategory) then return nil end
        local ctx = H.CreatePanel(frameName, title, {
            pageKey = page, defaultsButton = true, defaultsTooltip = defaultsTooltip,
        })
        ctx.panel.defaultsOnClick = function() H.RestoreDefaults(page, ctx) end
        H.SetRenderer(ctx, function(c)
            H.ClearScroll(c)
            H.RenderTabbedSchema(c, page)
        end)
        return Settings.RegisterCanvasLayoutSubcategory(mainCategory, ctx.panel, title)
    end
end
