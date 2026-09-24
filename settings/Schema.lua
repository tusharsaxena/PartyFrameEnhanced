local _, NS = ...

-- settings/Schema.lua — the LibKa0s-Schema-1.0 seam (library-stack-§7). The single source of truth
-- for every user-facing setting is the row array NS.Schema (architecture-§5); the machinery around
-- it — the path primitives, the row index, the single write seam, the bulk bracket, the profile
-- reset's count and the shape check — is the library's, bound here onto the host names every
-- caller already uses, so no call site moved.
--
-- Each settings/<page>.lua registers its rows through NS.RegisterSchemaRows at file load. The
-- panel (LibKa0s-Options-1.0), the CLI (LibKa0s-Slash-1.0: list/get/set/reset) and the reset paths
-- all walk NS.Schema, so a new option is one row.
--
-- Row fields this addon reads, beyond the libraries' own (docs/api Options "Row fields", Schema
-- "Row fields this major reads"):
--   section  the CONFIG payload for the row: "master", "general", "castbar", "target", "pet".
--            Derived from the path's first segment when absent; flat paths are "master".
--
-- NO ROW CARRIES `disabledIf` on a color (options-ui-§17, anti-pattern #74).

NS.Schema = NS.Schema or {}

-- THE ONE ROW STORED OUTSIDE THE PROFILE (launcher-§3): the minimap button, whose value LibDBIcon
-- keeps in the ACCOUNT-WIDE `db.global.minimap`. settings/General.lua stamps its get/set onto the
-- composed row; here it is only the source of two rules. A profile reset cannot reach it, so the
-- reset count skips it; and no SWEEP this addon ships may rewrite it (`resetExempt`), while a named
-- `/pfe reset global.minimap.shown` still does.
--
-- THE PATH READS IN THE ROW'S OWN SENSE (launcher-§3): it is the player's CLI name for a checkbox
-- that says SHOWN, so it is `global.minimap.shown`. The STORED key is still LibDBIcon's `hide`,
-- which the row's get/set invert onto; no `shown` key is ever stored (anti-pattern #81).
local MINIMAP_PATH = "global.minimap.shown"
NS.MINIMAP_PATH = MINIMAP_PATH
local GLOBAL_PATHS = { [MINIMAP_PATH] = true }

--- Whether `path` lives in the global store rather than the profile. Asked by the reset count's
--- predicate, the shape check's defaults root and settings/OptionsSetup.lua's Reset All veto.
function NS.IsGlobalSetting(path)
    return GLOBAL_PATHS[path] == true
end

-- ── the degradation stub (LibKa0s docs/api/Schema/version-2-docs.md, "The degradation stub") ──
--
-- A library-less load still runs this addon's feature code and its host verbs, and both reach the
-- seam: every show decision reads settings through it, and `/pfe enable|disable|lock|unlock`, the
-- degraded Reset All and the combat re-lock (modules/Preview.lua forceLock) write through it. So
-- the stub is WRITE-COMPLETING and LOG-SILENT: reads, writes, the row's reaction, the announce and
-- the sweep veto are real; the [Set] line, the bracket's tally and the reset count, which only feed
-- a debug console that build does not have, are not. Copied from LibKa0s tests/test_schema.lua's
-- `referenceStub` (v1.56.0, Schema minor 2), whole: the instance parity pin needs every member.
-- A deliberate, documented duplication — the section above names it and why.
local HostSchemaStub = {}

local function stubCopy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = stubCopy(x) end
    return out
end

function HostSchemaStub.SplitPath(path)
    local parts = {}
    if path ~= nil then
        for seg in tostring(path):gmatch("[^%.]+") do parts[#parts + 1] = seg end
    end
    return parts
end

local function stubParts(p) return type(p) == "table" and p or HostSchemaStub.SplitPath(p) end

function HostSchemaStub.Read(root, p, first)
    local parts, node = stubParts(p), root
    first = first or 1
    if type(root) ~= "table" or #parts < first then return nil end
    for i = first, #parts do
        if type(node) ~= "table" then return nil end
        node = node[parts[i]]
    end
    return node
end

function HostSchemaStub.Write(root, p, value, first)
    local parts, node = stubParts(p), root
    first = first or 1
    if type(root) ~= "table" or #parts < first then return end
    for i = first, #parts - 1 do
        if type(node[parts[i]]) ~= "table" then node[parts[i]] = {} end
        node = node[parts[i]]
    end
    node[parts[#parts]] = value
end

function HostSchemaStub.SameValue(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for k, v in pairs(a) do if not HostSchemaStub.SameValue(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

local STUB_BRAND = "PartyFrameEnhanced"

--- The stub's registry: rows by reference, a linear first-match FindRow, Reindex a no-op.
local function stubRegistry(S, d)
    local rows = d.rows
    function S.AllRows() return rows end
    function S.FindRow(path)
        if type(path) ~= "string" then return nil end
        for _, row in ipairs(rows) do
            if type(row) == "table" and row.path == path then return row end
        end
    end
    function S.AddRows(list, at)
        if type(list) ~= "table" then return 0 end
        at = type(at) == "number" and math.floor(at) or #rows + 1
        if at > #rows + 1 then at = #rows + 1 elseif at < 1 then at = 1 end
        for i, row in ipairs(list) do table.insert(rows, at + i - 1, row) end
        return #list
    end
    function S.Reindex() end
end

local function stubResolve(d, parts, id)
    if type(d.resolveRoot) ~= "function" then return nil end
    return d.resolveRoot(parts, id)
end

--- The write seam's order without its log and tally: refuse an unknown path (a listed writeThrough
--- path is not unknown), validate, normalize, refuse a missing root. Answers the plan, or nil and
--- the refusal. Set and SetMany share it.
local function stubPrepare(S, d, through, path, value, id)
    local row = S.FindRow(path) or through[path]
    if not row then return nil, STUB_BRAND .. ": no setting " .. tostring(path) end
    local w = { row = row, path = path, value = value, rid = id }
    w.stored = type(row.set) ~= "function" and not row.sessionOnly
    if w.stored then
        w.parts = HostSchemaStub.SplitPath(path)
        local r, f, got = stubResolve(d, w.parts, id)
        if type(r) == "table" then w.root, w.first = r, f end
        if got ~= nil then w.rid = got end
    end
    if type(row.validate) == "function" then
        local ok, why = row.validate(value, w.rid)
        if not ok then return nil, STUB_BRAND .. ": invalid value for " .. path, why end
    end
    if type(row.normalize) == "function" then
        local out, why = row.normalize(value, w.rid)
        if out == nil then return nil, STUB_BRAND .. ": invalid value for " .. path, why end
        w.value = out
    end
    if w.stored and not w.root then return nil, STUB_BRAND .. ": nowhere to store " .. path end
    return w
end

local function stubStore(w)
    if type(w.row.set) == "function" then
        w.row.set(w.value)
    elseif w.stored then
        HostSchemaStub.Write(w.root, w.parts, stubCopy(w.value), w.first)
    end
end

local function stubReact(w)
    if type(w.row.onChange) == "function" then w.row.onChange(w.value, w.rid) end
end

local function stubAnnounceAll(d, ws)
    if #ws == 0 then return end
    if type(d.announceBatch) == "function" then return d.announceBatch(ws, ws[1].rid) end
    if type(d.announce) ~= "function" then return end
    for _, w in ipairs(ws) do d.announce(w.row, w.path, w.value, w.rid) end
end

--- Set, and the all-or-nothing SetMany, over one shared preparation. Log-silent, so SetMany's
--- `act` is not read at all.
local function stubWrites(S, d, through)
    function S.Set(path, value, id)
        local w, err, why = stubPrepare(S, d, through, path, value, id)
        if not w then return false, err, why end
        stubStore(w)
        stubReact(w)
        if type(d.announce) == "function" then d.announce(w.row, path, w.value, w.rid) end
        return true
    end
    function S.SetMany(entries, opts)
        local id = type(opts) == "table" and opts.instanceId or nil
        local ws = {}
        for i, e in ipairs(type(entries) == "table" and entries or {}) do
            if type(e) ~= "table" then e = {} end
            local w, err, why = stubPrepare(S, d, through, e.path, e.value, id)
            if not w then return false, err, why, i end
            ws[i] = w
        end
        for _, w in ipairs(ws) do stubStore(w) end
        for _, w in ipairs(ws) do stubReact(w) end
        stubAnnounceAll(d, ws)
        return true
    end
end

--- The stub's bracket keeps its depth, because ApplyDefault's sweep veto reads it; it counts
--- nothing, and the reset count exists only for a debug line, so it is 0 / nil.
local function stubBracket(S)
    local depth = 0
    function S.BulkBegin() depth = depth + 1 end
    function S.BulkEnd() if depth > 0 then depth = depth - 1 end end
    function S.BulkRun(act, scope, fn)
        S.BulkBegin(act, scope)
        local ok, err = pcall(fn, { profileReset = false })
        S.BulkEnd(act, scope)
        if not ok then error(err, 0) end
    end
    function S.BulkAdd() end
    function S.InBulk() return depth > 0 end
    function S.CountOffDefault() return 0 end
    function S.ResetCounted(fn) fn() end
    function S.ConsumeResetCount() return nil end
end

-- Dot-defined with a placeholder receiver: called as SchemaLib:New{...}, like the library.
function HostSchemaStub.New(_, d)
    local S = {}
    -- writeThrough: one synthetic row per listed path, built once. It has no validate, normalize,
    -- set or onChange, so the store is raw (a copy) and announced; every other row-less path is
    -- still refused.
    local through = {}
    for _, p in ipairs(type(d.writeThrough) == "table" and d.writeThrough or {}) do
        if type(p) == "string" and p ~= "" then through[p] = { path = p, writeThrough = true } end
    end
    stubRegistry(S, d)
    function S.Get(path, id)
        local row = S.FindRow(path)
        if row and type(row.get) == "function" then return row.get(id) end
        if type(path) ~= "string" or (row and row.sessionOnly) then return nil end
        local parts = HostSchemaStub.SplitPath(path)
        local root, first = stubResolve(d, parts, id)
        if type(root) ~= "table" then return nil end
        return HostSchemaStub.Read(root, parts, first)
    end
    stubWrites(S, d, through)
    stubBracket(S)
    function S.Default(path)
        local row = S.FindRow(path)
        return row and stubCopy(row.default)
    end
    function S.ApplyDefault(row, id)
        if type(row) ~= "table" or type(row.path) ~= "string" or row.default == nil then return false end
        local exempt = d.resetExempt
        if S.InBulk() and type(exempt) == "table" and exempt[row.path] then return false end
        return S.Set(row.path, stubCopy(row.default), id)
    end
    function S.Validate()
        if type(d.print) == "function" then
            d.print(STUB_BRAND .. ": LibKa0s-Schema-1.0 is missing, so the schema was not checked")
        end
        return 0, 0, 0
    end
    return S
end

-- ── the instance ──────────────────────────────────────────────────────────────────────────────

local SchemaLib = LibStub and LibStub("LibKa0s-Schema-1.0", true) or HostSchemaStub

local function sectionOf(row)
    if row.section then return row.section end
    local first = row.path:match("^([^%.]+)%.")
    return first or "master"
end

-- The one sender of CONFIG (architecture-§4).
local function publishConfig(section)
    if NS.bus then NS.bus:SendMessage(NS.MSG.CONFIG, section) end
end

-- What a profile reset can reach: not the global minimap row, and not a Profiles page row.
local function profilePred(row)
    return not NS.IsGlobalSetting(row.path) and row.page ~= "profiles"
end

local inst = SchemaLib:New({
    rows        = NS.Schema,
    resolveRoot = function() return NS.db and NS.db.profile, 1 end,
    -- A session row stores nothing an element renders from, and a written-through path (below) is
    -- a composed row that is not there to carry a reaction: neither is announced.
    announce    = function(row)
        if not row.sessionOnly and not row.writeThrough then publishConfig(sectionOf(row)) end
    end,
    -- Forwarded at call time: the debug sink and the chat printer are swapped under test.
    debug        = function(tag, fmt, ...) NS.Debug(tag, fmt, ...) end,
    debugEnabled = function() return NS.State and NS.State.debug end,
    format       = function(row, v) return NS.FormatSchemaValue(row, v) end,
    print        = function(line) if NS.Print then NS.Print(line) end end,
    resetExempt  = GLOBAL_PATHS,
    -- options-ui-§1 route (a). On a library-less load the Master controls composer is hollow, so
    -- `enabled` and `locked` have no row there, but settings/Slash.lua's runEnabled and runLock and
    -- modules/Preview.lua's forceLock (the combat, master-switch and perf re-lock) still write them.
    -- Listed, the write lands raw, with no row's onChange; on a full load the composed row takes it.
    writeThrough = { "enabled", "locked" },
})

-- Published for the surface-parity pins (tests/test_surface_parity.lua) and suite cleanup.
NS.__schema, NS.__schemaLib = inst, SchemaLib

-- ── the host names, bound onto the instance ──────────────────────────────────────────────────

function NS.RegisterSchemaRows(rows) inst.AddRows(rows) end
NS.FindSchemaRow = inst.FindRow
NS.SetByPath     = inst.Set
NS.ApplyDefault  = inst.ApplyDefault
NS.Bulk = { Begin = inst.BulkBegin, End = inst.BulkEnd, Run = inst.BulkRun }

-- Allocation-free on a warm path: tests/perf.lua's resolveUnchanged is pinned at 0 bytes/iter.
NS.ResolvePath = SchemaLib.Read
NS.SetPath     = SchemaLib.Write

--- Read a setting: the row's own get, else the profile, else the shipped default (which is also
--- the answer before the db opens).
function NS.GetSetting(path)
    local v = inst.Get(path)
    if v ~= nil then return v end
    return SchemaLib.Read(NS.defaults and NS.defaults.profile, path)
end

-- ── the profile reset's count (debug-logging-§10) ────────────────────────────────────────────
--
-- `[Set] reset profile '<name>' to defaults (N rows)` counts the rows the reset CHANGED, which only
-- a caller running before the reset can know. Every reset this addon drives goes through
-- NS.ResetProfileCounted; a reset it did not drive (an AceDBOptions button) logs no count.

function NS.ProfileRowsOffDefault() return inst.CountOffDefault(profilePred) end

function NS.ResetProfileCounted(db)
    inst.ResetCounted(function() db:ResetProfile() end, profilePred)
end

NS.ConsumeResetCount = inst.ConsumeResetCount

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
-- a duplicate path, and (architecture-§5) any stored path that does not resolve against the
-- defaults. Prints; never refuses.

local VALID_PAGES = { general = true, castbar = true, target = true, pet = true, profiles = true }

--- Where a row's declared default lives: defaults.profile, or no tree at all. A Profiles page row
--- is in none. Nor is the GLOBAL minimap row: its path (`global.minimap.shown`) names the row's own
--- shown sense, while its get/set closures invert onto the stored `global.minimap.hide`, so the
--- path is not a storage path and there is nothing for it to resolve against -- exempt the way a
--- sessionOnly row is. The storage default is pinned by tests/test_schema.lua instead.
local function defaultsRoot(_, row)
    if NS.IsGlobalSetting(row.path) then return nil end
    if row.page == "profiles" then return nil end
    return NS.defaults and NS.defaults.profile, 1
end

--- Returns shape `errors`, paths `resolved` against the defaults, and `missing` paths.
function NS.ValidateSchema()
    return inst.Validate({ pages = VALID_PAGES, defaultsRoot = defaultsRoot })
end
