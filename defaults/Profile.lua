local _, NS = ...

-- defaults/Profile.lua — every profile default, and the only place one is written (savedvariables-§2).
-- Feature sections (castbar, target, pet) are added by the phase that builds each feature.

NS.defaults = NS.defaults or {}

NS.defaults.profile = {
    -- Master controls (options-ui-§15). The debug console row is session state and stores nothing.
    -- Locked by default: unlocking turns on preview mode, which a first login must not start in.
    enabled    = true,
    visibility = "always",
    scale      = 1.0,
    alpha      = 1.0,
    locked     = true,

    general = {
        provider      = "auto",   -- "auto" | "blizzard" | "ellesmere"
        includePlayer = true,
    },
}

NS.defaults.global = {
    -- The account-wide schema stamp NS:RunMigrations walks from (savedvariables-§1). 1 is also the
    -- "pre-ladder" value: AceDB copies defaults into an absent key before the runner reads it, so any
    -- higher default would mark a stale store as already migrated.
    schemaVersion = 1,
}
