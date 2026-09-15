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

--- A fresh AceEvent-embedded table per receiver, so no two receivers ever share one.
function NS.NewBusTarget()
    local t = {}
    AceEvent:Embed(t)
    return t
end

NS.MSG = {
    LAYOUT     = "Ka0s_PartyFrameEnhanced_LayoutChanged",
    CONFIG     = "Ka0s_PartyFrameEnhanced_ConfigChanged",
    VISIBILITY = "Ka0s_PartyFrameEnhanced_VisibilityChanged",
    PROFILE    = "Ka0s_PartyFrameEnhanced_ProfileChanged",
}
