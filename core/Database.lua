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
            NS.db.RegisterCallback(NS, "OnProfileDeleted", NS.OnProfileDeleted)
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
    -- The profile's skin, the moment the store exists (skinning-§2): core/SkinSetup.lua registered
    -- the owner at file load on Ka0s Default, before there was a profile to read. Before any module
    -- builds a frame (OnEnable), so the first paint is already this profile's skin.
    if NS.ApplySkinChoice then NS.ApplySkinChoice() end
end

-- The ladder, in order: one row per schema version, shaped
-- `{ to = N, scope = "profile"|"global", apply = function(tbl) … end }`. v1 is the shape v0.1.0
-- ships. A stored-value change adds its row here in the same change as the row it affects, and the
-- runner's target, NS.SCHEMA_VERSION below, moves with it.
--
-- A "profile" step runs over every STORED profile, and a raw stored profile has its defaults
-- stripped (AceDB's removeDefaults at logout, or it was never activated), so every step reads with
-- a fallback and is idempotent against a fresh default profile.

-- The HUD sections whose bar texture, border style and font follow the skin (skinning-§6).
local HUD_SECTIONS = { "castbar", "target", "pet" }

--- v1 -> v2: the one-time HUD style reset (skinning-§6, owner ruling R3; O2 of the 2026-10-29
--- skinning rollout), so the skin shows at once for every player. Sets the three `*FromSkin`
--- companions of each HUD section on: the bar texture and the font always, and the border style
--- only where the section does not draw a border. Ka0s Default's border style is "None", so a player
--- who turned Show border on would lose it; their companion is written FALSE instead, because the
--- default (true) would otherwise apply (D2). The companions are written directly, never through
--- Skin.ResetToSkin: on a raw stored profile the companion is absent (it is new), and ResetToSkin
--- before LibKa0s v1.81.0 (Skin minor 8) wrote the "@skin" sentinel there (Risks R3). The step has
--- shipped, so it keeps its direct writes and never depends on what a given library minor does with
--- an absent companion: a profile that migrates late gets the same result. The picks themselves are left
--- alone, so a player who turns a companion off gets their old pick back. A section the profile never
--- stored keeps the defaults, which already follow the skin. Idempotent.
local function hudFollowsSkin(p)
    for _, key in ipairs(HUD_SECTIONS) do
        local sec = p[key]
        if type(sec) == "table" then
            sec.barTextureFromSkin = true
            sec.fontFromSkin = true
            sec.borderStyleFromSkin = sec.borderShow ~= true
        end
    end
end

--- v2 -> v3: the HUD Font flags onto From skin (LibKa0s v1.82.0, ruling D-07; Addendum 01 of the
--- 2026-10-30 skin fonts run). A stored flag equal to the previous default, OUTLINE, becomes "@skin",
--- which draws OUTLINE under the default Font outline (HUD text only since v1.83.0) and follows the Skin tab from then
--- on. Any other stored flag is a pick the player made and stays. A section or flag never stored
--- already reads the new default. Idempotent; the stamp keeps it to one run, so an OUTLINE the
--- player picks afterwards is theirs.
local function flagsFromSkin(p)
    for _, key in ipairs(HUD_SECTIONS) do
        local sec = p[key]
        if type(sec) == "table" and sec.fontFlags == "OUTLINE" then sec.fontFlags = "@skin" end
    end
end

local SCHEMA_STEPS = {
    { to = 2, scope = "profile", apply = hudFollowsSkin },
    { to = 3, scope = "profile", apply = flagsFromSkin },
}
NS.__schemaSteps = SCHEMA_STEPS   -- test seam only (tests/test_database.lua injects a step)

-- The schema this build writes: the runner's target (savedvariables-§1), the ladder's highest step.
-- The defaults declare `global.schemaVersion = 0` and never this value (defaults/Profile.lua says
-- why); the runner owns the stamp.
NS.SCHEMA_VERSION = SCHEMA_STEPS[#SCHEMA_STEPS].to

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
