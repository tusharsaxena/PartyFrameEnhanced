local addonName, NS = ...

-- core/EnvSetup.lua — the LibKa0s-Env-1.0 seam: this addon's own TOC manifest and version
-- (library-stack-§7).
--
-- The library is told our FOLDER name (the first vararg), because a vendored copy cannot know
-- which folder it sits in. The degraded arm runs the same two-rung ladder the library runs —
-- C_AddOns.GetAddOnMetadata, else nil; the bare global went in the 11.0 AddOns purge and no admitted
-- client has it — so `/pfe version` and the landing page's Notes line survive a missing LibKa0s.

local Env = LibStub and LibStub("LibKa0s-Env-1.0", true)

--- One field of this addon's TOC manifest, or nil (absent library, headless client, absent field).
--- Env first, then C_AddOns.GetAddOnMetadata, else nil.
function NS.Meta(field)
    if Env then return Env.GetAddOnMetadata(addonName, field) end
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(addonName, field)
    end
    return nil
end

--- This addon's version, preferring the TOC over the NS.version fallback. Never nil. NS.version is
--- read at call time, not captured.
function NS.Version()
    if Env then return Env.Version(addonName, NS.version) or "?" end
    return NS.Meta("Version") or NS.version or "?"
end
