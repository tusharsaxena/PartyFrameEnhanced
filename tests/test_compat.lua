-- tests/test_compat.lua — core/Compat.lua: the secret guards and the version-variant shims.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local NS, mocks = T.NS, T.mocks
local Compat = NS.Compat

-- A stand-in for a client secret: issecretvalue answers true for it and nothing else. It is a
-- table, so a comparison against a string answers false rather than raising — the cases below
-- therefore assert the guard's RESULT, which is what a secret would change.
local SECRET = setmetatable({}, { __tostring = function() return "<secret>" end })

local function withSecrets(fn)
  mocks.issecretvalue = function(v) return v == SECRET end
  local ok, err = pcall(fn)
  mocks.issecretvalue = nil
  if not ok then error(err, 0) end
end

local function frame(fields)
  local f = mocks.CreateFrame("Frame")
  for k, v in pairs(fields or {}) do rawset(f, k, v) end
  return f
end

test("compat: IsSecret answers false without the client's issecretvalue", function()
  assertFalse(Compat.IsSecret("x"))
end)

test("compat: FrameUnit prefers displayedUnit, then unit, then unitToken, then the attribute", function()
  assertEqual(Compat.FrameUnit(frame({ displayedUnit = "vehicle", unit = "party1" })), "vehicle")
  assertEqual(Compat.FrameUnit(frame({ unit = "party2" })), "party2")
  assertEqual(Compat.FrameUnit(frame({ unitToken = "party3" })), "party3")
  local f = frame()
  f.GetAttribute = function(_, k) return k == "unit" and "party4" or nil end
  assertEqual(Compat.FrameUnit(f), "party4")
end)

test("compat: FrameUnit rejects a secret, an empty string and a non-string, and moves on", function()
  withSecrets(function()
    assertEqual(Compat.FrameUnit(frame({ displayedUnit = SECRET, unit = "party1" })), "party1")
    assertEqual(Compat.FrameUnit(frame({ unit = "" , unitToken = "party2" })), "party2")
    local f = frame()
    f.GetAttribute = function() return SECRET end
    assertNil(Compat.FrameUnit(f), "a secret attribute is no unit at all")
  end)
  -- The bare stub answers its own frame for GetAttribute; that is not a unit either.
  assertNil(Compat.FrameUnit(frame()))
end)

test("compat: FrameVisible fails open on a secret and closed on nil or an error", function()
  local f = frame()
  f:Show()
  assertTrue(Compat.FrameVisible(f))
  f:Hide()
  assertFalse(Compat.FrameVisible(f))
  withSecrets(function()
    f.IsVisible = function() return SECRET end
    assertTrue(Compat.FrameVisible(f), "a secret visibility reads as shown")
  end)
  f.IsVisible = function() error("boom") end
  assertFalse(Compat.FrameVisible(f))
  assertFalse(Compat.FrameVisible(nil))
end)

test("compat: UseRaidStyleParty reads Edit Mode first and the CVar second", function()
  mocks.EditModeManagerFrame = { UseRaidStylePartyFrames = function() return true end }
  assertTrue(Compat.UseRaidStyleParty())
  mocks.EditModeManagerFrame = nil
  mocks.GetCVarBool = function(name) return name == "useCompactPartyFrames" end
  assertTrue(Compat.UseRaidStyleParty())
  mocks.GetCVarBool = nil
  assertFalse(Compat.UseRaidStyleParty())
end)

test("compat: IsAddOnLoaded goes through C_AddOns and answers false without it", function()
  assertFalse(Compat.IsAddOnLoaded("EllesmereUIRaidFrames"))
  mocks.C_AddOns = { IsAddOnLoaded = function(name) return name == "EllesmereUIRaidFrames" end }
  assertTrue(Compat.IsAddOnLoaded("EllesmereUIRaidFrames"))
  assertFalse(Compat.IsAddOnLoaded("Other"))
  mocks.C_AddOns = nil
end)
