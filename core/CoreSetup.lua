local addonName, NS = ...

-- core/CoreSetup.lua — the LibKa0s-Core-1.0 seam: the secret-safe stringifier, the prefixed chat
-- printer, the class-color resolver, the shared window skin and the close-button factory.
--
-- After core/Namespace.lua (NS.PREFIX) and before everything that prints: core/PerfSetup.lua and
-- every settings file take NS.Print as a load-time upvalue.

NS.Util = NS.Util or {}
local Util = NS.Util

-- The one cause clause every degraded seam appends its own "so <what> is unavailable" to.
NS.LIBKA0S_MISSING = "The LibKa0s library is missing from this installation of Party Frame " ..
    "Enhanced (expected in libs/LibKa0s)"

local lib = LibStub and LibStub("LibKa0s-Core-1.0", true)

if not lib then
    -- Degrade, never error: settings files capture `local print = NS.Print` at load, so a nil
    -- printer would take the settings UI down and a no-op one would make /pfe answer nothing. These
    -- are short working fallbacks, and "not installed" is said ONCE, on the first line printed.
    local function probeConcat(v) return table.concat({ v }) end
    function NS.IsConcatSafe(v)
        return (pcall(probeConcat, v))
    end

    function NS.SafeToString(v)
        if v == nil then return "nil" end
        if type(v) == "boolean" then return tostring(v) end
        if NS.IsConcatSafe(v) then return tostring(v) end
        return "<secret>"
    end

    -- The class-color resolver the target and pet frames call on every render: a working
    -- fallback, following the library's three rules (options-ui-§17) — the stored alpha survives,
    -- an unresolvable class falls through to the stored swatch, the swatch is read in both modes.
    function NS.ResolveColor(stored, on, unit)
        if type(stored) ~= "table" then stored = {} end
        local r, g, b, a = stored.r or 1, stored.g or 1, stored.b or 1, stored.a or 1
        if not on then return r, g, b, a end
        local ok, _, token = pcall(UnitClass, unit or "player")
        local c = (ok and type(token) == "string" and type(RAID_CLASS_COLORS) == "table")
            and RAID_CLASS_COLORS[token] or nil
        if type(c) ~= "table" or type(c.r) ~= "number" then return r, g, b, a end
        return c.r, c.g, c.b, a
    end

    -- The shared chrome degrades to nothing rather than to a hand-copied backdrop: SKIN's values are
    -- the contract (standalone-windows), and a host copy is the one that goes stale. SKIN is an empty
    -- table so a reader may index it without a guard; MakeCloseButton answers nil, as the library's
    -- own does where CreateFrame is unavailable.
    NS.SKIN            = {}
    NS.ApplySkin       = function() end
    NS.MakeCloseButton = function() return nil end

    -- The pcalled event registration helper (events-frames-taint-§1), one rung: the pcall and the
    -- once-only append to the caller's `rejected` list, no C_EventUtils front gate. The shape is
    -- the Core version-8 doc's Degradation note; a stub is the path for a missing library, not a
    -- second implementation.
    local function safeRegister(method, target, event, rejected, ...)
        if pcall(method, target, event, ...) then return true end
        if type(rejected) == "table" then
            for i = 1, #rejected do if rejected[i] == event then return false end end
            rejected[#rejected + 1] = event
        end
        return false
    end
    NS.SafeRegisterEvent = function(t, e, h, r) return safeRegister(t.RegisterEvent, t, e, r, h) end
    NS.SafeRegisterUnitEvent = function(f, e, r, ...)
        return safeRegister(f.RegisterUnitEvent, f, e, r, ...)
    end
    NS.SafeRegisterEvents = function(t, events, h, r)
        local n = 0
        for _, e in ipairs(events) do if safeRegister(t.RegisterEvent, t, e, r, h) then n = n + 1 end end
        return n
    end

    local announced = false
    function NS.Print(...)
        local parts = { NS.PREFIX }
        for i = 1, select("#", ...) do parts[i + 1] = NS.SafeToString((select(i, ...))) end
        if not DEFAULT_CHAT_FRAME then return end
        if not announced then
            announced = true
            DEFAULT_CHAT_FRAME:AddMessage(NS.SafeToString(NS.PREFIX) .. " " ..
                NS.LIBKA0S_MISSING .. "; running on reduced built-in fallbacks.")
        end
        DEFAULT_CHAT_FRAME:AddMessage(table.concat(parts, " "))
    end
    Util.print = NS.Print
    return
end

NS.IsConcatSafe = lib.IsConcatSafe
NS.SafeToString = lib.SafeToString
NS.ResolveColor = lib.ResolveColor

-- The pcalled event registration helper (events-frames-taint-§1, Core minor 8). Every RegisterEvent
-- and RegisterUnitEvent in core/, modules/ and settings/ goes through one of these three, with
-- NS.RejectedEvents (core/State.lua) as the list: one retired name then costs only itself, and the
-- refused names are reachable from `/pfe status`.
NS.SafeRegisterEvent     = lib.SafeRegisterEvent
NS.SafeRegisterUnitEvent = lib.SafeRegisterUnitEvent
NS.SafeRegisterEvents    = lib.SafeRegisterEvents

-- The shared window edge, published flat so a module reaches it by name (standalone-windows).
NS.SKIN      = lib.SKIN
NS.ApplySkin = lib.ApplySkin

-- WRAPPED, TO SAY WHO IS ASKING, and the wrapper is a MUST (standalone-windows). The library draws
-- the catalog's `close` mark only when told which FOLDER to build the path from; a two-argument call
-- silently draws the fallback glyph and nothing can see it (anti-patterns #64, #65). Every close
-- control this addon ever builds goes through here, so
--   grep -rn 'MakeCloseButton(' --include='*.lua' . | grep -v '/libs/'
-- returns this definition and its callers and nothing else. No caller yet: the two windows this
-- addon shows (the debug console, the perf panel) draw their own marks inside the library.
NS.MakeCloseButton = function(parent, onClick)
    return lib.MakeCloseButton(parent, onClick, addonName)
end

-- The prefix goes in as a FUNCTION, so a later change to NS.PREFIX is not frozen out at load.
local printer = lib:New({ prefix = function() return NS.PREFIX end })

-- NS.Print and NS.Util.print MUST be the same function object: AceAddon:NewAddon(NS, …,
-- "AceConsole-3.0") stamps AceConsole's :Print over NS.Print, and core/PartyFrameEnhanced.lua
-- reclaims it from NS.Util.print (architecture-§2, anti-pattern #36).
NS.Print = printer.Print
Util.print = NS.Print
