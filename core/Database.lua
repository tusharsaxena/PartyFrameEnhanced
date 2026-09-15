local _, NS = ...

-- core/Database.lua — AceDB init and the migration runner (savedvariables). Called from
-- OnInitialize, and directly by the headless harness.

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

-- The account-wide ladder, in order: one row per schema version. v1 is the shape v0.1.0 ships, so
-- the ladder is empty; a future stored-value change adds `{ to = 2, apply = function() … end }` here
-- in the same change as the row it affects.
local SCHEMA_STEPS = {}

--- Walk every step above the stored version. Idempotent: a second call is a no-op.
function NS:RunMigrations()
    local g = NS.db and NS.db.global
    if not g then return end
    g.schemaVersion = g.schemaVersion or 1
    for _, step in ipairs(SCHEMA_STEPS) do
        if g.schemaVersion < step.to then
            step.apply(NS.db.profile)
            NS.Debug("Migrate", "v%s \226\134\146 v%s", g.schemaVersion, step.to)
            g.schemaVersion = step.to
        end
    end
end
