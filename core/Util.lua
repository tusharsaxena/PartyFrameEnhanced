local _, NS = ...

-- core/Util.lua — small helpers with no better home: the LibSharedMedia handle and fetch, and a
-- recursive copy. `NS.Util = NS.Util or {}`, never a fresh table: core/CoreSetup.lua hangs the
-- printer on NS.Util, and a later file that replaced the table would drop it silently.
NS.Util = NS.Util or {}
local Util = NS.Util

local LSM

--- The LibSharedMedia-3.0 handle, resolved once and cached. Nil when the library is absent.
function NS.GetLSM()
    if LSM then return LSM end
    if LibStub then LSM = LibStub("LibSharedMedia-3.0", true) end
    return LSM
end

--- Forget the cached handle (OnEnable re-resolves it, in case a later addon registered one).
function NS.ClearLSMCache()
    LSM = nil
end

--- The path LSM has for `key` of media `kind`, or `fallback`. Never raises: a key another addon
--- unregistered, or no LSM at all, lands on the fallback.
function NS.FetchMedia(kind, key, fallback)
    local lsm = NS.GetLSM()
    if lsm and key then
        local ok, path = pcall(lsm.Fetch, lsm, kind, key, true)
        if ok and path then return path end
    end
    return fallback
end

--- Deep copy of a plain table (no metatables, no cycles). Non-tables pass through.
function Util.DeepCopy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, vv in pairs(v) do out[k] = Util.DeepCopy(vv) end
    return out
end

--- Fill every key `dst` lacks from `src`, recursively; present keys are left alone. The no-AceDB
--- fallback uses it to give a raw SavedVariables table the defaults AceDB would have merged.
function Util.FillDefaults(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = Util.DeepCopy(v)
        elseif type(v) == "table" and type(dst[k]) == "table" then
            Util.FillDefaults(dst[k], v)
        end
    end
    return dst
end
