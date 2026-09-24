local _, NS = ...

-- core/Database.lua — AceDB init and the migration runner (savedvariables). Called from
-- OnInitialize, and directly by the headless harness.

local L = NS.L

--- Open the database, register the profile callbacks, and run the migration ladder.
function NS:InitDB()
    local AceDB = LibStub and LibStub("AceDB-3.0", true)
    if AceDB then
        NS.db = AceDB:New("PartyFrameEnhancedDB", NS.defaults, true)
        -- One handler per event, because each logs its own one line (debug-logging-§10). Looked up
        -- on NS at registration, which runs after every file has loaded.
        if NS.db.RegisterCallback then
            NS.db.RegisterCallback(NS, "OnProfileChanged", NS.OnProfileChanged)
            NS.db.RegisterCallback(NS, "OnProfileCopied", NS.OnProfileCopied)
            NS.db.RegisterCallback(NS, "OnProfileReset", NS.OnProfileReset)
        end
    end
    -- Without AceDB: a db-shaped table over the raw SavedVariables global, given the defaults AceDB
    -- would have merged. No profiles, no callbacks — the addon still runs and still answers /pfe.
    if not NS.db then
        PartyFrameEnhancedDB = PartyFrameEnhancedDB or {}
        local sv = PartyFrameEnhancedDB
        sv.profile = NS.Util.FillDefaults(sv.profile or {}, NS.defaults.profile)
        sv.global = NS.Util.FillDefaults(sv.global or {}, NS.defaults.global)
        NS.db = { profile = sv.profile, global = sv.global }
    end
    NS:RunMigrations()
end

-- The schema this build writes: the runner's target (savedvariables-§1). v1 is the shape v0.1.0
-- ships. The defaults declare `global.schemaVersion = 0` and never this value (defaults/Profile.lua
-- says why); the runner owns the stamp.
NS.SCHEMA_VERSION = 1

-- The ladder, in order: one row per schema version, shaped
-- `{ to = N, scope = "profile"|"global", apply = function(tbl) … end }`. v1 is the shape v0.1.0
-- ships, so the ladder is empty; a future stored-value change adds its row here, and raises
-- NS.SCHEMA_VERSION, in the same change as the row it affects.
--
-- A "profile" step runs over every STORED profile, and a raw stored profile has its defaults
-- stripped (AceDB's removeDefaults at logout, or it was never activated), so every step reads with
-- a fallback and is idempotent against a fresh default profile.
local SCHEMA_STEPS = {}
NS.__schemaSteps = SCHEMA_STEPS   -- test seam only (tests/test_database.lua injects a step)

--- The tables one step applies to: the account-wide table for a "global" step; for a "profile"
--- step every stored profile — AceDB's raw `profiles` (which includes the active one; the kit's
--- fake exposes it only as `db.sv.profiles`) — or the one profile the no-AceDB path has.
local function targetsFor(step, db)
    if step.scope == "global" then return { db.global } end
    local stored = db.profiles or (db.sv and db.sv.profiles)
    if not stored then return { db.profile } end
    local list = {}
    for _, p in pairs(stored) do
        if type(p) == "table" then list[#list + 1] = p end
    end
    return list
end

--- Apply one step to every table it targets. Returns true and the count, or false and the error.
local function applyStep(step, db)
    local targets = targetsFor(step, db)
    local ok, err = pcall(function()
        for _, tbl in ipairs(targets) do step.apply(tbl) end
    end)
    return ok, ok and #targets or err
end

--- Walk every step above the stored stamp. The stamp advances only past a step that returned
--- without raising; a failed step is logged, said once, and stops the walk with the stamp where it
--- was, so the next login retries it. Idempotent: a second call is a no-op.
function NS:RunMigrations()
    local db = NS.db
    local g = db and db.global
    if not g then return end
    local stamp = g.schemaVersion or 0
    for _, step in ipairs(SCHEMA_STEPS) do
        if stamp < step.to then
            local ok, result = applyStep(step, db)
            if not ok then
                NS.DebugLog:Add("Migrate", ("v%d failed: %s"):format(step.to, tostring(result)))
                NS.Print(L["Settings migration to v%d failed; your settings were left as they were"]:format(step.to))
                return
            end
            NS.Debug("Migrate", "v%d \226\134\146 v%d (%d profiles)", stamp, step.to, result)
            stamp = step.to
            g.schemaVersion = stamp
        end
    end
    if stamp < NS.SCHEMA_VERSION then g.schemaVersion = NS.SCHEMA_VERSION end
end
