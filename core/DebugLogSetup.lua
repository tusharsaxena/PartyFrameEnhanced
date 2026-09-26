local addonName, NS = ...

-- core/DebugLogSetup.lua — the LibKa0s-DebugLog-1.0 seam (debug-logging). The console, the copy
-- window, both formatters, the line buffer (its size is the library's MAX_BUFFER) and the enable
-- seam are the library's. This file supplies the frame-name prefix, the title, the monospace font,
-- where the flag lives, what the [Init] line says, and the diagnostics report's brand, chat line
-- and sections hook.
--
-- After core/Constants.lua (FONT_MONO), core/State.lua (the flag) and core/CoreSetup.lua (the
-- printer), before anything that calls NS.Debug.

local lib = LibStub and LibStub("LibKa0s-DebugLog-1.0", true)

if not lib then
    -- Degrade, never error. Every member the addon calls, and SetEnabled still flips OUR flag and
    -- acknowledges it — a player who types `/pfe debug on` must not be told nothing happened. What is
    -- lost is the window, said once. No formatter is copied here: nothing outside the library calls
    -- one, and a copy is the drift the extraction exists to end.
    local missing = NS.LIBKA0S_MISSING .. ", so the debug console window is unavailable."
    local announced = false
    local function sayOnce()
        if announced then return end
        announced = true
        if NS.Print then NS.Print(missing) end
    end

    NS.DebugLog = {
        buffer = {},
        Add             = function() end,
        Debug           = function() end,
        Clear           = function() end,
        Show            = function() sayOnce() end,
        Hide            = function() end,
        Toggle          = function() sayOnce() end,
        IsShown         = function() return false end,
        IsEnabled       = function() return NS.State and NS.State.debug or false end,
        SetEnabled      = function(_, on)
            on = not not on
            if NS.State then NS.State.debug = on end
            if NS.Print then
                NS.Print(NS.L["debug logging %s"]:format(on and "|cff40ff40ON|r" or "|cffff4040OFF|r"))
            end
            if on then sayOnce() end
        end,
        RefreshHeader   = function() end,
        ShowCopy        = function() sayOnce() end,
        UpdateScrollBar = function() end,
        UpdateStatus    = function() end,
        BufferSize      = function() return 0 end,
        LastLine        = function() return nil end,
        FindLine        = function() return nil end,
        MakeCloseButton = function() return nil end,
        -- The diagnostics report (debug-logging-§14) needs the console it writes into, so the stub
        -- says so on the collection's library-absent line, writes nothing and counts 0 lines.
        -- BuildDiagnostics and DebugVerb carry the rest of the instance surface (DebugLog 14.1).
        RunDiagnostics  = function()
            if NS.Print and NS.L then
                NS.Print(NS.L["%s is unavailable: the LibKa0s library did not load."]:format("/pfe diagnostics"))
            end
            return 0
        end,
        BuildDiagnostics = function()
            return { lines = {}, dropped = 0, capped = false, capsHit = false }
        end,
        DebugVerb       = function(self, rest)
            local word = (tostring(rest or ""):match("^%s*(%S*)") or ""):lower()
            if word == "diagnostics" then self:RunDiagnostics() return true end
            if word == "on" or word == "off" then self:SetEnabled(word == "on") return true end
            return false
        end,
        ConsoleCheckbox = function()
            return {
                label   = NS.L["Debug console"],
                tooltip = missing,
                get = function() return false end,
                set = function() sayOnce() end,
            }
        end,
    }
    NS.Debug = NS.DebugLog.Debug
    return
end

NS.DebugLog = lib:New({
    -- Seeds PartyFrameEnhancedDebugWindow and friends, and their UISpecialFrames entries.
    name      = addonName,
    -- The FOLDER name the console's close/copy/clear marks build their paths from. A different
    -- question from `name`, answered with the same string here.
    addonName = addonName,
    title     = "Party Frame Enhanced",
    -- The full brand, named in both diagnostics markers so a paste holding several addons' reports
    -- can be split. The same spelling settings/Slash.lua gives the dispatcher.
    brandName = "Ka0s Party Frame Enhanced",
    font      = NS.Constants.FONT_MONO,
    slash     = "/pfe",

    -- The flag stays ours and session-only (debug-logging-§5): never in SV, reset every /reload.
    isEnabled  = function() return NS.State and NS.State.debug or false end,
    setEnabled = function(on) if NS.State then NS.State.debug = on end end,

    -- Call-time forwarders: NS.Print is reclaimed from AceConsole in a file that loads later.
    print        = function(line) NS.Print(line) end,
    safeToString = function(v) return NS.SafeToString(v) end,

    initSummary = function()
        local schemaVer = NS.db and NS.db.global and NS.db.global.schemaVersion
        local profile = NS.db and NS.db.GetCurrentProfile and NS.db:GetCurrentProfile()
        local provider = NS.Providers and NS.Providers.ActiveLabel and NS.Providers.ActiveLabel()
        return ("%s v%s, schema v%s, profile '%s', frames '%s'"):format(
            NS.SafeToString(NS.name), NS.SafeToString(NS.version),
            NS.SafeToString(schemaVer or "?"), NS.SafeToString(profile or "?"),
            NS.SafeToString(provider or "none"))
    end,

    -- The diagnostics report's sections (debug-logging-§14), asked for each time a report runs:
    -- modules/Diagnostics.lua loads after this file.
    diagnostics = function() return NS.Diagnostics and NS.Diagnostics.Sections() or {} end,

    -- The report's one chat line, through the locale (localization-§1). The report BODY is English
    -- diagnostic text, like every trace line, and never goes through NS.L.
    L = {
        DIAG_WRITTEN = NS.L["Diagnostic report written to the debug console: %d lines. Use Copy to share it."],
    },

    -- So a console opened by `/pfe debug` moves the checkbox on an already-open options panel.
    onVisibilityChanged = function()
        if NS.Helpers and NS.Helpers.RefreshAllPanels then NS.Helpers.RefreshAllPanels() end
    end,
})

-- The gated sink, bound bare so call sites read NS.Debug("Cast", "%s start", unit).
NS.Debug = NS.DebugLog.Debug
