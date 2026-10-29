local addonName, NS = ...

-- core/SkinSetup.lua — the LibKa0s-Skin-1.0 seam: which skin this addon wears (skinning-§1, §3).
-- The shape is LootHistory's core/SkinSetup.lua, the leg-1 adopter; only the paths and the brand
-- are this addon's.
--
-- ── WHAT IT PUBLISHES ────────────────────────────────────────────────────────────────────────
--
--   NS.Skin                 the owner's facade, `Skin:For("PartyFrameEnhanced")`: the painting
--                           vocabulary and Token / Color / Resolve / OnLooksChanged. Every surface
--                           this addon draws reads its colors, faces and textures here.
--   NS.SKIN_TOKENS          this addon's own tokens (skinning-§1, LibKa0s Skin minor 7): a color
--                           it draws under Ka0s Default that no library token holds, with that value
--                           as `default` and the nearest library role as `follow`.
--   NS.SKIN_FALLBACK        the host copy of the Ka0s Default library tokens the degraded facade
--                           answers, limited to the ones this addon reads.
--   NS.SkinChoice()         the stored (source, skin) pair, read through NS.GetSetting; "ka0s",
--                           "ka0s" before settings/Schema.lua and NS:InitDB have built the store.
--   NS.WriteSkinChoice(s,k,i,m) the write seam: every half through NS.SetByPath, the one seam
--                           `/pfe set` and the panel already write through (architecture-§5); `i`,
--                           the Scope's `{ panel, fonts }`, writes the two exceptions, and `m`, the
--                           Font and texture section's `{ font, texture }`, the two overrides ("" for
--                           false, the skin's own). A nil half is not written.
--   NS.SkinOverride()       the stored overrides: font, texture, each an LSM key or false for the
--                           skin's own.
--   NS.ApplySkinChoice(s,k) moves the applied skin: `Skin:SetChoice`, which resolves, repaints every
--                           frame recorded for this owner and THEN fires OnLooksChanged. No argument
--                           applies the stored pair and with it the stored exceptions and overrides
--                           (NS:InitDB, the profile events); a nil half keeps that half (each Skin
--                           tab row's onChange).
--   NS.ApplySkinIgnore(p,f) moves the applied exceptions: `Skin:SetIgnore`, live.
--   NS.ApplySkinOverride(f,t) moves the applied overrides: `Skin:SetOverride`, live.
--   NS.SKIN_SOURCE_VALUES   the source row's values and order, and the skin row's (every
--   NS.SKIN_SOURCE_SORTING  registered skin, in the library's order); settings/General.lua reads
--   NS.SKIN_VALUES          all four at file load.
--   NS.SKIN_SORTING
--
-- ── WHERE IT LOADS ───────────────────────────────────────────────────────────────────────────
--
-- After core/CoreSetup.lua (NS.Print, which the reload line uses) and before core/PerfSetup.lua,
-- core/DebugLogSetup.lua and every module, so NS.Skin exists for every surface that draws. It runs
-- at FILE LOAD, never at PLAYER_LOGIN, because the EllesmereUI provider has to offer the owner to
-- EllesmereUI before EllesmereUI dispatches its skins (skinning-§5). Nothing here reads the profile
-- at load: RegisterOwner calls `get` once, before AceDB exists, and it answers Ka0s Default; the
-- profile's pair is applied by NS.ApplySkinChoice at the end of NS:InitDB (core/Database.lua).
--
-- ── WHY A ROW'S onChange PASSES ONE HALF ─────────────────────────────────────────────────────
--
-- The Skin tab and another addon's "Copy to every Ka0s addon" both call Skin:SetChoice FIRST and
-- write the store after, one half at a time. A row reaction that re-applied the whole stored pair
-- would apply the half-written one in between: a second repaint, to a skin the player never
-- picked. Applying only the row's own half against the applied choice makes each write a no-op
-- (SetChoice is idempotent), so a pick is ONE effective SetChoice and one repaint, while a bare
-- `/pfe set skin.skin obsidian` still repaints.

local Skin = LibStub and LibStub("LibKa0s-Skin-1.0", true)

local SOURCE_PATH, SKIN_PATH = "skin.source", "skin.skin"
local PANEL_PATH, FONTS_PATH = "skin.ignorePanel", "skin.ignoreFonts"
local FONT_PATH, TEXTURE_PATH = "skin.font", "skin.texture"
local DEFAULT = "ka0s"
local BRAND = "Ka0s Party Frame Enhanced"

-- This addon's own tokens (X1, X2, X12 of the 2026-10-29 skinning rollout). Each name is in the
-- `pf.` namespace, never a library family; `default` is the exact color drawn before adoption, so
-- Ka0s Default keeps its pixels, and `follow` is the library role every other skin draws it from.
NS.SKIN_TOKENS = {
    -- The free-placement holder's plate, shown while unlocked (modules/Anchor.lua): "grab here".
    -- Gap PF-G1. Follows the list selection wash, each skin's accent at a low alpha.
    ["pf.mover"] = { default = { 0, 0.6, 1, 0.25 }, follow = "list.sel" },
}

-- The Ka0s Default library tokens the DEGRADED facade answers, copied from the library and limited
-- to the ones this addon reads. Both arms publish the table, so tests/test_surface_parity.lua can
-- hold each entry to the live library's Ka0s Default value: a copy that drifts goes red there. A
-- surface converted to a token adds the token here in the same change.
NS.SKIN_FALLBACK = {
    ["text.accent"] = { 1, 0.82, 0, 1 },
}

-- The source row's values and order.
NS.SKIN_SOURCE_VALUES  = { ka0s = "Ka0s skins", eui = "EllesmereUI" }
NS.SKIN_SOURCE_SORTING = { "ka0s", "eui" }

-- The skin row's values: every registered skin, Ka0s Default first. Without the library the one
-- skin the degraded facade can draw.
NS.SKIN_VALUES, NS.SKIN_SORTING = {}, {}
if Skin and type(Skin.Skins) == "function" then
    for _, def in ipairs(Skin:Skins()) do
        NS.SKIN_VALUES[def.key] = def.label or def.key
        NS.SKIN_SORTING[#NS.SKIN_SORTING + 1] = def.key
    end
end
if #NS.SKIN_SORTING == 0 then
    NS.SKIN_VALUES[DEFAULT] = "Ka0s Default"
    NS.SKIN_SORTING[1] = DEFAULT
end

--- A setting through the seam, nil-safely: nil until settings/Schema.lua and the store exist.
local function stored(path)
    if not (NS.db and NS.GetSetting) then return nil end
    return NS.GetSetting(path)
end

--- The stored pair, lazily and nil-safely: Ka0s Default until the profile store exists.
function NS.SkinChoice()
    return stored(SOURCE_PATH) or DEFAULT, stored(SKIN_PATH) or DEFAULT
end

--- A stored override as the profile keeps it: the LSM key, or "" for the skin's own.
local function storedKey(v)
    if type(v) == "string" and v ~= "" and v ~= (Skin and Skin.FROM_SKIN) then return v end
    return ""
end

--- The write seam: each half through NS.SetByPath (validate, store, the [Set] line, onChange).
function NS.WriteSkinChoice(source, skin, ignore, media)
    if not (NS.db and NS.SetByPath) then return end
    if source ~= nil then NS.SetByPath(SOURCE_PATH, source) end
    if skin ~= nil then NS.SetByPath(SKIN_PATH, skin) end
    if type(ignore) == "table" then
        NS.SetByPath(PANEL_PATH, ignore.panel == true)
        NS.SetByPath(FONTS_PATH, ignore.fonts == true)
    end
    if type(media) == "table" then
        NS.SetByPath(FONT_PATH, storedKey(media.font))
        NS.SetByPath(TEXTURE_PATH, storedKey(media.texture))
    end
end

--- The stored overrides, nil-safely: each an LSM key, or false for the skin's own.
function NS.SkinOverride()
    local font, texture = storedKey(stored(FONT_PATH)), storedKey(stored(TEXTURE_PATH))
    return font ~= "" and font or false, texture ~= "" and texture or false
end

--- The stored exceptions, nil-safely. Before the store exists, the profile default's answer:
--- the settings panel left the client's, the fonts skinned.
local function storedIgnore()
    local panel, fonts = stored(PANEL_PATH), stored(FONTS_PATH)
    if panel == nil then panel = true end
    return panel == true, fonts == true
end

-- ── the degraded arm ─────────────────────────────────────────────────────────────────────────

if not Skin then
    local function color(name)
        local c = NS.SKIN_FALLBACK[name]
        local own = NS.SKIN_TOKENS[name]
        if not c and own then c = own.default end
        if c then return c[1], c[2], c[3], c[4] or 1 end
    end
    local function noop() end
    local S = { owner = addonName, apiVersion = 3, FROM_SKIN = "@skin" }
    -- Every vocabulary name answers, as a no-op that never raises: this addon draws no window of
    -- its own, so there is no pre-library edge to route Shell to. The list is LibKa0s-Skin-1.0's
    -- VOCAB; tests/test_surface_parity.lua holds this table to the live facade key for key.
    for _, name in ipairs({
        "Shell", "Panel", "Inset", "FadeRegions", "FadeNineSlice", "Button", "WhiteButtonLabel",
        "StateButtonLabel", "EditBox", "Checkbox", "Dropdown", "ScrollBar", "Tab", "SetTabSelection",
        "CloseButton", "PageButton", "SquareIcon", "SortHeaderBar", "Font", "White", "ApplyBarFill",
        "GetAccentColor", "GetPanelColor", "GetFont",
        "TitleBar", "Divider", "Footer", "Card", "Slider", "NavItem", "Drawer", "ListRow", "MenuFrame",
        "Tooltip", "Strip", "Cover", "Text", "ChartStyle", "BarStyle", "IconBorder", "GlowColor",
        "BarTexture",
    }) do S[name] = noop end

    S.Token = function(name)
        local c = NS.SKIN_FALLBACK[name]
        if c == nil and NS.SKIN_TOKENS[name] then c = NS.SKIN_TOKENS[name].default end
        return c
    end
    S.Color = color
    -- A HUD style value that follows the skin has no skin to follow without the library: the
    -- player's stored pick stands, and a caller's own fallback covers the sentinel.
    S.Resolve = function(kind, value, fromSkin)
        if fromSkin or value == S.FROM_SKIN then
            local t = S.Token(kind)
            if t ~= nil then return t end
            if value == S.FROM_SKIN then return nil end
        end
        return value
    end
    S.OnLooksChanged = function(fn) return fn end   -- the skin never changes without the library
    S.IsEnabled = function() return false end
    S.GetStyle = function() return "ka0s:" .. DEFAULT end
    S.Text = function(fs, role)
        local r, g, b, a = color(role == "title" and "title.text" or ("text." .. tostring(role)))
        if r == nil then r, g, b, a = color(tostring(role)) end
        if r and fs and fs.SetTextColor then fs:SetTextColor(r, g, b, a) end
    end
    S.GetFont = function() return STANDARD_TEXT_FONT end
    S.ChartStyle = function() return {} end
    S.BarStyle = function() return {} end

    NS.Skin = S
    function NS.ApplySkinChoice() return false, false end
    function NS.ApplySkinIgnore() return false, false end
    function NS.ApplySkinOverride() return false end
    return
end

-- ── the live seam ────────────────────────────────────────────────────────────────────────────

NS.Skin = Skin:For(addonName)
Skin:RegisterOwner(addonName, {
    label  = BRAND,
    get    = NS.SkinChoice,
    set    = NS.WriteSkinChoice,
    tokens = NS.SKIN_TOKENS,
    -- The provider's one refusal line goes to the debug console, read at call time: the console
    -- loads after this file.
    log    = function(line) if NS.DebugLog and NS.DebugLog.Add then NS.DebugLog:Add("Skin", line) end end,
})

-- The one line a reload request earns on the path that has no popup of its own (a profile event
-- leaving an EllesmereUI that painted this session). The Skin tab raises the library's popup for
-- its own picks.
local function reloadLine()
    local L = NS.L
    return L and L["Reload your interface (/reload) to finish changing the skin."]
        or "Reload your interface (/reload) to finish changing the skin."
end

function NS.ApplySkinIgnore(panel, fonts)
    if type(Skin.SetIgnore) ~= "function" then return false, false end
    if panel == nil and fonts == nil then panel, fonts = storedIgnore() end
    local changed, reload = Skin:SetIgnore(addonName, panel, fonts)
    if reload and NS.Print then NS.Print(reloadLine()) end
    return changed, reload
end

--- No argument applies the stored overrides; a nil half keeps that half, false or "" clears it
--- (the skin's own). A copy without SetOverride (a Skin major before minor 6) moves nothing.
function NS.ApplySkinOverride(font, texture)
    if type(Skin.SetOverride) ~= "function" then return false end
    if font == nil and texture == nil then font, texture = NS.SkinOverride() end
    return Skin:SetOverride(addonName, font, texture)
end

--- No argument applies the stored pair AND the stored exceptions and overrides (NS:InitDB, the
--- profile events); a nil half keeps that half and leaves the rest alone (each Skin tab row).
function NS.ApplySkinChoice(source, skin)
    local whole = source == nil and skin == nil
    if whole then source, skin = NS.SkinChoice() end
    local changed, reload = Skin:SetChoice(addonName, source, skin)
    if reload and NS.Print then NS.Print(reloadLine()) end
    if whole then
        NS.ApplySkinIgnore()
        NS.ApplySkinOverride()
    end
    return changed, reload
end
