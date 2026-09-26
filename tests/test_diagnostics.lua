-- tests/test_diagnostics.lua — modules/Diagnostics.lua, the addon's sections of `/pfe diagnostics`
-- (debug-logging-§14, DX-PF).
--
-- The dispatcher half of the rule (both forms, while disabled, append, ungated, the markers, `diag`
-- not running it) is the kit's shared case, tests/_kit/test_diagnostics_contract.lua, wired in
-- tests/run.lua. What stays here is what only this addon can know: which sections the report
-- carries, that each reads what it says it reads, that a stand-down is reported rather than shown as
-- empty data, that a raise or a secret costs one line at most, and that the report acts on nothing.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local NS, mocks = T.NS, T.mocks

local loadDegraded = dofile("tests/degraded_env.lua")

local function settle() while mocks.__fireTimers() > 0 do end end

--- The report as data, rendered `[Tag] msg` per line. Writes nothing.
local function report(spec)
  local r = NS.DebugLog:BuildDiagnostics(spec)
  local out = {}
  for i, line in ipairs(r.lines) do out[i] = "[" .. line[1] .. "] " .. line[2] end
  return out, r
end

--- The index of the first line containing `needle` (plain), or nil.
local function find(lines, needle, from)
  for i = from or 1, #lines do
    if lines[i]:find(needle, 1, true) then return i end
  end
  return nil
end

local function has(lines, needle) return find(lines, needle) ~= nil end

local function count(lines, needle)
  local n = 0
  for _, line in ipairs(lines) do
    if line:find(needle, 1, true) then n = n + 1 end
  end
  return n
end

local function readFile(path)
  local f = assert(io.open(path, "r"))
  local body = f:read("*a")
  f:close()
  return body
end

-- Every case restores what it changed, even when it fails, so later suites see the world they
-- expect: enabled, logging off, out of combat, no secret seam.
local function case(name, fn)
  test(name, function()
    local ok, err = pcall(fn)
    mocks.issecretvalue = nil
    mocks.InCombatLockdown = function() return false end
    NS.SetByPath("enabled", true)
    NS.State.debug = false
    settle()
    if not ok then error(err, 0) end
  end)
end

-- ── the descriptor ──────────────────────────────────────────────────────────────────────────

test("diagnostics: the console carries the brand and reads the sections at run time", function()
  local lines = report()
  assertEqual(lines[1], "[Diag] ==== Ka0s Party Frame Enhanced diagnostics begin ====",
    "the begin marker names the full brand, the same spelling the Slash descriptor uses")
  assertTrue(type(NS.Diagnostics) == "table" and type(NS.Diagnostics.Sections) == "function",
    "modules/Diagnostics.lua publishes NS.Diagnostics.Sections")
end)

-- ── the sections, in order ──────────────────────────────────────────────────────────────────

test("diagnostics: every DX-PF section is present, in order", function()
  -- red under: a section dropped from Sections(), or two swapped (the order is the read order a
  -- maintainer follows: who we are, what is configured, where we are, what we drew)
  local lines = report()
  local order = {
    "schema: stored=", "latch: enabled=", "Set] enabled = ", "party: inParty=", "frames: setting=",
    "place castbar:", "elem castbar player:", "fade: mode=", "secure: pending=", "events: rejected",
  }
  local at = 0
  for _, needle in ipairs(order) do
    local i = find(lines, needle, at + 1)
    assertTrue(i ~= nil, "the report has a line containing `" .. needle .. "` after line " .. at)
    at = i
  end
end)

test("diagnostics: the always-print rows print at their defaults, other defaults do not", function()
  local lines = report()
  for _, path in ipairs({ "enabled", "locked", "visibility", "general.provider",
                          "general.includePlayer" }) do
    assertTrue(has(lines, "[Set] " .. path .. " = "), path .. " prints whatever its value")
  end
  assertFalse(has(lines, "[Set] general.rangeFade = "), "a row at its default does not print")
  NS.SetByPath("general.rangeFade", false)
  local changed = report()
  NS.SetByPath("general.rangeFade", true)
  assertTrue(has(changed, "[Set] general.rangeFade = false (true)"),
    "a row off its default prints as `path = value (default)`")
end)

test("diagnostics: per feature per unit, the element fields and the secure wants", function()
  local lines = report()
  for _, key in ipairs({ "castbar", "target", "pet" }) do
    for _, unit in ipairs(NS.Units.LIST) do
      assertTrue(has(lines, "[Elem] elem " .. key .. " " .. unit .. ":"), key .. " " .. unit)
    end
  end
  local cast = lines[find(lines, "elem castbar party1:")]
  assertTrue(cast:find("registered=", 1, true) ~= nil and cast:find("ticking=", 1, true) ~= nil,
    "a cast bar prints its registration and ticker flags: " .. cast)
  local target = lines[find(lines, "elem target party1:")]
  assertTrue(target:find("driverWant=", 1, true) ~= nil and target:find("clicksWant=", 1, true) ~= nil,
    "a secure button prints its driver and clicks, requested and applied: " .. target)
end)

case("diagnostics: the free-placement position prints stored and applied", function()
  NS.SetByPath("castbar.anchorMode", "free")
  NS.db.profile.castbar.position = { point = "TOPLEFT", x = 12, y = -34 }
  NS.Anchor.Apply("castbar")
  local line = report()[find(report(), "place castbar:")]
  NS.db.profile.castbar.position = nil
  NS.SetByPath("castbar.anchorMode", "attached")
  NS.Anchor.Apply("castbar")
  assertTrue(line:find("mode=free", 1, true) ~= nil, line)
  assertTrue(line:find("stored=TOPLEFT 12 -34", 1, true) ~= nil, "the stored anchor: " .. line)
  assertTrue(line:find("applied=TOPLEFT 12 -34", 1, true) ~= nil, "the anchor last applied: " .. line)
end)

case("diagnostics: the secure-write queue's keys, the flush listener and the blocked count", function()
  local blocked = NS.BlockedActionCount()
  NS.addon:OnActionBlocked("ADDON_ACTION_BLOCKED", "PartyFrameEnhanced", "SetPoint")
  mocks.InCombatLockdown = function() return true end
  NS.RunSecure("diag:probe", function() end)
  local lines = report()
  mocks.InCombatLockdown = function() return false end
  NS.addon:OnLeaveCombat()
  assertTrue(has(lines, "secure: pending=1"), "the queue's size")
  assertTrue(has(lines, "queued keys: diag:probe"), "and its keys, in queue order")
  assertTrue(has(lines, "flush listener armed=false"), "enabled, the addon's own regen handler flushes")
  assertTrue(has(lines, "blocked actions this session: " .. (blocked + 1)), "the session's count")
end)

case("diagnostics: the frame system, the unit map and the range fade", function()
  local lines = report()
  assertTrue(has(lines, "frames: setting=auto active="), "the provider setting and what resolved")
  assertTrue(has(lines, "frame player:"), "one line per unit")
  assertTrue(has(lines, "resolve: suspended=false"), "the provider's resolve state")
  assertTrue(has(lines, "fade: mode=" .. NS.RangeFade.Mode()), "the fade's mode")
  assertTrue(has(lines, "hooked=" .. NS.RangeFade.HookedCount()), "and its hook count")
  assertTrue(has(lines, "bus: record="), "the bus arm")
  assertTrue(has(lines, "degraded arms: none"), "every major this addon consumes is live")
end)

-- ── stood down ──────────────────────────────────────────────────────────────────────────────

case("diagnostics: stood down, runtime sections say so and stored settings still print", function()
  -- red under: a report that prints an empty provider map as if it were the live answer (Q4), or one
  -- that stops at the stand-down and loses the settings a maintainer needs most then
  NS.SetByPath("enabled", false)
  settle()
  local lines = report()
  assertTrue(has(lines, "latch: enabled=false stoodDown=true"), "the latch")
  assertTrue(has(lines, "holds: disabled"), "and the hold that took it down")
  assertTrue(has(lines, "frames: stood down"), "the provider section says it is stood down")
  assertTrue(has(lines, "fade: stood down"), "and so does the range fade")
  assertTrue(has(lines, "[Set] enabled = false (true)"), "the stored settings still print")
  assertTrue(has(lines, "elem castbar player:"), "and so do the elements the stand-down left")
end)

-- ── failure and secrets ─────────────────────────────────────────────────────────────────────

case("diagnostics: a raising read costs exactly one line and the next section still runs", function()
  local saved = NS.RangeFade.Mode
  NS.RangeFade.Mode = function() error("probe raise") end
  local ok, lines = pcall(report)
  NS.RangeFade.Mode = saved
  assertTrue(ok, "the report did not raise: " .. tostring(lines))
  assertEqual(count(lines, "failed:"), 1, "one failure line")
  assertTrue(has(lines, "section rangefade failed:"), "naming the section")
  assertTrue(has(lines, "secure: pending="), "and the section after it still ran")
end)

case("diagnostics: a secret value reaches no comparison and prints as the sentinel", function()
  -- red under: a field compared or concatenated before it is stringified, which raises on a secret
  local SECRET = setmetatable({}, { __tostring = function() error("a secret was concatenated") end })
  mocks.issecretvalue = function(v) return v == SECRET end
  local el = NS.CastBars.__bars.party1
  local savedWhy, savedState = el.__hiddenWhy, el.state
  el.__hiddenWhy, el.state = SECRET, SECRET
  local rejected = NS.RejectedEvents
  rejected[#rejected + 1] = SECRET
  local ok, lines = pcall(report)
  el.__hiddenWhy, el.state = savedWhy, savedState
  rejected[#rejected] = nil
  assertTrue(ok, "the report did not raise: " .. tostring(lines))
  assertEqual(count(lines, "failed:"), 0, "no section failed on the secret")
  assertTrue(lines[find(lines, "elem castbar party1:")]:find("<secret>", 1, true) ~= nil,
    "the secret field printed as the sentinel")
end)

test("diagnostics: over the cap, the report ends in the truncated line and then the end marker", function()
  local lines, r = report({ maxLines = 12 })
  assertTrue(r.capped, "the cap bit")
  assertEqual(#lines, 12, "the report stopped at the cap")
  assertTrue(lines[#lines - 1]:find("truncated: ", 1, true) ~= nil, "the truncated line: " .. lines[#lines - 1])
  assertTrue(lines[#lines]:find("diagnostics end: 12 line(s)", 1, true) ~= nil, "then the end marker")
end)

-- ── it acts on nothing ──────────────────────────────────────────────────────────────────────

case("diagnostics: the report writes no setting, queues no secure write and registers nothing", function()
  -- red under: a section that calls a setter, a RunSecure, a registration or a timer to "refresh"
  -- what it is about to read. The report reads state; it never changes it (STD-05).
  local writes, secure = 0, 0
  local savedSet, savedSecure = NS.SetByPath, NS.RunSecure
  NS.SetByPath = function(...) writes = writes + 1 return savedSet(...) end
  NS.RunSecure = function(...) secure = secure + 1 return savedSecure(...) end
  local regsBefore = #mocks.__registrations()
  local n = NS.DebugLog:RunDiagnostics()
  local timers = mocks.__fireTimers()
  NS.SetByPath, NS.RunSecure = savedSet, savedSecure
  assertTrue(n > 20, "a report was written: " .. n .. " lines")
  assertEqual(writes, 0, "no setting written")
  assertEqual(secure, 0, "no secure write queued or run")
  assertEqual(#mocks.__registrations(), regsBefore, "no event, message or callback registered")
  assertEqual(timers, 0, "no timer armed")
end)

test("diagnostics: the sections file calls no API the report must never call", function()
  -- DX-PF's never list, read from source: a cast read, the fade frame's alpha, a compound-token
  -- UnitIsUnit, a GetPoint on a frame that is not ours, any secure or state write, and Clear().
  local src = readFile("modules/Diagnostics.lua"):gsub("%-%-[^\n]*", "")
  for _, name in ipairs({ "UnitCastingInfo", "UnitChannelInfo", "GetAlpha", "UnitIsUnit",
                          "GetPoint", "SetAttribute", "RegisterStateDriver", "RunSecure",
                          "SetByPath", "RegisterEvent", "C_Timer", ":Clear", "StandIn.Frame",
                          "Resolve()", ":Show", ":Hide" }) do
    assertFalse(src:find(name, 1, true) ~= nil, "modules/Diagnostics.lua calls " .. name)
  end
end)

-- ── the chat line, and the library-absent build ─────────────────────────────────────────────

test("diagnostics: the one chat line is the locale's, with the line count", function()
  local key = "Diagnostic report written to the debug console: %d lines. Use Copy to share it."
  assertTrue(rawget(NS.L, key) ~= nil, "the chat line is an enUS key")
  local before = #mocks.__chat
  local n = NS.DebugLog:RunDiagnostics()
  local said = {}
  for i = before + 1, #mocks.__chat do said[#said + 1] = mocks.__chat[i] end
  assertEqual(#said, 1, "one chat line")
  assertTrue(said[1]:find(NS.L[key]:format(n), 1, true) ~= nil, "formatted from L: " .. said[1])
end)

test("diagnostics: without LibKa0s, both forms print the one library-absent line", function()
  local NS2, mocks2 = loadDegraded()
  for _, form in ipairs({ "diagnostics", "debug diagnostics" }) do
    local before = #mocks2.__chat
    NS2.Slash:OnSlash(form)
    local said = {}
    for i = before + 1, #mocks2.__chat do said[#said + 1] = mocks2.__chat[i] end
    local line = table.concat(said, "\n")
    assertTrue(line:find("/pfe diagnostics is unavailable: the LibKa0s library did not load.", 1, true)
      ~= nil, "/pfe " .. form .. " said the report is unavailable: " .. line)
  end
end)
