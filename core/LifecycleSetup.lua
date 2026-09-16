local addonName, NS = ...

-- core/LifecycleSetup.lua — the LibKa0s-Lifecycle-1.0 seam (slash-commands-§7, anti-pattern #85).
--
-- ONE LATCH, TWO NAMED HOLDS, AND NO SECOND TEARDOWN PATH. This addon has exactly one way to be
-- inert. The perf harness takes the `perf` hold for its suspended arm; the stored `enabled` path
-- takes the `disabled` hold. The addon is stood down whenever at least one hold is taken and stands
-- up only when the last one is released — so a perf run that finishes under a player who disabled
-- the addon halfway through does NOT resurrect it, and a `/pfe enable` mid-capture does not either.
-- A bare stand-up is the bug the latch exists to prevent, which is why the library has no
-- `:StandUp()` member and neither does this file.
--
-- LOAD-BEARING POSITION: core/PerfSetup.lua REQUIRES `descriptor.lifecycle` and loads immediately
-- after this file, so the instance has to exist before it. NS.StandDown and NS.StandUp are defined
-- much later, in core/PartyFrameEnhanced.lua, so both are reached through call-time forwarders.

local Lifecycle = LibStub and LibStub("LibKa0s-Lifecycle-1.0", true)

if Lifecycle then
    NS.lifecycle = Lifecycle:New({
        name      = addonName,
        standDown = function() if NS.StandDown then NS.StandDown() end end,
        standUp   = function() if NS.StandUp then NS.StandUp() end end,
        print     = function(line) NS.Print(line) end,
    })
else
    -- Degrade, never error, exactly as core/DebugLogSetup.lua and settings/OptionsSetup.lua do. A
    -- build without LibKa0s still has to let a player switch the addon off and back on, and the
    -- switch has to go both ways, so the hold SET is modeled rather than a boolean — a stub that
    -- collapsed the two holds would be the one-boolean bug the library was extracted to end. It is
    -- the library's contract at its smallest, not a second mechanism: the addon calls the same
    -- members against the same key space, and nothing else in the tree knows which arm it has.
    local held, count = {}, 0
    local lc = { name = addonName, HOLD_DISABLED = "disabled", HOLD_PERF = "perf" }
    local down = false

    local function edge()
        local want = count > 0
        if want == down then return false end
        down = want
        if want then
            if NS.StandDown then NS.StandDown() end
        elseif NS.StandUp then
            NS.StandUp()
        end
        return true
    end

    function lc.Hold(_, key)
        if held[key] then return false end
        held[key], count = true, count + 1
        return edge()
    end

    function lc.Release(_, key)
        if not held[key] then return false end
        held[key], count = nil, count - 1
        return edge()
    end

    function lc.Set(self, key, on) if on then return self:Hold(key) end return self:Release(key) end
    function lc.IsHeld(_, key) return held[key] == true end
    function lc.IsDown() return count > 0 end
    function lc.Reevaluate() return edge() end

    function lc.Holds()
        local out = {}
        for key in pairs(held) do out[#out + 1] = key end
        table.sort(out)
        return out
    end

    function lc.PrintHolds() return false end

    NS.lifecycle = lc
end

NS.HOLD_DISABLED = (Lifecycle and Lifecycle.HOLD_DISABLED) or "disabled"

--- Is the addon stood down right now, for any reason? The one question every show-decision ladder
--- asks (modules/Element.lua rung 0). Never a boolean of this file's own: the latch is the single
--- answer and this reads through to it.
function NS.IsStoodDown()
    return NS.lifecycle:IsDown()
end

--- Take or release the `disabled` hold from the stored `enabled` path. The `enabled` row's
--- onChange, `/pfe enable`, `/pfe disable` and the profile callbacks all land here, so the checkbox
--- and the verbs can never show the player two different answers.
function NS.ApplyEnabled(enabled)
    NS.lifecycle:Set(NS.HOLD_DISABLED, enabled ~= true)
end

--- A profile switch can flip the stored path with nothing else touched (slash-commands-§7): re-read
--- it and re-run the empty/non-empty decision, which fires a callback only on an actual edge.
function NS.ReevaluateEnabled()
    NS.ApplyEnabled(NS.GetSetting("enabled"))
    NS.lifecycle:Reevaluate()
end
