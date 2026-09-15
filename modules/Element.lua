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
-- Blizzard's own cast-bar shield rather than LibKa0s's `shield` icon, deliberately: a party cast bar
-- is read against the default UI's cast bars, and the shield means "cannot be interrupted" there.
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

-- ── the restyle's parts ───────────────────────────────────────────────────────────────────────

-- The icon square at one end, or none. Answers how far the bar is inset on each side.
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

-- The status bar between the insets, and the background behind it in the same texture.
local function applyBar(el, cfg, left, right)
    local bar = el.bar
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", el, "TOPLEFT", left, 0)
    bar:SetPoint("BOTTOMRIGHT", el, "BOTTOMRIGHT", -right, 0)
    local texture = NS.FetchMedia("statusbar", cfg.barTexture, C.FALLBACK_TEXTURE)
    bar:SetStatusBarTexture(texture)
    el.bg:ClearAllPoints()
    el.bg:SetAllPoints(bar)
    el.bg:SetTexture(texture)
end

-- The spark, the shield and the raid marker, each anchored ONCE. The spark rides the fill texture's
-- right edge and is never positioned from the fill, which can be secret (the KickCD lesson).
local function applyMarks(el, h)
    local bar = el.bar
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

-- Both text lines in the configured face: the name on the left, clipped by the right-hand one.
local function applyFonts(el, cfg, scale)
    local font = NS.FetchMedia("font", cfg.font, C.FALLBACK_FONT)
    local size = (cfg.fontSize or 11) * scale
    local flags = FONT_FLAGS[cfg.fontFlags] or cfg.fontFlags or ""
    applyFont(el.text, font, size, flags, cfg.fontShadow)
    applyFont(el.text2, font, size, flags, cfg.fontShadow)
    el.text2:ClearAllPoints()
    el.text2:SetPoint("RIGHT", el.bar, "RIGHT", -3, 0)
    el.text:ClearAllPoints()
    el.text:SetPoint("LEFT", el.bar, "LEFT", 3, 0)
    el.text:SetPoint("RIGHT", el.text2, "LEFT", -2, 0)
end

-- Every config field the structural half reads, in one string. A color picker commits every 50 ms,
-- and before this memo each commit re-laid-out every region of every element — 40 SetPoint calls
-- and a fresh backdrop table per commit on the cast bars alone (tests/perf.lua's settingsDrag; the
-- same finding KickCD recorded as F-015). IF YOU ADD A CONFIG READ TO THE STRUCTURAL HALF, ADD THE
-- FIELD HERE, or the new setting silently does nothing until some other structural field moves.
local function structureSignature(cfg, look, scale)
    return ("%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s"):format(
        tostring(scale), tostring(cfg.width), tostring(cfg.height), tostring(cfg.anchorMode),
        tostring(cfg.matchWidth), tostring(look.showIcon), tostring(look.iconSide),
        tostring(cfg.barTexture), tostring(cfg.borderShow), tostring(cfg.borderStyle),
        tostring(cfg.borderSize), tostring(cfg.font), tostring(cfg.fontSize),
        tostring(cfg.fontFlags), tostring(cfg.fontShadow))
end

local function applyMasterAlpha(el)
    el.__alpha = NS.GetSetting("alpha") or 1
    if not el.__combatFaded then el:SetAlpha(el.__alpha) end
end

--- The config-driven restyle: size, bar texture, icon layout, spark and shield placement, border,
--- fonts and master alpha. Runs on a settings or profile change, never on the hot path. `look`
--- carries the feature's icon choice ({ showIcon, iconSide }); nil for a feature without one.
--- The structural half is skipped when nothing it reads has changed; `force` re-runs it anyway.
--- Returns true when the structural half ran.
function Element.Reskin(el, cfg, look, force)
    local scale = NS.GetSetting("scale") or 1
    look = look or {}
    local sig = structureSignature(cfg, look, scale)
    if force or el.__structure ~= sig then
        el.__structure = sig
        local h = (cfg.height or 16) * scale
        el:SetHeight(h)
        -- Attached and matching the party frame's width, the two edge anchors set the width.
        if cfg.anchorMode == "free" or not cfg.matchWidth then el:SetWidth((cfg.width or 100) * scale) end
        applyBar(el, cfg, applyIcon(el, h, look))
        applyMarks(el, h)
        applyBorder(el, cfg)
        applyFonts(el, cfg, scale)
        applyMasterAlpha(el)
        return true
    end
    applyMasterAlpha(el)
    return false
end

--- The colors that can follow a unit's class: background, border and text. `resolve(stored, on)`
--- answers r, g, b, a for one swatch and its "Use class color" companion, for the unit the element
--- describes (options-ui-§17: classColorSource = "unit"); an unresolvable class falls through to the
--- stored swatch. Passed in rather than chosen here, because a target frame's unit can have a secret
--- class that must never reach a table lookup (Element.ClassResolver).
function Element.ApplyColors(el, cfg, resolve)
    el.bg:SetVertexColor(resolve(cfg.bgColor, cfg.useClassColorBg))
    if cfg.borderShow then
        el.border:SetBackdropBorderColor(resolve(cfg.borderColor, cfg.useClassColorBorder))
    end
    local r, g, b, a = resolve(cfg.fontColor, cfg.useClassColorFont)
    el.text:SetTextColor(r, g, b, a)
    el.text2:SetTextColor(r, g, b, a)
end

--- The stored swatch's channels.
function Element.Stored(stored)
    if type(stored) ~= "table" then return 1, 1, 1, 1 end
    return stored.r or 1, stored.g or 1, stored.b or 1, stored.a or 1
end

-- One resolver per class token, built once: a target frame repaints its colors on every target
-- change, and a fresh closure per repaint is garbage the ticker's neighbors pay for.
local classResolvers = {}
local NO_CLASS = "\0none"

--- A resolver for a class token already known to be plain (or nil): the class color with the
--- stored alpha when the companion is on and the class resolves, the stored swatch otherwise.
function Element.ClassResolver(classToken)
    local key = classToken or NO_CLASS
    local resolver = classResolvers[key]
    if resolver then return resolver end
    local c = classToken and type(RAID_CLASS_COLORS) == "table" and RAID_CLASS_COLORS[classToken]
    resolver = function(stored, on)
        local r, g, b, a = Element.Stored(stored)
        if on and type(c) == "table" and type(c.r) == "number" then return c.r, c.g, c.b, a end
        return r, g, b, a
    end
    classResolvers[key] = resolver
    return resolver
end

--- A resolver for a party member's own class (never secret), cached on the element.
function Element.UnitResolver(el, unit)
    local resolver = el.__unitResolver
    if not resolver then
        resolver = function(stored, on) return NS.ResolveColor(stored, on, unit) end
        el.__unitResolver = resolver
    end
    return resolver
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
