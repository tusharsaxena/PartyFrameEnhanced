local _, NS = ...

-- core/Compat.lua — every version-variant or optional client API this addon calls (compat), and the
-- secret-value guards around them (spec §7). Retail only: these shim cross-patch differences, never
-- game flavors. Feature modules call NS.Compat.X and never the raw API, so a patch that renames or
-- removes one is a one-file fix. Every global is read at CALL time: 12.0 and 12.1 differ in which
-- members exist (C_Secrets.CanCompareUnitTokens is 12.1), and a headless run has none of them.
NS.Compat = NS.Compat or {}
local Compat = NS.Compat

--- True only for a value the client marks secret. `issecretvalue` is a 12.0 global; an older build
--- or a headless run lacks it and answers false.
function Compat.IsSecret(v)
    local f = issecretvalue
    return f ~= nil and f(v) == true
end

--- Whether an addon is loaded. The presence guard every optional integration goes through
--- (library-stack-§6); C_AddOns first, the deprecated global second.
function Compat.IsAddOnLoaded(name)
    local api = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
    if not api then return false end
    local ok, loaded = pcall(api, name)
    return ok and loaded and true or false
end

--- Whether another addon's (or Blizzard's) frame is on screen. A secret answer counts as VISIBLE —
--- failing open, as both reference addons do, because hiding every element over an unreadable flag
--- is the worse error. A nil frame or a raising call is not visible.
function Compat.FrameVisible(frame)
    if type(frame) ~= "table" or type(frame.IsVisible) ~= "function" then return false end
    local ok, v = pcall(frame.IsVisible, frame)
    if not ok then return false end
    if Compat.IsSecret(v) then return true end
    return v and true or false
end

-- The fields a party member frame keeps its unit in, in the order they are trusted:
-- CompactUnitFrame's displayedUnit (differs from `unit` in a vehicle), the generic `unit`, and
-- Blizzard's classic PartyMemberFrame `unitToken`. Then the secure attribute, which is where a
-- SecureGroupHeader child (EllesmereUI) keeps it.
local UNIT_FIELDS = { "displayedUnit", "unit", "unitToken" }

local function plainUnit(u)
    -- The secret test comes FIRST: comparing a secret string with "" raises.
    if Compat.IsSecret(u) or type(u) ~= "string" then return nil end
    if u == "" then return nil end
    return u
end

--- The unit token a member frame currently shows, or nil when it shows none or only a secret.
function Compat.FrameUnit(frame)
    if type(frame) ~= "table" then return nil end
    for i = 1, #UNIT_FIELDS do
        local u = plainUnit(rawget(frame, UNIT_FIELDS[i]))
        if u then return u end
    end
    if type(frame.GetAttribute) == "function" then
        local ok, u = pcall(frame.GetAttribute, frame, "unit")
        if ok then return plainUnit(u) end
    end
    return nil
end

--- Whether two unit tokens name the same unit: true, false, or nil for UNKNOWN. 12.1 refuses to
--- compare tokens whose identity is secret, and UnitIsUnit itself can answer a secret boolean; both
--- are unknown, never a guess.
function Compat.UnitIsUnit(a, b)
    local secrets = C_Secrets
    if secrets and secrets.CanCompareUnitTokens then
        local ok, can = pcall(secrets.CanCompareUnitTokens, a, b)
        if not ok or Compat.IsSecret(can) or not can then return nil end
    end
    if not UnitIsUnit then return nil end
    local ok, same = pcall(UnitIsUnit, a, b)
    if not ok or Compat.IsSecret(same) then return nil end
    return same and true or false
end

--- Whether Blizzard's party frames are in the raid-style layout. 12.x stores this per Edit Mode
--- layout; the old `useCompactPartyFrames` CVar is the fallback for a build without the method.
function Compat.UseRaidStyleParty()
    local em = EditModeManagerFrame
    if em and type(em.UseRaidStylePartyFrames) == "function" then
        local ok, v = pcall(em.UseRaidStylePartyFrames, em)
        if ok and not Compat.IsSecret(v) then return v and true or false end
    end
    if GetCVarBool then
        local ok, v = pcall(GetCVarBool, "useCompactPartyFrames")
        if ok and not Compat.IsSecret(v) then return v and true or false end
    end
    return false
end
