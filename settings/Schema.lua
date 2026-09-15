local _, NS = ...

-- settings/Schema.lua — the single source of truth for every user-facing setting (architecture-§5),
-- and the single write seam every writer goes through.
--
-- Each settings/<page>.lua registers its rows through NS.RegisterSchemaRows at file load. The
-- panel (LibKa0s-Options-1.0), the CLI (LibKa0s-Slash-1.0: list/get/set/reset) and the reset paths
-- all walk NS.Schema, so a new option is one row.
--
-- Row fields this addon reads, beyond the library's own (docs/api Options "Row fields"):
--   section  the CONFIG payload for the row: "master", "general", "castbar", "target", "pet".
--            Derived from the path's first segment when absent; flat paths are "master".
--   onChange extra work beyond the CONFIG publish the seam always does.
--
-- NO ROW CARRIES `disabledIf` on a color (options-ui-§17, anti-pattern #74).

NS.Schema = NS.Schema or {}

-- path → row, maintained by RegisterSchemaRows. FindSchemaRow is on the write seam, which a color
-- picker drag reaches every 50 ms, so it is an index lookup rather than a walk.
local byPath = {}

-- ── registration and lookup ───────────────────────────────────────────────────────────────────

function NS.RegisterSchemaRows(rows)
    for _, row in ipairs(rows) do
        NS.Schema[#NS.Schema + 1] = row
        if row.path then byPath[row.path] = row end
    end
end

function NS.FindSchemaRow(path)
    return byPath[path]
end

--- Rows for one page, grouped in first-registration order and ordered by `order` within a group.
--- Sorting on `order` alone would interleave groups and break the tab partition (options-ui-§13).
function NS.SchemaForPage(pageKey)
    local out, groupIndex = {}, {}
    for _, row in ipairs(NS.Schema) do
        if row.page == pageKey then
            out[#out + 1] = row
            local g = row.group or ""
            if groupIndex[g] == nil then groupIndex[g] = #out end
        end
    end
    table.sort(out, function(a, b)
        local ga, gb = groupIndex[a.group or ""], groupIndex[b.group or ""]
        if ga ~= gb then return ga < gb end
        return (a.order or 100) < (b.order or 100)
    end)
    return out
end

-- ── dotted paths ──────────────────────────────────────────────────────────────────────────────

--- The value at a dotted path, or nil. ALLOCATION-FREE, and that is measured rather than tidy:
--- the show decision reads `general.includePlayer` per element per pass and the provider pick reads
--- `general.provider` per resolve, and a `gmatch` walk built an iterator closure every time
--- (tests/perf.lua's resolveUnchanged went 88 → 0 bytes/iter). `sub` over a path this addon owns
--- yields strings Lua has already interned, so the walk creates nothing.
function NS.ResolvePath(tbl, path)
    if type(tbl) ~= "table" or type(path) ~= "string" then return nil end
    local start = 1
    local node = tbl
    while true do
        local dot = path:find(".", start, true)
        local segment = path:sub(start, dot and dot - 1 or -1)
        node = node[segment]
        if dot == nil or node == nil then return node end
        if type(node) ~= "table" then return nil end
        start = dot + 1
    end
end

function NS.SetPath(tbl, path, value)
    if type(tbl) ~= "table" or type(path) ~= "string" then return end
    local segments = {}
    for segment in path:gmatch("[^%.]+") do segments[#segments + 1] = segment end
    if #segments == 0 then return end
    local node = tbl
    for i = 1, #segments - 1 do
        local key = segments[i]
        if type(node[key]) ~= "table" then node[key] = {} end
        node = node[key]
    end
    node[segments[#segments]] = value
end

-- ── session settings ──────────────────────────────────────────────────────────────────────────
--
-- A row whose value is NOT in the profile: today only the Master controls tab's debug console
-- toggle (`state.debugConsole`), whose real home is the console window's own visibility.
local sessionSettings = {}

function NS.RegisterSessionSetting(path, spec)
    if type(path) ~= "string" or type(spec) ~= "table" then return end
    sessionSettings[path] = spec
end

--- Read a setting: the session registry first, then the profile, then the shipped default.
function NS.GetSetting(path)
    local session = sessionSettings[path]
    if session then return session.get() end
    local db = NS.db
    if db and db.profile then
        local val = NS.ResolvePath(db.profile, path)
        if val ~= nil then return val end
    end
    return NS.ResolvePath(NS.defaults and NS.defaults.profile, path)
end

--- Store a setting without any side effect. Every caller outside this file uses NS.SetByPath.
function NS.SetSetting(path, value)
    local session = sessionSettings[path]
    if session then
        session.set(value)
        return
    end
    local db = NS.db
    if db and db.profile then NS.SetPath(db.profile, path, value) end
end

-- ── the write seam ────────────────────────────────────────────────────────────────────────────

local function sectionOf(row)
    if row.section then return row.section end
    local first = row.path:match("^([^%.]+)%.")
    return first or "master"
end

-- The one sender of CONFIG (architecture-§4).
local function publishConfig(section)
    if NS.bus then NS.bus:SendMessage(NS.MSG.CONFIG, section) end
end

-- The bulk bracket (debug-logging-§10): a bulk reset through this seam is ONE
-- `[Set] <act> <scope>: N rows` line. While a bracket is open the seam still stores, fires onChange
-- and publishes per row, but tallies the writes that CHANGED a value instead of logging each. A
-- depth, so a bracket inside a bracket is still one act; a whole-profile reset logs nothing here,
-- because NS.OnProfileReset logs it once.
local bulkDepth, bulkWrites, bulkProfileReset, bulkFailed = 0, 0, false, false

local function sameValue(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for k, v in pairs(a) do
        if not sameValue(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

--- Write `value` at `path`, run the row's onChange, and publish CONFIG for the row's section. The
--- single write seam for every schema path (architecture-§5): the panel, `/pfe set`, `/pfe lock`,
--- resets — all land here, so the CLI and the panel cannot drift onto different code paths.
function NS.SetByPath(path, value)
    -- The old value is read only inside a bracket: outside one it is needed for nothing.
    local changed = bulkDepth > 0 and not sameValue(NS.GetSetting(path), value)
    NS.SetSetting(path, value)
    local row = byPath[path]
    if bulkDepth > 0 then
        if changed then bulkWrites = bulkWrites + 1 end
    elseif NS.State and NS.State.debug then
        NS.Debug("Set", "%s = %s", path, row and NS.FormatSchemaValue(row, value) or tostring(value))
    end
    if not row then return end
    if row.onChange then row.onChange(value) end
    -- Session rows store nothing an element renders from; nothing needs to hear about them.
    if not row.sessionOnly then publishConfig(sectionOf(row)) end
end

NS.Bulk = {}

function NS.Bulk.Begin()
    if bulkDepth == 0 then bulkWrites, bulkProfileReset, bulkFailed = 0, false, false end
    bulkDepth = bulkDepth + 1
end

--- `bulkEnd(act, scope, count, err, info)`'s shape; `count` is ignored, because N is the rows that
--- changed, not the rows the library walked.
function NS.Bulk.End(act, scope, _, err, info)
    if bulkDepth == 0 then return end
    bulkDepth = bulkDepth - 1
    if info and info.profileReset then bulkProfileReset = true end
    if err ~= nil then bulkFailed = true end
    if bulkDepth > 0 or bulkProfileReset then return end
    NS.Debug("Set", "%s %s: %d rows%s", tostring(act), tostring(scope), bulkWrites,
        bulkFailed and " (stopped by an error)" or "")
end

--- Run a bulk act inside a bracket that always closes, even when the walk raises.
function NS.Bulk.Run(act, scope, walk)
    local info = { profileReset = false }
    local ok, err = pcall(function()
        NS.Bulk.Begin(act, scope)
        walk(info)
    end)
    NS.Bulk.End(act, scope, nil, err, info)
    if not ok then error(err, 0) end
end

-- ── the profile reset's count (debug-logging-§10) ────────────────────────────────────────────
--
-- `[Set] reset profile '<name>' to defaults (N rows)` counts the rows the reset CHANGED, which only
-- a caller running before the reset can know. Every reset this addon drives goes through
-- NS.ResetProfileCounted; a reset it did not drive (an AceDBOptions button) logs no count.
local pendingResetCount

function NS.ProfileRowsOffDefault()
    local n = 0
    for _, row in ipairs(NS.Schema) do
        if row.path and not row.sessionOnly and row.page ~= "profiles"
            and not sameValue(NS.GetSetting(row.path), row.default) then
            n = n + 1
        end
    end
    return n
end

function NS.ResetProfileCounted(db)
    pendingResetCount = NS.ProfileRowsOffDefault()
    local ok, err = pcall(db.ResetProfile, db)
    pendingResetCount = nil
    if not ok then error(err, 0) end
end

function NS.ConsumeResetCount()
    local n = pendingResetCount
    pendingResetCount = nil
    return n
end

--- Reset one row to its default through the seam, so it logs and reacts like any other write.
function NS.ApplyDefault(row)
    if row.default == nil then return end
    NS.SetByPath(row.path, NS.Util.DeepCopy(row.default))
end

-- ── value formatting ──────────────────────────────────────────────────────────────────────────

-- Resolved once at load: LibKa0s.xml loads in the lib block, long before this file.
local SlashLib = LibStub and LibStub("LibKa0s-Slash-1.0", true)

--- How `/pfe get` and the [Set] line render a value — the library's one formatter. The degraded
--- fallback is deliberately bare: its only reader is the debug line, which a library-less build
--- hands to a stub sink.
function NS.FormatSchemaValue(row, v)
    if SlashLib then return SlashLib.FormatValue(row, v) end
    if v == nil then return "nil" end
    return tostring(v)
end

-- ── validation ────────────────────────────────────────────────────────────────────────────────
--
-- Run once when the panel registers. Catches a misspelled page or type, a missing path or group,
-- and (architecture-§5) any path that does not resolve against the defaults. Prints; never refuses.

local VALID_PAGES = { general = true, castbar = true, target = true, pet = true, profiles = true }
local VALID_TYPES = { bool = true, number = true, string = true, color = true }

local function schemaError(where, msg)
    if NS.Print then NS.Print("|cffff0000schema error|r: " .. where .. ": " .. msg) end
end

--- Returns shape `errors`, paths `resolved` against defaults.profile, and `missing` paths.
function NS.ValidateSchema()
    local errors, resolved, missing = 0, 0, 0
    local defaults = (NS.defaults and NS.defaults.profile) or {}
    for i, row in ipairs(NS.Schema) do
        local where = "row #" .. i .. " (" .. tostring(row.path or "<no path>") .. ")"
        local hasPath = type(row.path) == "string" and row.path ~= ""
        if not hasPath then
            schemaError(where, "missing or empty `path`"); errors = errors + 1
        end
        if not VALID_PAGES[row.page] then
            schemaError(where, "invalid `page` = " .. tostring(row.page)); errors = errors + 1
        end
        if not VALID_TYPES[row.type] then
            schemaError(where, "invalid `type` = " .. tostring(row.type)); errors = errors + 1
        end
        if row.page ~= "profiles" and type(row.group) ~= "string" then
            schemaError(where, "missing `group` (options-ui-§13)"); errors = errors + 1
        end
        if hasPath and row.page ~= "profiles" and not row.sessionOnly then
            if NS.ResolvePath(defaults, row.path) ~= nil then
                resolved = resolved + 1
            else
                schemaError(where, "`path` does not resolve against defaults.profile")
                missing = missing + 1
            end
        end
    end
    return errors, resolved, missing
end
