local _, NS = ...

-- modules/SecureFollow.lua — the target and pet frames follow their member through an IN-COMBAT
-- re-sort (#3). The frames are secure, so Lua cannot move them under lockdown; restricted code can.
--
--   THE HEADER   one SecureHandlerBaseTemplate frame, built at OnEnable (out of combat) and never
--                again, holding a frame ref to every target and pet button ("<feature>:<unit>") and
--                the attributes the snippet reads: `pfe-provider`, and per feature `<f>-live`,
--                `<f>-point`/`-rel`/`-x`/`-y`, `<f>-match` and the match-width edges `-lp`/`-lr`/
--                `-rp`/`-rr`. ONE template only: combining templates drops the injected methods.
--   THE SYNC     SecureFollow.Sync writes only the attributes whose value changed, out of combat
--                only; a change in combat is queued through NS.RunSecure and lands at regen, so a
--                frame followed in combat uses the attributes as they stood when combat began.
--   THE WRAP     SecureHandlerWrapScript(memberFrame, "OnAttributeChanged", header, SNIPPET[id]) on
--                each protected member frame of the active provider — only the providers that
--                RE-SORT (`resorts = true` in modules/Providers.lua: EllesmereUI and Blizzard
--                raid-style) — lazily, out of combat, once per frame. When the frame's `unit`
--                attribute changes, the snippet re-anchors that unit's target and pet buttons to it.
--   THE FALLBACK anything not wrapped (a frame created in combat, an unprotected frame, a refused
--                wrap, Blizzard classic) keeps modules/Anchor.lua's fade-then-regen. Anchor asks
--                SecureFollow.Covers before fading.
--
-- WRAPPING IS THE ONE PLACE this addon attaches anything to another addon's or Blizzard's frame:
-- modules/Providers.lua stays read-only by construction and only hands the frames out
-- (Providers.ForEachActiveFrame). docs/ARCHITECTURE.md's taint notes describe it.
--
-- STAND-DOWN (slash-commands-§7): Suspend gates every follow off (`<f>-live` false, `pfe-provider`
-- "none") and unwraps every frame where OUR wrap is the outermost. Where another addon wrapped the
-- same script after us, its wrap is put back exactly and ours stays attached beneath it, gated off:
-- the client offers no by-header unwrap. That residue is a Documented-deviations row in
-- docs/ARCHITECTURE.md.
--
-- NOT PROVEN OFFLINE: whether the member frames change their `unit` attribute in combat, whether
-- the client accepts the wrap from a third-party header, and taint. tests/test_securefollow.lua runs
-- the snippets in the mock's restricted environment; the rest is docs/smoke-tests.md COMBAT-6/9/10.

local Units = NS.Units

local SecureFollow = NS.RegisterModule({ name = "SecureFollow" })
NS.SecureFollow = SecureFollow

local HEADER_NAME = "PartyFrameEnhancedSecureFollow"
local SCRIPT = "OnAttributeChanged"
local PROVIDER = "pfe-provider"
local FEATURES = { "target", "pet" }
local OWNER = { target = "TargetFrames", pet = "PetFrames" }

-- Attribute names, precomputed so a sync concatenates nothing.
local ATTR = {}
for _, f in ipairs(FEATURES) do
    ATTR[f] = {
        live = f .. "-live", point = f .. "-point", rel = f .. "-rel", x = f .. "-x", y = f .. "-y",
        match = f .. "-match", lp = f .. "-lp", lr = f .. "-lr", rp = f .. "-rp", rr = f .. "-rr",
    }
end

-- The restricted pre-body, one per re-sorting provider with its id embedded literally. Restricted
-- dialect: handle methods only, no table constructor. `self` is the member frame, `owner` the
-- header, `name`/`value` the attribute change. It must never answer false, which would block the
-- member frame's own OnAttributeChanged. A unit outside the five tracked ones (raidN) finds no
-- frame ref and does nothing.
local SNIPPET_BODY = [[
if name ~= "unit" or not value or owner:GetAttribute("pfe-provider") ~= "<id>" then return end
for f = 1, 2 do
  local feat = f == 1 and "target" or "pet"
  local btn = owner:GetAttribute(feat .. "-live") and owner:GetFrameRef(feat .. ":" .. value)
  if btn then
    local x, y = owner:GetAttribute(feat .. "-x"), owner:GetAttribute(feat .. "-y")
    btn:ClearAllPoints()
    if owner:GetAttribute(feat .. "-match") then
      btn:SetPoint(owner:GetAttribute(feat .. "-lp"), self, owner:GetAttribute(feat .. "-lr"), x, y)
      btn:SetPoint(owner:GetAttribute(feat .. "-rp"), self, owner:GetAttribute(feat .. "-rr"), x, y)
    else
      btn:SetPoint(owner:GetAttribute(feat .. "-point"), self, owner:GetAttribute(feat .. "-rel"), x, y)
    end
  end
end
]]

local SNIPPET = {}
for _, p in ipairs(NS.Providers.__list) do
    if p.resorts then SNIPPET[p.id] = (SNIPPET_BODY:gsub("<id>", p.id)) end
end
SecureFollow.SNIPPET = SNIPPET

-- ── state ─────────────────────────────────────────────────────────────────────────────────────

local header                                         -- nil until built, and for good without the API
local memo = {}                                      -- attribute -> the value last written
local wrapped = setmetatable({}, { __mode = "k" })   -- member frame -> the provider id it was wrapped for
local refused = setmetatable({}, { __mode = "k" })   -- member frames whose wrap raised: never retried
local suspended = false
SecureFollow.__wrapped = wrapped

function SecureFollow.__header() return header end

-- ── the attribute sync ────────────────────────────────────────────────────────────────────────

local function put(k, v)
    if memo[k] == v then return end
    memo[k] = v
    header:SetAttribute(k, v)
end

local function featureLive(spec)
    if suspended or NS.GetSetting("enabled") ~= true then return false end
    local cfg = spec.config()
    return cfg.enabled == true and cfg.anchorMode ~= "free"
end

local function syncFeature(feat)
    local a = ATTR[feat]
    local spec = NS.Anchor.__features[feat]
    if not spec then put(a.live, false) return end
    local point, rel, x, y, match = NS.Anchor.PlacementOf(feat)
    local live = point ~= nil and rel ~= nil and featureLive(spec)
    -- The gate closes before anything it guards changes, and opens only after.
    if not live then put(a.live, false) end
    put(a.point, point)
    put(a.rel, rel)
    put(a.x, x)
    put(a.y, y)
    put(a.match, match)
    local L, R = NS.Anchor.__LEFT_OF, NS.Anchor.__RIGHT_OF
    put(a.lp, L[point])
    put(a.lr, L[rel])
    put(a.rp, R[point])
    put(a.rr, R[rel])
    put(a.live, live)
end

--- Write the header's attributes from current settings, only those that changed. Out of combat
--- only: callers go through NS.RunSecure("follow:sync", SecureFollow.Sync), which passes this one
--- prebuilt function, so a request allocates nothing.
function SecureFollow.Sync()
    if not header then return end
    put(PROVIDER, (not suspended and NS.Providers.ActiveId()) or "none")
    for _, feat in ipairs(FEATURES) do syncFeature(feat) end
end

--- Whether restricted code already follows `key`'s element onto `frame`: the feature is live in
--- the header's attributes as they stand, the header names the active provider, and `frame` is
--- wrapped for it. Anchor's in-combat pass asks this before fading.
function SecureFollow.Covers(key, frame)
    local a = ATTR[key]
    if not header or not a or frame == nil or memo[a.live] ~= true then return false end
    local id = wrapped[frame]
    return id ~= nil and id == memo[PROVIDER] and id == NS.Providers.ActiveId()
end

--- The diagnostics report's view: whether the header was built, how many member frames are
--- wrapped now (the stand-down's gated residue included), and how many wraps the client refused.
function SecureFollow.Status()
    local n = 0
    for _ in pairs(wrapped) do n = n + 1 end
    return header ~= nil, n, NS.State.followRefused or 0
end

-- ── the wrap ──────────────────────────────────────────────────────────────────────────────────

local wrapId, wrapCount   -- the pass in progress, so the per-frame callback is one prebuilt function

local function onRefused(frame, err)
    refused[frame] = true
    NS.State.followRefused = (NS.State.followRefused or 0) + 1
    local msg = tostring(err)
    NS.DebugOnce("Follow:refused:" .. msg, "Follow", "wrap refused, that frame keeps the fade: %s", msg)
end

local function wrapFrame(frame)
    if wrapped[frame] or refused[frame] then return end
    if type(frame.IsProtected) ~= "function" or not frame:IsProtected() then return end
    local ok, err = pcall(SecureHandlerWrapScript, frame, SCRIPT, header, SNIPPET[wrapId])
    if not ok then return onRefused(frame, err) end
    wrapped[frame] = wrapId
    wrapCount = wrapCount + 1
end

--- Wrap every protected member frame of the active provider not wrapped yet, when that provider
--- re-sorts. Out of combat only: callers go through NS.RunSecure("follow:wrap", SecureFollow.Wrap).
function SecureFollow.Wrap()
    if not header or suspended then return end
    local id = NS.Providers.ActiveId()
    if not (id and SNIPPET[id]) then return end
    wrapId, wrapCount = id, 0
    NS.Providers.ForEachActiveFrame(wrapFrame)
    if wrapCount > 0 then
        NS.Debug("Follow", "wrapped %d %s frame(s) for the in-combat follow", wrapCount, id)
    end
end

-- Remove our wrap where it is the outermost one. Where another header's wrap came off instead, put
-- it back exactly as it was and keep ours recorded: it stays attached, gated off by the attributes.
-- That re-wrap is guarded like Wrap's own: a raise goes to the client's error handler (never
-- discarded) and the unwrap pass goes on to the next frame. A closure, because Lua 5.1's xpcall
-- passes no arguments; this runs once per wrapped frame on a stand-down, not on a hot path.
local function unwrapFrame(frame)
    local ok, h, pre, post = pcall(SecureHandlerUnwrapScript, frame, SCRIPT)
    if not ok then return false end
    if h == header or h == nil then
        wrapped[frame] = nil
        return true
    end
    xpcall(function() SecureHandlerWrapScript(frame, SCRIPT, h, pre, post) end, geterrorhandler())
    return false
end

local function unwrapAll()
    local kept = 0
    for frame in pairs(wrapped) do
        if not unwrapFrame(frame) then kept = kept + 1 end
    end
    if kept > 0 then
        NS.Debug("Follow", "%d wrap(s) left attached and gated off: another wrap is outermost", kept)
    end
end

-- ── lifecycle ─────────────────────────────────────────────────────────────────────────────────

function SecureFollow:OnEnable()
    -- Inert without the secure-handler API: no header, nothing covered, every frame on the fade.
    if type(SecureHandlerWrapScript) ~= "function" or type(SecureHandlerUnwrapScript) ~= "function" then
        NS.Debug("Follow", "no SecureHandlerWrapScript: in-combat follow off, the fade stays")
        return
    end
    header = CreateFrame("Frame", HEADER_NAME, UIParent, "SecureHandlerBaseTemplate")
    header:Hide()
    for _, feat in ipairs(FEATURES) do
        local owner = NS[OWNER[feat]]
        local buttons = owner and owner.__buttons or {}
        for _, unit in ipairs(Units.LIST) do
            if buttons[unit] then header:SetFrameRef(feat .. ":" .. unit, buttons[unit]) end
        end
    end
    SecureFollow.Sync()
end

function SecureFollow:Suspend()
    suspended = true
    if not header then return end
    NS.RunSecure("follow:sync", SecureFollow.Sync)
    NS.RunSecure("follow:wrap", unwrapAll)
end

function SecureFollow:Resume()
    suspended = false
    if not header then return end
    NS.RunSecure("follow:wrap", SecureFollow.Wrap)
    NS.RunSecure("follow:sync", SecureFollow.Sync)
end

-- ── listening ─────────────────────────────────────────────────────────────────────────────────

local ev = NS.NewBusTarget()
SecureFollow.__ev = ev

local function requestSync()
    if header then NS.RunSecure("follow:sync", SecureFollow.Sync) end
end

-- After a resolve: wrap what the active provider shows now, and publish which provider it is.
local function onLayout()
    if not header then return end
    NS.RunSecure("follow:wrap", SecureFollow.Wrap)
    NS.RunSecure("follow:sync", SecureFollow.Sync)
end

ev:RegisterMessage(NS.MSG.LAYOUT, onLayout)
ev:RegisterMessage(NS.MSG.CONFIG, requestSync)
ev:RegisterMessage(NS.MSG.PROFILE, requestSync)
ev:RegisterMessage(NS.MSG.VISIBILITY, requestSync)
