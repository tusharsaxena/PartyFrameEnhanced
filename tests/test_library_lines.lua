-- tests/test_library_lines.lua — the lines LibKa0s writes through this addon's sink (LibKa0s
-- v1.65.0: Slash minor 18, Lifecycle minor 3, Launcher minor 5). Each case reads the REAL console
-- buffer, not a swapped NS.Debug, so it proves the descriptor's `debug` reaches this addon's log
-- and that the line lands exactly once: the library writes it, and this addon writes no copy.

local T = _G.PFE_TEST
local test, assertEqual = T.test, T.assertEqual
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
