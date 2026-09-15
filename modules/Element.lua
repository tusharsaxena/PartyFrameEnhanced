local _, NS = ...

-- modules/Element.lua — what the three features' elements have in common: the regions (background,
-- status bar, border, two text lines, optional icon / spark / shield / marker), the config-driven
-- restyle, the unit-colored parts, and the first rungs of every element's show decision.
--
-- Built onto a root the feature creates — a plain Frame for a cast bar, a SecureUnitButtonTemplate
-- button for a target or pet frame — so one set of drawing code serves both.

local C = NS.Constants

local Element = {}
NS.Element = Element

local SPARK_TEXTURE  = "Interface\\CastingBar\\UI-CastingBar-Spark"
local SHIELD_TEXTURE = "Interface\\CastingBar\\UI-CastingBar-Small-Shield"
local MARKER_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"

-- A composer flag value meaning "no outline" is SetFont's empty string.
local FONT_FLAGS = { NONE = "" }

--- Add the shared regions to `root`. opts = { icon, spark, shield, marker }.
function Element.Build(root, opts)
    opts = opts or {}
    local bar = CreateFrame("StatusBar", nil, root)
    root.bar = bar
    root.bg = root:CreateTexture(nil, "BACKGROUND")
    root.text = bar:CreateFontString(nil, "OVERLAY")
    root.text:SetJustifyH("LEFT")
    root.text:SetWordWrap(false)
    root.text2 = bar:CreateFontString(nil, "OVERLAY")
    root.text2:SetJustifyH("RIGHT")
    -- A child of the bar draws above the bar and the icon.
    root.border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    if opts.icon then
        root.icon = root:CreateTexture(nil, "ARTWORK")
        root.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
    if opts.spark then
        root.spark = bar:CreateTexture(nil, "OVERLAY")
        root.spark:SetTexture(SPARK_TEXTURE)
        root.spark:SetBlendMode("ADD")
    end
    if opts.shield then
        root.shield = bar:CreateTexture(nil, "OVERLAY")
        root.shield:SetTexture(SHIELD_TEXTURE)
    end
    if opts.marker then
        root.marker = bar:CreateTexture(nil, "OVERLAY")
        root.marker:SetTexture(MARKER_TEXTURE)
    end
    -- The alpha this element wants; Anchor's combat fade restores to it (modules/Anchor.lua).
    root.__alpha = 1
    return root
end

local function applyIcon(el, h, look)
    if not el.icon then return 0, 0 end
    if not look.showIcon then
        el.icon:Hide()
        return 0, 0
    end
    el.icon:Show()
    el.icon:SetSize(h, h)
    el.icon:ClearAllPoints()
    if look.iconSide == "RIGHT" then
        el.icon:SetPoint("TOPRIGHT", el, "TOPRIGHT", 0, 0)
        return 0, h
    end
    el.icon:SetPoint("TOPLEFT", el, "TOPLEFT", 0, 0)
    return h, 0
end

local function applyBorder(el, cfg)
    local b = el.border
    if not cfg.borderShow then
        b:Hide()
        return
    end
    local size = cfg.borderSize or 1
    local out = math.floor(size / 2 + 0.5)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", el, "TOPLEFT", -out, out)
    b:SetPoint("BOTTOMRIGHT", el, "BOTTOMRIGHT", out, -out)
    b:SetBackdrop({ edgeFile = NS.FetchMedia("border", cfg.borderStyle, C.FALLBACK_BORDER),
                    edgeSize = size })
    b:Show()
end

local function applyFont(fs, font, size, flags, shadow)
    fs:SetFont(font, size, flags)
    if shadow then
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 1)
    else
        fs:SetShadowOffset(0, 0)
    end
end

--- The config-driven restyle: size, bar texture, icon layout, spark and shield placement, border,
--- fonts and master alpha. Runs on a settings or profile change, never on the hot path. `look`
--- carries the feature's icon choice ({ showIcon, iconSide }); nil for a feature without one.
function Element.Reskin(el, cfg, look)
    local scale = NS.GetSetting("scale") or 1
    local w, h = (cfg.width or 100) * scale, (cfg.height or 16) * scale
    el:SetHeight(h)
    -- Attached and matching the party frame's width, the two edge anchors set the width.
    if cfg.anchorMode == "free" or not cfg.matchWidth then el:SetWidth(w) end

    local left, right = applyIcon(el, h, look or {})
    local bar = el.bar
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", el, "TOPLEFT", left, 0)
    bar:SetPoint("BOTTOMRIGHT", el, "BOTTOMRIGHT", -right, 0)
    local texture = NS.FetchMedia("statusbar", cfg.barTexture, C.FALLBACK_TEXTURE)
    bar:SetStatusBarTexture(texture)
    el.bg:ClearAllPoints()
    el.bg:SetAllPoints(bar)
    el.bg:SetTexture(texture)

    -- The spark rides the fill texture's right edge, anchored ONCE: its position is never computed
    -- from the fill, which can be secret (the KickCD lesson).
    if el.spark then
        el.spark:ClearAllPoints()
        el.spark:SetSize(math.max(8, h * 0.6), h * 2)
        el.spark:SetPoint("CENTER", bar:GetStatusBarTexture(), "RIGHT", 0, 0)
    end
    if el.shield then
        el.shield:ClearAllPoints()
        el.shield:SetSize(h * 1.6, h * 1.6)
        el.shield:SetPoint("CENTER", bar, "LEFT", 0, 0)
    end
    if el.marker then
        el.marker:ClearAllPoints()
        el.marker:SetSize(h, h)
        el.marker:SetPoint("CENTER", bar, "LEFT", 0, 0)
    end

    applyBorder(el, cfg)

    local font = NS.FetchMedia("font", cfg.font, C.FALLBACK_FONT)
    local size = (cfg.fontSize or 11) * scale
    local flags = FONT_FLAGS[cfg.fontFlags] or cfg.fontFlags or ""
    applyFont(el.text, font, size, flags, cfg.fontShadow)
    applyFont(el.text2, font, size, flags, cfg.fontShadow)
    el.text2:ClearAllPoints()
    el.text2:SetPoint("RIGHT", bar, "RIGHT", -3, 0)
    el.text:ClearAllPoints()
    el.text:SetPoint("LEFT", bar, "LEFT", 3, 0)
    el.text:SetPoint("RIGHT", el.text2, "LEFT", -2, 0)

    el.__alpha = NS.GetSetting("alpha") or 1
    if not el.__combatFaded then el:SetAlpha(el.__alpha) end
end

--- The colors that can follow a unit's class: background, border and text. `unit` is the one the
--- element describes (options-ui-§17: classColorSource = "unit"); a class the client cannot answer
--- falls through to the stored swatch, inside the resolver.
function Element.ApplyColors(el, cfg, unit)
    el.bg:SetVertexColor(NS.ResolveColor(cfg.bgColor, cfg.useClassColorBg, unit))
    if cfg.borderShow then
        el.border:SetBackdropBorderColor(NS.ResolveColor(cfg.borderColor, cfg.useClassColorBorder, unit))
    end
    local r, g, b, a = NS.ResolveColor(cfg.fontColor, cfg.useClassColorFont, unit)
    el.text:SetTextColor(r, g, b, a)
    el.text2:SetTextColor(r, g, b, a)
end

-- ── the show decision's shared rungs (spec §6.7) ──────────────────────────────────────────────

--- Rungs 0–1: not suspended (performance-§6 — step 0, so nothing re-shows behind suspend's back)
--- and the addon switched on.
function Element.MasterShows()
    if NS.Perf.suspended then return false end
    return NS.GetSetting("enabled") == true
end

--- Rung 4: General visibility against the event-driven combat flag (never InCombatLockdown, which
--- is a secure-write gate, events-frames-taint-§2).
function Element.VisibilityAllows()
    local mode = NS.GetSetting("visibility")
    if mode == "never" then return false end
    if mode == "inCombat" then return NS.State.inCombat == true end
    if mode == "outOfCombat" then return NS.State.inCombat ~= true end
    return true
end
