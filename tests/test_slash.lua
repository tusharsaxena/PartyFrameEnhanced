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
                          "enable", "disable", "perf", "version", "diagnostics" }) do
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
  assertTrue(joined(slash("version")):find("v1.2.0", 1, true) ~= nil)
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

test("slash: NS.COMMANDS holds the eighteen verbs in their documented order", function()
  -- red under: a verb added, dropped or moved without docs/ARCHITECTURE.md's Slash Commands table,
  -- docs/slash-dispatch.md and the help index moving with it. `profile` keeps its one row: the
  -- `profile <name>` form is a word of that verb, not a nineteenth.
  local names = {}
  for _, e in ipairs(NS.COMMANDS) do names[#names + 1] = e[1] end
  assertEqual(table.concat(names, ","), "help,config,enable,disable,list,get,set,reset,resetall,"
    .. "resetposition,lock,unlock,status,debug,diagnostics,perf,version,profile")
end)

test("slash: bare `profile` lists the profiles, current marked, then the sub-verb help", function()
  -- red under: the old bare form, which printed only the sub-verb help and never said which
  -- profiles exist. The list is the library's (Slash minor 17), so it reads as every addon's does.
  local out = slash("profile")
  local current = NS.db:GetCurrentProfile()
  local list, help
  for i, line in ipairs(out) do
    if not list and line:find("Profiles|r", 1, true) then list = i end
    if line:find("Profile commands", 1, true) then help = i end
  end
  assertEqual(list, 1, "the list header comes first")
  assertTrue(out[1]:find("Profiles:", 1, true) == nil, "and carries no trailing colon")
  assertTrue(joined(out):find(current .. " (current)", 1, true) ~= nil, "the current profile is marked")
  assertTrue(joined(out):find("/pfe profile <name> switches profile", 1, true) ~= nil, "the hint row")
  assertTrue(help ~= nil and help > list, "the sub-verb help follows the list")
  assertEqual(#out - help, 7, "seven sub-verb rows under the help header")
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
  -- ONE CONFIG, NOT TWO, and that is the stand-down rather than a missed publish. The `enabled`
  -- row's onChange takes the latch's `disabled` hold, which unregisters every bus receiver -- this
  -- probe included -- BEFORE the seam publishes CONFIG, so the disable edge reaches nobody by
  -- design. `enable` releases the hold, the receivers come back from the record, and the publish
  -- that follows is heard. Every module rebuilds from CURRENT state on the way up, so nothing is
  -- lost by the message the disable edge did not deliver.
  assertEqual(table.concat(sections, ","), "master", "and the onChange ran on both edges")
  assertTrue(not NS.IsStoodDown(), "the latch, not a second copy of the switch, carries the state")
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
  assertTrue(joined(slash("version")):find("v1.2.0", 1, true) ~= nil, "`version` still answers")
  assertTrue(joined(slash("help")):find("/pfe enable", 1, true) ~= nil, "`help` still lists `enable`")

  slash("enable")
  assertEqual(NS.GetSetting("enabled"), true, "and `enable` above all brought it back")
end)

-- --- the disabled-state gate (slash-commands-§2) -------------------------------------------------
--
-- The dispatcher surviving the disabled state (above) is one half; what it ANSWERS is the other. A
-- verb that drives the addon's features refuses on one tagged line naming `/pfe enable` and does
-- nothing else, while the thirteen reserved verbs plus this addon's own `status` and `profile` stay live.

-- The collection's ONE refusal line, matched by SHAPE rather than by its words: the wording lives in
-- LibKa0s-Slash-1.0 (`lib.DISABLED_LINE_FORMAT`, `cli:DisabledLine()`) and is not this addon's to
-- re-spell, so hard-coding the sentence here would pin a string the addon does not own.
local REFUSAL = "/pfe enable"

test("slash: a feature verb REFUSES while disabled -- one line, and it does NOT act", function()
  -- red under: a verb that prints the refusal and then acts anyway. A case checking only the message
  -- passes straight over that, so the act itself is counted: `resetposition` is the clearest, since
  -- with the addon off it would otherwise move every stack and say `Positions reset` to a player who
  -- can see nothing move.
  local calls = 0
  local savedReset = NS.Anchor.ResetPositions
  NS.Anchor.ResetPositions = function() calls = calls + 1 end

  NS.SetByPath("enabled", false)
  local out = slash("resetposition")
  NS.Anchor.ResetPositions = savedReset
  NS.SetByPath("enabled", true)

  assertEqual(#out, 1, "exactly one line -- no second line, no paragraph")
  assertTrue(out[1]:find(NS.Slash.__cli:DisabledLine(), 1, true) ~= nil,
    "verbatim the library's line under the addon's tag, not a re-spelling")
  assertTrue(out[1]:find(REFUSAL, 1, true) ~= nil, "it names the verb that turns the addon back on")
  assertEqual(calls, 0, "the act never ran")
end)

test("slash: `unlock` refuses at the DISPATCHER, before the write seam", function()
  -- red under: a gate that lets the write through and leans on the row's own validate. The value
  -- would still not stick -- NS.AcceptLock refuses an unlock while the addon is disabled -- but the
  -- player would get that refusal instead of the one naming `/pfe enable`, and the single write seam
  -- would have been entered for a verb the addon is standing down from.
  NS.SetByPath("locked", true)
  local writes = {}
  local saved = NS.SetByPath
  saved("enabled", false)
  NS.SetByPath = function(p, v)
    writes[#writes + 1] = p .. "=" .. tostring(v)
    return saved(p, v)
  end
  local out = slash("unlock")
  NS.SetByPath = saved
  saved("enabled", true)

  assertEqual(#out, 1, "one line")
  assertTrue(out[1]:find(REFUSAL, 1, true) ~= nil)
  assertEqual(#writes, 0, "and nothing went through the write seam")
  assertTrue(NS.GetSetting("locked"), "the lock did not move")
end)

test("slash: the gate is DENY BY DEFAULT -- every verb outside the live set refuses", function()
  -- red under: a gate that lists the verbs to REFUSE rather than the ones to keep, which the next
  -- verb added joins on the wrong side by default. This walks NS.COMMANDS against the addon's own
  -- published live set instead of restating either list, so a new verb arrives here already checked.
  local live = NS.Slash.__liveWhileDisabled
  assertTrue(type(live) == "table", "the live set is published for introspection")

  NS.SetByPath("enabled", false)
  local refused = {}
  for _, e in ipairs(NS.COMMANDS) do
    if not live[e[1]] then
      local out = slash(e[1])
      assertEqual(#out, 1, e[1] .. " answered on exactly one line")
      assertTrue(out[1]:find(REFUSAL, 1, true) ~= nil, e[1] .. " named /pfe enable")
      refused[#refused + 1] = e[1]
    end
  end
  NS.SetByPath("enabled", true)

  -- The inventory, so a verb quietly changing sides is a failure rather than a silent policy change.
  assertEqual(table.concat(refused, ","), "resetposition,lock,unlock",
    "the three verbs that drive what this addon draws, and only those")
end)

test("slash: the live set still ANSWERS and still ACTS while the addon is off", function()
  -- red under: "refuse while disabled" read literally, which takes the whole command surface down
  -- with it. A player must be able to read and repair settings, and reach the panel, while the addon
  -- is off -- and `enable` above all, or the pair is one-way (slash-commands-§2).
  local function unrefused(lines, what)
    assertTrue(joined(lines):find(REFUSAL, 1, true) == nil, what .. " was not refused")
    return lines
  end

  NS.SetByPath("general.provider", "blizzard")
  NS.SetByPath("enabled", false)

  -- `help` is the one live verb that carries the line, and it is not a refusal OF help: the index
  -- prints in full, because the player has to be able to SEE `enable` in the list. The line is a
  -- statement about the rows below it, which is why the library puts it under the header.
  local help = joined(slash("help"))
  assertTrue(help:find("/pfe enable", 1, true) ~= nil, "help still lists `enable`")
  assertTrue(help:find("/pfe lock", 1, true) ~= nil, "and still lists the verbs it is refusing")

  unrefused(slash("version"), "version")
  unrefused(slash("list"), "list")
  unrefused(slash("status"), "status")
  unrefused(slash("profile"), "profile")
  unrefused(slash("perf"), "perf")
  unrefused(slash("debug off"), "debug")
  assertEqual(countOpens(function() unrefused(slash("config"), "config") end), 1,
    "`config` still opened the panel")

  -- Not merely unrefused: they still DO the thing. `get` / `set` / `reset` are how a player repairs
  -- settings with the addon off, so the writes have to land.
  slash("set general.includePlayer false")
  assertEqual(NS.GetSetting("general.includePlayer"), false, "`set` still wrote")
  slash("reset general.includePlayer")
  assertEqual(NS.GetSetting("general.includePlayer"), true, "`reset` still put it back")
  unrefused(slash("get general.provider"), "get")

  -- `resetall` too, and it really resets: the provider goes back to its default with the addon off.
  unrefused(slash("resetall"), "resetall")
  while mocks.__fireTimers() > 0 do end
  assertEqual(NS.GetSetting("general.provider"), "auto", "`resetall` still reset the profile")

  -- And `enable` above all, from the off state the reset's own default happened to leave.
  NS.SetByPath("enabled", false)
  unrefused(slash("enable"), "enable")
  assertEqual(NS.GetSetting("enabled"), true, "`enable` above all still turns the addon back on")
end)

-- --- the profile sub-verbs refuse bad names (slash-commands-§3/§4) ------------------------------
--
-- AceDB's SetProfile creates a profile on demand and its CopyProfile / DeleteProfile raise on a
-- bad name, so every name-taking sub-verb checks the name against db:GetProfiles() first and
-- refuses on ONE tagged line. Each case puts the starting profile back and deletes what it made,
-- so later suites see the store they expect.

local function hasProfile(name)
  for _, n in ipairs(NS.db:GetProfiles()) do
    if n == name then return true end
  end
  return false
end

local function dropProfile(start, name)
  NS.db:SetProfile(start)
  if hasProfile(name) then NS.db:DeleteProfile(name, true) end
end

-- Runs one slash line through pcall, so a raw AceDB raise is a failed assertion, not a dead suite.
local function slashSafe(msg)
  local before = #mocks.__chat
  local ok, err = pcall(NS.Slash.OnSlash, NS.Slash, msg)
  local out = {}
  for i = before + 1, #mocks.__chat do out[#out + 1] = mocks.__chat[i] end
  return ok, err, out
end

test("slash: `profile new` on an existing name refuses and does NOT wipe it", function()
  -- red under: drop the exists() guard in new. The unguarded verb switched to Healer, reset it to
  -- defaults and said "Created" -- a whole profile's data gone from one ordinary command.
  local start = NS.db:GetCurrentProfile()
  slash("profile new Healer")
  slash("set castbar.width 222")
  slash("profile use " .. start)
  local out = slash("profile new Healer")
  local current = NS.db:GetCurrentProfile()
  NS.db:SetProfile("Healer")
  local width = NS.GetSetting("castbar.width")
  dropProfile(start, "Healer")

  assertEqual(width, 222, "Healer kept its width")
  assertEqual(current, start, "and the refusal did not switch to it")
  assertEqual(#out, 1, "one line")
  assertTrue(out[1]:find("already exists", 1, true) ~= nil, "the 'already exists' line")
end)

test("slash: `profile new` switches once: one PROFILE, no reset line", function()
  -- red under: NS.ResetProfileCounted after SetProfile in `new`. The fresh profile is already all
  -- defaults, so the reset only re-ran adoptProfile: a second PROFILE broadcast and a no-op
  -- '[Set] reset profile ... (0 rows)' line.
  local start = NS.db:GetCurrentProfile()
  local profiles, debugLines = 0, {}
  local target = NS.NewBusTarget()
  target:RegisterMessage(NS.MSG.PROFILE, function() profiles = profiles + 1 end)
  local savedDebug = NS.Debug
  NS.Debug = function(tag, fmt, ...) debugLines[#debugLines + 1] = tag .. " " .. fmt:format(...) end
  local ok, err, out = slashSafe("profile new FreshOne")
  NS.Debug = savedDebug
  target:UnregisterMessage(NS.MSG.PROFILE)
  local current = NS.db:GetCurrentProfile()
  dropProfile(start, "FreshOne")

  assertTrue(ok, tostring(err))
  assertEqual(current, "FreshOne", "switched to the new profile")
  assertEqual(profiles, 1, "every module rebuilds off one PROFILE message")
  for _, line in ipairs(debugLines) do
    assertTrue(not line:find("reset profile", 1, true), "no reset line: " .. line)
  end
  assertEqual(#out, 1, "one chat line")
  assertTrue(out[1]:find("Created and switched", 1, true) ~= nil, "the 'Created and switched' line")
end)

test("slash: `profile use` on a missing name refuses and creates nothing", function()
  -- red under: `use` straight through SetProfile, which makes a profile out of any typo. `use`
  -- routes through the library's ProfileSwitch, so the refusal is its line and then the list.
  local start = NS.db:GetCurrentProfile()
  local out = slash("profile use Typo")
  local created, current = hasProfile("Typo"), NS.db:GetCurrentProfile()
  dropProfile(start, "Typo")

  assertTrue(not created, "no 'Typo' profile")
  assertEqual(current, start, "still on the starting profile")
  assertTrue(out[1]:find("No profile named 'Typo'.", 1, true) ~= nil, "the no-profile line first")
  assertTrue(joined(out):find("Profiles|r", 1, true) ~= nil, "then the list of what does exist")
end)

test("slash: `profile copy` refuses a missing name and the current profile, with no Lua error", function()
  -- red under: db:CopyProfile unguarded. AceDB-3.0 (:581-587) raises on both, and so does the kit's
  -- fake from revision 26, so the unguarded verb dies with a raw error frame.
  local start = NS.db:GetCurrentProfile()
  slash("set castbar.width 223")

  local ok1, err1, out1 = slashSafe("profile copy Missing")
  local ok2, err2, out2 = slashSafe("profile copy " .. start)
  local width = NS.GetSetting("castbar.width")
  slash("reset castbar.width")

  assertTrue(ok1, "copy Missing raised: " .. tostring(err1))
  assertTrue(ok2, "copy <current> raised: " .. tostring(err2))
  assertEqual(#out1, 1, "one line for the missing name")
  assertTrue(out1[1]:find("No profile named 'Missing'", 1, true) ~= nil, "the no-profile line")
  assertEqual(#out2, 1, "one line for the current profile")
  assertTrue(out2[1]:find("Cannot copy the current profile onto itself", 1, true) ~= nil)
  assertEqual(width, 223, "the store is unchanged")
  assertTrue(not hasProfile("Missing"), "and nothing was created")
end)

test("slash: `profile delete` on a missing name refuses instead of claiming it deleted", function()
  -- red under: DeleteProfile(name, true) unguarded -- silent, so it printed 'Deleted profile' for a
  -- profile that never existed.
  local ok, err, out = slashSafe("profile delete Missing")
  assertTrue(ok, tostring(err))
  assertEqual(#out, 1, "one line")
  assertTrue(joined(out):find("Deleted profile", 1, true) == nil, "no false 'Deleted' line")
  assertTrue(out[1]:find("No profile named 'Missing'", 1, true) ~= nil, "the no-profile line")
end)

-- --- `/pfe profile <name>` through LibKa0s-Slash-1.0 minor 17 ------------------------------------
--
-- A first word that is a sub-verb (in any case) runs that sub-verb; anything else is a profile name
-- and goes to cli:CliProfile, which strips one pair of quotes, keeps case and inner spaces, switches
-- only to a profile that exists and never creates one.

local function settle() while mocks.__fireTimers() > 0 do end end

-- Makes `names` exist without leaving the starting profile, and answers a cleanup for them.
local function withProfiles(names, fn)
  local start = NS.db:GetCurrentProfile()
  for _, name in ipairs(names) do NS.db:SetProfile(name) end
  NS.db:SetProfile(start)
  settle()
  local ok, err = pcall(fn, start)
  NS.db:SetProfile(start)
  for _, name in ipairs(names) do
    if hasProfile(name) then NS.db:DeleteProfile(name, true) end
  end
  settle()
  if not ok then error(err, 0) end
end

test("slash: `profile <name>` switches to an existing profile and the profile handler runs", function()
  -- red under: the old unknown-sub-verb branch, which answered `Unknown profile subcommand` for a
  -- perfectly good profile name. The switch is AceDB's, so the host's own OnProfileChanged runs:
  -- one PROFILE publish, which every module rebuilds from.
  withProfiles({ "Healer" }, function()
    local published = 0
    local target = NS.NewBusTarget()
    target:RegisterMessage(NS.MSG.PROFILE, function() published = published + 1 end)
    local out = slash("profile Healer")
    local current = NS.db:GetCurrentProfile()
    target:UnregisterMessage(NS.MSG.PROFILE)

    assertEqual(current, "Healer", "switched")
    assertEqual(#out, 1, "one line")
    assertTrue(out[1]:find("Switched to profile 'Healer'.", 1, true) ~= nil, "the switched line")
    assertEqual(published, 1, "the profile handler ran and published PROFILE once")
  end)
end)

test("slash: `profile use <name>` switches through the same library path", function()
  withProfiles({ "Healer" }, function()
    local out = slash("profile use Healer")
    assertEqual(NS.db:GetCurrentProfile(), "Healer", "switched")
    assertTrue(out[1]:find("Switched to profile 'Healer'.", 1, true) ~= nil, "the library's line")
  end)
end)

test("slash: `profile <unknown>` refuses, lists the profiles and creates nothing", function()
  -- red under: SetProfile on the typed name, which AceDB answers by creating the profile.
  withProfiles({}, function(start)
    local out = slash("profile Typo")
    assertTrue(not hasProfile("Typo"), "no 'Typo' profile")
    assertEqual(NS.db:GetCurrentProfile(), start, "still on the starting profile")
    assertTrue(out[1]:find("No profile named 'Typo'.", 1, true) ~= nil, "the refusal first")
    assertTrue(joined(out):find(start .. " (current)", 1, true) ~= nil, "then the list")
  end)
end)

test("slash: `profile <name>` keeps case, so a wrong-case name is refused with a did-you-mean", function()
  -- red under: lowercasing the whole argument with the sub-verb, which would miss `Healer` from
  -- `healer` and, worse, create `healer`. Profile names are case-sensitive AceDB keys.
  withProfiles({ "Healer" }, function(start)
    local out = slash("profile healer")
    assertEqual(NS.db:GetCurrentProfile(), start, "no switch")
    assertTrue(not hasProfile("healer"), "nothing created")
    assertTrue(out[1]:find("No profile named 'healer'.", 1, true) ~= nil, "refused")
    assertTrue(out[2]:find("Did you mean 'Healer'?", 1, true) ~= nil, "with the one near match")
  end)
end)

test("slash: `profile \"<name with spaces>\"` strips the quotes and keeps the spaces", function()
  withProfiles({ "Tank Two" }, function(start)
    slash("profile \"Tank Two\"")
    assertEqual(NS.db:GetCurrentProfile(), "Tank Two", "double quotes stripped")
    NS.db:SetProfile(start)
    slash("profile 'Tank Two'")
    assertEqual(NS.db:GetCurrentProfile(), "Tank Two", "single quotes stripped")
    NS.db:SetProfile(start)
    slash("profile Tank Two")
    assertEqual(NS.db:GetCurrentProfile(), "Tank Two", "and unquoted, the whole line is the name")
  end)
end)

test("slash: a sub-verb matches in any case, and the current profile is already on", function()
  withProfiles({}, function(start)
    local out = slash("profile LIST")
    assertTrue(out[1]:find("Profiles|r", 1, true) ~= nil, "`LIST` ran the list sub-verb")
    out = slash("profile Current")
    assertTrue(out[1]:find("Current profile: " .. start, 1, true) ~= nil, "`Current` ran current")
    out = slash("profile " .. start)
    assertEqual(#out, 1, "one line")
    assertTrue(out[1]:find("Already on profile '" .. start .. "'.", 1, true) ~= nil, "already on it")
  end)
end)

test("slash: `profile <name>` refuses in combat and switches nothing", function()
  withProfiles({ "Healer" }, function(start)
    local saved = mocks.InCombatLockdown
    mocks.InCombatLockdown = function() return true end
    local out = slash("profile Healer")
    local viaUse = slash("profile use Healer")
    mocks.InCombatLockdown = saved
    assertEqual(NS.db:GetCurrentProfile(), start, "no switch")
    assertTrue(out[1]:find("Can't switch profiles in combat.", 1, true) ~= nil, "the combat line")
    assertTrue(viaUse[1]:find("Can't switch profiles in combat.", 1, true) ~= nil, "`use` too")
  end)
end)

test("slash: `status` prints the frame system's label through NS.L", function()
  -- red under: the provider labels were raw strings, so 'Blizzard (raid-style)' and
  -- 'Blizzard (classic)' had no enUS key and a translation could never reach /pfe status
  -- (localization-§1, PartyFrameEnhanced-A-09).
  for _, p in ipairs(NS.Providers.__list) do
    assertTrue(rawget(NS.L, p.label) ~= nil, "provider label is an enUS key: " .. p.label)
  end
  local container = mocks.CreateFrame("Frame", "CompactPartyFrame")
  container:Show()
  container.memberUnitFrames = {}
  local savedGroup = mocks.__context.inGroup
  mocks.__context.inGroup = true
  mocks.CompactPartyFrame = container
  mocks.EditModeManagerFrame = { UseRaidStylePartyFrames = function() return true end }
  NS.Providers.Resolve()
  local out = slash("status")
  mocks.CompactPartyFrame, mocks.EditModeManagerFrame = nil, nil
  mocks.__context.inGroup = savedGroup
  NS.Providers.Resolve()
  local want = "Frame system: " .. NS.L["Blizzard (raid-style)"]
  assertEqual(out[1]:sub(-#want), want, "the L-routed label ends the first line")
end)

-- The `Note:` line of `/pfe status`, or "" when there is none.
local function statusNote()
  for _, line in ipairs(slash("status")) do
    local note = line:match("Note: (.*)$")
    if note then return note end
  end
  return ""
end

-- Counts the comma-separated flags of a Note line that start with "unlocked".
local function unlockedFlags(note)
  local n, bare = 0, 0
  for flag in (note .. ","):gmatch("%s*(.-),") do
    if flag:sub(1, 8) == "unlocked" then n = n + 1 end
    if flag == "unlocked" then bare = bare + 1 end
  end
  return n, bare
end

test("slash: `status` names an unlock with preview on once", function()
  -- red under: statusFlags added the preview branch's 'unlocked (stand-in)' AND a bare
  -- 'unlocked' from Anchor.IsUnlocked(), and applyLock sets both together, so the Note line read
  -- 'unlocked (stand-in), unlocked' (PFE-R-04).
  slash("unlock")
  local note = statusNote()
  slash("lock")
  assertTrue(note:find("unlocked (", 1, true) ~= nil, "the preview branch names the view: " .. note)
  local n, bare = unlockedFlags(note)
  assertEqual(n, 1, "one unlocked flag: " .. note)
  assertEqual(bare, 0, "no second bare 'unlocked': " .. note)
end)

test("slash: `status` still reports an unlock whose preview was refused", function()
  -- The holders are grabbable but preview is off (setPreview refused): the bare flag is the only
  -- one that says so.
  NS.Anchor.SetUnlocked(true)
  local preview = NS.State.preview
  local note = statusNote()
  NS.Anchor.SetUnlocked(false)
  assertTrue(not preview, "precondition: preview off")
  local n, bare = unlockedFlags(note)
  assertEqual(n, 1, "one unlocked flag: " .. note)
  assertEqual(bare, 1, "and it is the bare one: " .. note)
end)
