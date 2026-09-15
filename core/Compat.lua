local _, NS = ...

-- core/Compat.lua — every version-variant or optional client API this addon calls (compat).
-- Retail only: these shim cross-patch differences, never game flavors. Feature modules call
-- NS.Compat.X and never the raw API, so a patch that renames or removes one is a one-file fix.
NS.Compat = NS.Compat or {}
local Compat = NS.Compat

--- True only for a value the client marks secret. Looked up at call time: `issecretvalue` is a
--- 12.0 global, and a headless run or an older build simply lacks it (answering false).
function Compat.IsSecret(v)
    local f = issecretvalue
    return f ~= nil and f(v) == true
end
