-- Ka0s Party Frame Enhanced's WoW-API mock: the shared base (tests/_kit/mock_base.lua) plus the APIs
-- that are genuinely this addon's own. A thin extender (testing-§1): anything universal belongs in
-- the kit, and a base that stubbed every addon's APIs would hide a missing stub behind a neighbor's.

local base = dofile("tests/_kit/mock_base.lua")

return function()
  local M = base()

  -- The class-color table LibKa0s-Core-1.0's resolver reads, with enough classes to tell "the
  -- tracked unit's class" from "the player's" (MAGE is the base's capture-context class).
  M.RAID_CLASS_COLORS = {
    MAGE    = { r = 0.25, g = 0.78, b = 0.92 },
    PRIEST  = { r = 1.00, g = 1.00, b = 1.00 },
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
  }

  -- UnitClass made unit-aware: target and pet frames color by the unit they describe.
  M.__classByUnit = {}
  M.UnitClass = function(unit)
    local token = M.__classByUnit[unit or "player"]
    if token then return token, token end
    return M.__context.class, M.__context.classToken
  end

  -- Distinct, RECORDING regions. The base stub answers CreateTexture/CreateFontString with the frame
  -- itself (the kit's documented divergence); an element with a bar, two text lines, an icon and a
  -- spark needs each to be its own object, and a suite needs to read what each was told. Status
  -- bars record their values, color and timer the same way.
  local baseCreateFrame = M.CreateFrame
  local function region()
    local r = M.__stubFrame()
    rawset(r, "SetText", function(self, t) self.__text = t end)
    rawset(r, "SetFormattedText", function(self, fmt, ...) self.__text = fmt:format(...) end)
    rawset(r, "SetTexture", function(self, t) self.__texture = t end)
    rawset(r, "SetAlpha", function(self, a) self.__alpha = a end)
    return r
  end
  M.CreateFrame = function(frameType, name, parent, template)
    local f = baseCreateFrame(frameType, name, parent, template)
    rawset(f, "CreateTexture", function() return region() end)
    rawset(f, "CreateFontString", function() return region() end)
    if frameType == "StatusBar" then
      rawset(f, "SetMinMaxValues", function(self, lo, hi) self.__min, self.__max = lo, hi end)
      rawset(f, "SetValue", function(self, v) self.__value = v end)
      rawset(f, "SetStatusBarColor", function(self, r, g, b, a) self.__color = { r, g, b, a } end)
      rawset(f, "SetTimerDuration", function(self, d, interp, dir)
        self.__timer = { duration = d, interpolation = interp, direction = dir }
      end)
    end
    return f
  end

  -- A cast a suite can start and stop per unit: M.__casts[unit] = { kind = "cast" | "channel",
  -- name, texture, notInterruptible, remaining, total }. The duration object's getters answer
  -- plain numbers here; in the client they can be secret, which is why the addon never reads them.
  M.__casts = {}
  local function durationFor(c)
    if not c then return nil end
    return {
      GetRemainingDuration = function() return c.remaining or 1.5 end,
      GetTotalDuration = function() return c.total or 2 end,
      GetElapsedDuration = function() return (c.total or 2) - (c.remaining or 1.5) end,
    }
  end
  M.UnitCastingInfo = function(unit)
    local c = M.__casts[unit]
    if c and c.kind == "cast" then return c.name, c.name, c.texture, 0, 0, false, 1, c.notInterruptible end
  end
  M.UnitChannelInfo = function(unit)
    local c = M.__casts[unit]
    if c and c.kind ~= "cast" then
      return c.name, c.name, c.texture, 0, 0, false, c.notInterruptible, 1, c.kind == "empower"
    end
  end
  M.UnitCastingDuration = function(unit)
    local c = M.__casts[unit]
    return c and c.kind == "cast" and durationFor(c) or nil
  end
  M.UnitChannelDuration = function(unit)
    local c = M.__casts[unit]
    return c and c.kind ~= "cast" and durationFor(c) or nil
  end

  -- Every chat line the addon prints, in order. The printer (LibKa0s-Core-1.0, or core/CoreSetup.lua's
  -- fallback) reaches DEFAULT_CHAT_FRAME at call time, so recording here sees both arms.
  M.__chat = {}
  M.DEFAULT_CHAT_FRAME.AddMessage = function(_, msg) M.__chat[#M.__chat + 1] = msg end

  return M
end
