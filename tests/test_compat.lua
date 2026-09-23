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

-- ── the secret guard (LibKa0s-Compat-1.0's IsSecret) ─────────────────────────────────────────

-- Every answer as a list, so a changed arity or a truthy non-boolean shows as a difference.
local function answers(...) return { n = select("#", ...), ... } end

test("compat: IsSecret answers exactly one boolean, true only for what the client marks secret", function()
  withSecrets(function()
    local cases = { { SECRET, true }, { "party1", false }, { 0, false }, { false, false }, { {}, false } }
    for _, c in ipairs(cases) do
      local got = answers(Compat.IsSecret(c[1]))
      assertEqual(got.n, 1, "one value for " .. tostring(c[1]))
      assertEqual(got[1], c[2], tostring(c[1]))
    end
    local got = answers(Compat.IsSecret(nil))
    assertEqual(got.n, 1, "one value for nil")
    assertEqual(got[1], false, "nil is not secret")
  end)
  local got = answers(Compat.IsSecret(SECRET))
  assertEqual(got.n, 1)
  assertEqual(got[1], false, "without issecretvalue nothing is secret")
end)

local loadDegraded = dofile("tests/degraded_env.lua")

-- Every member of LibKa0s-Compat-1.0 this addon deliberately does not wire onto NS.Compat: the two
-- other guards and the six readers have no caller in this tree. A member the major gains later is in
-- neither list, so parity fails until this addon decides.
local NOT_WIRED = {
  "CanAccess", "IsSafeKey",
  "GetSpellInfo", "GetSpellName", "GetSpellTexture", "GetSpellCooldown",
  "GetSpecialization", "GetSpecializationInfo",
}

test("compat: IsSecret is the library's member on the live load", function()
  assertTrue(Compat.IsSecret == mocks.LibStub("LibKa0s-Compat-1.0").IsSecret)
end)

test("compat: without the library the guard stub answers what the library answers, fixture for fixture", function()
  local NS2, mocks2 = loadDegraded()
  local stub = NS2.Compat.IsSecret
  assertTrue(stub ~= Compat.IsSecret, "the degraded load took the stub")
  local values = { SECRET, "party1", 0, false, {}, n = 6 }
  local function compare(label)
    for i = 1, values.n do
      local live, degraded = answers(Compat.IsSecret(values[i])), answers(stub(values[i]))
      assertEqual(degraded.n, live.n, label .. ": arity for " .. tostring(values[i]))
      assertEqual(degraded[1], live[1], label .. ": " .. tostring(values[i]))
    end
  end
  compare("no issecretvalue")
  local fixture = function(v) return v == SECRET end
  mocks.issecretvalue, mocks2.issecretvalue = fixture, fixture
  local ok, err = pcall(compare, "issecretvalue present")
  mocks.issecretvalue, mocks2.issecretvalue = nil, nil
  if not ok then error(err, 0) end
end)

test("compat: NS.Compat carries every LibKa0s-Compat-1.0 member it wires", function()
  T.assertSurfaceParity(Compat, "LibKa0s-Compat-1.0", NOT_WIRED)
  T.assertSurfaceParity(loadDegraded().Compat, "LibKa0s-Compat-1.0", NOT_WIRED)
end)
