-- tests/test_profile_switch.lua — a REAL profile switch, copy and reset, and where every element ends up
-- afterwards. modules/Anchor.lua re-applies on MSG.PROFILE, and so does each feature re-bind its own
-- `cfg` on MSG.PROFILE; CallbackHandler-1.0 dispatches with next() over per-target tables, so the
-- order those handlers run in is hash order, not TOC order. Anchor therefore reads the LIVE profile
-- section and never depends on a feature having re-bound first. These cases pin that.

local T = _G.PFE_TEST
local test, assertTrue = T.test, T.assertTrue
local NS, mocks = T.NS, T.mocks
local Anchor, Units = NS.Anchor, NS.Units

local KEYS = { "castbar", "target", "pet" }
local FREE, COPY = "PFE-Free", "PFE-Copy"

local function settle()
  while mocks.__fireTimers() > 0 do end
end

local function hasProfile(name)
  for _, n in ipairs(NS.db:GetProfiles()) do
    if n == name then return true end
  end
  return false
end

-- A fixed frame for every unit, so an attached element has a provider frame to pin to and the
-- attached and free answers can never coincide.
local function withFrames(fn)
  local frames = {}
  for _, unit in ipairs(Units.LIST) do frames[unit] = mocks.CreateFrame("Frame") end
  local orig = NS.Providers.FrameFor
  NS.Providers.FrameFor = function(unit) return frames[unit] end
  local ok, err = pcall(fn, frames)
  NS.Providers.FrameFor = orig
  if not ok then error(err, 0) end
end

local function setMode(mode)
  for _, key in ipairs(KEYS) do NS.SetByPath(key .. ".anchorMode", mode) end
  settle()
end

-- Every feature's elements where `mode` puts them: the unit's provider frame when attached, the
-- feature's holder when free (a unit left out of the stack is unpinned either way).
local function assertPlaced(mode, frames, why)
  for _, key in ipairs(KEYS) do
    local spec = Anchor.__features[key]
    for _, unit in ipairs(Units.LIST) do
      local want = frames[unit]
      if mode == "free" then want = Units.IsIncluded(unit) and spec.holder or nil end
      assertTrue(spec.elements[unit].__aTarget == want,
        ("%s: %s %s is not on its %s anchor"):format(why, key, unit, mode))
    end
  end
end

-- Default attached, FREE with all three features in free placement, and the store back on Default.
local function prepare()
  local start = NS.db:GetCurrentProfile()
  setMode("attached")
  NS.db:SetProfile(FREE)
  setMode("free")
  NS.db:SetProfile(start)
  settle()
  return start
end

local function cleanup(start)
  NS.db:SetProfile(start)
  settle()
  for _, name in ipairs({ FREE, COPY }) do
    if hasProfile(name) then NS.db:DeleteProfile(name, true) end
  end
  settle()
end

local function case(fn)
  return function()
    local start = prepare()
    local ok, err = pcall(withFrames, function(frames)
      Anchor.ApplyAll()
      fn(frames, start)
    end)
    cleanup(start)
    if not ok then error(err, 0) end
  end
end

test("profile switch: Anchor places by the NEW profile even when it hears PROFILE first", case(function(frames)
  -- red under: revert config() to the captured upvalue. With every receiver stood down, nothing
  -- re-binds a feature's `cfg`; this ApplyAll is exactly Anchor winning the hash-order race.
  assertPlaced("attached", frames, "before the switch")
  NS.BusStandDown()
  local ok, err = pcall(function()
    NS.db:SetProfile(FREE)
    Anchor.ApplyAll()
    assertPlaced("free", frames, "Anchor ahead of every feature")
  end)
  NS.BusStandUp()
  NS.OnProfileChanged()
  settle()
  if not ok then error(err, 0) end
end))

test("profile switch: a real SetProfile each way follows the profile", case(function(frames, start)
  -- red under: revert config() to the captured upvalue (whenever the bus runs Anchor first).
  for _ = 1, 2 do
    NS.db:SetProfile(FREE)
    settle()
    assertPlaced("free", frames, "switched to " .. FREE)
    NS.db:SetProfile(start)
    settle()
    assertPlaced("attached", frames, "switched back to " .. start)
  end
end))

test("profile switch: Reset all settings on a free profile returns it to attached", case(function(frames)
  NS.db:SetProfile(FREE)
  settle()
  assertPlaced("free", frames, "switched to " .. FREE)
  NS.Helpers.RestoreAllDefaults()
  settle()
  assertPlaced("attached", frames, "after Reset all settings")
end))

test("profile switch: copying a free profile in places by the copy", case(function(frames)
  NS.db:SetProfile(COPY)
  settle()
  assertPlaced("attached", frames, "a fresh profile")
  NS.db:CopyProfile(FREE)
  settle()
  assertPlaced("free", frames, "after copying " .. FREE)
end))
