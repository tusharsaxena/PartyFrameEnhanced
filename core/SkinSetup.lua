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
--                           false, the skin's own). A nil half is not written. Its `outline`,
--                           when not nil, writes skin.outline (LibKa0s v1.82.0, D-06).
--   NS.SkinOverride()       the stored overrides: font, texture, each an LSM key or false for the
--                           skin's own.
--   NS.ApplySkinChoice(s,k) moves the applied skin: `Skin:SetChoice`, which resolves, repaints every
--                           frame recorded for this owner and THEN fires OnLooksChanged. No argument
--                           applies the stored pair and with it the stored exceptions and overrides
--                           (NS:InitDB, the profile events); a nil half keeps that half (each Skin
--                           tab row's onChange).
--   NS.ApplySkinIgnore(p,f) moves the applied exceptions: `Skin:SetIgnore`, live.
--   NS.ApplySkinOverride(f,t) moves the applied overrides: `Skin:SetOverride`, live.
--   NS.ApplySkinOutline(m)  moves the applied Font outline: `Skin:SetOutline` (Skin minor 9), live;
--                           no argument applies the stored skin.outline. NS.ApplySkinChoice() with
--                           no argument applies it after the exceptions and the overrides.
--   NS.SKIN_OUTLINE_VALUES  the outline row's values and order: the library's OUTLINE_MODES ("all",
--   NS.SKIN_OUTLINE_SORTING "hud", "off") with the Skin tab's words.
--   NS.SkinPaintAceTree(c)  `Skin:PaintAceTree` with the owner bound: the Profiles page's
--                           AceConfigDialog tree (settings/Profiles.lua). 0 without the library.
--   NS.MaybeShowSkinPicker() the first-run skin picker (LibKa0s OptionsSkinPicker 1): `O.SkinPicker`
--                           while the profile's `skin.pickerSeen` is false and the addon stands up,
--                           held through combat. NS.ScheduleSkinPicker() lights its login fuse,
--   NS.HideSkinPicker()     takes a shown picker down (or out of the queue) unmarked, and
--   NS.SkinPickerSpec()     is the spec MaybeShowSkinPicker hands O.SkinPicker.
--   NS.RunSkinVerb()        the reserved `/pfe skin` verb's act (LibKa0s v1.82.0, O.SkinVerb, D-16):
--                           the same picker on demand, whatever `skin.pickerSeen` says.
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
local OUTLINE_PATH = "skin.outline"
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
    -- The HUD's plain fills and background (FS-PF-FLIP, causes D3 and D4). Ka0s Default keeps what
    -- each feature drew, which is not that skin's `bar.fill` or `bar.bg`; every other skin answers
    -- the library token. The fills are data-free: cast states and reactions are meaning colors and
    -- never read these.
    ["pf.castFill"]   = { default = { 1.0, 0.7, 0.0, 1 }, follow = "bar.fill" },
    ["pf.targetFill"] = { default = { 0.25, 0.75, 0.25, 1 }, follow = "bar.fill" },
    ["pf.petFill"]    = { default = { 0.35, 0.70, 0.35, 1 }, follow = "bar.fill" },
    ["pf.barBg"]      = { default = { 0, 0, 0, 0.6 }, follow = "bar.bg" },
}

-- The Ka0s Default library tokens the DEGRADED facade answers, copied from the library and limited
-- to the ones this addon reads. Both arms publish the table, so tests/test_surface_parity.lua can
-- hold each entry to the live library's Ka0s Default value: a copy that drifts goes red there. A
-- surface converted to a token adds the token here in the same change.
NS.SKIN_FALLBACK = {
    ["text.accent"] = { 1, 0.82, 0, 1 },
    ["bar.border"]  = { 0, 0, 0, 1 },
}

-- The source row's values and order.
NS.SKIN_SOURCE_VALUES  = { ka0s = "Ka0s skins", eui = "EllesmereUI" }
NS.SKIN_SOURCE_SORTING = { "ka0s", "eui" }

-- The Font outline row's values (LibKa0s-Skin-1.0 minor 9's OUTLINE_MODES, ruling D-06), in the
-- library's order, with the Skin tab's words. The same three without the library, so `/pfe set
-- skin.outline` validates either way.
NS.SKIN_OUTLINE_VALUES  = { all = "All text", hud = "HUD text only", off = "Off" }
NS.SKIN_OUTLINE_SORTING = { "all", "hud", "off" }

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
        if media.outline ~= nil then NS.SetByPath(OUTLINE_PATH, media.outline) end
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
-- THE PREVIEW (LibKa0s OptionsSkinPicker minor 11, spec.preview, mode "unlock"; Ka0sAddonsCommonTasks
-- docs/2026-11-03-SMOKE_ROUND6, R6-PV). This addon has no window and no test mode: its unlocked
-- view IS its preview (options-ui-§15, modules/Preview.lua), the placeholders on every enabled
-- element, or the stand-in party frame out of a party. So "the surface hidden" is "locked": a
-- picker shown with the elements locked unlocks them, the eye toggles the lock, and every close
-- (Apply, Apply to all, the gear, the close control, Escape, O.HideSkinPicker and this addon's own
-- NS.HideSkinPicker) puts the lock back as it was at open; the library undoes only what moved.
-- Enter and exit take `/pfe unlock` and `/pfe lock`'s path (settings/Slash.lua's runLock): the
-- write seam, with the row's refusals (combat, a perf suspend, disabled) printed by NS.AcceptLock,
-- then the panel refresh, so the Lock frame checkbox and the launcher's Locked entry stay in step.
-- The verbs' "Elements unlocked" reply is left out: the eye's lit or dimmed state is the reply, and
-- a picker that shows at login or on a new profile would otherwise print it unasked.
-- This reverses the enter-only eye of 2026-10-29 (rollout DECISIONS, PartyFrameEnhanced D6). The
-- lock is a stored setting: a /reload while the picker is up leaves the elements unlocked until
-- `/pfe lock`.
--
-- A PROFILE EVENT closes the picker after AceDB has switched (adoptProfile's NS.HideSkinPicker), so
-- the library's restore reads the NEW profile's lock and has nothing to undo, while the profile left
-- behind still stores the picker's `locked = false`. So the profile a showing's own enter unlocked
-- is remembered (`owedProfile`), and a quiet close that finds another profile active puts that
-- one's stored lock back to its default, raw: it is not the active profile, so nothing publishes.
-- An unlock the player made before the picker opened is never the picker's, and is left alone.
-- The library also calls enter("picker") to put such an unlock BACK after the eye locked it, at the
-- close or, after a close in combat, from its end-of-combat park. Both follow an eye press, so an
-- enter("picker") after one (`eyeMoved`) is a restore, never the opening's own unlock. The flag
-- clears when that restore unlocks, and at every close except one whose restore was refused in
-- combat (`restoreParked`), which keeps it for the parked restore. A close in combat that owed
-- nothing clears it too, or the next showing's own opening unlock would read as that restore and
-- owe no profile.

local PICKER_PATH = "skin.pickerSeen"
local PICKER_DELAY = 2
local pickerTarget       -- the one-shot PLAYER_REGEN_ENABLED target, while a start is held
local pickerTimer        -- the login fuse's AceTimer handle, while it is lit
local quietClose = false -- true while NS.HideSkinPicker takes the picker down
local owedProfile        -- the profile table this showing's own enter unlocked, while it is up
local eyeMoved = false   -- the eye has moved the lock since the restore it would owe
local restoreParked = false -- this close's restore unlock was refused, so the library parked it

--- The lock through the write seam, then the panel redrawn, as runLock does.
local function setLocked(v)
    if not NS.SetByPath then return end
    NS.SetByPath("locked", v)
    if NS.RefreshOptionsPanel then NS.RefreshOptionsPanel() end
end

local function unlocked() return NS.GetSetting ~= nil and NS.GetSetting("locked") == false end

--- spec.preview: unlocked is the mode, and unlocked is what shows (there is no window to ask).
local PREVIEW = {
    mode = "unlock",
    enter = function(why)
        local profile, restore = NS.db and NS.db.profile, why == "picker" and eyeMoved
        if why == "eye" then eyeMoved = true end
        setLocked(false)
        if not unlocked() then              -- refused: a restore stays owed for the park
            if restore then restoreParked = true end
            return
        end
        if restore then eyeMoved = false elseif why == "picker" then owedProfile = profile end
    end,
    exit = function(why)
        if why == "eye" then eyeMoved = true end
        setLocked(true)
    end,
    isActive = unlocked,
    isShown = unlocked,
}

--- The player's close: the picker seen, and nothing else (the library's put-back already wears the
--- stored choice).
local function pickerClosed()
    owedProfile = nil   -- the library's restore has run (it runs before onClose)
    if not (restoreParked and InCombatLockdown()) then eyeMoved = false end
    restoreParked = false
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
        preview = PREVIEW, onClose = pickerClosed,
    }
end

--- `/pfe skin` (settings/Slash.lua's `skin` row; the dispatcher refuses it while disabled):
--- O.SkinVerb with the first-run spec, so it shows the picker a new profile shows whatever
--- skin.pickerSeen says. The library prints its own lines (combat on every call, queued,
--- unavailable); without LibKa0s the Options stub answers nil, "absent" and this prints the
--- library-absent line. Answers the picker's frame, or nil and the reason.
function NS.RunSkinVerb()
    local O = NS.Helpers
    local win, why
    if O and type(O.SkinVerb) == "function" then
        win, why = O.SkinVerb(NS.SkinPickerSpec())
    else
        why = "absent"
    end
    if win == nil and why == "absent" and NS.Print then
        local L = NS.L
        local line = L and L["%s is unavailable: the LibKa0s library did not load."]
            or "%s is unavailable: the LibKa0s library did not load."
        NS.Print(line:format("/pfe skin"))
    end
    return win, why
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
    local owed = owedProfile
    quietClose = true
    local ok, err = pcall(O.HideSkinPicker)
    quietClose = false
    owedProfile = nil
    -- THE PREVIEW's profile-event case: the profile left behind gets its stored lock back.
    if owed and NS.db and owed ~= NS.db.profile and owed.locked == false then owed.locked = nil end
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

-- ── the one-time skin notice (LibKa0s OptionsSkinPicker minor 9, SG-L3) ────────────────────────
-- A release that wants every account to learn skins exist raises lib.SKIN_NOTICE_VERSION. The first
-- addon to ask in a session claims the notice and shows the picker; every other addon records the
-- version and stays quiet. The record is `db.global.skinNotice`, a number: account-wide, so a profile
-- switch never shows it twice. In combat nothing is claimed; it asks again every NOTICE_RETRY seconds until combat ends.
local NOTICE_RETRY = 5   -- seconds between asks while the player is in combat
local noticeWaiting = false

local function noticeGlobal()
    local d = NS.db or (NS.addon and NS.addon.db)
    return d and d.global or nil
end

local noticeStore = {
    get = function() local g = noticeGlobal(); return g and g.skinNotice or nil end,
    set = function(v) local g = noticeGlobal(); if g then g.skinNotice = v end end,
}

function NS.MaybeShowSkinNotice()
    local O = NS.Helpers
    if not (O and type(O.SkinNotice) == "function" and noticeGlobal()) then return nil, "unavailable" end
    if NS.IsStoodDown and NS.IsStoodDown() then
        -- A stood-down addon shows nothing, but a seen record still silences the rest (SG-L3).
        O.SkinNotice(nil, noticeStore, true)
        return nil, "standdown"
    end
    local spec = NS.SkinPickerSpec()
    local frame, why = O.SkinNotice(spec, noticeStore)
    if why == "combat" and not noticeWaiting and type(_G.C_Timer) == "table" and _G.C_Timer.After then
        noticeWaiting = true
        _G.C_Timer.After(NOTICE_RETRY, function()
            noticeWaiting = false
            NS.MaybeShowSkinNotice()
        end)
    end
    return frame, why
end

local pickerFirstRun = NS.MaybeShowSkinPicker
function NS.MaybeShowSkinPicker()
    local frame, why = NS.MaybeShowSkinNotice()
    if frame or why == "queued" then return frame, why end
    return pickerFirstRun()
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
        "BarTexture", "FontFlags", "HudFontSize", "Mark",
        -- LibKa0s v1.85.0: nil is each getter's degraded answer. The three colors answer nothing, so
        -- the stored color draws; HudShadow's nil is "the stored fontShadow stands". BarGloss and
        -- HoverArt draw nothing: no skin, no gloss, and the client's own hover art.
        "HudTextColor", "HudLabelColor", "BarFillColor", "HudShadow", "BarGloss", "HoverArt",
        -- Round 5: Band answers nil (no library, no band frame to anchor to) and Header, which lays
        -- a window's header children on the band, does nothing.
        "Band", "Header",
    }) do S[name] = noop end

    S.Token = function(name)
        local c = NS.SKIN_FALLBACK[name]
        if c == nil and NS.SKIN_TOKENS[name] then c = NS.SKIN_TOKENS[name].default end
        return c
    end
    S.Color = color
    -- A HUD style value that follows the skin has no skin to follow without the library: the
    -- player's stored pick stands, and a caller's own fallback covers the sentinel.
    -- No skin to win: the player's stored three stand (Skin doc, What a consumer owes).
    S.BarBorder = function(style, show, size) return style, show, size end
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
    -- LibKa0s v1.82.0 (SkinPaintExtras minor 7): never nil, since SetFont reads nil as no flags and
    -- refuses a nil size. A picked flag as stored; From skin ("@skin", or nothing stored) is the
    -- library's HUD text only default, OUTLINE. A HUD size as stored: no skin to scale it by.
    S.FontFlags = function(v)
        if type(v) == "string" and v ~= S.FROM_SKIN then return v end
        return "OUTLINE"
    end
    S.HudFontSize = function(size)
        local n = tonumber(size)
        return (n and n > 0) and n or 12
    end
    -- LibKa0s v1.85.0 (SkinPaintExtras minor 9): a string a caller concatenates, so never nil. The
    -- same markup in the art's own color, there being no tint to read.
    S.MarkText = function(path, size)
        size = size or 14
        return ("|T%s:%d:%d|t"):format(path, size, size)
    end
    -- The one member that must draw (LibKa0s Options doc, Moving to, section 7): a no-op leaves the
    -- string with no face. Both shadow arms are written, so turning the row off clears it; on a
    -- 12.0.7 client the stored shadow itself does not draw here, which that section accepts.
    S.HudFont = function(fs, opts)
        opts = type(opts) == "table" and opts or {}
        local face = opts.face
        if type(face) ~= "string" or face == "" then face = STANDARD_TEXT_FONT end
        if type(face) ~= "string" then return nil end
        fs:SetFont(face, S.HudFontSize(opts.size), S.FontFlags(opts.flags))
        local on = opts.shadow and true or false
        fs:SetShadowColor(0, 0, 0, on and 1 or 0)
        fs:SetShadowOffset(on and 1 or 0, on and -1 or 0)
    end

    NS.Skin = S
    function NS.ApplySkinChoice() return false, false end
    function NS.ApplySkinIgnore() return false, false end
    function NS.ApplySkinOverride() return false end
    function NS.ApplySkinOutline() return false end
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

--- No argument applies the stored Font outline; the library reads a mode it does not know as "hud".
--- A copy without SetOutline (a Skin major before minor 9) moves nothing.
function NS.ApplySkinOutline(mode)
    if type(Skin.SetOutline) ~= "function" then return false end
    if mode == nil then mode = stored(OUTLINE_PATH) end
    return Skin:SetOutline(addonName, mode)
end

--- No argument applies the stored pair AND the stored exceptions, overrides and Font outline (NS:InitDB, the
--- profile events); a nil half keeps that half and leaves the rest alone (each Skin tab row).
function NS.ApplySkinChoice(source, skin)
    local whole = source == nil and skin == nil
    if whole then source, skin = NS.SkinChoice() end
    local changed, reload = Skin:SetChoice(addonName, source, skin)
    if reload and NS.Print then NS.Print(reloadLine()) end
    if whole then
        NS.ApplySkinIgnore()
        NS.ApplySkinOverride()
        NS.ApplySkinOutline()
    end
    return changed, reload
end
