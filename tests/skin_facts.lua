-- tests/skin_facts.lua — this addon's facts for the kit's two skin suites (kit revision 58,
-- skinning-§1, tests/_kit/test_skin_values.lua and test_skin_switch.lua), held apart so tests/run.lua
-- stays a load list. Answers Kit.skinValues, Kit.skinSwitch.

-- skinning-§9 Preview stand-ins (owner U-24, 2026-11-20; SD_RULE.md of Ka0sAddonsCommonTasks
-- docs/2026-11-20-LIBKA0S_94_97_99_100): the stand-in keeps the look of the frame it imitates under
-- every skin. Its rows cite that ruling's plan item, SD-RULE, in place of A7 (fades, dims, flat thin
-- bars), which the audit found was the wrong class. Its (test) mark is the addon's own and reads
-- `text.muted`, so it has no row.
local STANDIN = "the preview stand-in imitates the Blizzard or EllesmereUI party frame it stands in for, "
  .. "so offsets tuned against it match a real party (skinning-§9 Preview stand-ins, owner U-24, 2026-11-20)"
local STANDIN_CAUSE = "SD-RULE"
local CHAT = "a chat line: the chat frame is no skinned surface"

local ROWS = {
  { file = "modules/StandIn.lua", substring = "SetColorTexture(0.06, 0.06, 0.06, 0.9)", why = STANDIN, cause = STANDIN_CAUSE },
  { file = "modules/StandIn.lua", substring = "SetBackdropBorderColor(0, 0, 0, 1)", why = STANDIN, cause = STANDIN_CAUSE },
  { file = "modules/StandIn.lua", substring = "SetColorTexture(0, 0, 0, 0.5)", why = STANDIN, cause = STANDIN_CAUSE },
  { file = "modules/StandIn.lua", substring = "Raid-Bar-Hp-Fill", why = STANDIN .. ": the raid frame's own art", cause = STANDIN_CAUSE },
  { file = "modules/StandIn.lua", substring = "Raid-Bar-Hp-Bg", why = STANDIN .. ": the raid frame's own art", cause = STANDIN_CAUSE },
  -- Kit revision 58 reads `return` triples: the stand-in's class and power hues with no client table.
  { file = "modules/StandIn.lua", substring = "return 0.2, 0.8, 0.2", why = STANDIN .. ": its health bar with no class color", cause = STANDIN_CAUSE },
  { file = "modules/StandIn.lua", substring = "return 0, 0, 1", why = STANDIN .. ": its power bar with no power color", cause = STANDIN_CAUSE },
  -- AceDB merges every swatch's table, so a stored color that is no table never reaches a player.
  { file = "modules/Element.lua", substring = "return 1, 1, 1, 1", why = "a stored swatch that is no table: AceDB's defaults fill every one",
    category = "unreachable default" },
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

  --- A LibSharedMedia answering every key with a path of its own (kit revision 58, skinning-§9 *Two
  --- gates enforce it*): the suite's mock answers every key with one fallback, so a bar texture drawn
  --- from the skin's `bar.texture` could never move under the probe. Installed for one surface's
  --- build, undone by `reset`; NS.FetchMedia reads NS.GetLSM at each call.
  local function distinctMedia()
    local real = NS.GetLSM()
    local fake = setmetatable({
      Fetch = function(_, kind, key) return "Interface\\AddOns\\Probe\\" .. tostring(kind) .. "\\" .. tostring(key) end,
    }, { __index = real })
    setStored(NS, "GetLSM", function() return fake end)
  end

  --- One surface of an element. `fields` (optional) carries the kit's revision-58 fields: `expect`,
  --- `hold` or `clear`.
  local function part(s, name, keys, stored, pick, fields)
    local surface = {
      name = s.label .. "'s " .. name,
      companion = function(on)
        for _, key in ipairs(keys) do NS.db.profile[s.key][key] = on end
      end,
      build = function()
        raise(s.key, stored)
        return pick(s.el())
      end,
    }
    for k, v in pairs(fields or {}) do surface[k] = v end
    surfaces[#surfaces + 1] = surface
  end

  local TEXTURE = { expect = "texture" }

  for _, s in ipairs(SECTIONS) do
    part(s, "fill", { "barColorFromSkin" }, nil, function(el) return tap(el.bar, { "SetStatusBarColor" }) end)
    -- The fill's texture as the StatusBar is given it, and the background drawn in the same texture
    -- (modules/Element.lua applyBar), each a data fill on a Texture that has to move.
    part(s, "bar texture", { "barTextureFromSkin" }, nil, function(el)
      distinctMedia()
      return tap(el.bar, { "SetStatusBarTexture" })
    end, TEXTURE)
    part(s, "background texture", { "barTextureFromSkin" }, nil, function(el)
      distinctMedia()
      return tap(el.bg, { "SetTexture" })
    end, TEXTURE)
    part(s, "background", { "bgColorFromSkin" }, nil, function(el) return tap(el.bg, { "SetVertexColor" }) end)
    part(s, "border style", { "borderStyleFromSkin" }, nil, function(el) return tap(el.border, { "SetBackdrop" }) end)
    part(s, "border color", { "borderColorFromSkin" }, { borderStyleFromSkin = false },
      function(el) return tap(el.border, { "SetBackdropBorderColor" }) end)
    part(s, "text color", { "fontColorFromSkin" }, nil, function(el) return tap(el.text, { "SetTextColor" }) end)
    part(s, "face", { "fontFromSkin" }, nil, function(el) return tap(el.text, { "SetFont", "SetFontObject" }) end)
    part(s, "text shadow", { "fontShadowFromSkin" }, { fontFromSkin = false },
      function(el) return tap(el.text, { "SetFontObject", "SetShadowColor", "SetShadowOffset" }) end)
    -- The second line (the cast bar's time left, the target's health percent) is drawn with the first.
    part(s, "second line's color", { "fontColorFromSkin" }, nil, function(el) return tap(el.text2, { "SetTextColor" }) end)
    part(s, "second line's face", { "fontFromSkin" }, nil,
      function(el) return tap(el.text2, { "SetFont", "SetFontObject" }) end)
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

  -- The stand-in keeps its host's look (skinning-§9 Preview stand-ins, owner U-24, 2026-11-20), so
  -- only its (test) mark, the addon's own annotation, is a surface: `text.muted` in an escape on the
  -- name line, set again by StandIn's OnLooksChanged repaint. Unlocking out of a party raises it.
  surfaces[#surfaces + 1] = {
    name = "the stand-in's (test) mark",
    build = function()
      raise("castbar")
      return tap(NS.StandIn.Frame().name, { "SetText" })
    end,
  }

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
