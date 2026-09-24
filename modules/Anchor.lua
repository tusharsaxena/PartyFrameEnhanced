local _, NS = ...

-- modules/Anchor.lua — where every element goes (design spec §3.2, §6.4). Shared by the three features:
-- each registers its five elements once, and Anchor places them.
--
--   attached  each unit's element pinned to Providers.FrameFor(unit) by the feature's point,
--             relative point and offsets — or edge to edge across the frame's width
--   free      the feature's elements stacked in one movable holder, by growth and spacing
--
-- MEMOIZED: an element remembers what it was last pinned to, and a pass that would pin it to the
-- same thing makes no SetPoint call at all (SimplePartyTargets measured 46 SetPoint calls per block
-- per pass before it did the same).
--
-- SECURE ELEMENTS (the clickable target and pet frames) cannot be moved in combat. A pass in combat
-- fades any secure element whose anchor changed — alpha is not protected — and queues the real pass
-- through NS.RunSecure, which runs on PLAYER_REGEN_ENABLED and restores the alpha.
--
-- OWNER of the free-placement positions (`<feature>.position`, named non-setting state,
-- architecture-§5): written only by SavePosition (a drag) and ResetPositions.

local Perf  = NS.Perf
local Units = NS.Units

local Anchor = NS.RegisterModule({ name = "Anchor" })
NS.Anchor = Anchor

local features, order = {}, {}
Anchor.__features, Anchor.__order = features, order
local unlocked = false

-- For a "match the party frame's width" pin: the left and right edge points on the same side as a
-- nine-point anchor. Precomputed so a pass concatenates nothing.
local LEFT_OF = {
    TOPLEFT = "TOPLEFT", TOP = "TOPLEFT", TOPRIGHT = "TOPLEFT",
    LEFT = "LEFT", CENTER = "LEFT", RIGHT = "LEFT",
    BOTTOMLEFT = "BOTTOMLEFT", BOTTOM = "BOTTOMLEFT", BOTTOMRIGHT = "BOTTOMLEFT",
}
local RIGHT_OF = {
    TOPLEFT = "TOPRIGHT", TOP = "TOPRIGHT", TOPRIGHT = "TOPRIGHT",
    LEFT = "RIGHT", CENTER = "RIGHT", RIGHT = "RIGHT",
    BOTTOMLEFT = "BOTTOMRIGHT", BOTTOM = "BOTTOMRIGHT", BOTTOMRIGHT = "BOTTOMRIGHT",
}

-- Where each element's corner sits in the holder, and which way the next slot lies, by growth
-- direction.
local STACK_POINT = { DOWN = "TOPLEFT", UP = "BOTTOMLEFT", RIGHT = "TOPLEFT", LEFT = "TOPRIGHT" }
local GROWTH_DIR  = { DOWN = { 0, -1 }, UP = { 0, 1 }, RIGHT = { 1, 0 }, LEFT = { -1, 0 } }

-- The holder's size for `n` slots stacked along `dir`.
local function stackSize(dir, n, w, h, gap)
    if dir[1] ~= 0 then return n * w + (n - 1) * gap, h end
    return w, n * h + (n - 1) * gap
end

-- ── placing one element ───────────────────────────────────────────────────────────────────────

--- Pin `el` to `target`, unless it is already pinned exactly so. Returns true when it moved. A nil
--- target unpins it; the feature's show decision hides an element with no frame.
local function pin(el, target, point, rel, x, y, match)
    if el.__aSet and el.__aTarget == target and el.__aPoint == point and el.__aRel == rel
        and el.__aX == x and el.__aY == y and el.__aMatch == match then
        return false
    end
    el.__aSet, el.__aTarget, el.__aPoint, el.__aRel, el.__aX, el.__aY, el.__aMatch =
        true, target, point, rel, x, y, match
    el:ClearAllPoints()
    if target == nil then return true end
    if match then
        el:SetPoint(LEFT_OF[point], target, LEFT_OF[rel], x, y)
        el:SetPoint(RIGHT_OF[point], target, RIGHT_OF[rel], x, y)
    else
        el:SetPoint(point, target, rel, x, y)
    end
    return true
end

--- Restore an element's own alpha after a combat fade. Features record the alpha they want on
--- `el.__alpha`, so a fade never loses it.
local function unfade(el)
    if el.__combatFaded then
        el.__combatFaded = nil
        el:SetAlpha(el.__alpha or 1)
    end
end

-- ── the free-placement holder ─────────────────────────────────────────────────────────────────

local function positionOf(spec)
    local cfg = spec.config()
    local p = cfg and cfg.position
    if type(p) == "table" and p.point then return p.point, p.x or 0, p.y or 0 end
    local d = spec.defaultPosition
    return d[1], d[2], d[3]
end

local function placeHolder(spec)
    local holder = spec.holder
    local point, x, y = positionOf(spec)
    if holder.__aPoint == point and holder.__aX == x and holder.__aY == y then return end
    holder.__aPoint, holder.__aX, holder.__aY = point, x, y
    holder:ClearAllPoints()
    holder:SetPoint(point, UIParent, point, x, y)
end

-- ── a feature's pass ──────────────────────────────────────────────────────────────────────────

-- An absent section reads as an empty one rather than raising a second way.
local EMPTY_SECTION = {}

-- The section's shipped defaults, for the one moment `cfg` cannot be trusted to carry them.
local function shipped(spec)
    if spec.defaults then return spec.defaults end
    local d = NS.defaults and NS.defaults.profile
    return (d and d[spec.key]) or EMPTY_SECTION
end

-- The attached placement: point, relative point, offsets and match width.
local function placementOf(spec, cfg)
    -- DEFAULTED, and not defensively: on a profile switch, copy or reset, AceDB calls
    -- removeDefaults() on the OUTGOING profile table, which strips every key whose value still
    -- equals its default. `point` and `relativePoint` are almost always exactly that -- most
    -- players never move them -- so the table is left without them. The order MSG.PROFILE
    -- handlers run in is UNDEFINED: CallbackHandler-1.0 dispatches with next() over per-target
    -- tables (libs/CallbackHandler-1.0/CallbackHandler-1.0.lua:15-22), so it is hash order, not
    -- TOC order. That is why every feature's `spec.config()` and `spec.slotSize()` read the LIVE
    -- profile section rather than the `cfg` upvalue the feature re-binds in its own handler:
    -- Anchor never depends on a feature having re-bound first. A section can still come without
    -- the key (a reference held across the switch, a section with no AceDB defaults behind it),
    -- and a nil would reach SetPoint, which raises
    -- "Usage: SetPoint(point, ...)" and takes the whole ApplyAll fan-out down with it.
    -- Falling back to the shipped default is the same move positionOf() already makes for the
    -- holder, and it is correct rather than merely safe: the key is absent precisely BECAUSE its
    -- value is the default.
    local d = shipped(spec)
    return cfg.point or d.point, cfg.relativePoint or d.relativePoint,
        cfg.offsetX or 0, cfg.offsetY or 0, cfg.matchWidth and true or false
end

local function applyAttached(spec, cfg)
    local moved, missing = 0, 0
    local point, rel, x, y, match = placementOf(spec, cfg)
    for _, unit in ipairs(Units.LIST) do
        local el = spec.elements[unit]
        local target = NS.Providers.FrameFor(unit)
        -- A point that resolves to nothing even after the default is an UNPLACEABLE element, not a
        -- reason to raise: pin(nil) unpins it and the feature's show decision hides it, which is
        -- the same answer a missing party frame already gets. SetPoint(nil, ...) would instead
        -- take down every remaining element in the pass.
        if not target or not point or not rel then missing = missing + 1 end
        if pin(el, (point and rel) and target or nil, point, rel, x, y, match) then
            moved = moved + 1
        end
        unfade(el)
    end
    return moved, missing
end

local function applyFree(spec, cfg)
    placeHolder(spec)
    local growth = GROWTH_DIR[cfg.growth] and cfg.growth or "DOWN"
    local corner, dir = STACK_POINT[growth], GROWTH_DIR[growth]
    local w, h = spec.slotSize()
    local gap = cfg.spacing or 0
    local stepX, stepY = dir[1] * (w + gap), dir[2] * (h + gap)
    local moved, slot = 0, 0
    for _, unit in ipairs(Units.LIST) do
        local el = spec.elements[unit]
        -- A unit left out entirely (the player, with "Include my own row" off) takes no slot, so
        -- the stack stays tight. Units that merely do not exist keep their slot: a stack that closed
        -- up around them would have to move secure frames in combat.
        if Units.IsIncluded(unit) then
            if pin(el, spec.holder, corner, corner, slot * stepX, slot * stepY, false) then
                moved = moved + 1
            end
            slot = slot + 1
        elseif pin(el, nil) then
            moved = moved + 1
        end
        unfade(el)
    end
    spec.holder:SetSize(stackSize(dir, math.max(slot, 1), w, h, gap))
    return moved, 0
end

-- In combat a secure feature cannot move. Anything whose pin would change is faded instead, and
-- the real pass is queued for PLAYER_REGEN_ENABLED.
local function deferSecure(spec, cfg)
    local attached = cfg.anchorMode ~= "free"
    local faded = 0
    for _, unit in ipairs(Units.LIST) do
        local el = spec.elements[unit]
        local want = attached and NS.Providers.FrameFor(unit) or spec.holder
        if el.__aTarget ~= want and not el.__combatFaded then
            el.__combatFaded = true
            el:SetAlpha(0)
            faded = faded + 1
        end
    end
    NS.RunSecure("anchor:" .. spec.key, function() Anchor.Apply(spec.key) end)
    return faded
end

--- Place every element of one feature for the current settings and frame map.
function Anchor.Apply(key)
    local spec = features[key]
    if not spec then return end
    local t0 = Perf.on and debugprofilestop()
    local cfg = spec.config()
    local moved, missing, faded = 0, 0, 0
    if spec.secure and InCombatLockdown() then
        faded = deferSecure(spec, cfg)
    elseif cfg.anchorMode == "free" then
        moved, missing = applyFree(spec, cfg)
    else
        moved, missing = applyAttached(spec, cfg)
    end
    if t0 then Perf.Note("anchor", debugprofilestop() - t0) end
    if (moved > 0 or faded > 0) and NS.State.debug then
        NS.Debug("Anchor", "%s %s: moved %d, no frame %d, faded %d", key,
            tostring(cfg.anchorMode), moved, missing, faded)
    end
end

function Anchor.ApplyAll()
    for _, key in ipairs(order) do Anchor.Apply(key) end
end

-- ── registration and dragging ─────────────────────────────────────────────────────────────────

--- Register one feature. `spec` = { key, secure, elements = { [unit] = frame }, config = fn → the
--- feature's profile section, slotSize = fn → w, h, defaultPosition = { point, x, y } }. Builds the
--- feature's free-placement holder, which is draggable only while unlocked.
function Anchor.Register(spec)
    features[spec.key] = spec
    order[#order + 1] = spec.key
    local holder = CreateFrame("Frame", "PartyFrameEnhanced_" .. spec.key .. "_Holder", UIParent)
    holder:SetSize(1, 1)
    -- What a player grabs while unlocked: a translucent plate and the feature's name, shown only
    -- for a free-placement feature in unlocked mode (Anchor.SetUnlocked).
    holder.plate = holder:CreateTexture(nil, "BACKGROUND")
    holder.plate:SetAllPoints(holder)
    holder.plate:SetColorTexture(0, 0.6, 1, 0.25)
    holder.plate:Hide()
    holder.label = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    holder.label:SetPoint("BOTTOM", holder, "TOP", 0, 2)
    holder.label:SetText(spec.label or spec.key)
    holder.label:Hide()
    -- THE NAME PLATE IS A HANDLE, because the plate alone is not one. A FontString takes no mouse
    -- input, so the label above the stack was only ever a caption; everything grabbable was the
    -- holder's own rect, which the elements cover almost exactly. At a large gap the plate shows
    -- between them and there is something to grab; at a 2px gap there is nothing, and a
    -- free-placement stack becomes immovable at the one setting that makes it look tidiest.
    -- This frame gives the label a body, sized to it and parented to the holder, so the caption
    -- players naturally aim at is the handle it looks like.
    holder.grip = CreateFrame("Frame", nil, holder)
    holder.grip:SetPoint("TOPLEFT", holder.label, "TOPLEFT", -4, 4)
    holder.grip:SetPoint("BOTTOMRIGHT", holder.label, "BOTTOMRIGHT", 4, -4)
    holder.grip:EnableMouse(false)
    holder.grip:RegisterForDrag("LeftButton")
    holder.grip:Hide()
    holder:SetMovable(true)
    -- Re-anchored from the addon's own stored or default position; a client-cached one is never wanted.
    if holder.SetDontSavePosition then holder:SetDontSavePosition(true) end
    holder:SetClampedToScreen(true)
    holder:EnableMouse(false)
    holder:RegisterForDrag("LeftButton")
    holder:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    holder:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Anchor.SavePosition(spec.key)
    end)
    -- Every other handle moves the HOLDER, never itself: the elements are pinned to it, so
    -- dragging one of them directly would tear it off the stack it belongs to.
    local function dragHolder()
        if not InCombatLockdown() then holder:StartMoving() end
    end
    local function dropHolder()
        holder:StopMovingOrSizing()
        Anchor.SavePosition(spec.key)
    end
    holder.grip:SetScript("OnDragStart", dragHolder)
    holder.grip:SetScript("OnDragStop", dropHolder)
    spec.__drag, spec.__drop = dragHolder, dropHolder
    spec.holder = holder
    return spec
end

-- Grabbable exactly while unlocked and in free placement. The holder carries no secure frame's
-- anchor as a child, but a secure element anchored to it restricts it in combat, so its mouse state
-- changes out of combat only.
local function refreshHolder(spec)
    local grab = unlocked and spec.config().anchorMode == "free"
    NS.RunSecure("holder:" .. spec.key, function()
        spec.holder:EnableMouse(grab)
        -- THE BARS ARE HANDLES TOO. With the gap closed the elements ARE the visible stack, so
        -- they are what a player aims at. Each forwards its drag to the holder rather than moving
        -- itself. Secure elements are included: this runs through RunSecure, and an unlock is
        -- already refused in combat (modules/Preview.lua), so no attribute moves under lockdown.
        -- Only the drag is taken -- the click stays the element's own, so a target frame keeps
        -- targeting while unlocked.
        for _, el in pairs(spec.elements) do
            -- CLEARED WITH NO ARGUMENT, never with nil: RegisterForDrag(nil) is not "register for
            -- nothing", it is a bad argument #2 and it raises. The no-arg call is the documented
            -- way to drop every registered button.
            if grab then el:RegisterForDrag("LeftButton") else el:RegisterForDrag() end
            el:SetScript("OnDragStart", grab and spec.__drag or nil)
            el:SetScript("OnDragStop", grab and spec.__drop or nil)
        end
    end)
    if grab then
        spec.holder.plate:Show()
        spec.holder.label:Show()
        spec.holder.grip:Show()
        spec.holder.grip:EnableMouse(true)
    else
        spec.holder.plate:Hide()
        spec.holder.label:Hide()
        spec.holder.grip:EnableMouse(false)
        spec.holder.grip:Hide()
    end
end

-- The free-placement holders are on screen whenever the addon is up and hidden on stand-down.
-- Secure elements anchor to them, so the change goes through the secure queue and, under lockdown,
-- waits for PLAYER_REGEN_ENABLED; a later call under the same key replaces a queued one.
local function showHolders(on)
    NS.RunSecure("holder:shown", function()
        for _, key in ipairs(order) do
            local holder = features[key].holder
            if on then holder:Show() else holder:Hide() end
        end
    end)
end

function Anchor:Suspend()
    showHolders(false)
end

function Anchor:Resume()
    showHolders(true)
end

--- Unlocked (preview) mode lets the free-placement holders be grabbed.
function Anchor.SetUnlocked(on)
    unlocked = on and true or false
    for _, key in ipairs(order) do refreshHolder(features[key]) end
end

function Anchor.IsUnlocked()
    return unlocked
end

--- Store where a drag left a feature's holder. The only writer of `<feature>.position` besides
--- ResetPositions, and deliberately outside the write seam: no control sets it and no schema row
--- addresses it (architecture-§5).
function Anchor.SavePosition(key)
    local spec = features[key]
    if not spec then return end
    local point, _, _, x, y = spec.holder:GetPoint(1)
    if type(point) ~= "string" then return end
    local cfg = spec.config()
    cfg.position = { point = point, x = math.floor((x or 0) + 0.5), y = math.floor((y or 0) + 0.5) }
    spec.holder.__aPoint = nil   -- StartMoving re-anchored it; the memo no longer describes it
    Anchor.Apply(key)
end

--- Every feature's free-placement stack back to its default position.
function Anchor.ResetPositions()
    for _, key in ipairs(order) do
        local spec = features[key]
        spec.config().position = nil
        spec.holder.__aPoint = nil
        Anchor.Apply(key)
    end
end

-- ── listening ─────────────────────────────────────────────────────────────────────────────────

local ev = NS.NewBusTarget()
Anchor.__ev = ev

ev:RegisterMessage(NS.MSG.LAYOUT, function() Anchor.ApplyAll() end)
ev:RegisterMessage(NS.MSG.PROFILE, function() Anchor.ApplyAll() end)
ev:RegisterMessage(NS.MSG.CONFIG, function(_, section)
    if features[section] then
        Anchor.Apply(section)
        -- An anchor-mode change moves the feature in or out of the grabbable set.
        refreshHolder(features[section])
    elseif section == "master" or section == "general" then
        Anchor.ApplyAll()
    end
end)
