local _, NS = ...

-- modules/StandIn.lua — test mode's stand-in party frame
-- (docs/superpowers/specs/2026-09-15-test-mode-design.md §3).
--
-- Out of a party there is no party frame to attach to, so `/pfe test` shows this one in party1's
-- place (modules/TestMode.lua decides when). It copies the size and position of the imitated frame
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
    f:SetFrameStrata("MEDIUM")
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
    f.tag = f.health:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.tag:SetText(L["Test"])
    f.tag:SetTextColor(0.6, 0.6, 0.6, 1)
    f:Hide()
    return f
end

-- Size and top-left from `source`, converted by the two frames' effective-scale ratio. A missing or
-- unusable size takes the fallback; a missing position goes to the screen center.
local function place(f, id, source)
    local ratio = 1
    local theirs, ours = plain(read(source, "GetEffectiveScale")), plain(f:GetEffectiveScale())
    if theirs and ours and theirs > 0 and ours > 0 then ratio = theirs / ours end
    local w, h = read(source, "GetSize")
    w, h = plain(w), plain(h)
    if w and h and w > 0 and h > 0 then
        w, h = w * ratio, h * ratio
    else
        w, h = FALLBACK[id][1], FALLBACK[id][2]
    end
    f:SetSize(w, h)
    f:ClearAllPoints()
    local left, top = plain(read(source, "GetLeft")), plain(read(source, "GetTop"))
    local placed = { id = id, w = w, h = h }
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
--- `source`'s size and position; a nil source takes the fallback size at the screen center.
function StandIn.Place(id, source)
    local f = StandIn.Frame()
    if not FALLBACK[id] then id = "blizzard-party" end
    local w, h = place(f, id, source)
    local r, g, b = classColor()
    PRESETS[id](f, w, h, r, g, b)
    f.name:SetText(UnitName("player") or "")
    f.tag:ClearAllPoints()
    f.tag:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -2)
    return f
end

function StandIn.Show() StandIn.Frame():Show() end

function StandIn.Hide()
    if frame then frame:Hide() end
end

function StandIn.IsShown()
    return frame ~= nil and frame:IsShown() == true
end
