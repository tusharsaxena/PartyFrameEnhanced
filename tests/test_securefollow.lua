-- tests/test_securefollow.lua — modules/SecureFollow.lua (#3): the target and pet frames follow their
-- member through an in-combat re-sort by a restricted snippet wrapped on the re-sorting provider's
-- member frames, with the fade-then-regen pass kept as the fallback for anything not wrapped.
--
-- WHAT THIS SUITE CAN AND CANNOT PROVE. The snippets RUN here, in tests/wow_mock.lua's restricted
-- environment (handles, no table constructors, a short global list), against the real header's
-- attributes and frame refs; the wrap, the unwrap and the attribute sync run against the mock's
-- lockdown model. Whether the client lets a third-party header wrap EllesmereUI's or Blizzard's
-- member frames, whether those frames change their `unit` attribute in combat at all, and whether
-- any of it taints, is the owner's in-client smoke (docs/smoke-tests.md COMBAT-6/9/10). Nothing here
-- claims otherwise.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertNil, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertNil, T.assertFalse
local NS, mocks = T.NS, T.mocks
local SF = NS.SecureFollow

local function settle() while mocks.__fireTimers() > 0 do end end

local function combat(on) mocks.InCombatLockdown = function() return on end end

local function regen()
  combat(false)
  NS.addon:OnLeaveCombat()
  settle()
end

local function pending(key)
  for _, k in ipairs(NS.PendingSecureKeys()) do if k == key then return true end end
  return false
end

-- A member frame as a SecureGroupHeader child presents it: the unit is an ATTRIBUTE, the frame is
-- protected, and it is on screen.
local function member(unit, protected)
  local f = mocks.CreateFrame("Button")
  f.__attrs = { unit = unit }
  rawset(f, "GetAttribute", function(self, k) return self.__attrs[k] end)
  rawset(f, "IsProtected", function() return protected ~= false end)
  f:Show()
  return f
end

local function reset()
  mocks.ERFPartyHeader, mocks.ERFPartySelfButton = nil, nil
  mocks.CompactPartyFrame, mocks.PartyFrame, mocks.EditModeManagerFrame = nil, nil, nil
  mocks.C_AddOns = nil
  NS.db.profile.general.provider = "auto"
  NS.Providers.Resolve()
  settle()
end

-- EllesmereUI's party header with one child per unit; `unprotected` names the units whose frame
-- reports IsProtected() false. Resolved, so LAYOUT has run.
local function installEllesmere(units, unprotected)
  local header = mocks.CreateFrame("Frame", "ERFPartyHeader")
  header:Show()
  local byIndex = {}
  for i, unit in ipairs(units) do
    header[i] = member(unit, not (unprotected and unprotected[unit]))
    byIndex[i] = header[i]
  end
  mocks.ERFPartyHeader = header
  mocks.C_AddOns = { IsAddOnLoaded = function(name) return name == "EllesmereUIRaidFrames" end }
  NS.Providers.Resolve()
  settle()
  return byIndex
end

local function installClassic(units)
  local pf = mocks.CreateFrame("Frame", "PartyFrame")
  pf:Show()
  local frames = {}
  for i, unit in ipairs(units) do
    local f = member(unit)
    pf["MemberFrame" .. i] = f
    frames[i] = f
  end
  mocks.PartyFrame = pf
  NS.Providers.Resolve()
  settle()
  return frames
end

local function buttonsOf(feat)
  return feat == "target" and NS.TargetFrames.__buttons or NS.PetFrames.__buttons
end

-- Every target and pet button records its ClearAllPoints and SetPoint calls for the duration.
local function recording(fn)
  local all = {}
  for _, feat in ipairs({ "target", "pet" }) do
    for _, b in pairs(buttonsOf(feat)) do
      b.__pts, b.__clr = {}, 0
      rawset(b, "SetPoint", function(self, ...) self.__pts[#self.__pts + 1] = { ... } end)
      rawset(b, "ClearAllPoints", function(self) self.__clr = self.__clr + 1; self.__pts = {} end)
      all[#all + 1] = b
    end
  end
  local ok, err = pcall(fn)
  for _, b in ipairs(all) do
    rawset(b, "SetPoint", nil)
    rawset(b, "ClearAllPoints", nil)
    b.__pts, b.__clr = nil, nil
  end
  -- Out of combat through the real regen path, so nothing this case queued leaks into the next.
  regen()
  if not ok then error(err, 0) end
end

local function wrapsOn(frame)
  return frame.__wraps and frame.__wraps.OnAttributeChanged and #frame.__wraps.OnAttributeChanged or 0
end

local function attr(k) return SF.__header():GetAttribute(k) end

-- The suites before this one leave the features in whatever placement they last tested. This one
-- needs both attached at their shipped placement, and puts back what it found in its last case.
local SAVED_KEYS = { "enabled", "anchorMode", "point", "relativePoint", "offsetX", "offsetY", "matchWidth" }
local saved = {}

test("securefollow: setup — target and pet attached at their shipped placement", function()
  for _, feat in ipairs({ "target", "pet" }) do
    local cfg, d = NS.db.profile[feat], NS.defaults.profile[feat]
    saved[feat] = {}
    for _, k in ipairs(SAVED_KEYS) do
      saved[feat][k] = cfg[k]
      cfg[k] = d[k]
    end
  end
  NS.bus:SendMessage(NS.MSG.PROFILE)
  settle()
end)

-- ── the snippets and the header ──────────────────────────────────────────────────────────────

test("securefollow: one restricted snippet per RE-SORTING provider, and none for classic", function()
  -- red under: no modules/SecureFollow.lua, or a snippet table that covers Blizzard classic, which
  -- never re-sorts and has nothing to follow.
  assertTrue(SF ~= nil, "NS.SecureFollow is published")
  assertTrue(type(SF.SNIPPET.ellesmere) == "string", "EllesmereUI re-sorts in combat")
  assertTrue(type(SF.SNIPPET["blizzard-raid"]) == "string", "Blizzard raid-style re-sorts in combat")
  assertNil(SF.SNIPPET["blizzard-party"], "Blizzard classic never re-sorts")
  for id, body in pairs(SF.SNIPPET) do
    assertFalse(body:find("{", 1, true) ~= nil, id .. ": the restricted dialect has no table constructor")
    assertTrue(body:find('"' .. id .. '"', 1, true) ~= nil, id .. ": the provider id is embedded literally")
  end
end)

test("securefollow: one SecureHandlerBaseTemplate header, hidden, holding a ref to every button", function()
  -- red under: combining templates (the injected methods are dropped), or a header left shown,
  -- which the stand-down census in tests/test_disabled.lua would then see as the addon's screen.
  local h = SF.__header()
  assertTrue(h ~= nil, "the header was built at OnEnable")
  assertEqual(h.__template, "SecureHandlerBaseTemplate", "exactly one template")
  assertEqual(h.__name, "PartyFrameEnhancedSecureFollow")
  assertFalse(h:IsShown(), "the header draws nothing")
  for _, feat in ipairs({ "target", "pet" }) do
    for _, unit in ipairs(NS.Units.LIST) do
      assertTrue(h.__attrs["frameref-" .. feat .. ":" .. unit] == buttonsOf(feat)[unit],
        feat .. ":" .. unit .. " frame ref")
    end
  end
end)

-- ── the attribute sync ───────────────────────────────────────────────────────────────────────

test("securefollow: Sync publishes the provider and each feature's placement as attributes", function()
  installEllesmere({ "player", "party1", "party2" })
  assertEqual(attr("pfe-provider"), "ellesmere")
  assertEqual(attr("target-live"), true, "attached and enabled: the target frames follow")
  assertEqual(attr("target-point"), "TOPLEFT")
  assertEqual(attr("target-rel"), "TOPRIGHT")
  assertEqual(attr("target-x"), 4)
  assertEqual(attr("target-y"), 0)
  assertEqual(attr("target-match"), false)
  assertEqual(attr("pet-y"), -20)
  NS.SetByPath("target.matchWidth", true)
  assertEqual(attr("target-match"), true)
  assertEqual(attr("target-lp") .. ">" .. attr("target-lr"), "TOPLEFT>TOPLEFT")
  assertEqual(attr("target-rp") .. ">" .. attr("target-rr"), "TOPRIGHT>TOPRIGHT")
  NS.SetByPath("target.matchWidth", false)
  NS.SetByPath("target.anchorMode", "free")
  assertEqual(attr("target-live"), false, "free placement: nothing to follow")
  NS.SetByPath("target.anchorMode", "attached")
  assertEqual(attr("target-live"), true)
  reset()
  assertEqual(attr("pfe-provider"), "none", "no frame system on screen")
end)

test("securefollow: a Sync that changes nothing writes no attribute", function()
  -- red under: dropping the per-attribute memo, which rewrites every attribute on every message.
  installEllesmere({ "player", "party1" })
  local h = SF.__header()
  local before = h.__attrWrites
  SF.Sync()
  NS.bus:SendMessage(NS.MSG.CONFIG, "general")
  NS.bus:SendMessage(NS.MSG.VISIBILITY)
  assertEqual(h.__attrWrites, before, "nothing changed, nothing written")
  reset()
end)

test("securefollow: a placement change in combat is queued, and lands at regen", function()
  -- red under: writing the header's attributes under lockdown (the mock raises, as the client blocks).
  installEllesmere({ "player", "party1" })
  combat(true)
  NS.SetByPath("target.offsetX", 10)
  assertEqual(attr("target-x"), 4, "the header keeps the old offset through combat")
  assertTrue(pending("follow:sync"), "the sync waits for regen")
  regen()
  assertEqual(attr("target-x"), 10, "and lands at regen")
  NS.SetByPath("target.offsetX", 4)
  reset()
end)

-- ── the snippet, run in the restricted environment ───────────────────────────────────────────

test("securefollow: a re-sort in combat moves the member's target and pet frames to its new frame", function()
  -- red under: a snippet that anchors to the OLD frame, or reads the wrong feature's attributes.
  local frames = installEllesmere({ "player", "party1", "party2" })
  recording(function()
    combat(true)
    mocks.__changeAttribute(frames[2], "unit", "party2")
    local t, p = buttonsOf("target").party2, buttonsOf("pet").party2
    assertEqual(t.__clr, 1, "the target frame was cleared once")
    assertEqual(#t.__pts, 1)
    assertEqual(t.__pts[1][1], "TOPLEFT")
    assertTrue(t.__pts[1][2] == frames[2], "anchored to the frame that now shows party2")
    assertEqual(t.__pts[1][3] .. " " .. t.__pts[1][4] .. " " .. t.__pts[1][5], "TOPRIGHT 4 0")
    assertTrue(p.__pts[1][2] == frames[2], "the pet frame follows too")
    assertEqual(p.__pts[1][5], -20, "at the pet section's own offset")
    assertEqual(buttonsOf("target").party1.__clr, 0, "nobody else moved")
  end)
  reset()
end)

test("securefollow: match width follows with both edges", function()
  local frames = installEllesmere({ "player", "party1", "party2" })
  NS.SetByPath("target.matchWidth", true)
  recording(function()
    combat(true)
    mocks.__changeAttribute(frames[3], "unit", "party1")
    local pts = buttonsOf("target").party1.__pts
    assertEqual(#pts, 2)
    assertEqual(pts[1][1] .. ">" .. pts[1][3], "TOPLEFT>TOPLEFT")
    assertEqual(pts[2][1] .. ">" .. pts[2][3], "TOPRIGHT>TOPRIGHT")
    assertTrue(pts[2][2] == frames[3])
  end)
  NS.SetByPath("target.matchWidth", false)
  reset()
end)

test("securefollow: the snippet does nothing for another attribute, a raid unit, nil, or a stale provider", function()
  local frames = installEllesmere({ "player", "party1", "party2" })
  local h = mocks.__handle(SF.__header())
  local self_ = mocks.__handle(frames[2])
  recording(function()
    combat(true)
    local cases = {
      { SF.SNIPPET.ellesmere, "statehidden", "party2" },
      { SF.SNIPPET.ellesmere, "unit", "raid3" },
      { SF.SNIPPET.ellesmere, "unit", nil },
      { SF.SNIPPET["blizzard-raid"], "unit", "party2" },   -- the header says ellesmere
    }
    for i, c in ipairs(cases) do
      local r = mocks.__runRestricted(c[1], "case" .. i, self_, c[2], c[3], h)
      assertNil(r, "case " .. i .. ": a pre-body never answers false, which would block the frame's own handler")
    end
    for _, feat in ipairs({ "target", "pet" }) do
      for unit, b in pairs(buttonsOf(feat)) do assertEqual(b.__clr, 0, feat .. ":" .. unit .. " moved") end
    end
  end)
  reset()
end)

test("securefollow: a feature that is not live is left alone by the snippet", function()
  local frames = installEllesmere({ "player", "party1", "party2" })
  NS.SetByPath("target.anchorMode", "free")
  recording(function()
    combat(true)
    mocks.__changeAttribute(frames[2], "unit", "party2")
    assertEqual(buttonsOf("target").party2.__clr, 0, "free placement: the target frame stays put")
    assertEqual(buttonsOf("pet").party2.__clr, 1, "the pet frame is attached and follows")
  end)
  NS.SetByPath("target.anchorMode", "attached")
  reset()
end)

-- ── the wrap ─────────────────────────────────────────────────────────────────────────────────

test("securefollow: frames that appear in combat are wrapped at regen, once each", function()
  -- red under: wrapping under lockdown (the mock raises), or a wrap per LAYOUT, which nests our
  -- snippet on the same frame again and again.
  local calls = #mocks.__wrapCalls
  combat(true)
  local frames = installEllesmere({ "player", "party1", "party2" })
  assertEqual(#mocks.__wrapCalls, calls, "nothing wrapped under lockdown")
  assertTrue(pending("follow:wrap"), "the wrap waits for regen")
  regen()
  for i, f in ipairs(frames) do
    assertEqual(wrapsOn(f), 1, "frame " .. i .. " wrapped at regen")
    assertTrue(mocks.__wrapCalls[#mocks.__wrapCalls].header == SF.__header(), "by our header")
  end
  local after = #mocks.__wrapCalls
  NS.bus:SendMessage(NS.MSG.LAYOUT)
  NS.bus:SendMessage(NS.MSG.LAYOUT)
  assertEqual(#mocks.__wrapCalls, after, "a later LAYOUT wraps nothing twice")
  reset()
end)

test("securefollow: Blizzard classic and unprotected frames are never wrapped", function()
  local calls = #mocks.__wrapCalls
  installClassic({ "party1", "party2" })
  assertEqual(#mocks.__wrapCalls, calls, "classic does not re-sort: no wrap")
  reset()
  local frames = installEllesmere({ "player", "party1" }, { party1 = true })
  assertEqual(wrapsOn(frames[1]), 1, "the protected frame is wrapped")
  assertEqual(wrapsOn(frames[2]), 0, "the unprotected one keeps the fade fallback")
  reset()
end)

test("securefollow: a refused wrap is recorded and leaves that frame on the fade", function()
  local realWrap = mocks.SecureHandlerWrapScript
  mocks.SecureHandlerWrapScript = function() error("refused") end
  local before = NS.State.followRefused or 0
  local frames = installEllesmere({ "player", "party1" })
  mocks.SecureHandlerWrapScript = realWrap
  assertEqual(NS.State.followRefused, before + 2, "both refusals counted")
  assertFalse(SF.Covers("target", frames[1]), "a refused frame is not covered")
  reset()
end)

-- ── the anchor engine's in-combat pass ───────────────────────────────────────────────────────

test("securefollow: a re-sort onto a wrapped frame is followed, not faded, and re-pinned at regen", function()
  -- red under: deferSecure without the Covers check, which fades a frame the snippet already moved.
  local frames = installEllesmere({ "player", "party1", "party2" })
  local btn = buttonsOf("target").party2
  btn.__alphaSet = nil
  combat(true)
  mocks.__changeAttribute(frames[2], "unit", "party2")
  mocks.__changeAttribute(frames[3], "unit", "party1")
  NS.Providers.Resolve()
  assertTrue(NS.Providers.FrameFor("party2") == frames[2], "the map moved")
  assertTrue(btn.__alphaSet ~= 0, "followed: no combat fade")
  assertFalse(btn.__combatFaded == true)
  assertNil(btn.__aSet, "the memo is invalidated: restricted code moved it behind the memo's back")
  assertTrue(pending("anchor:target"), "the regen pass is still queued")
  regen()
  assertTrue(btn.__aTarget == frames[2], "regen re-pinned it to the frame the map holds")
  assertTrue(btn.__aSet == true)
  reset()
end)

test("securefollow: a re-sort onto an UNWRAPPED frame still fades (the COMBAT-6 fallback)", function()
  -- red under: skipping the fade for every frame of a re-sorting provider, wrapped or not.
  local frames = installEllesmere({ "player", "party1", "party2" }, { party2 = true })
  local btn = buttonsOf("target").party1
  combat(true)
  mocks.__changeAttribute(frames[3], "unit", "party1")
  mocks.__changeAttribute(frames[2], "unit", "party2")
  NS.Providers.Resolve()
  assertEqual(btn.__alphaSet, 0, "party1 landed on an unwrapped frame: faded")
  regen()
  assertEqual(btn.__alphaSet, btn.__alpha or 1, "and restored at regen")
  reset()
end)

test("securefollow: regen re-pins a followed element even when the map is back where the memo was", function()
  -- The A->B->A case: the snippet moved the frame away and back (or with attributes stale against
  -- a /pfe set made in combat), and the map ends on the frame the memo already names.
  -- red under: invalidating the memo only when the wanted frame differs from the memo's.
  installEllesmere({ "player", "party1", "party2" })
  local btn = buttonsOf("target").party2
  recording(function()
    combat(true)
    NS.Anchor.Apply("target")
    assertNil(btn.__aSet, "covered: the memo is invalidated even though nothing moved in Lua")
    regen()
    assertEqual(#btn.__pts, 1, "regen re-pinned it")
  end)
  reset()
end)

-- ── the stand-down (slash-commands-§7, the Documented-deviations row) ────────────────────────

test("securefollow: stand-down gates every follow off and unwraps where ours is outermost", function()
  local frames = installEllesmere({ "player", "party1" })
  NS.SetByPath("enabled", false)
  settle()
  assertEqual(attr("target-live"), false)
  assertEqual(attr("pet-live"), false)
  assertEqual(attr("pfe-provider"), "none")
  for i, f in ipairs(frames) do
    assertEqual(wrapsOn(f), 0, "frame " .. i .. " unwrapped")
    assertNil(SF.__wrapped[f], "and forgotten")
  end
  NS.SetByPath("enabled", true)
  settle()
  for i, f in ipairs(frames) do assertEqual(wrapsOn(f), 1, "frame " .. i .. " re-wrapped on stand-up") end
  assertEqual(attr("target-live"), true)
  assertEqual(attr("pfe-provider"), "ellesmere")
  reset()
end)

test("securefollow: stand-down restores another addon's outer wrap and leaves ours gated beneath it", function()
  -- red under: unwrapping blindly, which pops the OTHER addon's wrap and leaves ours live.
  local frames = installEllesmere({ "player", "party1" })
  local other = mocks.CreateFrame("Frame", nil, mocks.UIParent, "SecureHandlerBaseTemplate")
  mocks.SecureHandlerWrapScript(frames[1], "OnAttributeChanged", other, "-- theirs", "-- after")
  NS.SetByPath("enabled", false)
  settle()
  local stack = frames[1].__wraps.OnAttributeChanged
  assertEqual(#stack, 2, "both wraps are still there")
  assertTrue(stack[2].header == other, "theirs is outermost again")
  assertEqual(stack[2].pre .. "|" .. stack[2].post, "-- theirs|-- after", "restored exactly")
  assertTrue(stack[1].header == SF.__header(), "ours stays beneath it")
  assertTrue(SF.__wrapped[frames[1]] ~= nil, "and stays recorded")
  assertEqual(wrapsOn(frames[2]), 0, "the frame with only ours is unwrapped")
  recording(function()
    combat(true)
    mocks.__changeAttribute(frames[1], "unit", "party1")
    assertEqual(buttonsOf("target").party1.__clr, 0, "the gated residue moves nothing while disabled")
  end)
  NS.SetByPath("enabled", true)
  settle()
  assertEqual(#stack, 2, "stand-up does not nest a second wrap on the residue")
  assertEqual(wrapsOn(frames[2]), 1)
  reset()
end)

test("securefollow: a stand-down in combat queues the gate and the unwrap for regen", function()
  local frames = installEllesmere({ "player", "party1" })
  combat(true)
  NS.SetByPath("enabled", false)
  assertEqual(attr("target-live"), true, "nothing secure was touched under lockdown")
  assertTrue(pending("follow:sync") and pending("follow:wrap"), "both are held")
  combat(false)
  mocks.__fire("PLAYER_REGEN_ENABLED")
  assertEqual(attr("target-live"), false)
  assertEqual(wrapsOn(frames[1]), 0)
  NS.SetByPath("enabled", true)
  settle()
  reset()
end)

-- ── without the secure-handler API ───────────────────────────────────────────────────────────

test("securefollow: without SecureHandlerWrapScript the module is inert and the fade is unchanged", function()
  local Loader = dofile("tests/_kit/loader.lua")
  local m2, NS2 = dofile("tests/wow_mock.lua")(), {}
  m2.__context.inGroup, m2.__context.inRaid = true, false
  m2.SecureHandlerWrapScript, m2.SecureHandlerUnwrapScript = nil, nil
  Loader.addonName = "PartyFrameEnhanced"
  Loader.loadAll(Loader.xmlFiles("libs/LibKa0s/LibKa0s.xml"), NS2, m2)
  Loader.loadAll(Loader.tocFiles("PartyFrameEnhanced.toc"), NS2, m2)
  NS2:InitDB()
  NS2.addon:OnEnable()
  while m2.__fireTimers() > 0 do end
  assertNil(NS2.SecureFollow.__header(), "no header is built")
  local f = m2.CreateFrame("Button")
  assertFalse(NS2.SecureFollow.Covers("target", f), "nothing is covered")
  NS2.Providers.FrameFor = function() return f end
  m2.InCombatLockdown = function() return true end
  NS2.Anchor.Apply("target")
  assertEqual(NS2.TargetFrames.__buttons.party1.__alphaSet, 0, "the fade still runs")
end)

test("securefollow: the degraded build (LibKa0s absent) loads the module", function()
  local NS2 = dofile("tests/degraded_env.lua")()
  assertTrue(NS2.SecureFollow ~= nil)
  assertFalse(NS2.SecureFollow.Covers("target", {}), "nothing built, nothing covered")
end)

test("securefollow: teardown — the placement the earlier suites left is put back", function()
  for feat, values in pairs(saved) do
    for _, k in ipairs(SAVED_KEYS) do NS.db.profile[feat][k] = values[k] end
  end
  NS.bus:SendMessage(NS.MSG.PROFILE)
  settle()
end)
