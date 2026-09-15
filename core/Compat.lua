local _, NS = ...

-- core/Compat.lua — every version-variant or optional client API this addon calls (compat), and the
-- secret-value guards around them (design spec §7). Retail only: these shim cross-patch differences, never
-- game flavors. Feature modules call NS.Compat.X and never the raw API, so a patch that renames or
-- removes one is a one-file fix. Every global is read at CALL time: 12.0 and 12.1 differ in which
-- members exist, and a headless run has none of them.
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

-- ── casts (design spec §6.2) ─────────────────────────────────────────────────────────────────────────
--
-- A party member's cast info is secret whenever the client restricts it: the name, the texture,
-- `notInterruptible` and every time. Nothing below compares, formats or does arithmetic on any of
-- them. A truthiness test on the name is the one thing that is safe, and it is all a kind needs.

--- What `unit` is casting now: kind ("cast" | "channel" | "empower"), name, texture and
--- notInterruptible (all three possibly secret), or nil when it is casting nothing. `hint` is the
--- kind the triggering event implies; it decides empower-vs-channel when the client's own
--- isEmpowered flag comes back secret.
function Compat.CastInfo(unit, hint)
    local name, _, texture, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
    if name then return "cast", name, texture, notInterruptible end
    local cname, _, ctexture, _, _, _, cnotInterruptible, _, isEmpowered = UnitChannelInfo(unit)
    if not cname then return nil end
    local kind = "channel"
    if hint == "empower" then
        kind = "empower"
    elseif not Compat.IsSecret(isEmpowered) and isEmpowered then
        kind = "empower"
    end
    return kind, cname, ctexture, cnotInterruptible
end

--- The client's duration object for the cast `unit` is running, or nil. Opaque: its getters are
--- secret in combat, so it is only ever passed to C methods.
function Compat.CastDuration(unit, kind)
    local fn
    if kind == "cast" then
        fn = UnitCastingDuration
    elseif kind == "empower" then
        fn = UnitEmpoweredChannelDuration or UnitChannelDuration
    else
        fn = UnitChannelDuration
    end
    if not fn then return nil end
    local ok, d = pcall(fn, unit)
    if ok then return d end
    return nil
end

--- Hand `duration` to the status bar's engine-side timer: casts and empowers fill, channels drain.
--- Returns true when the engine animates the bar; false means the caller drives it by hand (a build
--- without SetTimerDuration), from the same object's getters passed straight to SetValue.
function Compat.ApplyTimer(bar, duration, kind)
    local dirs = Enum and Enum.StatusBarTimerDirection
    if not duration or not dirs or type(bar.SetTimerDuration) ~= "function" then return false end
    local interp = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate
    local dir = (kind == "channel") and dirs.RemainingTime or dirs.ElapsedTime
    bar:SetTimerDuration(duration, interp, dir)
    return true
end

--- `ifTrue` or `ifFalse` by a boolean that may be secret. A plain flag is simply tested; a secret
--- one goes through C_CurveUtil.EvaluateColorValueFromBoolean, whose result may itself be secret
--- and is only ever handed to a C method. Without the curve API a secret flag reads as false.
function Compat.BoolValue(flag, ifTrue, ifFalse)
    if not Compat.IsSecret(flag) then
        if flag then return ifTrue end
        return ifFalse
    end
    local cu = C_CurveUtil
    if cu and cu.EvaluateColorValueFromBoolean then
        return cu.EvaluateColorValueFromBoolean(flag, ifTrue, ifFalse)
    end
    return ifFalse
end

--- Set `region`'s alpha by a boolean that may be secret: SetAlphaFromBoolean is the one C method
--- that takes the secret form. A region's GetAlpha is secret afterwards, so callers keep their own
--- record of what they asked for.
function Compat.AlphaFromBool(region, flag, ifTrue, ifFalse)
    if Compat.IsSecret(flag) and type(region.SetAlphaFromBoolean) == "function" then
        region:SetAlphaFromBoolean(flag, ifTrue, ifFalse)
        return
    end
    region:SetAlpha(Compat.BoolValue(flag, ifTrue, ifFalse))
end

-- ── units a party member targets (design spec §6.3) ──────────────────────────────────────────────────
--
-- `partyNtarget` is a compound token: its identity is secret whenever any link in the chain fails
-- the client's identity test, so its class, player-ness and reaction can come back secret. Each shim
-- below answers a PLAIN value or nil (unknown); nothing downstream ever indexes a table with a value
-- it has not checked.

--- The unit's health as 0-100 (possibly secret), for SetFormattedText only, or nil. The curve makes
--- the client scale it, so no Lua arithmetic touches it.
function Compat.HealthPercent(token)
    if not UnitHealthPercent then return nil end
    local curve = CurveConstants and CurveConstants.ScaleTo100
    local ok, pct = pcall(UnitHealthPercent, token, true, curve)
    if ok then return pct end
    return nil
end

--- The unit's class TOKEN ("MAGE"), or nil when it is secret, absent or not a string. The localized
--- name (the first return) is never used: class colors key on the token (localization-§4).
function Compat.ClassToken(token)
    local ok, _, classToken = pcall(UnitClass, token)
    if not ok or Compat.IsSecret(classToken) or type(classToken) ~= "string" then return nil end
    return classToken
end

--- true / false for a player-controlled unit, or nil when the answer is secret.
function Compat.IsPlayer(token)
    if not UnitIsPlayer then return nil end
    local ok, v = pcall(UnitIsPlayer, token)
    if not ok or Compat.IsSecret(v) then return nil end
    return v and true or false
end

--- The unit's reaction to the player (1-8), or nil when it is secret or unknown.
function Compat.Reaction(token)
    if not UnitReaction then return nil end
    local ok, v = pcall(UnitReaction, token, "player")
    if not ok or Compat.IsSecret(v) or type(v) ~= "number" then return nil end
    return v
end

--- Show the unit's raid marker on `texture`, or hide it. The index may be secret; it is handed to
--- the client's own setter untouched, and only its presence is tested.
function Compat.RaidMarker(texture, token)
    local ok, index = pcall(GetRaidTargetIndex, token)
    if ok and index and SetRaidTargetIconTexture then
        SetRaidTargetIconTexture(texture, index)
        texture:Show()
        return true
    end
    texture:Hide()
    return false
end

-- No UnitExists shim, on purpose. Lua's answer for a compound token can be secret in combat, and
-- reading that as "exists" repainted every hidden target button five times a second
-- (docs/perf-analysis/20260915-161824). Whether a target frame's unit exists is its state driver's
-- `[@token,exists]`, resolved securely; Lua asks the button whether it is shown.

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
