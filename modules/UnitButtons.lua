local _, NS = ...

-- modules/UnitButtons.lua — the clickable elements the target and pet frames are made of: a
-- SecureUnitButtonTemplate button per tracked unit, its visibility state driver, its click
-- attributes, and the health/name painting both features share (spec §6.3–§6.5).
--
-- SECURE RULES (events-frames-taint-§2, spec §6.4):
--   * buttons are created in OnEnable — at PLAYER_LOGIN, out of combat — and never later;
--   * every attribute, state driver, mouse or geometry write goes through NS.RunSecure, which runs
--     now out of combat and queues (latest write per key) for PLAYER_REGEN_ENABLED in combat;
--   * show/hide is the STATE DRIVER's, not Lua's: `[@party1target,exists] show; hide`, with the
--     General visibility mode folded in as `[combat]` / `[nocombat]`, so combat transitions change
--     nothing Lua has to write. Lua only re-issues a driver when a setting, preview or frame
--     presence changes.
--
-- Painting the regions inside a secure button is not a protected action, so content updates freely
-- in combat.

local Compat  = NS.Compat
local Element = NS.Element

local UnitButtons = {}
NS.UnitButtons = UnitButtons

--- Create one feature's button for `unit`, acting on `token` (partyNtarget, partypetN, …).
function UnitButtons.Create(feature, unit, token)
    local btn = CreateFrame("Button", "PartyFrameEnhanced" .. feature .. "_" .. unit, UIParent,
        "SecureUnitButtonTemplate")
    btn:SetAttribute("unit", token)
    btn:RegisterForClicks("AnyUp")
    Element.Build(btn, { marker = feature == "Target" })
    btn:Hide()
    btn.unit, btn.token, btn.__key = unit, token, feature .. ":" .. unit
    return btn
end

--- The visibility driver for a button: "hide" unless the Lua-side rungs pass (`allowed`), "show"
--- in preview, otherwise the token's existence gated by General visibility.
function UnitButtons.Driver(token, allowed, preview)
    if not allowed then return "hide" end
    if preview then return "show" end
    local mode = NS.GetSetting("visibility")
    if mode == "never" then return "hide" end
    local exists = "[@" .. token .. ",exists] show; hide"
    if mode == "inCombat" then return "[nocombat] hide; " .. exists end
    if mode == "outOfCombat" then return "[combat] hide; " .. exists end
    return exists
end

--- Install `driver` unless it is already the installed one.
function UnitButtons.ApplyDriver(btn, driver)
    if btn.__driver == driver then return end
    NS.RunSecure("driver:" .. btn.__key, function()
        btn.__driver = driver
        RegisterStateDriver(btn, "visibility", driver)
        NS.Debug("Secure", "%s driver: %s", btn.__key, driver)
    end)
end

--- Left-click targets the unit, or the button ignores the mouse entirely.
function UnitButtons.ApplyClicks(btn, on)
    on = on and true or false
    if btn.__clicks == on then return end
    NS.RunSecure("clicks:" .. btn.__key, function()
        btn.__clicks = on
        btn:SetAttribute("*type1", on and "target" or nil)
        btn:EnableMouse(on)
    end)
end

--- Health bar and percent. Secret values go straight to the C setters; a plain value equal to the
--- last one painted is skipped (the ticker calls this five times a pass). Returns true when it
--- painted.
function UnitButtons.RenderHealth(btn, token, showPercent)
    local h, hm = UnitHealth(token), UnitHealthMax(token)
    local plain = not Compat.IsSecret(h) and not Compat.IsSecret(hm)
    if plain and btn.__h == h and btn.__hm == hm and btn.__pctShown == showPercent then
        return false
    end
    btn.bar:SetMinMaxValues(0, hm)
    btn.bar:SetValue(h)
    if plain then
        btn.__h, btn.__hm = h, hm
    else
        btn.__h, btn.__hm = nil, nil
    end
    btn.__pctShown = showPercent
    local pct = showPercent and Compat.HealthPercent(token)
    if pct then
        btn.text2:SetFormattedText("%d%%", pct)
    else
        btn.text2:SetText("")
    end
    return true
end

--- The unit's name (possibly secret — SetText takes it as is), or nothing.
function UnitButtons.RenderName(btn, token, showName)
    if showName then
        local name = UnitName(token)
        btn.text:SetText(name or "")
    else
        btn.text:SetText("")
    end
end

--- Forget what was painted, so the next render paints everything (a new unit behind the token).
function UnitButtons.Invalidate(btn)
    btn.__h, btn.__hm, btn.__pctShown = nil, nil, nil
end

--- The placeholder content preview mode shows (preview-mode), through the same regions.
function UnitButtons.RenderPreview(btn, name, pct, showName, showPercent)
    btn.bar:SetMinMaxValues(0, 100)
    btn.bar:SetValue(pct)
    btn.text:SetText(showName and name or "")
    if showPercent then btn.text2:SetFormattedText("%d%%", pct) else btn.text2:SetText("") end
    UnitButtons.Invalidate(btn)
end

--- The feature-independent rungs of the show decision (spec §6.7, rungs 0–2 and 5–6).
function UnitButtons.Allowed(cfg, unit)
    if not Element.MasterShows() or not cfg.enabled then return false end
    if not NS.Units.IsIncluded(unit) then return false end
    if cfg.anchorMode ~= "free" and not NS.Providers.FrameFor(unit) then return false end
    return true
end
