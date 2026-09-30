-- tests/test_debug_coverage.lua — what the debug console carries (debug-logging-§8, the flows and
-- the Diagnosis checklist) and what it does NOT carry (§9, quiet steady state). Each case captures
-- the tagged lines NS.Debug receives with the flag on. A "quiet" case drives a repeating path N
-- times with nothing changed and asserts the log gained nothing past the first line.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local NS, mocks = T.NS, T.mocks

--- The `Tag message` lines NS.Debug received while `fn` ran, with the flag on. Put back after,
--- raising or not.
local function trace(fn)
  local lines = {}
  local savedDebug, savedFlag = NS.Debug, NS.State.debug
  NS.State.debug = true
  NS.Debug = function(tag, fmt, ...) lines[#lines + 1] = tag .. " " .. fmt:format(...) end
  local ok, err = pcall(fn, lines)
  NS.Debug, NS.State.debug = savedDebug, savedFlag
  if not ok then error(err, 0) end
  return lines
end

--- How many of `lines` start with `prefix`.
local function count(lines, prefix)
  local n = 0
  for _, line in ipairs(lines) do
    if line:sub(1, #prefix) == prefix then n = n + 1 end
  end
  return n
end

local function drainTimers()
  for _ = 1, 10 do if mocks.__fireTimers() == 0 then break end end
end

local function world(inGroup, inRaid)
  mocks.__context.inGroup, mocks.__context.inRaid = inGroup, inRaid
  mocks.__fireEvent("GROUP_ROSTER_UPDATE")
  drainTimers()
end

local function prep()
  local p = NS.db.profile
  p.enabled, p.visibility, p.locked = true, "always", true
  for _, key in ipairs({ "castbar", "target", "pet" }) do
    p[key].enabled, p[key].anchorMode = true, "free"
  end
  NS.bus:SendMessage(NS.MSG.PROFILE)
  drainTimers()
end

-- ── the secure queue: held and flushed, one line per key (§8 Deferred work, §9 quiet) ────────────

test("coverage: a secure write queued in combat logs once per key held, then one flush line", function()
  -- red under: the pre-060 `queued %s` line fired on EVERY write, and a re-sort in combat re-queues
  -- the same anchor pass many times a fight (a steady stream through the whole pull).
  mocks.InCombatLockdown = function() return true end
  local ran = 0
  local lines = trace(function()
    for _ = 1, 5 do NS.RunSecure("coverage:probe", function() ran = ran + 1 end) end
  end)
  assertEqual(count(lines, "Secure queued coverage:probe"), 1, "one line for the key held")
  assertTrue(lines[1]:find("combat lockdown", 1, true) ~= nil, "the line names why it is held")
  mocks.InCombatLockdown = function() return false end
  lines = trace(function() NS.addon:OnLeaveCombat() end)
  assertEqual(ran, 1, "the replaced writes ran once")
  assertTrue(count(lines, "Secure flushed 1 deferred write(s)") == 1, table.concat(lines, " | "))
  assertTrue(count(lines, "Combat left:") == 1, "the combat rollup follows")
end)

-- ── state edges (§8 Diagnosis) ────────────────────────────────────────────────────────────────

test("coverage: entering combat, entering the world, and the stand-down and stand-up each log once", function()
  -- red under: none of these four edges had a line, so a log could not say whether the addon was up.
  prep()
  local lines = trace(function() NS.addon:OnEnterCombat() end)
  assertEqual(table.concat(lines, " | "), "Combat entered: secure writes queue until it ends")
  NS.addon:OnLeaveCombat()
  lines = trace(function() NS.addon:OnEnterWorld() end)
  assertEqual(table.concat(lines, " | "), "State entered world: in a party")
  lines = trace(function()
    NS.SetByPath("enabled", false)
    drainTimers()
  end)
  assertEqual(count(lines, "State stood down (holds: disabled), 0 secure write(s) held"), 1,
    table.concat(lines, " | "))
  lines = trace(function()
    NS.SetByPath("enabled", true)
    drainTimers()
  end)
  assertEqual(count(lines, "State stood up, 0 secure write(s) held"), 1, table.concat(lines, " | "))
end)

test("coverage: a stand-down in combat names the secure writes it leaves held", function()
  -- red under: logged at the TOP of NS.StandDown, the count missed the driver releases the
  -- modules' Suspend hooks queue, so the line read 0 with a flush of ten to follow.
  prep()
  mocks.InCombatLockdown = function() return true end
  local lines = trace(function() NS.SetByPath("enabled", false) end)
  local line
  for _, l in ipairs(lines) do if l:find("^State stood down") then line = l end end
  assertTrue(line ~= nil, table.concat(lines, " | "))
  local held = tonumber(line:match("(%d+) secure write"))
  assertTrue(held and held > 0 and held == NS.PendingSecureCount(), line)
  mocks.InCombatLockdown = function() return false end
  mocks.__fireEvent("PLAYER_REGEN_ENABLED")
  NS.SetByPath("enabled", true)
  drainTimers()
end)

-- ── data mutations and refusals (§8) ──────────────────────────────────────────────────────────

test("coverage: a profile delete logs its one line, and the callback is registered", function()
  -- red under: a delete (the Profiles page or `/pfe profile delete`) left no trace at all.
  local lines = trace(function() NS.OnProfileDeleted("OnProfileDeleted", NS.db, "Old") end)
  assertEqual(table.concat(lines, " | "), "Profile deleted 'Old'")
  local f = assert(io.open("core/Database.lua", "rb"))
  local src = f:read("*a")
  f:close()
  assertTrue(src:find('"OnProfileDeleted", NS.OnProfileDeleted', 1, true) ~= nil,
    "InitDB registers the handler")
end)

test("coverage: a free-placement reset and a drag each log one line", function()
  -- red under: `/pfe resetposition` and a dropped drag moved the stacks with no trace.
  prep()
  local lines = trace(function() NS.Anchor.ResetPositions() end)
  assertEqual(count(lines, "Anchor positions reset to default (3 feature(s))"), 1, table.concat(lines, " | "))
  local holder = NS.Anchor.__features.castbar.holder
  rawset(holder, "GetPoint", function() return "TOPLEFT", nil, "TOPLEFT", 40.2, -59.8 end)
  lines = trace(function() holder:__fire("OnDragStop") end)
  rawset(holder, "GetPoint", nil)
  assertEqual(count(lines, "Anchor castbar dragged to TOPLEFT 40, -60"), 1, table.concat(lines, " | "))
  NS.Anchor.ResetPositions()
end)

test("coverage: an unlock refused in combat names the guard on the console", function()
  -- red under: the refusal went to chat only, so a copied log showed a lock that never moved.
  prep()
  mocks.InCombatLockdown = function() return true end
  local lines = trace(function() NS.SetByPath("locked", false) end)
  mocks.InCombatLockdown = function() return false end
  assertEqual(count(lines, "Preview unlock refused: in combat"), 1, table.concat(lines, " | "))
  assertTrue(NS.GetSetting("locked") == true, "still locked")
end)

-- ── dependencies (§8 Diagnosis) ───────────────────────────────────────────────────────────────

test("coverage: the [Init] summary says whether EllesmereUI's raid frames are loaded", function()
  -- red under: the optional dependency was said nowhere; the flag is off at login, so the summary
  -- is the one place an at-enable line can land.
  local saved = NS.State.debug
  NS.State.debug = false
  NS.DebugLog:SetEnabled(true)
  local line = NS.DebugLog:FindLine("EllesmereUI raid frames")
  NS.DebugLog:SetEnabled(saved)
  assertTrue(line ~= nil and line:find("[Init]", 1, true) ~= nil, tostring(line))
  assertTrue(line:find("frames '", 1, true) ~= nil, "after the frame system")
end)

test("coverage: EllesmereUI loading after us logs one line", function()
  -- red under: ADDON_LOADED for EllesmereUI re-resolved silently, so a log could not show that
  -- the dependency loaded late or that the frame map was rebuilt for it.
  local lines = trace(function()
    mocks.__fireEvent("ADDON_LOADED", "EllesmereUIRaidFrames")
    mocks.__fireEvent("ADDON_LOADED", "SomeOtherAddon")
    drainTimers()
  end)
  assertEqual(count(lines, "Provider EllesmereUIRaidFrames loaded after us: re-resolving"), 1,
    table.concat(lines, " | "))
  assertEqual(count(lines, "Provider SomeOtherAddon"), 0, "another addon is not a dependency")
end)

test("coverage: a refused EditMode.Exit registration is logged once per distinct error", function()
  -- red under: the pcall swallowed it, so an Edit Mode exit silently re-resolved nothing.
  local registry = mocks.EventRegistry
  local saved = registry.RegisterCallback
  registry.RegisterCallback = function() error("coverage: refused", 0) end
  local lines = trace(function()
    for _ = 1, 3 do
      NS.Providers:Suspend()
      NS.Providers:Resume()
    end
  end)
  registry.RegisterCallback = saved
  NS.Providers:Suspend()
  NS.Providers:Resume()
  drainTimers()
  assertEqual(count(lines, "Provider EditMode.Exit register failed: coverage: refused"), 1,
    table.concat(lines, " | "))
end)

-- ── quiet steady state (§9): one test per repeating path fixed ────────────────────────────────

test("coverage quiet: repeated UNIT_TARGET with the same target logs once, a new target once more", function()
  -- red under: `%s targets %s` on every UNIT_TARGET and PLAYER_TARGET_CHANGED, changed or not.
  prep()
  local btn = NS.TargetFrames.__buttons.party1
  mocks.__units.party1target = { name = "Dummy" }
  local lines = trace(function()
    for _ = 1, 6 do btn:__fire("OnEvent", "UNIT_TARGET", "party1") end
  end)
  assertEqual(count(lines, "Target party1 targets Dummy"), 1, table.concat(lines, " | "))
  mocks.__units.party1target = { name = "Boss" }
  lines = trace(function()
    for _ = 1, 3 do btn:__fire("OnEvent", "UNIT_TARGET", "party1") end
  end)
  assertEqual(count(lines, "Target party1 targets Boss"), 1, "a real change still logs")
  mocks.__units.party1target = nil
  btn:__fire("OnEvent", "UNIT_TARGET", "party1")
  mocks.__runStateDrivers()
  NS.db.profile.target.enabled = false
  NS.TargetFrames.UpdateTicker()
  NS.db.profile.target.enabled = true
  while mocks.__fireTimers() > 0 do end
end)

test("coverage quiet: repeated UNIT_PET with the same pet logs once", function()
  -- red under: `%s pet: %s` on every UNIT_PET, the same pet or not.
  prep()
  local btn = NS.PetFrames.__buttons.party1
  mocks.__units.partypet1 = { name = "Wolf" }
  local lines = trace(function()
    for _ = 1, 6 do btn:__fire("OnEvent", "UNIT_PET", "party1") end
  end)
  assertEqual(count(lines, "Pet party1 pet: Wolf"), 1, table.concat(lines, " | "))
  mocks.__units.partypet1 = { exists = false }
  lines = trace(function() btn:__fire("OnEvent", "UNIT_PET", "party1") end)
  mocks.__units.partypet1 = nil
  assertEqual(count(lines, "Pet party1 pet: none"), 1, "the pet going is a change")
end)

test("coverage quiet: previewing out of a party, a roster burst re-logs no unchanged stand-in", function()
  -- red under: dress() logged `stand-in as ...` on every GROUP_ROSTER_UPDATE while previewing
  -- solo or in a raid, where the roster fires many times a minute.
  prep()
  world(false, false)
  local lines = trace(function()
    NS.SetByPath("locked", false)
    for _ = 1, 6 do world(false, false) end
  end)
  assertEqual(count(lines, "Preview stand-in as "), 1, table.concat(lines, " | "))
  -- Joining and leaving again is a new raise, and says so.
  lines = trace(function()
    world(true, false)
    world(false, false)
  end)
  assertEqual(count(lines, "Preview stand-in as "), 1, "a raise after a lower logs again")
  NS.SetByPath("locked", true)
  world(true, false)
end)

test("coverage quiet: the range fade logs its mode on change, not on every LAYOUT", function()
  -- red under: a per-pass line in update() would fire on every LAYOUT, VISIBILITY and PROFILE.
  prep()
  NS.SetByPath("general.rangeFade", false)
  local lines = trace(function()
    NS.SetByPath("general.rangeFade", true)
    for _ = 1, 8 do NS.bus:SendMessage(NS.MSG.LAYOUT) end
    NS.PublishVisibility()
  end)
  assertEqual(count(lines, "Fade "), 1, table.concat(lines, " | "))
  lines = trace(function() NS.SetByPath("general.rangeFade", false) end)
  assertEqual(count(lines, "Fade off,"), 1, "turning it off is a change")
  NS.SetByPath("general.rangeFade", NS.defaults.profile.general.rangeFade)
end)
