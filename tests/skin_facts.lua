-- tests/skin_facts.lua — this addon's facts for the kit's two skin suites (kit revision 50,
-- skinning-§1, tests/_kit/test_skin_values.lua and test_skin_switch.lua), held apart so tests/run.lua
-- stays a load list. Answers Kit.skinValues, Kit.skinSwitch.

local STANDIN = "the preview stand-in imitates the Blizzard or EllesmereUI party frame it stands in for, "
  .. "so offsets tuned against it match a real party"
local CHAT = "a chat line: the chat frame is no skinned surface"

local ROWS = {
  { file = "modules/StandIn.lua", substring = "SetColorTexture(0.06, 0.06, 0.06, 0.9)", why = STANDIN, cause = "A7" },
  { file = "modules/StandIn.lua", substring = "SetBackdropBorderColor(0, 0, 0, 1)", why = STANDIN, cause = "A7" },
  { file = "modules/StandIn.lua", substring = "SetColorTexture(0, 0, 0, 0.5)", why = STANDIN, cause = "A7" },
  { file = "modules/StandIn.lua", substring = "|cff999999", why = STANDIN .. ": its (test) mark", cause = "A7" },
  { file = "modules/StandIn.lua", substring = "Raid-Bar-Hp-Fill", why = STANDIN .. ": the raid frame's own art", cause = "A7" },
  { file = "modules/StandIn.lua", substring = "Raid-Bar-Hp-Bg", why = STANDIN .. ": the raid frame's own art", cause = "A7" },
  { file = "modules/Preview.lua", substring = "REFUSED_COMBAT = \"|cff808080\"", why = CHAT, cause = "L13" },
  { file = "modules/Preview.lua", substring = "REFUSED_SUSPENDED = \"|cff808080\"", why = CHAT, cause = "L13" },
}

return function(NS, mocks)
  local SECTIONS = {
    { key = "castbar", label = "the cast bar", el = function() return NS.CastBars.__bars.party1 end },
    { key = "target", label = "the target frame", el = function() return NS.TargetFrames.__buttons.party1 end },
    { key = "pet", label = "the pet frame", el = function() return NS.PetFrames.__buttons.party1 end },
  }

  -- What a surface moved, undone by `reset`: stored values, and the methods tapped. `drop` takes a
  -- probe holder off first, because the lock applies every feature and it has no elements.
  local undo, drop = {}, nil

  local function setStored(tbl, key, value)
    local was = tbl[key]
    undo[#undo + 1] = function() tbl[key] = was end
    tbl[key] = value
  end

  --- A stand-in answering for `methods` on `obj`. A status bar's or a border's children hold the
  --- other parts of the element, and the kit's spy reads children too, so answering the frame itself
  --- would pass this surface on another part's change. The tap sees this part's setters alone.
  local function tap(obj, methods)
    local seen = {}
    for _, method in ipairs(methods) do
      seen[method] = function() end
      local draw = obj[method]
      rawset(obj, method, function(self, ...)
        seen[method](seen, ...)
        if draw then return draw(self, ...) end
      end)
      undo[#undo + 1] = function() rawset(obj, method, nil) end
    end
    return seen
  end

  --- The HUD on screen: every element up as the unlocked preview draws it, so a skin switch runs the
  --- features' own repaint. A border is shown in the stored style, so its color has an edge to draw
  --- under a skin's None.
  local function raise(section, stored)
    local p = NS.db.profile
    setStored(p, "enabled", true)
    setStored(p, "visibility", "always")
    for _, s in ipairs(SECTIONS) do
      local sec = p[s.key]
      setStored(sec, "enabled", true)
      setStored(sec, "anchorMode", "free")
      setStored(sec, "borderShow", true)
    end
    setStored(p.target, "colorReaction", false)
    for key, value in pairs(stored or {}) do setStored(p[section], key, value) end
    NS.PublishVisibility()
    NS.Slash:OnSlash("unlock")
  end

  local surfaces = {}

  local function part(s, name, keys, stored, pick)
    surfaces[#surfaces + 1] = {
      name = s.label .. "'s " .. name,
      companion = function(on)
        for _, key in ipairs(keys) do NS.db.profile[s.key][key] = on end
      end,
      build = function()
        raise(s.key, stored)
        return pick(s.el())
      end,
    }
  end

  for _, s in ipairs(SECTIONS) do
    part(s, "fill", { "barColorFromSkin" }, nil, function(el) return tap(el.bar, { "SetStatusBarColor" }) end)
    -- The key, one step before LibSharedMedia: the mock's answers every key with one fallback.
    part(s, "bar texture", { "barTextureFromSkin" }, nil, function()
      local seen, fetch = { SetStatusBarTexture = function() end }, NS.FetchMedia
      setStored(NS, "FetchMedia", function(kind, key, fallback)
        if kind == "statusbar" then seen:SetStatusBarTexture(key) end
        return fetch(kind, key, fallback)
      end)
      return seen
    end)
    part(s, "background", { "bgColorFromSkin" }, nil, function(el) return tap(el.bg, { "SetVertexColor" }) end)
    part(s, "border style", { "borderStyleFromSkin" }, nil, function(el) return tap(el.border, { "SetBackdrop" }) end)
    part(s, "border color", { "borderColorFromSkin" }, { borderStyleFromSkin = false },
      function(el) return tap(el.border, { "SetBackdropBorderColor" }) end)
    part(s, "text color", { "fontColorFromSkin" }, nil, function(el) return tap(el.text, { "SetTextColor" }) end)
    part(s, "face", { "fontFromSkin" }, nil, function(el) return tap(el.text, { "SetFont", "SetFontObject" }) end)
    part(s, "text shadow", { "fontShadowFromSkin" }, { fontFromSkin = false },
      function(el) return tap(el.text, { "SetFontObject", "SetShadowColor", "SetShadowOffset" }) end)
  end

  local Skin = mocks.LibStub("LibKa0s-Skin-1.0")

  surfaces[#surfaces + 1] = {
    name = "the cast bar's spell icon edge",
    build = function()
      raise("castbar")
      local rec = Skin.painted[SECTIONS[1].el().icon]
      -- LibKa0s R3-L3: a flat 1 px outline in every skin, so the edge textures are what a switch
      -- redraws (their color); the holder itself takes no backdrop any more.
      local r = rec.regions
      return r.holder, r.edgeTop, r.edgeBottom, r.edgeLeft, r.edgeRight
    end,
  }

  --- A holder under the kit's paint recorder, so its plate and caption are real regions: the base
  --- mock's FontString is no FontString to the library.
  local installPaint = dofile("tests/_kit/mock_paint.lua")
  local function holder()
    local Anchor = NS.Anchor
    local key = "skinfacts"
    local restore = installPaint(mocks)
    local ok, err = pcall(Anchor.Register, {
      key = key, elements = {}, label = "Probe",
      defaults = { point = "TOP", relativePoint = "BOTTOM" },
      config = function() return { anchorMode = "free", growth = "DOWN", spacing = 4 } end,
      slotSize = function() return 100, 20 end, defaultPosition = { "CENTER", 0, -150 },
    })
    restore()
    if not ok then error(err, 0) end
    local spec = Anchor.__features[key]
    drop = function()
      spec.holder:Hide()
      Anchor.__features[key] = nil
      for i, k in ipairs(Anchor.__order) do
        if k == key then table.remove(Anchor.__order, i) break end
      end
    end
    return spec.holder
  end

  surfaces[#surfaces + 1] = {
    name = "a holder's plate",
    build = function() return holder().plate end,
  }
  surfaces[#surfaces + 1] = {
    name = "a holder's caption",
    build = function() return holder().label end,
  }

  return { rows = ROWS }, {
    owner = "PartyFrameEnhanced",
    skin = Skin,
    surfaces = surfaces,
    reset = function()
      if drop then drop(); drop = nil end
      NS.Slash:OnSlash("lock")
      for i = #undo, 1, -1 do undo[i]() end
      undo = {}
      NS.PublishVisibility()
      while mocks.__fireTimers() > 0 do end
    end,
  }
end
