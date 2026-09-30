-- tests/test_library_lines.lua — the lines LibKa0s writes through this addon's sink (LibKa0s
-- v1.65.0: Slash minor 18, Lifecycle minor 3, Launcher minor 5). Each case reads the REAL console
-- buffer, not a swapped NS.Debug, so it proves the descriptor's `debug` reaches this addon's log
-- and that the line lands exactly once: the library writes it, and this addon writes no copy.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local NS, mocks = T.NS, T.mocks

local function settle() while mocks.__fireTimers() > 0 do end end

--- Runs `fn` with logging on and an empty console, then answers the console's plain lines. The flag
--- is put back after, raising or not.
local function logged(fn)
  local saved = NS.State.debug
  NS.State.debug = true
  NS.DebugLog:Clear()
  local ok, err = pcall(fn)
  local lines = {}
  for _, line in ipairs(NS.DebugLog.buffer) do lines[#lines + 1] = line end
  NS.State.debug = saved
  if not ok then error(err, 0) end
  return lines
end

--- How many of `lines` carry `needle` (plain find).
local function count(lines, needle)
  local n = 0
  for _, line in ipairs(lines) do
    if line:find(needle, 1, true) then n = n + 1 end
  end
  return n
end

local function slash(msg) NS.Slash:OnSlash(msg) end

-- ── Slash minor 18: the dispatcher's own refusals ─────────────────────────────────────────────

test("library lines: an unknown verb writes one [Cmd] refusal to this addon's console", function()
  -- red under: no `debug` on the Slash descriptor, so the refusal reached chat only.
  local lines = logged(function() slash("notaverb") end)
  assertEqual(count(lines, "[Cmd] refused notaverb: unknown verb"), 1, table.concat(lines, " | "))
end)

test("library lines: the disabled gate writes one [Cmd] refusal, and the chat line stays one", function()
  -- red under: the gate's refusal was chat-only; a host line matching the chat would make it two.
  NS.SetByPath("enabled", false)
  settle()
  local before = #mocks.__chat
  local lines = logged(function() slash("resetposition") end)
  local chat = 0
  for i = before + 1, #mocks.__chat do
    if mocks.__chat[i]:find(NS.DisabledLine(), 1, true) then chat = chat + 1 end
  end
  NS.SetByPath("enabled", true)
  settle()
  assertEqual(count(lines, "[Cmd] refused resetposition: disabled"), 1, table.concat(lines, " | "))
  assertEqual(count(lines, "refused resetposition"), 1, "no second line from this addon")
  assertEqual(chat, 1, "the chat refusal is unchanged")
end)

test("library lines: a `set` the parser refuses writes one [Cmd] line naming the path", function()
  local lines = logged(function() slash("set general.rangeFade notabool") end)
  assertEqual(count(lines, "[Cmd] refused set general.rangeFade: parse"), 1, table.concat(lines, " | "))
end)

test("library lines: a refusal this addon decides stays its own line, with no [Cmd] copy", function()
  -- NS.ToggleLock's disabled refusal is the host's (the library only lends the chat wording), so it
  -- is the Preview line and nothing else.
  NS.SetByPath("enabled", false)
  settle()
  local lines = logged(function() NS.ToggleLock() end)
  NS.SetByPath("enabled", true)
  settle()
  assertEqual(count(lines, "[Preview] lock toggle refused: addon disabled"), 1, table.concat(lines, " | "))
  assertEqual(count(lines, "[Cmd]"), 0, "the library decided nothing here")
end)

-- ── Lifecycle minor 3: stand-down and stand-up edges ──────────────────────────────────────────

test("library lines: each Lifecycle edge is one [Lifecycle] line in this addon's console", function()
  -- red under: no `debug` on the Lifecycle descriptor (no line), or the pre-v1.65.0 host line
  -- `[State] stood down (holds: ...)` beside the library's (two lines per edge).
  local down = logged(function()
    NS.SetByPath("enabled", false)
    settle()
  end)
  local up = logged(function()
    NS.SetByPath("enabled", true)
    settle()
  end)
  assertEqual(count(down, "[Lifecycle] stood down: added disabled (holds: disabled)"), 1,
    table.concat(down, " | "))
  assertEqual(count(up, "[Lifecycle] stood up: released disabled (holds: none)"), 1,
    table.concat(up, " | "))
  assertEqual(count(down, "stood down"), 1, "one line for the edge, not two")
  assertEqual(count(up, "stood up"), 1, "one line for the edge, not two")
end)

test("library lines: a hold that changes nothing writes no [Lifecycle] line", function()
  NS.SetByPath("enabled", false)
  settle()
  local lines = logged(function() NS.ApplyEnabled(false) end)
  NS.SetByPath("enabled", true)
  settle()
  assertEqual(count(lines, "[Lifecycle]"), 0, table.concat(lines, " | "))
end)

test("library lines: a second hold is named in the set, and releasing one fires no edge", function()
  local lines = logged(function()
    NS.lifecycle:Hold("perf")
    NS.ApplyEnabled(false)
    NS.lifecycle:Release("perf")
  end)
  NS.ApplyEnabled(true)
  settle()
  assertEqual(count(lines, "[Lifecycle] stood down: added perf (holds: perf)"), 1, table.concat(lines, " | "))
  assertEqual(count(lines, "[Lifecycle]"), 1, "the second hold and the partial release are no edge")
end)

-- ── DebugLogGates 1: the console's change gates replace this addon's memos ──────────────────────

local function prepTargets()
  local p = NS.db.profile
  p.enabled, p.visibility, p.locked = true, "always", true
  p.target.enabled, p.target.anchorMode = true, "free"
  NS.bus:SendMessage(NS.MSG.PROFILE)
  settle()
end

test("library lines: a Clear re-arms the target change gate, so an unchanged target says itself again", function()
  -- red under: the pre-v1.65.0 per-button memo (`__loggedTarget`), which a Clear never reset, so a
  -- cleared console stayed silent about a target that was still there.
  prepTargets()
  local btn = NS.TargetFrames.__buttons.party1
  mocks.__units.party1target = { name = "Dummy" }
  local after
  local lines = logged(function()
    for _ = 1, 3 do btn:__fire("OnEvent", "UNIT_TARGET", "party1") end
    NS.DebugLog:Clear()
    for _ = 1, 3 do btn:__fire("OnEvent", "UNIT_TARGET", "party1") end
    after = {}
    for _, line in ipairs(NS.DebugLog.buffer) do after[#after + 1] = line end
  end)
  mocks.__units.party1target = nil
  btn:__fire("OnEvent", "UNIT_TARGET", "party1")
  assertEqual(count(after, "[Target] party1 targets Dummy"), 1, table.concat(after, " | "))
  assertEqual(count(lines, "[Target] party1 targets Dummy"), 1, "the repeats after the Clear hold")
end)

test("library lines: turning logging on re-arms the gates, and nothing is remembered while it is off", function()
  prepTargets()
  local btn = NS.TargetFrames.__buttons.party1
  mocks.__units.party1target = { name = "Dummy" }
  local saved = NS.State.debug
  NS.DebugLog:SetEnabled(true)
  btn:__fire("OnEvent", "UNIT_TARGET", "party1")
  NS.DebugLog:SetEnabled(false)
  btn:__fire("OnEvent", "UNIT_TARGET", "party1")   -- off: nothing written, nothing remembered
  NS.DebugLog:Clear()
  NS.DebugLog:SetEnabled(true)
  btn:__fire("OnEvent", "UNIT_TARGET", "party1")
  local found = NS.DebugLog:FindLine("[Target] party1 targets Dummy")
  NS.DebugLog:SetEnabled(saved)
  mocks.__units.party1target = nil
  btn:__fire("OnEvent", "UNIT_TARGET", "party1")
  assertTrue(found ~= nil, "a new logging session hears the unchanged target again")
end)

test("library lines: no hand-rolled change gate is left in the addon's own files", function()
  -- The five memos DebugLogGates replaced. A copy that comes back is a gate a Clear never re-arms.
  local files = { "modules/CastBars.lua", "modules/Preview.lua", "modules/RangeFade.lua",
                  "modules/Providers.lua", "modules/TargetFrames.lua", "modules/PetFrames.lua" }
  for _, path in ipairs(files) do
    local f = assert(io.open(path, "rb"))
    local src = f:read("*a")
    f:close()
    for _, name in ipairs({ "__loggedTarget", "__loggedPet", "dressedAs", "loggedMode", "editModeErrors" }) do
      assertTrue(src:find(name, 1, true) == nil, path .. " still carries " .. name)
    end
  end
end)

-- ── DebugLogGates 1 and Launcher minor 5: the at-enable queue ────────────────────────────────

test("library lines: the launcher's dependency line, written at OnEnable, lands when logging turns on", function()
  -- red under: no `debugAtEnable` on the Launcher descriptor, so Register's state line went to the
  -- gated `debug` at OnEnable, with the flag off, and never landed. This harness has no
  -- LibDataBroker, so the line is the absent one.
  local saved = NS.State.debug
  if saved then NS.DebugLog:SetEnabled(false) end
  NS.DebugLog:Clear()
  NS.Launcher:Register()
  NS.Launcher:Register()   -- a retried Register is one held line
  local offLines = NS.DebugLog:BufferSize()
  NS.DebugLog:SetEnabled(true)
  local lines = {}
  for _, line in ipairs(NS.DebugLog.buffer) do lines[#lines + 1] = line end
  NS.DebugLog:SetEnabled(saved)
  local want = "[Launcher] LibDataBroker-1.1 absent; no launcher"
  assertEqual(count(lines, want), 1, table.concat(lines, " | "))
  local initAt, lineAt
  for i, line in ipairs(lines) do
    if line:find("[Init]", 1, true) then initAt = i end
    if line:find(want, 1, true) then lineAt = i end
  end
  assertTrue(initAt and lineAt and lineAt > initAt, "after the session bracket and the [Init] summary")
  assertEqual(offLines, 0, "nothing was written while logging was off: the line was held")
end)

test("library lines: with logging already on, the launcher's state line is written at once, once", function()
  local lines = logged(function() NS.Launcher:Register() end)
  assertEqual(count(lines, "[Launcher] LibDataBroker-1.1 absent; no launcher"), 1, table.concat(lines, " | "))
end)
