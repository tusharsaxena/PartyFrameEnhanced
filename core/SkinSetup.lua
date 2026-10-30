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
--   NS.SkinPaintAceTree(c)  `Skin:PaintAceTree` with the owner bound: the Profiles page's
--                           AceConfigDialog tree (settings/Profiles.lua). 0 without the library.
--   NS.MaybeShowSkinPicker() the first-run skin picker (LibKa0s OptionsSkinPicker 1): `O.SkinPicker`
--                           while the profile's `skin.pickerSeen` is false and the addon stands up,
--                           held through combat. NS.ScheduleSkinPicker() lights its login fuse,
--   NS.HideSkinPicker()     takes a shown picker down (or out of the queue) unmarked, and
--   NS.SkinPickerSpec()     is the spec MaybeShowSkinPicker hands O.SkinPicker.
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
    -- Gap PF-G1. Follows the list selection wash, each skin's accent at a low alpha. High Contrast
    -- is the exception: its list.sel is an opaque black (it marks a selection with an outline), so
    -- its plate is its yellow focus color (#FFE600) at the same 0.25.
    ["pf.mover"] = { default = { 0, 0.6, 1, 0.25 }, follow = "list.sel",
                     skins = { contrast = { 1, 0.9, 0, 0.25 } } },
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

-- ── the first-run skin picker (LibKa0s OptionsSkinPicker 1, LibKa0s#64) ───────────────────────
--
-- The shape is LootHistory's (core/SkinSetup.lua there); only the paths, the preview and the timer
-- are this addon's.
--
-- WHEN. Once per session, two seconds after the login or reload PLAYER_ENTERING_WORLD
-- (addon:OnEnterWorld, NS.ScheduleSkinPicker), so only on an addon that stands up (a stood-down
-- addon has that event unregistered); and again after every profile event (adoptProfile in
-- core/PartyFrameEnhanced.lua), because a new, copied or reset profile carries its own
-- `skin.pickerSeen`. Never while the addon stands down, and never in combat: a start in combat is
-- held for the PLAYER_REGEN_ENABLED edge, one target at most.
--
-- SEEN. The library calls `onClose` once per showing, by any route the player takes (Apply, its
-- close control, the gear, Escape), and once for a picker still queued behind another Ka0s addon's
-- when that addon's "Apply to all Ka0s addons" dismisses it unshown; that is the one write of
-- `skin.pickerSeen`, through NS.SetByPath. A close this addon makes itself (NS.HideSkinPicker: the
-- stand-down, a profile event) is not the player's and writes nothing.
--
-- PREVIEW. A pick only previews (Skin:SetChoice, no write); Apply, the gear or Apply to all save
-- through NS.WriteSkinChoice; the close control and Escape put back the stored choice (the library
-- reads `get` at the close). A profile event takes the picker down FIRST, before the new profile's
-- skin is applied, so the new profile's whole pair is what stays worn.
--
-- THE EYE. This addon has no window and no test mode: its unlocked view IS its preview
-- (options-ui-§15, modules/Preview.lua), the placeholders on every enabled element, or the stand-in
-- party frame out of a party. So the eye unlocks, through the write seam, the same path the Lock
-- row and `/pfe unlock` take, refusals included (combat, a perf suspend). It leaves the addon
-- unlocked until the player locks it again (2026-10-29 rollout DECISIONS, PartyFrameEnhanced D6).

local PICKER_PATH = "skin.pickerSeen"
local PICKER_DELAY = 2
local pickerTarget       -- the one-shot PLAYER_REGEN_ENABLED target, while a start is held
local pickerTimer        -- the login fuse's AceTimer handle, while it is lit
local quietClose = false -- true while NS.HideSkinPicker takes the picker down

--- The eye: unlocked, so the skin shows on this addon's own elements.
local function previewSkin()
    if NS.SetByPath then NS.SetByPath("locked", false) end
end

--- The player's close: the picker seen, and nothing else (the library's put-back already wears the
--- stored choice).
local function pickerClosed()
    if quietClose then return end
    if not (NS.db and NS.SetByPath) then return end
    NS.SetByPath(PICKER_PATH, true)
end

function NS.SkinPickerSpec()
    return {
        owner = addonName, get = NS.SkinChoice, set = NS.WriteSkinChoice,
        -- The gear's default: O.OpenOptionsPanel("general"), then O.SelectTab("general",
        -- "Appearance"), the Skin tab's key on the General page (settings/General.lua).
        page = "general", tab = "Appearance",
        onPreview = previewSkin, onClose = pickerClosed,
    }
end

local function dropPickerDeferral()
    if pickerTarget then pickerTarget:UnregisterAllEvents(); pickerTarget = nil end
end

local function dropPickerTimer()
    if pickerTimer and NS.addon and NS.addon.CancelTimer then NS.addon:CancelTimer(pickerTimer) end
    pickerTimer = nil
end

--- True while this profile has not closed the picker and the addon stands up.
local function pickerDue()
    if not (NS.db and NS.GetSetting) then return false end
    if NS.IsStoodDown and NS.IsStoodDown() then return false end
    return NS.GetSetting(PICKER_PATH) == false
end

--- Take a shown picker down, or out of the queue, without marking it seen; drop a held start and
--- a lit login fuse.
function NS.HideSkinPicker()
    dropPickerDeferral()
    dropPickerTimer()
    local O = NS.Helpers
    if not (O and type(O.HideSkinPicker) == "function") then return end
    quietClose = true
    local ok, err = pcall(O.HideSkinPicker)
    quietClose = false
    if not ok then error(err, 0) end
end

--- Show the picker when this profile has not seen it: answers O.SkinPicker's frame, or nil, "queued"
--- while another Ka0s addon's picker is up (it shows when that one closes), or nil.
function NS.MaybeShowSkinPicker()
    local O = NS.Helpers
    if not (O and type(O.SkinPicker) == "function") then return nil end
    if not pickerDue() then
        NS.HideSkinPicker()
        return nil
    end
    if InCombatLockdown() then
        if pickerTarget then return nil end
        pickerTarget = NS.NewBusTarget and NS.NewBusTarget()
        if not pickerTarget then return nil end
        NS.SafeRegisterEvent(pickerTarget, "PLAYER_REGEN_ENABLED", function()
            dropPickerDeferral()
            NS.MaybeShowSkinPicker()
        end, NS.RejectedEvents)
        return nil
    end
    return O.SkinPicker(NS.SkinPickerSpec())
end

--- The login fuse: the picker two seconds in, off the login spike; one fuse at most, canceled by
--- NS.HideSkinPicker (the stand-down).
function NS.ScheduleSkinPicker()
    if pickerTimer or not (NS.addon and NS.addon.ScheduleTimer) then return end
    pickerTimer = NS.addon:ScheduleTimer(function()
        pickerTimer = nil
        NS.MaybeShowSkinPicker()
    end, PICKER_DELAY)
end

-- ── the AceGUI rows this addon acquires itself (SkinAce.lua) ────────────────────────────────
--
-- One: the Profiles page's container, which AceConfigDialog fills from AceGUI directly, past the
-- Options instance's owner proxy. NS.SkinPaintAceTree paints it and every child after each Open
-- (settings/Profiles.lua). The container is kept for the session and never released, so no host
-- OnRelease rides it. Nothing is painted while the Scope's Ignore settings panel is on (the
-- library's rule); each painted child goes back to AceGUI's pool stock on release.

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
    -- Nothing to paint an AceGUI row with: stock AceGUI, as the client draws it.
    function NS.SkinPaintAceTree() return 0 end
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

--- Paint an AceGUI container and every child for this owner; a copy whose SkinAce secondary did
--- not attach paints nothing.
function NS.SkinPaintAceTree(container)
    if type(Skin.PaintAceTree) ~= "function" then return 0 end
    return Skin:PaintAceTree(addonName, container)
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
