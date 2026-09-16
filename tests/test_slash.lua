-- tests/test_slash.lua — NS.COMMANDS and the dispatcher: the table's shape, the reserved verbs,
-- both chat commands, and the host verbs going through the write seam.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local NS, mocks = T.NS, T.mocks

local function slash(msg)
  local before = #mocks.__chat
  NS.Slash:OnSlash(msg)
  local out = {}
  for i = before + 1, #mocks.__chat do out[#out + 1] = mocks.__chat[i] end
  return out
end

local function joined(lines) return table.concat(lines, "\n") end

test("slash: every NS.COMMANDS entry is a positional {name, desc, fn} triple", function()
  -- Named fields are invisible to LibKa0s-Slash-1.0: every verb would read as unknown.
  for i, e in ipairs(NS.COMMANDS) do
    assertTrue(type(e[1]) == "string" and type(e[2]) == "string" and type(e[3]) == "function",
      "entry " .. i .. " is not a positional triple")
  end
end)

test("slash: the reserved verbs are all present", function()
  local have = {}
  for _, e in ipairs(NS.COMMANDS) do have[e[1]] = true end
  for _, verb in ipairs({ "help", "config", "list", "get", "set", "reset", "resetall", "debug",
                          "enable", "disable", "perf", "version" }) do
    assertTrue(have[verb], "reserved verb missing: " .. verb)
  end
end)

-- Runs `fn` with NS.OpenOptionsPanel swapped for a counter; the `config` verb looks it up per call.
local function countOpens(fn)
  local saved, opens = NS.OpenOptionsPanel, 0
  NS.OpenOptionsPanel = function() opens = opens + 1 end
  local ok, err = pcall(fn)
  NS.OpenOptionsPanel = saved
  if not ok then error(err, 0) end
  return opens
end

test("slash: a bare /pfe opens the settings panel through `config`, not the help", function()
  local out
  assertEqual(countOpens(function() out = slash("") end), 1, "bare /pfe ran `config`")
  assertTrue(joined(out):find("slash commands", 1, true) == nil, "and printed no help block")
end)

test("slash: whitespace-only input is a bare /pfe", function()
  assertEqual(countOpens(function() slash("   ") end), 1)
end)

test("slash: `help` prints the command list and opens nothing", function()
  local out
  assertEqual(countOpens(function() out = slash("help") end), 0)
  local text = joined(out)
  assertTrue(text:find("slash commands", 1, true) ~= nil, "the version header")
  assertTrue(text:find("/pfe config", 1, true) ~= nil, "a row per verb")
end)

test("slash: /pfe and /partyframeenhanced are both registered through AceConsole", function()
  NS.Slash:Register()
  local AceConsole = mocks.LibStub("AceConsole-3.0")
  assertTrue(AceConsole.commands["pfe"] ~= nil, "/pfe")
  assertTrue(AceConsole.commands["partyframeenhanced"] ~= nil, "/partyframeenhanced")
end)

test("slash: `version` prints the TOC version", function()
  assertTrue(joined(slash("version")):find("v0.1.0", 1, true) ~= nil)
end)

test("slash: `unlock` and `lock` write `locked` through the seam", function()
  -- Through the seam means a CONFIG publish: a bare table write would publish nothing.
  local sections = {}
  local target = NS.NewBusTarget()
  target:RegisterMessage(NS.MSG.CONFIG, function(_, s) sections[#sections + 1] = s end)
  slash("unlock")
  assertEqual(NS.GetSetting("locked"), false)
  slash("lock")
  assertEqual(NS.GetSetting("locked"), true)
  target:UnregisterMessage(NS.MSG.CONFIG)
  assertEqual(table.concat(sections, ","), "master,master")
end)

test("slash: `set` parses and stores a schema value, `reset` puts it back", function()
  slash("set general.provider blizzard")
  assertEqual(NS.GetSetting("general.provider"), "blizzard")
  slash("reset general.provider")
  assertEqual(NS.GetSetting("general.provider"), "auto")
end)

test("slash: `perf` prints what the harness returns", function()
  assertTrue(#slash("perf") > 0)
end)

test("slash: `profile` with no argument prints the sub-verb list", function()
  assertTrue(joined(slash("profile")):find("Profile commands", 1, true) ~= nil)
end)

test("slash: an unknown verb says so and prints help", function()
  local out = joined(slash("nosuchverb"))
  assertTrue(out:find("nosuchverb", 1, true) ~= nil)
end)

test("slash: `enable` and `disable` are ALIASES for the Enable row -- no state of their own", function()
  -- red under: a second key, a session flag, or an NS.enabled local. slash-commands-§2 makes the two
  -- verbs write the SAME stored path the Master controls *Enable Party Frame Enhanced* checkbox
  -- writes, through the SAME seam, so the two surfaces can never show the player different answers.
  local writes, sections = {}, {}
  local saved = NS.SetByPath
  NS.SetByPath = function(path, value)
    writes[#writes + 1] = path .. "=" .. tostring(value)
    return saved(path, value)
  end
  local target = NS.NewBusTarget()
  target:RegisterMessage(NS.MSG.CONFIG, function(_, sec) sections[#sections + 1] = sec end)

  slash("disable")
  assertEqual(NS.GetSetting("enabled"), false)
  assertEqual(NS.db.profile.enabled, false, "it landed on the profile path the checkbox writes")
  slash("enable")
  assertEqual(NS.GetSetting("enabled"), true)

  NS.SetByPath = saved
  target:UnregisterMessage(NS.MSG.CONFIG)
  assertEqual(table.concat(writes, ","), "enabled=false,enabled=true", "one path, one seam")
  assertEqual(table.concat(sections, ","), "master,master", "and the row's onChange ran both times")
end)

test("slash: `enable` echoes the stored value in the shared `path = value` shape", function()
  -- slash-commands-§5: the echo is read back from the STORE after the write, through the library's
  -- own formatter, so `/pfe enable` reads exactly as `/pfe set enabled true` reads.
  local out = joined(slash("enable"))
  assertTrue(out:find("enabled", 1, true) ~= nil, "the path")
  assertTrue(out:find("true", 1, true) ~= nil, "the stored value")
  assertTrue(out:find(":", 1, true) == nil or out:find("enabled:", 1, true) == nil,
    "no trailing colon on the key")
end)

test("slash: the dispatcher answers while the addon is DISABLED -- the pair is never one-way", function()
  -- red under: a dispatcher that stands down with the features. Disabled means the addon stops
  -- drawing and stops registering events; it does NOT mean it drops the chat command, and an addon
  -- that does has built a switch that only goes one way (slash-commands-§2).
  NS.SetByPath("enabled", false)
  local AceConsole = mocks.LibStub("AceConsole-3.0")
  assertTrue(AceConsole.commands["pfe"] ~= nil, "/pfe is still registered")

  local opens = countOpens(function() slash("") end)
  assertEqual(opens, 1, "a bare /pfe still opens the settings panel")
  assertTrue(joined(slash("version")):find("v0.1.0", 1, true) ~= nil, "`version` still answers")
  assertTrue(joined(slash("help")):find("/pfe enable", 1, true) ~= nil, "`help` still lists `enable`")

  slash("enable")
  assertEqual(NS.GetSetting("enabled"), true, "and `enable` above all brought it back")
end)
