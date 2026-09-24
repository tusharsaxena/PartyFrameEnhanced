local addonName, NS = ...

-- core/Bus.lua — the closed cross-module message bus (architecture-§4), and the LibKa0s-Bus-1.0
-- seam.
--
-- Modules never reach into each other's tables to trigger work. Each message has exactly ONE sender
-- (the file named below), and each receiver registers on its OWN target from NS.NewBusTarget(),
-- because CallbackHandler keys callbacks by (message, target) and a second receiver on a shared
-- object silently replaces the first (anti-pattern #32). docs/ARCHITECTURE.md carries the same table.
--
--   LAYOUT      sender: modules/Providers.lua. The unit → party-frame map changed. No payload;
--               consumers read NS.Providers.FrameFor(unit).
--   CONFIG      sender: settings/Schema.lua (the single write seam). A setting changed. Payload: the
--               section — "master", "general", "castbar", "target" or "pet".
--   VISIBILITY  sender: core/PartyFrameEnhanced.lua (NS.PublishVisibility). Something every
--               element's show decision reads changed: combat, enable, preview, suspend/resume.
--   PROFILE     sender: core/PartyFrameEnhanced.lua. The whole profile was replaced (switch, copy,
--               reset). Consumers rebuild from current settings.

local AceEvent = LibStub("AceEvent-3.0")

-- The publish target. SendMessage on it reaches receivers registered on any AceEvent target. Host
-- code on purpose: sending is not a registration, so it has no part in the stand-down record.
NS.bus = NS.bus or {}
AceEvent:Embed(NS.bus)

-- ── the bus as the stand-down seam (slash-commands-§7) ────────────────────────────────────────
--
-- A disabled addon has EVERY registration it owns actually unregistered, and a message registration
-- is a registration. The modules' own Suspend hooks tear down their game-event frames; the record
-- tears down the bus, because putting a `UnregisterAllMessages` in each module's Suspend is nine
-- places to forget and the tenth module is the one that forgets. Every receiver comes from
-- NS.NewBusTarget, so the record is the one place that can know them all.
--
-- The record is LibKa0s-Bus-1.0's (docs/api/Bus/version-1-docs.md): it remembers what each target
-- is registered for, takes events and messages down at the stand-down, and replays the record as it
-- is NOW at the stand-up, so a module that dropped or gained a registration while the addon was
-- down comes back right (performance-§6). A registration made while down is recorded and goes live
-- at the stand-up, and a stand-up is refused while the latch still reads down.
local Bus = LibStub and LibStub("LibKa0s-Bus-1.0", true)

if not Bus then
    -- Degraded: the payload is missing. The untracked-target stub the Bus API document's Worked
    -- example prescribes (options-ui-§1 names the shape). Receivers still get a private target, so
    -- the receiver rule holds, but nothing is recorded: a disable leaves the bus registrations live.
    -- docs/ARCHITECTURE.md's Known Limitations states it. This build is already without Options,
    -- Slash and Lifecycle, and core/CoreSetup.lua has announced that.
    Bus = {
        New = function(_, d)
            return {
                name = d and d.name,
                NewTarget = function()
                    local ace = LibStub and LibStub("AceEvent-3.0", true)
                    if not ace then return nil end
                    local t = {}
                    ace:Embed(t)
                    return t
                end,
                StandDown = function() return 0 end,
                StandUp   = function() return 0, {} end,
            }
        end,
        Catalog = function(_, messages) return messages end,
    }
end

-- Published for introspection only: tests/test_surface_parity.lua holds the stub to the live major.
NS.__busLib = Bus

-- The record asks the latch through a closure: NS.IsStoodDown is defined in core/LifecycleSetup.lua,
-- which loads after this file.
NS.busRecord = Bus:New({ name = addonName, isDown = function() return NS.IsStoodDown() end })

--- A fresh AceEvent-embedded table per receiver, so no two receivers ever share one.
function NS.NewBusTarget() return NS.busRecord:NewTarget() end

--- Every bus receiver actually unregistered — events and messages both. Answers the entry count.
function NS.BusStandDown() return NS.busRecord:StandDown() end

--- Every bus receiver back, from the record as it is NOW. A replayed entry the client refused is
--- dropped from the record, appended to NS.RejectedEvents and named on the debug console; answers the
--- number replayed.
function NS.BusStandUp()
    local replayed, rejected = NS.busRecord:StandUp()
    if #rejected > 0 then
        -- The same host-owned list every SafeRegister* site writes (core/State.lua), each name once,
        -- so `/pfe status` names a refusal whichever path met it. The record names an entry
        -- "<kind>:<name>"; only an event is a name the client refuses.
        local list = NS.RejectedEvents
        for _, entry in ipairs(rejected) do
            local name = entry:match("^event:(.+)$")
            local seen = name == nil
            for i = 1, #list do seen = seen or list[i] == name end
            if not seen then list[#list + 1] = name end
        end
        if NS.Debug then NS.Debug("Bus", "rejected on stand-up: %s", table.concat(rejected, ", ")) end
    end
    return replayed
end

-- Declared once and read strictly: a mistyped key raises at the call site, for a sender as well as
-- a receiver (Bus.Catalog).
NS.MSG = Bus.Catalog(addonName, {
    LAYOUT     = "Ka0s_PartyFrameEnhanced_LayoutChanged",
    CONFIG     = "Ka0s_PartyFrameEnhanced_ConfigChanged",
    VISIBILITY = "Ka0s_PartyFrameEnhanced_VisibilityChanged",
    PROFILE    = "Ka0s_PartyFrameEnhanced_ProfileChanged",
})
