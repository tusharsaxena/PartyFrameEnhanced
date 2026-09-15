local _, NS = ...

-- modules/Preview.lua — preview mode (preview-mode): placeholder content on every enabled element,
-- fed through each feature's real render path, so a player can style and place things without
-- waiting for a pull.
--
-- Preview is HELD: on while any reason holds it (NS.State.preview, session-only), so the two ways in
-- combine and leaving one keeps the placeholders while the other still wants them:
--   * "unlock" — the Master controls tab's *Lock frame*, `/pfe unlock`, `/pfe set locked false` —
--     also makes the free-placement holders draggable; locking releases it;
--   * "test" — `/pfe test` (modules/TestMode.lua).
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

local held = {}   -- reason → true

--- Hold or release preview for `reason`. VISIBILITY goes out only when the overall answer changes.
function Preview.Hold(reason, on)
    held[reason] = on and true or nil
    local now = next(held) ~= nil
    if NS.State.preview == now then return end
    NS.State.preview = now
    NS.Debug("Preview", "%s (%s %s)", now and "on" or "off", reason, on and "held" or "released")
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

-- The lock's two halves: grabbable holders, and the "unlock" hold.
local function applyLock(unlocked)
    NS.Anchor.SetUnlocked(unlocked)
    Preview.Hold("unlock", unlocked)
end

--- The `locked` row's onChange, reached from every writer of that row once the value is stored.
function NS.OnLockChanged(locked)
    applyLock(not locked)
end

function Preview:OnEnable()
    -- A profile saved unlocked comes back unlocked. Everything else resets with the session.
    applyLock(NS.GetSetting("locked") == false)
end

local ev = NS.NewBusTarget()
Preview.__ev = ev

-- A new profile carries its own lock state.
ev:RegisterMessage(NS.MSG.PROFILE, function()
    applyLock(NS.GetSetting("locked") == false)
end)
