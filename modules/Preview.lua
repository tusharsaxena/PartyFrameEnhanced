local _, NS = ...

-- modules/Preview.lua — preview mode (preview-mode): placeholder content on every enabled element,
-- fed through each feature's real render path, so a player can style and place things without
-- waiting for a pull.
--
-- THE LOCK IS THE ONLY SWITCH (options-ui-§15). Preview is on exactly while the elements are
-- unlocked — Master controls' *Lock frame*, `/pfe unlock`, `/pfe set locked false` — and unlocking
-- also makes the free-placement holders draggable. There was a second way in until this was written,
-- a `/pfe test` verb and a Test mode checkbox holding preview under the reason `"test"`, and
-- §15 exempts an addon whose unlocked view already is its preview from exactly that row: two
-- switches for one state is the finding (anti-pattern #80). What test mode did that unlocking did
-- not — raise a stand-in party frame when you are not in a party, so there is something to place at
-- all — unlocking now does, so the capability outlived the verb. The multi-reason hold went with it:
-- one switch needs no set of holders.
--
-- THE STAND-IN. In a party, preview paints placeholders onto the real party frames. Out of one
-- (solo, or in a raid, where this addon stands down) there are no frames to paint, so
-- modules/StandIn.lua's own frame goes up in party1's place and is pushed into the provider map.
-- Which of the two is live is re-decided on every roster change while preview is on, so joining or
-- leaving a party mid-drag swaps the target without dropping preview.
--
-- UNLOCKING IS REFUSED IN COMBAT, with the addon disabled, and during a perf-run suspend. The
-- clickable target and pet frames are secure: their state drivers cannot switch to "show" and
-- nothing can be dragged until combat ends, so an unlock there would half-happen. The refusal puts
-- the stored value back and says why, in gray. LOCKING IS ALWAYS ALLOWED — whatever it cannot do at
-- once is queued for PLAYER_REGEN_ENABLED — so the refusal can never strand a player unlocked.
--
-- ENTERING COMBAT RE-LOCKS, at PLAYER_REGEN_DISABLED while secure writes are still permitted, so no
-- clickable placeholder and no stand-in anchor survives into the fight. That is where the old
-- "combat ends test mode" guarantee went; with one switch, ending preview and locking are one act.

local L = NS.L

local Preview = NS.RegisterModule({ name = "Preview" })
NS.Preview = Preview

local REFUSED_COMBAT = "|cff808080" ..
    L["cannot unlock during combat \226\128\148 the clickable frames cannot move until it ends"] .. "|r"
local REFUSED_DISABLED  = "|cff808080" .. L["cannot unlock \226\128\148 the addon is disabled"] .. "|r"
local REFUSED_SUSPENDED = "|cff808080" ..
    L["cannot unlock \226\128\148 a perf run has the addon suspended"] .. "|r"

local placedId   -- the frame system the stand-in was last dressed as

-- ── the stand-in ────────────────────────────────────────────────────────────────────────────

-- Dress it for the frame system it imitates, and say where its size came from: `frame`, `settings`
-- (the system's configured size) or `fallback` — the line a smoke step reads.
local function dress()
    local id, source, configured = NS.Providers.StandInSource()
    local p = NS.StandIn.Place(id, source, configured).__placed
    placedId = id
    NS.Debug("Preview", "stand-in as %s, %.0f x %.0f from %s", id, p.w, p.h, p.from)
end

local function raiseStandIn()
    dress()
    NS.StandIn.Show()
    NS.Providers.SetStandIn(NS.StandIn.Frame())
end

local function lowerStandIn()
    NS.Providers.SetStandIn(nil)
    NS.StandIn.Hide()
end

-- In a party the real frames carry the placeholders; out of one the stand-in does. Called on every
-- roster change while preview is on, so a join or a leave swaps the target rather than ending it.
local function applyStandIn()
    if NS.State.preview and not NS.Units.InParty() then raiseStandIn() else lowerStandIn() end
end

-- ── the lock ────────────────────────────────────────────────────────────────────────────────

local ev = NS.NewBusTarget()
Preview.__ev = ev

local function listen(on)
    if on then
        ev:RegisterEvent("GROUP_ROSTER_UPDATE", applyStandIn)
    else
        ev:UnregisterEvent("GROUP_ROSTER_UPDATE")
    end
end

--- Set preview to `on` and bring the world into line with it. VISIBILITY goes out only when the
--- answer actually changes, so a redundant write costs one comparison.
local function setPreview(on)
    on = on and true or false
    if NS.State.preview == on then return end
    NS.State.preview = on
    listen(on)
    applyStandIn()
    NS.Debug("Preview", "%s", on and "on" or "off")
    NS.PublishVisibility()
    -- Master controls' Lock frame checkbox reads the stored value, not this, but an open panel is
    -- redrawn so a lock forced by combat or a perf suspend ticks the box the player is looking at.
    if NS.RefreshOptionsPanel then NS.RefreshOptionsPanel() end
end

--- The `locked` row's validate (settings/General.lua): runs inside the write seam BEFORE the value
--- is stored, so a refused unlock never lands. A panel checkbox that was clicked is redrawn from the
--- unchanged value. The three refusals are the ones the removed Test mode row used to carry — an
--- unlock that cannot be honored is worse than one that is declined out loud.
function NS.AcceptLock(locked)
    if locked ~= false then return true end   -- locking is always allowed
    local why
    if InCombatLockdown() then why = REFUSED_COMBAT
    elseif NS.GetSetting("enabled") ~= true then why = REFUSED_DISABLED
    elseif NS.Perf.suspended then why = REFUSED_SUSPENDED
    end
    if not why then return true end
    NS.Print(why)
    if NS.RefreshOptionsPanel then NS.RefreshOptionsPanel() end
    return false
end

-- The lock's two halves: grabbable holders, and preview itself.
local function applyLock(unlocked)
    NS.Anchor.SetUnlocked(unlocked)
    setPreview(unlocked)
end

--- The `locked` row's onChange, reached from every writer of that row once the value is stored.
function NS.OnLockChanged(locked)
    applyLock(not locked)
end

--- Lock from something other than a player's write — combat, the master switch, a perf suspend.
--- Goes through the write seam so every reader ends up agreeing, and says why unless told not to.
local function forceLock(line)
    if not NS.State.preview then return false end
    NS.SetByPath("locked", true)
    if line then NS.Print(line) end
    return true
end

function Preview:OnEnable()
    -- A profile saved unlocked comes back unlocked. Everything else resets with the session.
    applyLock(NS.GetSetting("locked") == false)
end

--- The addon standing down ends preview, whichever hold put it down: a capture cannot measure
--- preview, and an addon the player switched off must not leave placeholders on their screen. Said
--- in the words of the reason, because "a perf run suspended the addon" is a confusing thing to
--- read after ticking a checkbox labeled *Enable Party Frame Enhanced*.
function Preview:Suspend()
    forceLock(NS.Perf.suspended and L["Locked \226\128\148 a perf run suspended the addon"]
        or L["Locked \226\128\148 the addon was disabled"])
end

-- Combat re-locks while secure writes are still permitted, so nothing clickable survives into it.
ev:RegisterEvent("PLAYER_REGEN_DISABLED", function()
    forceLock(L["Locked \226\128\148 combat started"])
end)

-- The disabled case is NOT here and is not an omission: the `enabled` row's onChange takes the
-- latch's hold, which stands the addon down and ends preview through Suspend above, before this
-- message is published at all — and by then this receiver is unregistered with the rest of the bus.
ev:RegisterMessage(NS.MSG.CONFIG, function(_, section)
    if not NS.State.preview then return end
    if section == "general" and NS.StandIn.IsShown() then
        -- A Frame system change: the stand-in takes the new system's look and size.
        if (NS.Providers.StandInSource()) ~= placedId then dress() end
    end
end)

-- A new profile carries its own lock state.
ev:RegisterMessage(NS.MSG.PROFILE, function()
    if NS.GetSetting("enabled") ~= true then
        applyLock(false)
    else
        applyLock(NS.GetSetting("locked") == false)
    end
end)
