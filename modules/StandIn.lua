local _, NS = ...

-- modules/StandIn.lua — preview's stand-in party frame
-- (docs/superpowers/specs/2026-09-15-test-mode-design.md §3, which predates the removal of the
-- separate test mode — the frame it specifies is unchanged, only its switch moved).
--
-- Out of a party there is no party frame to attach to, so UNLOCKING shows this one in party1's
-- place (modules/Preview.lua decides when; there is no `/pfe test` and no modules/TestMode.lua any
-- more — options-ui-§15 made the lock the only preview switch). It copies the size and position of the imitated frame
-- system's first member frame — which exists, hidden, out of a party — so offsets tuned against it are
-- the ones a real party gets, and wears one of three looks. The looks are approximations, judged by
-- eye in docs/smoke-tests.md.
--
-- READ-ONLY toward other frames: GetSize / GetLeft / GetTop / GetEffectiveScale only, each answer
-- checked for a plain number before it is compared. Never anchored, parented or hooked to a Blizzard
-- or EllesmereUI frame. The stand-in is an insecure plain Frame; the secure target and pet buttons may
-- pin to it out of combat, the only time test mode runs.

local Compat = NS.Compat
local L      = NS.L

local StandIn = {}
NS.StandIn = StandIn

-- After the player's name, in gray: a corner tag sat under whatever the player attached there (the
-- cast bar's time text, in game), and the name line is the one place nothing attaches over.
local TEST_MARK = "|cff999999" .. L["(test)"] .. "|r"

local WHITE     = "Interface\\Buttons\\WHITE8X8"
local RAID_FILL = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill"
local RAID_BG   = "Interface\\RaidFrame\\Raid-Bar-Hp-Bg"

-- Width and height when the source frame has no usable size.
local FALLBACK = {
    ellesmere          = { 125, 60 },   -- EllesmereUI's default party frame
    ["blizzard-raid"]  = { 72, 36 },    -- a guess; the smoke step checks it
    ["blizzard-party"] = { 120, 53 },   -- a guess; the smoke step checks it
}

local frame

-- ── reading another frame ─────────────────────────────────────────────────────────────────────

local function plain(v)
    if type(v) == "number" and not Compat.IsSecret(v) then return v end
    return nil
end

-- A getter's answers, or nothing when the method is missing or raises (a forbidden frame).
local function read(source, method)
    local fn = source and source[method]
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, source)
    if not ok then return nil end
    return a, b
end

-- ── the looks ─────────────────────────────────────────────────────────────────────────────────

local function classColor()
    local _, token = UnitClass("player")
    local c = token and type(RAID_CLASS_COLORS) == "table" and RAID_CLASS_COLORS[token]
    if type(c) == "table" and type(c.r) == "number" then return c.r, c.g, c.b end
    return 0.2, 0.8, 0.2
end

local function powerColor()
    if UnitPowerType and type(PowerBarColor) == "table" then
        local _, token = UnitPowerType("player")
        local c = token and PowerBarColor[token]
        if type(c) == "table" and type(c.r) == "number" then return c.r, c.g, c.b end
    end
    return 0, 0, 1
end

local function fillBar(bar, texture, r, g, b)
    bar:SetStatusBarTexture(texture)
    bar:SetStatusBarColor(r, g, b, 1)
    bar:Show()
end

-- `region` spanning `f`, inset by `n` on every side.
local function inset(region, f, n)
    region:ClearAllPoints()
    region:SetPoint("TOPLEFT", f, "TOPLEFT", n, -n)
    region:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -n, n)
end

local PRESETS = {}

-- EllesmereUI: a flat bar in class color on a dark ground, a 1 px black border, the name on the left.
PRESETS.ellesmere = function(f, _, _, r, g, b)
    f.bg:SetColorTexture(0.06, 0.06, 0.06, 0.9)
    f:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    f:SetBackdropBorderColor(0, 0, 0, 1)
    f.portrait:Hide()
    f.power:Hide()
    fillBar(f.health, WHITE, r, g, b)
    inset(f.health, f, 1)
    f.name:ClearAllPoints()
    f.name:SetPoint("LEFT", f.health, "LEFT", 4, 0)
end

-- Blizzard raid-style: Blizzard's raid bar textures in class color, the name top left.
PRESETS["blizzard-raid"] = function(f, _, _, r, g, b)
    f.bg:SetTexture(RAID_BG)
    f:SetBackdrop(nil)
    f.portrait:Hide()
    f.power:Hide()
    fillBar(f.health, RAID_FILL, r, g, b)
    inset(f.health, f, 1)
    f.name:ClearAllPoints()
    f.name:SetPoint("TOPLEFT", f.health, "TOPLEFT", 3, -3)
end

-- Blizzard classic: the portrait on the left, a green health bar over a power-colored bar, the name
-- above them.
PRESETS["blizzard-party"] = function(f, _, h)
    f.bg:SetColorTexture(0, 0, 0, 0.5)
    f:SetBackdrop(nil)
    f.portrait:ClearAllPoints()
    f.portrait:SetSize(h, h)
    f.portrait:SetPoint("LEFT", f, "LEFT", 0, 0)
    if SetPortraitTexture then SetPortraitTexture(f.portrait, "player") end
    f.portrait:Show()
    local barH = math.max(4, math.floor(h * 0.2))
    fillBar(f.health, WHITE, 0, 0.8, 0)
    f.health:ClearAllPoints()
    f.health:SetPoint("TOPLEFT", f, "TOPLEFT", h + 2, -h * 0.4)
    f.health:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -h * 0.4)
    f.health:SetHeight(barH)
    local pr, pg, pb = powerColor()
    fillBar(f.power, WHITE, pr, pg, pb)
    f.power:ClearAllPoints()
    f.power:SetPoint("TOPLEFT", f.health, "BOTTOMLEFT", 0, -1)
    f.power:SetPoint("TOPRIGHT", f.health, "BOTTOMRIGHT", 0, -1)
    f.power:SetHeight(barH)
    f.name:ClearAllPoints()
    f.name:SetPoint("BOTTOMLEFT", f.health, "TOPLEFT", 0, 2)
end

-- ── the frame ─────────────────────────────────────────────────────────────────────────────────

local function bar(parent)
    local b = CreateFrame("StatusBar", nil, parent)
    b:SetMinMaxValues(0, 1)
    b:SetValue(1)
    return b
end

local function build()
    local f = CreateFrame("Frame", "PartyFrameEnhancedStandIn", UIParent, "BackdropTemplate")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints(f)
    f.portrait = f:CreateTexture(nil, "ARTWORK")
    f.health = bar(f)
    f.power = bar(f)
    f.name = f.health:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f:Hide()
    return f
end

-- What converts `other`'s units into the stand-in's: the ratio of their effective scales when both
-- are plain numbers above 0, and 1 otherwise.
local function ratioTo(other, ours)
    local theirs = plain(read(other, "GetEffectiveScale"))
    if theirs and ours and theirs > 0 and ours > 0 then return theirs / ours end
    return 1
end

-- Size: the frame system's configured size when it has one (Providers.StandInSource: EllesmereUI,
-- whose hidden buttons carry its raid size), then `source`'s measured size, then the fallback. The
-- top-left always comes from `source`, or the screen center. Both convert by the effective-scale
-- ratio. `placed.from` names which size was used.
local function place(f, id, source, configured)
    local ours = plain(f:GetEffectiveScale())
    local ratio = ratioTo(source, ours)
    local w, h = read(source, "GetSize")
    w, h = plain(w), plain(h)
    local from
    if configured then
        local cr = ratioTo(configured.scaleFrame, ours)
        w, h, from = configured.w * cr, configured.h * cr, "settings"
    elseif w and h and w > 0 and h > 0 then
        w, h, from = w * ratio, h * ratio, "frame"
    else
        w, h, from = FALLBACK[id][1], FALLBACK[id][2], "fallback"
    end
    f:SetSize(w, h)
    f:ClearAllPoints()
    local left, top = plain(read(source, "GetLeft")), plain(read(source, "GetTop"))
    local placed = { id = id, w = w, h = h, from = from }
    if left and top then
        placed.point, placed.left, placed.top = "TOPLEFT", left * ratio, top * ratio
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", placed.left, placed.top)
    else
        placed.point = "CENTER"
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    f.__placed = placed
    return w, h
end

--- The stand-in, built on first ask.
function StandIn.Frame()
    frame = frame or build()
    return frame
end

--- Dress the stand-in as frame system `id` ("ellesmere", "blizzard-raid", "blizzard-party") and copy
--- `source`'s size and position. With no usable size on the source, `configured` ({ w, h,
--- scaleFrame }, or nil) is next, then the fallback; with no position, the screen center.
function StandIn.Place(id, source, configured)
    local f = StandIn.Frame()
    if not FALLBACK[id] then id = "blizzard-party" end
    -- Beneath what attaches to it, as a real party frame is: the elements are MEDIUM, and on their
    -- own strata the stand-in's health bar covered the cast bar's icon but for a 1px rim.
    f:SetFrameStrata("LOW")
    local w, h = place(f, id, source, configured)
    local r, g, b = classColor()
    PRESETS[id](f, w, h, r, g, b)
    f.name:SetText((UnitName("player") or "") .. " " .. TEST_MARK)
    return f
end

function StandIn.Show() StandIn.Frame():Show() end

function StandIn.Hide()
    if frame then frame:Hide() end
end

function StandIn.IsShown()
    return frame ~= nil and frame:IsShown() == true
end
