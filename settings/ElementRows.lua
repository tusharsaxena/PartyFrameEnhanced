local _, NS = ...

-- settings/ElementRows.lua — the row sets the three feature pages share: the Size and position tab, and
-- thin wrappers over the library's bar, border and font composers so every page declares them the same
-- way. The Bar tab holds Fill, the page's palette (Cast Bars and Target Frames), Background, then Border.
-- The three composers take `fromSkin = true` (skinning-§6): each adds its "Use the skin's texture /
-- border / font" companion after its rows, defaulting to the profile's true (X3), and disables the
-- picker it governs while it is on. modules/Element.lua draws through S.Resolve. The fill, background,
-- border and text colors and the Font shadow have no composer row, so each block carries its own
-- "Use the skin's color" or "Use the skin's shadow" as an extra (LibKa0s Options doc, Moving to,
-- section 3); no swatch beside one is dimmed (options-ui-§17).
-- Loads after settings/OptionsSetup.lua (the composers live on NS.Helpers) and before the pages.

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

ElementRows.POINT_LABELS = POINT_LABELS

--- The Size and position tab: the size first, then the anchor mode, the attached pin and the free
--- stack. Only the placement block the current anchor mode uses is DRAWN (`shownWhen`, LibKa0s
--- v1.45.0): the other block's rows stay in the schema, stored, and `/pfe set` still reaches them.
--- The library watches Anchor mode and redraws the tab once, on the next frame, when it changes.
--- Match party frame width sits in the selector's own Placement block, so it is dimmed rather than
--- hidden in free placement, and Width is dimmed while Match party frame width sets it.
function ElementRows.Position(page, prefix, D)
    local group = L["Size and position"]
    local modePath, matchPath = prefix .. "anchorMode", prefix .. "matchWidth"
    local ATTACHED_ONLY = { path = modePath, equals = "attached" }
    local FREE_ONLY = { path = modePath, equals = "free" }
    local function free() return NS.GetSetting(modePath) == "free" end
    local function attached() return not free() end
    local function widthFromFrame() return attached() and NS.GetSetting(matchPath) == true end
    local function row(t)
        t.page, t.group = page, group
        t.path = prefix .. t.path
        return t
    end
    return {
        row{ path = "width", subgroup = L["Size"], order = 10, type = "number",
             label = L["Width"],
             desc = L["Element width in pixels, before Master scale. Dimmed while attached with Match party frame width on."],
             default = D.width, min = 40, max = 400, step = 1, disabledIf = widthFromFrame },
        row{ path = "height", subgroup = L["Size"], order = 20, type = "number",
             label = L["Height"], desc = L["Element height in pixels, before Master scale."],
             default = D.height, min = 8, max = 60, step = 1 },
        row{ path = "anchorMode", subgroup = L["Placement"], order = 30, type = "string",
             label = L["Anchor mode"],
             desc = L["Attach each element to its party member's frame, or keep all five in one stack you place yourself."],
             default = D.anchorMode, values = ANCHOR_MODES, sorting = { "attached", "free" } },
        row{ path = "matchWidth", subgroup = L["Placement"], order = 40, type = "bool",
             label = L["Match party frame width"],
             desc = L["Attached only (dimmed in free placement): stretch each element across its party frame, edge to edge. Width is then ignored."],
             default = D.matchWidth, disabledIf = free },
        row{ path = "point", subgroup = L["Attached to party frames"], order = 50, type = "string",
             label = L["Anchor point"], desc = L["The point on the element that is pinned."],
             default = D.point, values = POINT_LABELS, sorting = C.POINTS, shownWhen = ATTACHED_ONLY },
        row{ path = "relativePoint", subgroup = L["Attached to party frames"], order = 60, type = "string",
             label = L["Party frame point"], desc = L["The point on the party frame it is pinned to."],
             default = D.relativePoint, values = POINT_LABELS, sorting = C.POINTS, shownWhen = ATTACHED_ONLY },
        row{ path = "offsetX", subgroup = L["Attached to party frames"], order = 70, type = "number",
             label = L["X offset"], desc = L["Horizontal nudge from the pin, in pixels."],
             default = D.offsetX, min = -200, max = 200, step = 1, shownWhen = ATTACHED_ONLY },
        row{ path = "offsetY", subgroup = L["Attached to party frames"], order = 80, type = "number",
             label = L["Y offset"], desc = L["Vertical nudge from the pin, in pixels."],
             default = D.offsetY, min = -200, max = 200, step = 1, shownWhen = ATTACHED_ONLY },
        row{ path = "growth", subgroup = L["Free placement"], order = 90, type = "string",
             label = L["Growth direction"], desc = L["Which way the stack grows from its first element."],
             default = D.growth, values = GROWTH, sorting = { "DOWN", "UP", "RIGHT", "LEFT" },
             shownWhen = FREE_ONLY },
        row{ path = "spacing", subgroup = L["Free placement"], order = 100, type = "number",
             label = L["Spacing"], desc = L["Gap between elements in the stack, in pixels."],
             default = D.spacing, min = 0, max = 40, step = 1, shownWhen = FREE_ONLY },
    }
end

--- A companion of a color or of the shadow, for a block's `extra`. Its tooltip is `desc`, which names
--- the row it governs and says that row is not read while this is on. The composer places it.
local function fromSkinRow(path, label, desc)
    return { path = path, type = "bool", label = label, desc = desc, default = true }
end

--- The canonical border block (options-ui-§16), with its Show border toggle: the last subsection of
--- the Bar tab, at order 140, after Background (110 to 130 on Cast Bars and Target Frames, 60 to 80
--- on Pet). `fromSkin = "bar"` puts the thickness on the skin with the style.
function ElementRows.Border(page, prefix, D)
    return H.BorderGroup({
        prefix = prefix, page = page, group = L["Bar"], subgroup = L["Border"], order = 140, show = true,
        classColor = UNIT_CLASS, fromSkin = "bar",
        extra = { fromSkinRow(prefix .. "borderColorFromSkin", L["Use the skin's color"],
            L["Draw the border in the skin's color. Border color is not read while this is on."]) },
        defaults = {
            borderShow = D.borderShow, borderStyle = D.borderStyle, borderStyleFromSkin = D.borderStyleFromSkin,
            borderSize = D.borderSize,
            borderColor = D.borderColor, useClassColorBorder = D.useClassColorBorder,
        },
    })
end

--- The canonical font block (options-ui-§16) on the Text tab, after the page's Shown text toggles
--- (orders 10 and 20): what text is drawn comes before how it looks.
function ElementRows.Font(page, prefix, D)
    return H.FontGroup({
        prefix = prefix, page = page, group = L["Text"], subgroup = L["Font"], order = 30,
        -- flagsFromSkin (OptionsCompose minor 14, ruling D-07): Font flags lead with From skin,
        -- the default, drawn through S.FontFlags (modules/Element.lua's Element.FontStyle).
        classColor = UNIT_CLASS, fromSkin = true, flagsFromSkin = true,
        extra = {
            fromSkinRow(prefix .. "fontColorFromSkin", L["Use the skin's color"],
                L["Draw the text in the skin's color. Font color is not read while this is on."]),
            fromSkinRow(prefix .. "fontShadowFromSkin", L["Use the skin's shadow"],
                L["Draw the skin's text shadow. Font shadow is not read while this is on."]),
        },
        defaults = {
            fontFromSkin = D.fontFromSkin, fontSize = D.fontSize, fontColor = D.fontColor,
            useClassColorFont = D.useClassColorFont, fontFlags = D.fontFlags,
            fontShadow = D.fontShadow,
        },
    })
end

--- The canonical bar block (options-ui-§16) under a Fill subgroup of the Bar tab. `extra` (optional)
--- is the page's own fill rows, appended after the block by the composer (Cast Bars' Show spark).
--- From order 0: with its two skin companions the block is six rows (0-50), so Show spark (60) still
--- closes it before the page's own rows from 60/70.
function ElementRows.Bar(page, prefix, D, labels, extra)
    local rows = { fromSkinRow(prefix .. "barColorFromSkin", L["Use the skin's color"],
        L["Draw the fill in the skin's color. The bar color is not read while this is on."]) }
    for _, row in ipairs(extra or {}) do rows[#rows + 1] = row end
    return H.BarGroup({
        prefix = prefix, page = page, group = L["Bar"], subgroup = L["Fill"], order = 0,
        classColor = UNIT_CLASS, labels = labels, extra = rows, fromSkin = true,
        defaults = {
            barTextureFromSkin = D.barTextureFromSkin, barAlpha = D.barAlpha, barColor = D.barColor,
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
        extra = { fromSkinRow(prefix .. "bgColorFromSkin", L["Use the skin's color"],
            L["Draw the background in the skin's color. Background color is not read while this is on."]) },
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
