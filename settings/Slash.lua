local _, NS = ...
NS.Slash = NS.Slash or {}
local Sl = NS.Slash

-- settings/Slash.lua — NS.COMMANDS and the LibKa0s-Slash-1.0 descriptor (slash-commands).
--
-- The dispatcher, help renderer, formatters, list builder and value parser are the library's. What
-- stays here is the ordered verb table (positional {name, desc, fn} triples — named fields would be
-- invisible to the library) and the host verbs that reach into this addon's own state. The table is
-- passed IN: the landing page renders the same one. Every word a player reads goes through NS.L
-- (localization-§1).

local print = NS.Print
local L = NS.L

local SlashLib = LibStub and LibStub("LibKa0s-Slash-1.0", true)
local cli   -- built at the bottom; every handler reaches it at CALL time

local runResetAll, runDebug, runPerf, runProfile, runLock, runStatus, runEnabled

NS.COMMANDS = {
    {"help",     L["List available commands"],
        function() cli:PrintHelp() end},
    {"config",   L["Open the settings panel"],
        function() NS.OpenOptionsPanel() end},
    {"enable",   L["Turn the addon on"],
        function() runEnabled(true) end},
    {"disable",  L["Turn the addon off without unloading it"],
        function() runEnabled(false) end},
    {"list",     L["List every setting and its current value"],
        function() cli:CliList() end},
    {"get",      L["Print a setting's current value \226\128\148 `/pfe get <path>`"],
        function(rest) cli:CliGet(rest) end},
    {"set",      L["Set a setting \226\128\148 `/pfe set <path> <value>` (try /pfe list)"],
        function(rest) cli:CliSet(rest) end},
    {"reset",    L["Reset one setting to its default \226\128\148 `/pfe reset <path>`"],
        function(rest) cli:CliReset(rest) end},
    {"resetall", L["Reset every setting to defaults"],
        function() runResetAll() end},
    {"resetposition", L["Move every free-placement stack back to its default position"],
        function()
            NS.Anchor.ResetPositions()
            print(L["Positions reset"])
        end},
    {"lock",     L["Lock the elements in place and leave preview mode"],
        function() runLock(true) end},
    {"unlock",   L["Unlock the elements to drag them, with placeholder content"],
        function() runLock(false) end},
    {"status",   L["Show which party frames were found and what each feature is doing"],
        function() runStatus() end},
    {"debug",    L["Toggle the debug console \226\128\148 `on`/`off` enable/disable logging"],
        function(rest) runDebug(rest) end},
    {"perf",     L["Measure performance \226\128\148 try `/pfe perf` for the workflow"],
        function(rest) runPerf(rest) end},
    {"version",  L["Print the addon version"],
        function() print(("v%s"):format(NS.Version())) end},
    {"profile",  L["Profile management \226\128\148 try `/pfe profile` for the list"],
        function(rest) runProfile(rest) end},
}

-- ── the disabled surface (slash-commands-§2, §7) ─────────────────────────────────
--
-- THE GATE IS THE LIBRARY'S, AND THE HOST DECLARES ONLY WHAT IS ADDON-SPECIFIC. LibKa0s-Slash-1.0
-- minor 13 takes `isEnabled` and refuses, on ONE tagged line naming `/pfe enable`, exactly the verbs
-- that are not on the live set. The wording lives in `cli:DisabledLine()` and is the collection's,
-- never re-spelled here: eleven addons each phrasing it their own way is the drift the shared
-- printer exists to end.
--
-- WHAT IS LIVE, AND IT IS A WIDENING RATHER THAN A NARROWING. The library's default is the
-- standard's twelve reserved verbs — help, config, version, enable, disable, debug, perf, get, set,
-- list, reset, resetall — plus the bare `/pfe`, which opens the settings panel. A player must be
-- able to READ AND REPAIR SETTINGS and to REACH THE PANEL while the addon is off, which is precisely
-- when they are most likely to need to, and `enable` above all or the pair is one-way. This addon
-- adds two of its own on that same reasoning rather than as exceptions to it:
--
--   status   a diagnostic, exactly like `debug`. It reads public seams and changes nothing, and its
--            own first flag is `addon disabled` — so refusing it would delete the answer to the
--            question a player actually asks a silent addon.
--   profile  settings management, in the class of the schema CLI: it switches, copies, creates and
--            resets where settings live, and draws nothing.
--
-- Passing this table REPLACES the library's default rather than adding to it, so the twelve are
-- spelled out here too. Widening is conformant and owes no deviation row; what a host must never do
-- is REFUSE something on the standard's live set, and nothing is missing from the list below.
--
-- WHAT IS LEFT, AND IT IS THE REFUSAL §2 ASKS FOR: `resetposition`, `lock` and `unlock`. All three
-- drive the display — unlocking IS this addon's preview switch (options-ui-§15) — so a disabled
-- addon answers them on the one line and does nothing else.
local LIVE_WHILE_DISABLED = {
    "help", "config", "version", "enable", "disable", "debug", "perf",
    "get", "set", "list", "reset", "resetall",
    "status", "profile",
}

-- Published for introspection only: tests/test_slash.lua and tests/test_disabled.lua walk
-- NS.COMMANDS against it and drive every verb on each side, rather than restating the list.
Sl.__liveWhileDisabled = {}
for _, verb in ipairs(LIVE_WHILE_DISABLED) do Sl.__liveWhileDisabled[verb] = true end

-- ── host verbs ────────────────────────────────────────────────────────────────────────────────

function runResetAll()
    -- The same helper the panel's Reset all settings button reaches, so the two cannot diverge. The
    -- acknowledgment sits inside the guard: printing it when nothing ran would claim a reset.
    if NS.Helpers and NS.Helpers.RestoreAllDefaults then
        NS.Helpers.RestoreAllDefaults()
        print(L["All settings reset to defaults"])
    else
        print(L["Cannot reset settings \226\128\148 the settings helpers failed to load"])
    end
end

-- Through the write seam, so the checkbox, `/pfe set locked` and this verb take one path. The row
-- may refuse an unlock in combat (modules/Preview.lua), so the reply reads the stored value back
-- rather than assuming.
function runLock(locked)
    NS.SetByPath("locked", locked)
    if NS.RefreshOptionsPanel then NS.RefreshOptionsPanel() end
    if NS.GetSetting("locked") ~= locked then return end
    print(locked and L["Elements locked"] or L["Elements unlocked \226\128\148 drag them into place"])
end

--- Flip the lock. THE ONE TOGGLE: the launcher's left click (core/LauncherSetup.lua, launcher-§2's
--- rung (b)) lands here, so the button drives the same `locked` path the Lock frame checkbox and
--- `/pfe lock` / `/pfe unlock` drive, through the same seam, and holds no copy of that state. An
--- unlock the row refuses leaves the lock where it was and runLock says nothing, which is the same
--- answer the checkbox gives.
---
--- REFUSED WHILE THE ADDON IS DISABLED (launcher-§2, slash-commands-§7). Rung (b) drives a preview
--- switch and a preview switch is a feature, so the left button prints the one line and does nothing
--- else — in particular it writes no SavedVariables. The line is `cli:DisabledLine()`, the same one
--- the slash gate prints, because the launcher MUST NOT re-spell it. Right-click is untouched: it
--- opens the settings panel in either state, which is one of the two routes the standard nominates
--- for reaching the panel, and rung (c)'s carve-out is the same rule read from the other side.
function NS.ToggleLock()
    if NS.GetSetting("enabled") ~= true then return print(cli:DisabledLine()) end
    runLock(NS.GetSetting("locked") ~= true)
end

-- `/pfe enable` and `/pfe disable` are RESERVED VERBS and are ALIASES, never a second switch
-- (slash-commands-§2). They write the `enabled` path the Master controls *Enable Party Frame
-- Enhanced* checkbox writes, through the same seam, and hold no state of their own -- no second key,
-- no session flag -- so the checkbox and the verbs can never show the player two different answers
-- and one onChange (NS.PublishVisibility) runs whichever surface was used.
--
-- The echo is the library's own `path = value` formatter, read back from the STORE after the write
-- (slash-commands-§5), so the line reads exactly as `/pfe set enabled true` reads. In a build with
-- no LibKa0s the echo degrades to one honest "unavailable" line while the WRITE still lands: the
-- pair must never be one-way, and a player who cannot read the acknowledgment must still be able to
-- turn the addon back on.
function runEnabled(on)
    NS.SetByPath("enabled", on)
    if NS.RefreshOptionsPanel then NS.RefreshOptionsPanel() end
    cli:CliGet("enabled")
end

-- `/pfe status`: what the addon found and what it is doing, for a player asking "why is nothing
-- showing". Reads only public seams; changes nothing.
local FEATURES = {
    { "castbar", L["Cast bars"] }, { "target", L["Target frames"] }, { "pet", L["Pet frames"] },
}

local function featureState(cfg)
    if not cfg.enabled then return L["off"] end
    return cfg.anchorMode == "free" and L["on, free placement"] or L["on, attached"]
end

-- Which way the out-of-range fade is running (modules/RangeFade.lua).
local function rangeFadeState()
    local mode = NS.RangeFade.Mode()
    if mode == "copy" then return L["copied from %s"]:format(NS.Providers.ActiveLabel() or "?") end
    if mode == "range" then return L["own range check (classic frames)"] end
    if mode == "idle" then return L["waiting for party frames"] end
    return L["off"]
end

local function statusFlags()
    local flags = {}
    if NS.GetSetting("enabled") ~= true then flags[#flags + 1] = L["addon disabled"] end
    if NS.GetSetting("visibility") ~= "always" then
        flags[#flags + 1] = L["visibility %s"]:format(tostring(NS.GetSetting("visibility")))
    end
    if NS.State.preview and not NS.Units.InParty() then
        flags[#flags + 1] = L["unlocked (stand-in)"]
    elseif NS.State.preview then
        flags[#flags + 1] = L["unlocked (your party frames)"]
    elseif not NS.Units.InParty() then
        flags[#flags + 1] = L["not in a party \226\128\148 nothing shows until you join one (try /pfe unlock)"]
    end
    if NS.Anchor.IsUnlocked() then flags[#flags + 1] = L["unlocked"] end
    if NS.Perf.suspended then flags[#flags + 1] = L["suspended by a perf run"] end
    return flags
end

function runStatus()
    print(L["Frame system: %s"]:format(NS.Providers.ActiveLabel() or L["none found"]))
    local parts = {}
    for _, unit in ipairs(NS.Units.LIST) do
        local mark = NS.Providers.FrameFor(unit) and L["frame"] or "\226\128\148"
        if not NS.Units.IsIncluded(unit) then mark = L["off"] end
        parts[#parts + 1] = NS.Units.LABEL[unit] .. ": " .. mark
    end
    print("  " .. table.concat(parts, "  \194\183  "))
    for _, f in ipairs(FEATURES) do
        print("  " .. f[2] .. ": " .. featureState(NS.db.profile[f[1]]))
    end
    print("  " .. L["Range fade: %s"]:format(rangeFadeState()))
    local flags = statusFlags()
    if #flags > 0 then print("  " .. L["Note: %s"]:format(table.concat(flags, ", "))) end
end

-- The guided run lives in LibKa0s-Perf; the library returns lines and this prints them
-- (performance-§4: the verb is the addon's, never registered by the harness).
function runPerf(rest)
    for _, line in ipairs(NS.Perf.OnCommand(rest or "")) do print(line) end
end

-- `/pfe debug` toggles the WINDOW; `on`/`off` go through the one SetEnabled seam (debug-logging-§5).
function runDebug(rest)
    local sub = ((rest or ""):match("^(%S*)") or ""):lower()
    if sub == "on" or sub == "off" then
        NS.DebugLog:SetEnabled(sub == "on")
        return
    end
    NS.DebugLog:Toggle()
end

-- ── /pfe profile ──────────────────────────────────────────────────────────────────────────────

local PROFILE_HELP = {
    { "list",          L["List all profiles"] },
    { "current",       L["Show current profile name"] },
    { "use <name>",    L["Switch to profile"] },
    { "new <name>",    L["Create new profile with defaults"] },
    { "copy <name>",   L["Copy settings from another profile"] },
    { "delete <name>", L["Delete a profile"] },
    { "reset",         L["Reset current profile to defaults"] },
}

local function printProfileHelp()
    print(L["Profile commands"])
    for _, row in ipairs(PROFILE_HELP) do
        print("  " .. SlashLib.FormatRow("/pfe profile " .. row[1], row[2]))
    end
end

local function needsName(verb, fn)
    return function(db, name)
        if name == "" then return print(L["Usage: /pfe profile %s <name>"]:format(verb)) end
        return fn(db, name)
    end
end

local PROFILE_VERBS = {
    list = function(db)
        print(L["Available profiles"])
        local current = db:GetCurrentProfile()
        for _, name in ipairs(db:GetProfiles()) do
            print("  " .. name .. ((name == current) and (" " .. L["(current)"]) or ""))
        end
    end,
    current = function(db)
        print(L["Current profile: %s"]:format(db:GetCurrentProfile()))
    end,
    use = needsName("use", function(db, name)
        db:SetProfile(name)
        print(L["Switched to profile '%s'"]:format(name))
    end),
    -- SetProfile first, then the reset, so the reset lands on the new profile.
    new = needsName("new", function(db, name)
        db:SetProfile(name)
        NS.ResetProfileCounted(db)
        print(L["Created and switched to new profile '%s'"]:format(name))
    end),
    copy = needsName("copy", function(db, name)
        db:CopyProfile(name)
        print(L["Copied settings from profile '%s'"]:format(name))
    end),
    delete = needsName("delete", function(db, name)
        if name == db:GetCurrentProfile() then
            return print(L["Cannot delete the current profile"])
        end
        db:DeleteProfile(name, true)
        print(L["Deleted profile '%s'"]:format(name))
    end),
    reset = function(db)
        NS.ResetProfileCounted(db)
        print(L["Profile reset to defaults"])
    end,
}

function runProfile(rest)
    local db = NS.db
    if not db or not db.SetProfile then
        return print(L["Profile system requires AceDB-3.0"])
    end
    -- Only the verb is lowercased: AceDB profile names are case-sensitive.
    local sub, subarg = (rest or ""):match("^(%S*)%s*(.*)$")
    sub = (sub or ""):lower()
    if sub == "" then return printProfileHelp() end
    local handler = PROFILE_VERBS[sub]
    if not handler then
        print(L["Unknown profile subcommand '%s'"]:format(sub))
        return printProfileHelp()
    end
    return handler(db, subarg)
end

-- ── the dispatcher ────────────────────────────────────────────────────────────────────────────

-- Page order for `/pfe list`. Profiles is omitted: its rows are AceDBOptions'.
local PAGE_ORDER = { "general", "castbar", "target", "pet" }

local function allRows()
    local out = {}
    for _, page in ipairs(PAGE_ORDER) do
        for _, row in ipairs(NS.SchemaForPage(page)) do out[#out + 1] = row end
    end
    return out
end

-- Degrade, never error: /pfe is registered unconditionally, so something must answer it. The host
-- verbs keep working; the schema CLI names the missing library. No formatter, parser or key/value
-- shape of the library's is copied here.
if not SlashLib then
    local missing = " " .. L["is unavailable."] .. " " .. NS.LIBKA0S_MISSING .. "."
    SlashLib = { FormatRow = function(cmd, desc) return cmd .. " \226\128\148 " .. desc end }

    -- The library's own format string, because the stub prints the SAME sentence the gate would:
    -- the wording is the collection's, and a build without LibKa0s is still this collection's addon.
    local DISABLED_LINE = "%s is disabled \226\128\148 enable it with |cFFFFFF00%s|r"

    function SlashLib:New(d)
        local stub = { SetRowAnnotator = function() end }
        stub.DisabledLine = function()
            return DISABLED_LINE:format(d.brandName or d.slash, d.slash .. " enable")
        end
        local function absent(verb)
            return function() print("/pfe " .. verb .. missing) end
        end
        for _, verb in ipairs({ "List", "Get", "Set", "Reset", "ResetAll" }) do
            stub["Cli" .. verb] = absent(verb:lower())
        end
        stub.LandingRows = function()
            local out = {}
            for _, e in ipairs(d.commands) do
                out[#out + 1] = SlashLib.FormatRow("/pfe " .. e[1], e[2])
            end
            return out
        end
        local live = {}
        for _, verb in ipairs(d.liveVerbs or {}) do live[verb] = true end
        local aliases = d.aliases or {}
        local function isDown() return d.isEnabled ~= nil and not d.isEnabled() end
        local function findCommand(verb)
            for _, e in ipairs(d.commands) do
                if e[1] == verb then return e end
            end
        end

        stub.PrintHelp = function()
            print(L["v%s \226\128\148 slash commands"]:format(d.version()))
            -- Under the header and unindented, as the library places it: the index prints in full,
            -- because the player has to be able to SEE `enable` in the list.
            if isDown() then print(stub.DisabledLine()) end
            for _, row in ipairs(stub.LandingRows()) do print("  " .. row) end
        end

        stub.OnSlash = function(stubSelf, msg)
            local raw = (msg or ""):match("^%s*(.-)%s*$") or ""
            -- Bare opens the settings through `config`, as the library does (slash-commands-§4).
            if raw == "" then
                local config = findCommand("config")
                if config then return config[3]("") end
                return stub.PrintHelp()
            end
            local cmd, rest = raw:match("^(%S+)%s*(.*)$")
            cmd = (cmd or ""):lower()
            cmd = aliases[cmd] or cmd
            -- The gate sits AFTER the lookup here too, so a typo still gets `unknown command`: a
            -- misspelling is the addon failing to understand, not the addon refusing. A verb that
            -- is reserved but not registered is unknown too, as the library answers it.
            local entry = findCommand(cmd)
            if entry and isDown() and not live[cmd] then return print(stubSelf:DisabledLine()) end
            if entry then return entry[3](rest or "") end
            print(L["unknown command '%s'"]:format(cmd))
            stub.PrintHelp()
        end
        return stub
    end
end

cli = SlashLib:New({
    slash        = "/pfe",
    slashAliases = { "/partyframeenhanced" },
    commands     = NS.COMMANDS,
    aliases      = { options = "config" },

    -- ASKED AT DISPATCH TIME, NEVER CACHED, so the command after an `/pfe enable` works. It reads
    -- the stored path through the same getter every other reader uses — there is no session flag
    -- and no second copy of the switch anywhere in this addon.
    isEnabled    = function() return NS.GetSetting("enabled") == true end,
    -- The plain-text brand name, and the SAME string core/LauncherSetup.lua gives the LDB object as
    -- `label` (launcher-§1). One brand spelling, not a second invented for this one line.
    brandName    = "Ka0s Party Frame Enhanced",
    liveVerbs    = LIVE_WHILE_DISABLED,

    print   = function(line) print(line) end,
    version = NS.Version,

    -- Through the seam, so a CLI change takes the panel's path: [Set] line, onChange, CONFIG.
    get          = function(path) return NS.GetSetting(path) end,
    set          = function(path, v)
        NS.SetByPath(path, v)
        if NS.RefreshOptionsPanel then NS.RefreshOptionsPanel() end
    end,
    findRow      = function(path) return NS.FindSchemaRow(path) end,
    applyDefault = function(row)
        NS.ApplyDefault(row)
        if NS.RefreshOptionsPanel then NS.RefreshOptionsPanel() end
    end,
    allRows      = allRows,
    groupKey     = function(row) return row.page end,
})

-- Published for introspection only: tests/test_surface_parity.lua compares the two arms.
Sl.__cli = cli

--- The command rows the landing page renders — `/pfe help`'s rows without the chat indent.
function Sl:LandingRows() return cli:LandingRows() end

function Sl:OnSlash(msg) cli:OnSlash(msg) end

function Sl:Register()
    NS.addon:RegisterChatCommand("pfe", function(msg) Sl:OnSlash(msg) end)
    NS.addon:RegisterChatCommand("partyframeenhanced", function(msg) Sl:OnSlash(msg) end)
end
