local _, NS = ...

-- modules/RangeFade.lua — every element fades with its party member's frame when that member is out
-- of range (General → Party frames → "Fade with party frames").
--
-- ONE FADE FRAME PER UNIT. Each unit's cast bar, target frame and pet frame are parented to a plain
-- frame of this module's, and only that frame's alpha changes here. The client multiplies a parent's
-- alpha into its children's, so the elements keep every alpha of their own -- the Master alpha, the
-- mid-combat reshuffle fade (modules/Anchor.lua), the cast bar's fade-out -- untouched. That split is
-- not a nicety: the alpha copied below can be SECRET, and a secret cannot be multiplied in Lua.
-- The fade frames are plain and never moved; they are shown whenever the addon is up and hidden on
-- stand-down. The secure target and pet buttons are parented to them at creation (OnEnable, out of
-- combat), so the hide and the show go through the secure queue; alpha is not a protected property.
--
-- HOW EACH FRAME SYSTEM FADES, and so what this copies (Blizzard 12.1.0 source, EllesmereUI as
-- installed):
--   * EllesmereUI sets its unit button's alpha itself on UNIT_IN_RANGE_UPDATE, through
--     SetAlphaFromBoolean(UnitInRange(unit), 1, oorAlpha) -- the flag is secret in combat -- or a
--     plain SetAlpha for offline, phased and its spell-range classes.
--   * Blizzard's raid-style CompactUnitFrame sets frame:SetAlpha(outOfRange and 0.5 or 1).
--   * Blizzard's classic PartyMemberFrame does NOT fade for range at all (only 0.6 for a phased
--     member or one in another group), so there is nothing to copy. There this module asks
--     UnitInRange itself, on UNIT_IN_RANGE_UPDATE, and fades to the raid-style frames' 0.5.
-- The first two are copied by post-hooking the party frame's own SetAlpha and SetAlphaFromBoolean
-- (hooksecurefunc: read-only, the frame is never called into) and replaying the same call on the
-- unit's fade frame, so the copy is exact -- EllesmereUI's own out-of-range alpha included.
--
-- A SECRET ALPHA. SetAlphaFromBoolean takes a secret flag by design. A secret NUMBER handed to
-- SetAlpha is tried under pcall; if the client refuses it, a raid-style frame's own `outOfRange`
-- flag (possibly secret) goes through SetAlphaFromBoolean instead, and anything else waits at full
-- alpha for the frame's next call. GetAlpha is never read back from a fade frame.
--
-- Full alpha whenever the fade does not apply: the setting off, the addon or a perf run suspending
-- it, preview mode, or a unit with no party frame.

local Compat    = NS.Compat
local Units     = NS.Units
local Providers = NS.Providers

local RangeFade = NS.RegisterModule({ name = "RangeFade" })
NS.RangeFade = RangeFade

local CLASSIC_OUT_OF_RANGE = 0.5   -- what Blizzard's raid-style frames fade to

local fades = {}                                         -- unit → fade frame
local unitOf = {}                                        -- party frame → the unit it shows now
local hooked = setmetatable({}, { __mode = "k" })        -- party frames already post-hooked
local suspended = false
local listening = false
local ready = false                                      -- OnEnable has run (the DB exists)

--- The frame `unit`'s elements are parented to. Created on first ask, by the features' OnEnable.
function RangeFade.Parent(unit)
    local f = fades[unit]
    if not f then
        f = CreateFrame("Frame", "PartyFrameEnhanced_Fade_" .. unit, UIParent)
        fades[unit] = f
    end
    return f
end

local function active()
    return not suspended and NS.GetSetting("general.rangeFade") == true
        and NS.GetSetting("enabled") == true and not NS.State.preview
end

local function classic()
    return Providers.ActiveId() == "blizzard-party"
end

-- ── the copy ──────────────────────────────────────────────────────────────────────────────────

local function copyAlpha(fade, frame, a)
    if not Compat.IsSecret(a) then
        fade:SetAlpha(type(a) == "number" and a or 1)
        return
    end
    if pcall(fade.SetAlpha, fade, a) then return end
    local out = frame.outOfRange   -- Blizzard CompactUnitFrame's own flag
    if Compat.IsSecret(out) or type(out) == "boolean" then
        Compat.AlphaFromBool(fade, out, CLASSIC_OUT_OF_RANGE, 1)
    else
        fade:SetAlpha(1)
    end
end

-- The unit whose fade a hooked frame's call should move, or nil when it moves none.
local function hookTarget(frame)
    local unit = unitOf[frame]
    if not unit or not active() or classic() then return nil end
    return fades[unit]
end

local function onSetAlpha(frame, a)
    local fade = hookTarget(frame)
    if fade then copyAlpha(fade, frame, a) end
end

local function onSetAlphaFromBoolean(frame, flag, ifTrue, ifFalse)
    local fade = hookTarget(frame)
    if fade then Compat.AlphaFromBool(fade, flag, ifTrue, ifFalse) end
end

local function hookFrame(frame)
    if hooked[frame] or type(frame.SetAlpha) ~= "function" then return end
    hooked[frame] = true
    hooksecurefunc(frame, "SetAlpha", onSetAlpha)
    if type(frame.SetAlphaFromBoolean) == "function" then
        hooksecurefunc(frame, "SetAlphaFromBoolean", onSetAlphaFromBoolean)
    end
end

-- ── Blizzard classic: our own range check ─────────────────────────────────────────────────────

local function classicAlpha(fade, unit)
    if unit == "player" then fade:SetAlpha(1); return end
    local inRange, checked = UnitInRange(unit)
    if Compat.IsSecret(inRange) or Compat.IsSecret(checked) then
        Compat.AlphaFromBool(fade, inRange, 1, CLASSIC_OUT_OF_RANGE)
    else
        fade:SetAlpha((checked and not inRange) and CLASSIC_OUT_OF_RANGE or 1)
    end
end

-- ── applying ──────────────────────────────────────────────────────────────────────────────────

local function apply(unit)
    local fade = fades[unit]
    if not fade then return end
    local frame = Providers.FrameFor(unit)
    if not active() or not frame then
        fade:SetAlpha(1)
    elseif classic() then
        classicAlpha(fade, unit)
    else
        -- Seed from the frame's current alpha; its next SetAlpha call keeps the copy current.
        copyAlpha(fade, frame, frame:GetAlpha())
    end
end

-- Re-read the unit → frame map: hook what is new, then bring every fade into line.
local function refresh()
    for frame in pairs(unitOf) do unitOf[frame] = nil end
    for _, unit in ipairs(Units.LIST) do
        local frame = Providers.FrameFor(unit)
        if frame then
            unitOf[frame] = unit
            if active() and not classic() then hookFrame(frame) end
        end
        apply(unit)
    end
end

local ev = NS.NewBusTarget()
RangeFade.__ev = ev

local function onRange(_, unit)
    if fades[unit] and Units.INDEX[unit] and active() and classic() and Providers.FrameFor(unit) then
        classicAlpha(fades[unit], unit)
    end
end

-- UNIT_IN_RANGE_UPDATE only while it can matter: the fade on, in a party, on the classic frames.
local function syncEvents()
    local want = active() and Units.InParty() and classic()
    if want == listening then return end
    listening = want
    if want then
        NS.SafeRegisterEvent(ev, "UNIT_IN_RANGE_UPDATE", onRange, NS.RejectedEvents)
    else
        ev:UnregisterEvent("UNIT_IN_RANGE_UPDATE")
    end
end

local function update()
    if not ready then return end
    syncEvents()
    refresh()
end

-- ── lifecycle ─────────────────────────────────────────────────────────────────────────────────

function RangeFade:OnEnable()
    for _, unit in ipairs(Units.LIST) do RangeFade.Parent(unit) end
    ready = true
    update()
end

-- Shown or hidden as one: secure buttons are parented to the fade frames, so under lockdown the
-- change waits for PLAYER_REGEN_ENABLED, and a later call under the same key replaces it.
local function showFades(on)
    NS.RunSecure("fade:shown", function()
        for _, f in pairs(fades) do
            if on then f:Show() else f:Hide() end
        end
    end)
end

function RangeFade:Suspend()
    suspended = true
    ev:UnregisterEvent("UNIT_IN_RANGE_UPDATE")
    listening = false
    refresh()
    showFades(false)
end

function RangeFade:Resume()
    suspended = false
    showFades(true)
    update()
end

--- Whether the classic frames' range event is registered.
function RangeFade.Listening()
    return listening
end

--- The unit -> party frame map the hooks read, as a copy keyed by unit (the diagnostics report).
function RangeFade.UnitMap()
    local map = {}
    for frame, unit in pairs(unitOf) do map[unit] = frame end
    return map
end

--- How many party frames carry this module's post-hooks. Hooks are never removed, so the count
--- only grows within a session.
function RangeFade.HookedCount()
    local n = 0
    for _ in pairs(hooked) do n = n + 1 end
    return n
end

--- What the fade is doing, for `/pfe status`: "off" (the setting, a suspend or preview), "idle" (no
--- frame system on screen), "range" (classic frames: this module's own UnitInRange check) or
--- "copy" (copied from the party frames).
function RangeFade.Mode()
    if not ready or not active() then return "off" end
    local id = Providers.ActiveId()
    if not id then return "idle" end
    return id == "blizzard-party" and "range" or "copy"
end

ev:RegisterMessage(NS.MSG.LAYOUT, update)
ev:RegisterMessage(NS.MSG.VISIBILITY, update)
ev:RegisterMessage(NS.MSG.PROFILE, update)
ev:RegisterMessage(NS.MSG.CONFIG, function(_, section)
    if section == "general" or section == "master" then update() end
end)
