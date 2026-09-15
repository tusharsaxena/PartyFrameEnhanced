local _, NS = ...

-- modules/Preview.lua — preview mode (preview-mode): placeholder content on every enabled element,
-- fed through each feature's real render path, so a player can style and place things without
-- waiting for a pull.
--
-- Two ways in, one state (NS.State.preview, session-only):
--   * unlocking — the Master controls tab's *Lock frame*, `/pfe unlock`, `/pfe set locked false` —
--     turns preview on AND makes the free-placement holders draggable; locking turns both off;
--   * `/pfe preview` toggles the placeholders alone, leaving the lock where it is.
--
-- UNLOCKING IS REFUSED IN COMBAT. The clickable target and pet frames are secure: their state
-- drivers cannot switch to "show" and nothing can be dragged until combat ends, so an unlock there
-- would half-happen. The refusal puts the stored value back and says why, in gray. Locking is always
-- allowed — whatever it cannot do at once is queued for PLAYER_REGEN_ENABLED.

local L = NS.L

local Preview = NS.RegisterModule({ name = "Preview" })
NS.Preview = Preview

local REFUSED = "|cff808080" ..
    L["cannot unlock during combat \226\128\148 the clickable frames cannot move until it ends"] .. "|r"

local function setPreview(on, why)
    on = on and true or false
    if NS.State.preview == on then return end
    NS.State.preview = on
    NS.Debug("Preview", "%s (%s)", on and "on" or "off", why)
    NS.PublishVisibility()
end

--- The `locked` row's validate (settings/General.lua): runs inside the write seam BEFORE the value
--- is stored, so a refused unlock never lands. A panel checkbox that was clicked is redrawn from the
--- unchanged value.
function NS.AcceptLock(locked)
    if locked == false and InCombatLockdown() then
        NS.Print(REFUSED)
        if NS.RefreshOptionsPanel then NS.RefreshOptionsPanel() end
        return false
    end
    return true
end

--- The `locked` row's onChange, reached from every writer of that row once the value is stored.
function NS.OnLockChanged(locked)
    NS.Anchor.SetUnlocked(not locked)
    setPreview(not locked, locked and "locked" or "unlocked")
end

--- `/pfe preview`: placeholders on or off, the lock untouched. Refused in combat for the same
--- reason unlocking is.
function Preview.Toggle()
    if not NS.State.preview and InCombatLockdown() then
        NS.Print(REFUSED)
        return false
    end
    setPreview(not NS.State.preview, "command")
    return true
end

function Preview:OnEnable()
    -- A profile saved unlocked comes back unlocked. Everything else resets with the session.
    local unlocked = NS.GetSetting("locked") == false
    NS.Anchor.SetUnlocked(unlocked)
    setPreview(unlocked, "login")
end

local ev = NS.NewBusTarget()
Preview.__ev = ev

-- A new profile carries its own lock state.
ev:RegisterMessage(NS.MSG.PROFILE, function()
    local unlocked = NS.GetSetting("locked") == false
    NS.Anchor.SetUnlocked(unlocked)
    setPreview(unlocked, "profile")
end)
