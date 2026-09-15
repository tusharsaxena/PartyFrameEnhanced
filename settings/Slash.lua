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

local runResetAll, runDebug, runPerf, runProfile, runLock, runStatus

NS.COMMANDS = {
    {"help",     L["List available commands"],
        function() cli:PrintHelp() end},
    {"config",   L["Open the settings panel"],
        function() NS.OpenOptionsPanel() end},
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
    {"preview",  L["Toggle placeholder content on every element, without unlocking"],
        function()
            if NS.Preview.Toggle() then
                print(NS.State.preview and L["Preview on"] or L["Preview off"])
            end
        end},
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

-- `/pfe status`: what the addon found and what it is doing, for a player asking "why is nothing
-- showing". Reads only public seams; changes nothing.
local FEATURES = {
    { "castbar", L["Cast bars"] }, { "target", L["Target frames"] }, { "pet", L["Pet frames"] },
}

local function featureState(cfg)
    if not cfg.enabled then return L["off"] end
    return cfg.anchorMode == "free" and L["on, free placement"] or L["on, attached"]
end

local function statusFlags()
    local flags = {}
    if NS.GetSetting("enabled") ~= true then flags[#flags + 1] = L["addon disabled"] end
    if NS.GetSetting("visibility") ~= "always" then
        flags[#flags + 1] = L["visibility %s"]:format(tostring(NS.GetSetting("visibility")))
    end
    if NS.State.preview then flags[#flags + 1] = L["preview on"] end
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

    function SlashLib:New(d)
        local stub = { SetRowAnnotator = function() end }
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
        stub.PrintHelp = function()
            print(L["v%s \226\128\148 slash commands"]:format(d.version()))
            for _, row in ipairs(stub.LandingRows()) do print("  " .. row) end
        end
        stub.OnSlash = function(_, msg)
            local raw = (msg or ""):match("^%s*(.-)%s*$") or ""
            if raw == "" then return stub.PrintHelp() end
            local cmd, rest = raw:match("^(%S+)%s*(.*)$")
            cmd = (cmd or ""):lower()
            cmd = (d.aliases or {})[cmd] or cmd
            for _, e in ipairs(d.commands) do
                if e[1] == cmd then return e[3](rest or "") end
            end
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
