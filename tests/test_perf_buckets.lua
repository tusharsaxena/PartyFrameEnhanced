-- tests/test_perf_buckets.lua — every declared perf bucket is reached by a real bracket, and every
-- nested one reports the parent it is declared under (performance-§3). A bucket no bracket reaches
-- is a lie in every report; a nesting claim with no observed parent is an unverified one.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local NS, mocks = T.NS, T.mocks

-- Capture on, with Perf.Note swapped for a recorder. Modules read `Perf.Note` off the shared
-- instance at call time, so the spy sees every bracket.
local function capture(fn)
  local seen = {}
  local Perf = NS.Perf
  local origNote, origOn = Perf.Note, Perf.on
  Perf.Note = function(key, _, parent)
    seen[key] = seen[key] or {}
    seen[key][parent or "-"] = true
  end
  Perf.on = true
  local ok, err = pcall(fn)
  Perf.Note, Perf.on = origNote, origOn
  if not ok then error(err, 0) end
  return seen
end

local function drive()
  local p = NS.db.profile
  p.enabled, p.visibility = true, "always"
  p.castbar.anchorMode, p.target.anchorMode, p.pet.anchorMode = "free", "free", "free"
  p.castbar.fadeOut = false
  NS.PublishVisibility()

  NS.Providers.Resolve()                                            -- resolve
  NS.Anchor.Apply("castbar")                                        -- anchor

  local bar = NS.CastBars.__bars.party1
  mocks.__casts.party1 = { kind = "cast", name = "Heal", remaining = 1, total = 2 }
  bar:__fire("OnEvent", "UNIT_SPELLCAST_START", "party1")           -- castEvent, castRender
  bar:GetScript("OnUpdate")(bar, 0.2)                               -- castTick
  mocks.__casts.party1 = nil
  bar:__fire("OnEvent", "UNIT_SPELLCAST_STOP", "party1")

  mocks.__units.party2target = { name = "Boar", health = 5, healthMax = 10, reaction = 2 }
  NS.TargetFrames.__buttons.party2:__fire("OnEvent", "UNIT_TARGET", "party2")   -- targetEvent
  mocks.__runStateDrivers()                                         -- the driver shows it
  mocks.__units.party2target.health = 4
  mocks.__fireTimers()                                              -- targetTick, targetRender
  mocks.__units.party2target = nil
  mocks.__runStateDrivers()
  mocks.__fireTimers()                                              -- the ticker cancels itself

  NS.PetFrames.__buttons.party3:__fire("OnEvent", "UNIT_HEALTH", "partypet3")    -- petEvent
  NS.SetByPath("castbar.height", NS.GetSetting("castbar.height"))  -- reskin
end

test("perf: every declared bucket is reached by a real bracket", function()
  local seen = capture(drive)
  for _, key in ipairs(NS.Perf.BUCKET_ORDER) do
    assertTrue(seen[key] ~= nil, "no bracket reached the declared bucket '" .. key .. "'")
  end
end)

test("perf: each nested bucket is observed inside the parent it declares", function()
  local seen = capture(drive)
  assertTrue(seen.castRender and seen.castRender.castEvent, "castRender is noted inside castEvent")
  assertTrue(seen.targetRender and seen.targetRender.targetTick, "targetRender is noted inside targetTick")
  -- And the roots are noted as roots: a root that reported a parent would be an undeclared nesting.
  for _, root in ipairs({ "resolve", "anchor", "castEvent", "castTick", "targetEvent",
                          "targetTick", "petEvent", "reskin" }) do
    assertEqual(next(seen[root]), "-", root .. " is noted with no parent")
  end
end)

test("perf: capture off, no bracket calls the sink", function()
  local calls = 0
  local Perf = NS.Perf
  local orig = Perf.Note
  Perf.Note = function() calls = calls + 1 end
  Perf.on = false
  drive()
  Perf.Note = orig
  assertEqual(calls, 0)
end)
