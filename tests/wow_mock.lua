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

  -- Every chat line the addon prints, in order. The printer (LibKa0s-Core-1.0, or core/CoreSetup.lua's
  -- fallback) reaches DEFAULT_CHAT_FRAME at call time, so recording here sees both arms.
  M.__chat = {}
  M.DEFAULT_CHAT_FRAME.AddMessage = function(_, msg) M.__chat[#M.__chat + 1] = msg end

  return M
end
