local _, NS = ...

-- modules/Diagnostics.lua — this addon's sections of `/pfe diagnostics` and `/pfe debug diagnostics`
-- (debug-logging-§14, DX-PF).
--
-- THE LIBRARY WRITES EVERYTHING AROUND THESE. LibKa0s-DebugLog-1.0's RunDiagnostics writes both
-- markers, the identity header (the [Init] summary, client build, locale, the debug flag, both
-- combat reads, the running LibKa0s minors), one pcall per section so a raise costs one line, the
-- cap and the truncated line, and it appends through the ungated sink without clearing anything.
-- core/DebugLogSetup.lua hands it `Sections` at RUN time, so this file's position in the TOC is
-- conventional rather than load-bearing: every seam below is reached through NS when a report runs.
--
-- READ STATE, NEVER ACT (STD-05). No setting written, no secure write queued, no event, message or
-- timer registered, nothing shown, hidden, resolved or built. The report runs while the addon is
-- stood down and in combat, so it calls no protected API. `out:add` stringifies every argument
-- through safeToString before its format sees it, so every value below is passed RAW and never
-- compared, concatenated or tested first: an element field can hold a secret the client handed a
-- paint call.
--
-- WHAT IT NEVER READS (DX-PF): a party member's cast (UnitCastingInfo / UnitChannelInfo), a fade
-- frame's alpha, UnitIsUnit on a compound token, or GetPoint on a Blizzard or EllesmereUI frame.
-- Positions come from the stored config and from Anchor's own memo of what it last applied; a
-- frame is reported by NAME.

NS.Diagnostics = NS.Diagnostics or {}
local Diagnostics = NS.Diagnostics

-- Printed whatever their value (DX-PF's always-print rows): the switches a "nothing shows" report
-- turns on first.
local ALWAYS = { "enabled", "locked", "visibility", "general.provider", "general.includePlayer" }

-- The LibKa0s majors this addon consumes through a setup file; one missing is a degraded arm.
local CONSUMED = {
    "Core", "Env", "Compat", "Lifecycle", "Bus", "Schema", "Media", "DebugLog", "Slash", "Launcher",
    "Options", "Perf",
}

-- The element fields worth a line, per kind of element. Printed unconditionally, in this order, so
-- no field is ever tested before it is stringified.
local CAST_FIELDS = {
    { "state", "state" }, { "registered", "__registered" }, { "ticking", "__ticking" },
    { "hiddenWhy", "__hiddenWhy" }, { "previewing", "__previewing" },
}
local BUTTON_FIELDS = {
    { "registered", "__registered" }, { "allowed", "__allowed" },
    { "driverWant", "__driverWant" }, { "driver", "__driver" },
    { "clicksWant", "__clicksWant" }, { "clicks", "__clicks" }, { "pending", "__pending" },
}

-- ── small readers ───────────────────────────────────────────────────────────────────────────

--- A frame's global name, pcall'd; "unnamed" when it has none, "-" for no frame at all.
local function frameName(f)
    if f == nil then return "-" end
    local ok, name = pcall(f.GetName, f)
    if ok and name ~= nil then return name end
    return "unnamed"
end

--- Whether one of OUR frames is shown, pcall'd: a secure button is read under a guard too.
local function shown(f)
    if f == nil then return "-" end
    local ok, v = pcall(f.IsShown, f)
    if ok then return v end
    return "unreadable"
end

--- A client read, pcall'd: the value, or "unreadable".
local function read(fn, ...)
    local ok, v = pcall(fn, ...)
    if ok then return v end
    return "unreadable"
end

local function classToken(unit)
    local ok, _, token = pcall(UnitClass, unit)
    if ok then return token end
    return "unreadable"
end

-- ── the sections ────────────────────────────────────────────────────────────────────────────

-- The host half of the identity header: the stored schema, the profile, and the latch.
local function identity(out)
    local db = NS.db
    out:add("State", "schema: stored=%s code=%s profile=%s", db and db.global.schemaVersion,
        NS.SCHEMA_VERSION, db and db:GetCurrentProfile())
    local lc = NS.lifecycle
    out:add("State", "latch: enabled=%s stoodDown=%s", NS.GetSetting("enabled"), lc:IsDown())
    out:joined("State", "holds:", lc:Holds())
    out:add("State", "state: preview=%s unlocked=%s inCombat=%s inParty=%s", NS.State.preview,
        NS.Anchor.IsUnlocked(), NS.State.inCombat, NS.State.inParty)
    out:add("State", "perf: on=%s suspended=%s; test mode: none (unlocking is the preview)",
        NS.Perf.on, NS.Perf.suspended)
end

-- `path = value (default)` for every schema row off its default, plus the always rows.
local function settings(out)
    out:nonDefaults(NS.Schema, function(row) return NS.GetSetting(row.path) end, nil,
        function(row, v) return NS.FormatSchemaValue(row, v) end, { always = ALWAYS })
end

-- The party the addon sees: class tokens only, which are never secret for a party member. No
-- UnitExists: .luacheckrc bans it (core/Compat.lua's "No UnitExists shim"), and a nil class
-- already says the slot is empty.
local function party(out)
    local Units = NS.Units
    out:add("Party", "party: inParty=%s inRaid=%s", Units.InParty(), read(IsInRaid))
    for _, unit in ipairs(Units.LIST) do
        out:add("Party", "unit %s: included=%s class=%s", unit, Units.IsIncluded(unit),
            classToken(unit))
    end
end

local function standInOf(f)
    return NS.StandIn.IsStandIn(f) and " (stand-in)" or ""
end

-- Which frame system resolved, and which frame shows each unit, by name.
local function frames(out)
    local P = NS.Providers
    if NS.IsStoodDown() then
        out:add("Frames", "frames: stood down (provider suspended, map released)")
        return
    end
    out:add("Frames", "frames: setting=%s active=%s label=%s", NS.GetSetting("general.provider"),
        P.ActiveId(), P.ActiveLabel())
    for _, unit in ipairs(NS.Units.LIST) do
        local f = P.FrameFor(unit)
        out:add("Frames", "frame %s: %s%s", unit, frameName(f), standInOf(f))
    end
    local rs = P.ResolveState()
    out:add("Frames", "resolve: suspended=%s scheduled=%s stale=%s", rs.suspended, rs.scheduled,
        rs.stale)
    out:add("Frames", "stand-in shown=%s; EllesmereUI loaded=%s raidFrames=%s header=%s",
        NS.StandIn.IsShown(), NS.Compat.IsAddOnLoaded("EllesmereUI"),
        NS.Compat.IsAddOnLoaded("EllesmereUIRaidFrames"), ERFPartyHeader ~= nil)
end

--- "POINT x y" from three values, each stringified first.
local function anchorText(out, point, x, y)
    return out:str(point) .. " " .. out:str(x) .. " " .. out:str(y)
end

-- Each feature's free-placement holder: the stored anchor and the one Anchor last applied.
local function placement(out)
    local A = NS.Anchor
    for _, key in ipairs(A.__order) do
        local spec = A.__features[key]
        local cfg = spec.config() or {}
        local p = cfg.position
        local stored = "default"
        if type(p) == "table" then stored = anchorText(out, p.point, p.x, p.y) end
        local h = spec.holder
        out:add("Place", "place %s: mode=%s stored=%s applied=%s holderShown=%s", key,
            cfg.anchorMode, stored, anchorText(out, h.__aPoint, h.__aX, h.__aY), shown(h))
    end
end

local function elementLine(out, key, unit, el, fields)
    local parts = { "shown=" .. out:str(shown(el)) }
    for _, field in ipairs(fields) do
        parts[#parts + 1] = field[1] .. "=" .. out:str(el[field[2]])
    end
    out:joined("Elem", "elem " .. key .. " " .. unit .. ":", parts)
end

-- Per feature per unit, the element's own state. A stand-down leaves these behind, so they print
-- stood down too: a secure driver released in combat is exactly what this shows.
local function elements(out)
    local A = NS.Anchor
    for _, key in ipairs(A.__order) do
        local spec = A.__features[key]
        local fields = spec.secure and BUTTON_FIELDS or CAST_FIELDS
        for _, unit in ipairs(NS.Units.LIST) do
            out:section(key .. " " .. unit, elementLine, key, unit, spec.elements[unit], fields)
        end
    end
end

-- The range fade: what it is doing, how many frames it hooked, and the unit map its hooks read.
local function rangeFade(out)
    local RF = NS.RangeFade
    if NS.IsStoodDown() then
        out:add("Fade", "fade: stood down (hooks inert, fade frames hidden)")
        return
    end
    out:add("Fade", "fade: mode=%s listening=%s hooked=%s", RF.Mode(), RF.Listening(), RF.HookedCount())
    local map, parts = RF.UnitMap(), {}
    for _, unit in ipairs(NS.Units.LIST) do
        parts[#parts + 1] = unit .. "=" .. out:str(frameName(map[unit]))
    end
    out:joined("Fade", "fade map:", parts)
end

-- The deferred secure-write queue and the one listener a stood-down addon keeps for it.
local function secure(out)
    out:add("Secure", "secure: pending=%s", NS.PendingSecureCount())
    out:list("Secure", "queued keys:", NS.PendingSecureKeys())
    out:add("Secure", "flush listener armed=%s", NS.PendingRegenArmed())
    out:add("Secure", "blocked actions this session: %s", NS.BlockedActionCount())
end

local function degradedArms()
    local missing = {}
    for _, name in ipairs(CONSUMED) do
        if not LibStub("LibKa0s-" .. name .. "-1.0", true) then missing[#missing + 1] = name end
    end
    return missing
end

-- The events the client refused, the bus arm, and any LibKa0s major that did not load.
local function events(out)
    out:list("Events", "events: rejected", NS.RejectedEvents)
    local live = LibStub("LibKa0s-Bus-1.0", true)
    out:add("Events", "bus: record=%s", (live ~= nil and NS.__busLib == live) and "LibKa0s-Bus-1.0"
        or "untracked stub")
    local missing = degradedArms()
    if #missing == 0 then
        out:add("Events", "degraded arms: none")
    else
        out:joined("Events", "degraded arms:", missing)
    end
end

--- The sections, in report order. core/DebugLogSetup.lua's descriptor calls this each time a
--- report runs.
function Diagnostics.Sections()
    return {
        { "identity",  identity },
        { "settings",  settings },
        { "party",     party },
        { "frames",    frames },
        { "placement", placement },
        { "elements",  elements },
        { "rangefade", rangeFade },
        { "secure",    secure },
        { "events",    events },
    }
end
