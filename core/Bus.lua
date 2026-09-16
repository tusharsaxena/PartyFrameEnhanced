local _, NS = ...

-- core/Bus.lua — the closed cross-module message bus (architecture-§4).
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

-- The publish target. SendMessage on it reaches receivers registered on any AceEvent target.
NS.bus = NS.bus or {}
AceEvent:Embed(NS.bus)

-- ── the bus as the stand-down seam (slash-commands-Â§7) ────────────────────────────────────────
--
-- A disabled addon has EVERY registration it owns actually unregistered, and a message registration
-- is a registration. The modules' own Suspend hooks tear down their game-event frames; this file
-- tears down the bus, because putting a `UnregisterAllMessages` in each module's Suspend is nine
-- places to forget and the tenth module is the one that forgets. Every receiver comes from
-- NS.NewBusTarget, so this is the one place that can know them all.
--
-- WHY IT REPLAYS RATHER THAN RE-RUNS THE FILES. Standing back up has to rebuild from CURRENT state
-- (performance-Â§6), and a module's message registrations ARE its current state: they are declared at
-- file scope and never conditional. The conditional ones â Providers' game events, Preview's
-- roster watch â are registered and unregistered through the wrappers below, so the record follows
-- them, and each module's Resume re-decides them anyway.
--
-- THE TEARDOWN BYPASSES THE WRAPPERS ON PURPOSE. NS.BusStandDown unregisters through the raw
-- AceEvent members, so the record survives the stand-down and there is something to replay. A
-- module unregistering for its own reasons goes through the wrapper and the record follows it.
local targets = {}

--- A fresh AceEvent-embedded table per receiver, so no two receivers ever share one.
function NS.NewBusTarget()
    local t = {}
    AceEvent:Embed(t)

    local raw = {
        RegisterEvent         = t.RegisterEvent,
        UnregisterEvent       = t.UnregisterEvent,
        UnregisterAllEvents   = t.UnregisterAllEvents,
        RegisterMessage       = t.RegisterMessage,
        UnregisterMessage     = t.UnregisterMessage,
        UnregisterAllMessages = t.UnregisterAllMessages,
    }
    -- `want` is what this target would be registered for if the addon were up, keyed by kind and
    -- name; `order` keeps the replay deterministic. A handler stored as `false` means "no function
    -- was given", which AceEvent reads as the method named for the event.
    local order, want = {}, {}

    local function remember(kind, name, fn)
        local key = kind .. "\0" .. name
        if want[key] == nil then order[#order + 1] = { kind = kind, name = name, key = key } end
        want[key] = fn or false
    end

    local function forget(kind, name) want[kind .. "\0" .. name] = nil end

    local function forgetKind(kind)
        for _, e in ipairs(order) do
            if e.kind == kind then want[e.key] = nil end
        end
    end

    function t:RegisterEvent(event, fn)
        remember("event", event, fn)
        return raw.RegisterEvent(self, event, fn)
    end

    function t:UnregisterEvent(event)
        forget("event", event)
        return raw.UnregisterEvent(self, event)
    end

    function t:UnregisterAllEvents()
        forgetKind("event")
        return raw.UnregisterAllEvents(self)
    end

    function t:RegisterMessage(message, fn)
        remember("message", message, fn)
        return raw.RegisterMessage(self, message, fn)
    end

    function t:UnregisterMessage(message)
        forget("message", message)
        return raw.UnregisterMessage(self, message)
    end

    function t:UnregisterAllMessages()
        forgetKind("message")
        return raw.UnregisterAllMessages(self)
    end

    targets[#targets + 1] = { target = t, raw = raw, order = order, want = want }
    return t
end

--- Every bus receiver actually unregistered â events and messages both.
function NS.BusStandDown()
    for _, rec in ipairs(targets) do
        rec.raw.UnregisterAllEvents(rec.target)
        rec.raw.UnregisterAllMessages(rec.target)
    end
end

--- Every bus receiver back, from the record as it is NOW rather than from a snapshot taken on the
--- way down.
function NS.BusStandUp()
    for _, rec in ipairs(targets) do
        for _, e in ipairs(rec.order) do
            local fn = rec.want[e.key]
            if fn ~= nil then
                if e.kind == "event" then
                    rec.raw.RegisterEvent(rec.target, e.name, fn or nil)
                else
                    rec.raw.RegisterMessage(rec.target, e.name, fn or nil)
                end
            end
        end
    end
end

NS.MSG = {
    LAYOUT     = "Ka0s_PartyFrameEnhanced_LayoutChanged",
    CONFIG     = "Ka0s_PartyFrameEnhanced_ConfigChanged",
    VISIBILITY = "Ka0s_PartyFrameEnhanced_VisibilityChanged",
    PROFILE    = "Ka0s_PartyFrameEnhanced_ProfileChanged",
}
