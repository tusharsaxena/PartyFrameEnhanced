-- tests/test_launcher.lua -- the launcher (launcher-§1/§2/§3/§4): ONE object registered twice,
-- left-click opening the settings panel, right-click opening the options menu whose entries route
-- to the addon's OWN slash handlers, the Minimap button row's inversion onto LibDBIcon's `hide`, and
-- a host with neither broker library.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local loadLauncher = dofile("tests/launcher_env.lua")

local MINIMAP_PATH = "global.minimap.shown"
local ICON = "Interface\\AddOns\\PartyFrameEnhanced\\media\\logos\\partyframeenhanced.logo.128.tga"

-- One fully wired world, built once: every case below reads it or drives it and puts it back.
local NS, mocks, ldb, icons = loadLauncher()

local function registration() return icons.__registrations.PartyFrameEnhanced end
local function object() return NS.Launcher:Object() end

--- Drive the ONE click implementation both surfaces dispatch into, as the client does.
local function click(button) object().OnClick(object(), button) end

-- --- one object, registered twice --------------------------------------------------------------

test("launcher: one object, registered twice under the addon's FOLDER name", function()
  -- red under: two objects, a second click handler, or either registration under another spelling.
  -- The folder name is not cosmetic -- LibDBIcon keys the button's SAVED POSITION by it, so a second
  -- spelling drops the angle the player dragged the button to (launcher-§1).
  assertTrue(NS.Launcher ~= nil, "the launcher seam built an instance")
  assertTrue(NS.Launcher:IsRegistered(), "both halves are wired")
  local obj = object()
  assertEqual(ldb.__objects.PartyFrameEnhanced, obj, "the broker object is registered under the folder name")
  assertEqual(registration().object, obj, "LibDBIcon holds the very same object")
  assertEqual(obj.type, "launcher", "type launcher, not `data source` -- it has no value to show")
  assertEqual(obj.label, "Ka0s Party Frame Enhanced")
  local n = 0
  for _ in pairs(ldb.__objects) do n = n + 1 end
  assertEqual(n, 1, "exactly one broker object")
end)

test("launcher: Register is idempotent -- a second call builds no second button", function()
  -- red under: a Register that re-enters LibDBIcon, which would draw a second button over the first.
  local before = registration().calls
  assertTrue(NS.Launcher:Register(), "a second Register still reports fully wired")
  NS.Launcher:Register()
  assertEqual(registration().calls, before, "LibDBIcon:Register ran once and only once")
end)

test("launcher: the icon is the addon's own 128 logo, and the TOC's IconTexture names that file", function()
  -- red under: a Blizzard icon path or a numeric file id on either surface (anti-pattern #82), or
  -- the two drifting apart -- one file is the addon's face in the AddOns list, on the minimap and in
  -- a broker display (launcher-§4).
  assertEqual(object().icon, ICON)
  local toc = dofile("tests/_kit/loader.lua").readFile("PartyFrameEnhanced.toc")
  local declared = toc:match("##%s*IconTexture:%s*([^\r\n]+)")
  assertEqual(declared, ICON, "## IconTexture names the same file the launcher draws")
end)

test("launcher: the broker label is the BRAND NAME in plain text, never the Title or the folder", function()
  -- red under: an ad-hoc spelling, the escaped TOC Title, or the folder name (anti-pattern #84).
  -- `label` is what a broker display prints in its row, BESIDE the other ten, so it is the one
  -- field that decides whether the collection reads as one collection (launcher-§1).
  local label = object().label
  assertEqual(label, "Ka0s Party Frame Enhanced")
  assertTrue(label:find("|c", 1, true) == nil and label:find("|r", 1, true) == nil,
    "no escape sequence of any kind -- a display drawing it raw would splatter the row")
  assertTrue(label ~= "PartyFrameEnhanced", "not the folder name: that is the registration `name`")

  -- And the two fields are not wired to each other. The Title is free to carry escapes; the label
  -- is not, so reading one off the other is exactly the mistake the rule forbids.
  local toc = dofile("tests/_kit/loader.lua").readFile("PartyFrameEnhanced.toc")
  local title = toc:match("##%s*Title:%s*([^\r\n]+)")
  assertTrue(title ~= nil, "the TOC declares a Title")
  assertTrue(label:find("Ka0s ", 1, true) == 1, "the brand prefix every row in the display shares")
end)

-- --- the two buttons (launcher-§2, Launcher minor 4) --------------------------------------------
--
-- Left-click opens the settings panel; right-click opens the client's context menu, which the
-- library builds from the descriptor's accessor-and-toggle pairs. This addon has an enable switch
-- and a lock and nothing else (no test mode: unlocking IS its preview, options-ui-§15; no primary
-- window), so the menu is *Enabled* and *Locked*, matching ADDONS.md's row. Every case below drives
-- the one object as the client does and reads the menu through tests/mock_menu.lua.

local menu = mocks.__menu

--- Right-click the button and answer the menu the library opened.
local function openMenu()
  menu.reset()
  click("RightButton")
  return menu.last
end

--- Replace NS[name] with a recorder that still calls through, for the duration of `fn`.
local function spying(name, fn)
  local calls, saved = {}, NS[name]
  NS[name] = function(...)
    calls[#calls + 1] = { n = select("#", ...), ... }
    return saved(...)
  end
  local ok, err = pcall(fn, calls)
  NS[name] = saved
  if not ok then error(err, 0) end
end

local function withPanelCounter(fn)
  local opens, saved = 0, NS.OpenOptionsPanel
  NS.OpenOptionsPanel = function() opens = opens + 1 end
  local ok, err = pcall(fn, function() return opens end)
  NS.OpenOptionsPanel = saved
  if not ok then error(err, 0) end
end

local function settleTimers() while mocks.__fireTimers() > 0 do end end

test("launcher: LEFT click opens the settings panel and moves nothing", function()
  -- red under: a left click still on the retired rung (b) (toggling the lock), or one that opens
  -- nothing.
  withPanelCounter(function(opens)
    NS.SetByPath("locked", true)
    click("LeftButton")
    assertEqual(opens(), 1, "the panel opened")
    assertTrue(NS.GetSetting("locked"), "and the lock did not move")
  end)
end)

test("launcher: LEFT click opens the settings panel while DISABLED too", function()
  -- red under: the retired minor-2 refusal. The panel is where a disabled addon is re-enabled.
  NS.SetByPath("enabled", false)
  settleTimers()
  local chat = #mocks.__chat
  withPanelCounter(function(opens)
    click("LeftButton")
    assertEqual(opens(), 1, "the panel opened in the disabled state")
  end)
  assertEqual(#mocks.__chat, chat, "and no refusal line was printed")
  NS.SetByPath("enabled", true)
  settleTimers()
end)

test("launcher: RIGHT click opens the options menu -- title, then Enabled and Locked only", function()
  -- red under: a missing pair (no entry), a test-mode or window pair this addon does not have, or a
  -- right click that still opens the panel.
  withPanelCounter(function(opens)
    local m = openMenu()
    assertTrue(m ~= nil, "a context menu opened")
    assertEqual(opens(), 0, "the right click did not open the panel")
    assertEqual(m.titles[1], "Ka0s Party Frame Enhanced", "titled with the label")
    assertEqual(table.concat(m:Texts(), ","), "Enabled,Locked",
      "exactly the toggles this addon has, in the library's order")
  end)
end)

test("launcher: each menu entry shows the state read when the menu opens", function()
  NS.SetByPath("locked", true)
  local m = openMenu()
  assertTrue(m:Checked("Enabled"), "enabled")
  assertTrue(m:Checked("Locked"), "locked")
  NS.SetByPath("locked", false)
  m = openMenu()
  assertFalse(m:Checked("Locked"), "the next open reads the unlock")
  NS.SetByPath("locked", true)
end)

test("launcher: the menu's Locked entry routes to NS.ToggleLock, the `/pfe lock|unlock` seam", function()
  -- red under: a toggle that wrote `locked` itself, or drove preview mode directly, instead of the
  -- one seam the slash verbs and the Lock frame row use.
  NS.SetByPath("locked", true)
  spying("ToggleLock", function(calls)
    openMenu():Click("Locked")
    assertEqual(#calls, 1, "one call per click")
    assertEqual(calls[1].n, 0, "called with no argument")
  end)
  assertFalse(NS.GetSetting("locked"), "the click unlocked -- the preview switch")
  assertEqual(NS.db.profile.locked, false, "in the profile, not a launcher-local flag")
  openMenu():Click("Locked")
  assertTrue(NS.GetSetting("locked"), "the second click locked again")
end)

test("launcher: the menu's Locked entry and `/pfe lock` write the one path through the one seam", function()
  local seen = {}
  local saved = NS.SetByPath
  NS.SetByPath("locked", true)
  NS.SetByPath = function(path, value)
    seen[#seen + 1] = path .. "=" .. tostring(value)
    return saved(path, value)
  end
  openMenu():Click("Locked")
  NS.Slash:OnSlash("lock")
  NS.SetByPath = saved
  assertEqual(table.concat(seen, ","), "locked=false,locked=true")
end)

test("launcher: the menu's Enabled entry routes to NS.SetEnabled, the `/pfe enable|disable` handler", function()
  -- red under: a toggle that wrote `enabled` around the verbs' handler, so the echo and the panel
  -- refresh the verbs run would be skipped.
  spying("SetEnabled", function(calls)
    openMenu():Click("Enabled")
    assertEqual(#calls, 1, "one call per click")
    assertEqual(calls[1][1], false, "handed the state the addon moves TO")
  end)
  settleTimers()
  assertFalse(NS.GetSetting("enabled"), "the addon is disabled")
  local menuEcho = mocks.__chat[#mocks.__chat]

  NS.SetByPath("enabled", true)
  settleTimers()
  NS.Slash:OnSlash("disable")
  settleTimers()
  assertEqual(mocks.__chat[#mocks.__chat], menuEcho, "the same echo `/pfe disable` prints")

  spying("SetEnabled", function(calls)
    openMenu():Click("Enabled")
    assertEqual(calls[1][1], true, "and from disabled, it enables")
  end)
  settleTimers()
  assertTrue(NS.GetSetting("enabled"), "back on")
end)

test("launcher: while DISABLED the menu grays Locked and leaves Enabled live", function()
  -- red under: a Locked entry that can unlock (drive the preview) on a disabled addon, or an Enabled
  -- entry grayed with it (the menu would be one-way).
  NS.SetByPath("locked", true)
  NS.SetByPath("enabled", false)
  settleTimers()
  local m = openMenu()
  assertEqual(table.concat(m:Texts(), ","), "Enabled,Locked (enable the addon first)")
  assertFalse(m:Find("Locked").enabled, "Locked is grayed")
  assertTrue(m:Find("Enabled").enabled, "Enabled stays live")
  spying("ToggleLock", function(calls)
    assertNil(m:Click("Locked"), "a grayed entry cannot be clicked")
    m:ForceClick("Locked")
    assertEqual(#calls, 0, "even a forced click calls no handler")
  end)
  assertTrue(NS.GetSetting("locked"), "the lock did not move")
  m:Click("Enabled")
  settleTimers()
  assertTrue(NS.GetSetting("enabled"), "Enabled re-enables from the menu")
end)

test("launcher: with no client menu API, RIGHT click falls back to the settings panel", function()
  menu.remove()
  withPanelCounter(function(opens)
    click("RightButton")
    assertEqual(opens(), 1, "the panel holds every toggle the menu would have")
  end)
  menu.install()
end)

-- --- the status tooltip (launcher-§1, Launcher minor 3; hints fixed at minor 4) -------------------
--
-- The library draws the tooltip; this addon only answers its questions. So the cases below pin the
-- DESCRIPTOR (which states this addon claims to have, and where each answer comes from) and then
-- hover the one object, as LibDBIcon does, and read every line the library drew from it.

local GREEN, RED = "|cFF00FF00", "|cFFFF0000"

--- Hover the button once and answer the lines drawn, in order.
local function hover()
  local tt = mocks.__stubFrame()
  local lines = {}
  tt.AddLine = function(_, line) lines[#lines + 1] = line end
  object().OnTooltipShow(tt)
  return lines
end

local function tocVersion()
  local toc = dofile("tests/_kit/loader.lua").readFile("PartyFrameEnhanced.toc")
  return toc:match("##%s*Version:%s*([^\r\n]+)")
end

local function descriptor() return mocks.__launcherDescriptor end

test("launcher: the descriptor passes the pairs this addon HAS, and none of the retired fields", function()
  -- red under: a test-mode or window pair (this addon has neither), a missing half of the Enabled or
  -- Locked pair, or a retired field still carried (dead configuration, launcher-§5).
  local d = descriptor()
  assertTrue(d ~= nil, "the env caught the descriptor")
  assertEqual(type(d.isEnabled), "function", "Enabled is on every addon (slash-commands-§7)")
  assertEqual(type(d.setEnabled), "function", "the Enabled entry's toggle")
  assertEqual(type(d.isLocked), "function", "the Lock frame row's state")
  assertEqual(type(d.toggleLock), "function", "the Locked entry's toggle")
  assertNil(d.isTestMode, "no test mode, so no Test mode line or entry")
  assertNil(d.toggleTestMode, "no test mode")
  assertNil(d.isWindowShown, "no primary window")
  assertNil(d.toggleWindow, "no primary window")
  assertEqual(type(d.version), "function", "read at show time, not captured at load")
  assertEqual(type(d.openSettings), "function", "left-click's action")
  for _, retired in ipairs({ "onClick", "leftClickLabel", "disabledLine", "slash" }) do
    assertNil(d[retired], retired .. " is retired at Launcher minor 4")
  end
  assertNil(d.onTooltipShow, "nothing of the addon's own to append -- and never a title or hints")
end)

test("launcher: each accessor reads the store the Master-controls rows read, on every call", function()
  local d = descriptor()
  NS.SetByPath("locked", true)
  assertTrue(d.isLocked(), "locked row true -> Locked")
  assertTrue(d.isEnabled(), "the enabled row")
  NS.SetByPath("locked", false)
  assertFalse(d.isLocked(), "the same accessor, asked again, sees the unlock")
  NS.SetByPath("locked", true)
  assertEqual(d.version(), tocVersion(), "the version is the TOC's ## Version")
end)

test("launcher: tooltip while enabled and locked -- title, Enabled, Locked, the two fixed hints", function()
  NS.SetByPath("locked", true)
  local lines = hover()
  assertEqual(#lines, 5, "title, Enabled, Locked, Left-click, Right-click: " .. table.concat(lines, " / "))
  assertEqual(lines[1], "Ka0s Party Frame Enhanced  v" .. tocVersion())
  assertEqual(lines[2], "Enabled: " .. GREEN .. "Yes|r")
  assertEqual(lines[3], "Locked: " .. GREEN .. "Yes|r")
  assertEqual(lines[4], "Left-click: Open settings")
  assertEqual(lines[5], "Right-click: Options menu")
end)

test("launcher: tooltip while unlocked -- Locked: No, and no Test mode line in any state", function()
  NS.SetByPath("locked", false)
  local lines = hover()
  assertEqual(#lines, 5)
  assertEqual(lines[3], "Locked: " .. RED .. "No|r")
  for _, line in ipairs(lines) do
    assertTrue(line:find("Test mode", 1, true) == nil, "no Test mode line in any state")
  end
  NS.SetByPath("locked", true)
end)

test("launcher: tooltip while DISABLED -- still shown, Enabled: No, the same two hints", function()
  -- red under: no tooltip while disabled (anti-pattern #89), or an Enabled line that stays Yes.
  NS.SetByPath("enabled", false)
  settleTimers()
  local chatAfterDisable = #mocks.__chat
  local lines = hover()
  assertEqual(#lines, 5, table.concat(lines, " / "))
  assertEqual(lines[2], "Enabled: " .. RED .. "No|r")
  assertEqual(lines[3], "Locked: " .. GREEN .. "Yes|r", "a disabled addon is locked")
  assertEqual(lines[4], "Left-click: Open settings")
  assertEqual(lines[5], "Right-click: Options menu")
  assertEqual(#mocks.__chat, chatAfterDisable, "a hover prints nothing")
  NS.SetByPath("enabled", true)
  settleTimers()
  assertEqual(hover()[2], "Enabled: " .. GREEN .. "Yes|r", "re-read on the next show, never cached")
end)

-- --- the Minimap button row (launcher-§3) -------------------------------------------------------

test("launcher: the Minimap button row is composed, stored, and in its canonical position", function()
  -- red under: a hand-written row (options-ui-§15/§16 forbid it), a sessionOnly one (a hidden button
  -- must survive a reload), or a path the composer prefixed.
  local row = NS.FindSchemaRow(MINIMAP_PATH)
  assertTrue(row ~= nil, "the composer emitted the row")
  assertEqual(row.label, "Minimap button")
  assertEqual(row.type, "bool")
  assertEqual(row.default, true, "the row's own sense is SHOWN")
  assertNil(row.sessionOnly, "stored, never session-only")
  assertTrue(row.startsLine, "it opens the fourth line of the canonical set")
  local master = {}
  for _, r in ipairs(NS.SchemaForPage("general")) do
    if r.group == "Master controls" then master[#master + 1] = r.path end
  end
  assertEqual(master[#master], MINIMAP_PATH, "below Lock frame / Debug console")
end)

test("launcher: the row's get/set INVERT onto LibDBIcon's `hide`, and move the button", function()
  -- red under: a second `show` key beside `hide` (anti-pattern #81), a missing inversion, or a
  -- checkbox the button only follows at the next reload.
  NS.SetByPath(MINIMAP_PATH, true)
  assertEqual(NS.db.global.minimap.hide, false, "SHOWN stores hide = false")
  assertTrue(NS.GetSetting(MINIMAP_PATH), "and reads back as shown")
  assertTrue(registration().shown, "the button is shown")

  NS.SetByPath(MINIMAP_PATH, false)
  assertEqual(NS.db.global.minimap.hide, true, "not-shown stores hide = true")
  assertFalse(NS.GetSetting(MINIMAP_PATH), "and reads back as hidden")
  assertFalse(registration().shown, "the button followed the checkbox immediately")

  -- LibDBIcon writes `hide` itself from its own right-click menu. One key, so the row follows.
  NS.db.global.minimap.hide = false
  assertTrue(NS.GetSetting(MINIMAP_PATH), "the library's own write moves the checkbox too")
  NS.SetByPath(MINIMAP_PATH, true)
end)

-- --- the row's CLI path reads in its own SHOWN sense (launcher-§3, WS-06) ------------------------
--
-- The path is the player's name for the row, so it says what the checkbox says: `global.minimap.shown`.
-- The STORED key does not move -- it is LibDBIcon's `hide` -- so every existing player keeps their
-- choice with no migration and no schema-version bump, and no `shown` key is ever stored beside it
-- (anti-pattern #81: two records of one state, free to disagree).

local function slashOut(ns, m, msg)
  local before = #m.__chat
  ns.Slash:OnSlash(msg)
  local out = {}
  for i = before + 1, #m.__chat do out[#out + 1] = m.__chat[i] end
  return table.concat(out, "\n")
end

test("launcher: the row's path is `global.minimap.shown`, and the old `hide` path is gone", function()
  -- red under: the path still named after LibDBIcon's storage key, or an alias kept beside it.
  assertEqual(NS.MINIMAP_PATH, "global.minimap.shown")
  assertTrue(NS.FindSchemaRow("global.minimap.shown") ~= nil, "the row answers to its shown-sense path")
  assertNil(NS.FindSchemaRow("global.minimap.hide"), "no alias: the storage key is not a CLI path")
  assertTrue(NS.IsGlobalSetting("global.minimap.shown"), "still the one global row")
  assertFalse(NS.IsGlobalSetting("global.minimap.hide"))
end)

test("launcher: `/pfe get|set global.minimap.shown` invert onto the stored `hide`, never a `shown` key", function()
  NS.SetByPath(MINIMAP_PATH, true)
  assertEqual(NS.db.global.minimap.hide, false)
  assertTrue(registration().shown, "the button is shown")
  local got = slashOut(NS, mocks, "get global.minimap.shown")
  assertTrue(got:find("true", 1, true) ~= nil, "get answers true while the button is shown: " .. got)

  slashOut(NS, mocks, "set global.minimap.shown false")
  assertEqual(NS.db.global.minimap.hide, true, "set ... false stores hide = true")
  assertFalse(registration().shown, "and the button is hidden")
  got = slashOut(NS, mocks, "get global.minimap.shown")
  assertTrue(got:find("false", 1, true) ~= nil, "get answers false while the button is hidden: " .. got)
  assertNil(rawget(NS.db.global.minimap, "shown"), "no `shown` key is ever stored")

  local old = slashOut(NS, mocks, "get global.minimap.hide")
  assertFalse(old:find("true", 1, true) ~= nil or old:find("false", 1, true) ~= nil,
    "the old path answers no value: " .. old)
  slashOut(NS, mocks, "set global.minimap.hide false")
  assertEqual(NS.db.global.minimap.hide, true, "the old path writes nothing")

  NS.SetByPath(MINIMAP_PATH, true)
  assertNil(rawget(NS.db.global.minimap, "shown"), "still no `shown` key after a set")
end)

test("launcher: a legacy store with `hide = true` carries over -- no migration, no `shown` key", function()
  -- red under: a rename that moved the stored key, or a path that reads the old key's polarity.
  -- The store is exactly what an existing player's SavedVariables file holds today.
  local sv = { global = { minimap = { hide = true, minimapPos = 200 } }, profiles = {} }
  local NS2, mocks2, _, icons2 = loadLauncher(nil, sv)
  local reg = icons2.__registrations.PartyFrameEnhanced
  assertFalse(NS2.GetSetting("global.minimap.shown"), "the row reads hidden")
  local got = slashOut(NS2, mocks2, "get global.minimap.shown")
  assertTrue(got:find("false", 1, true) ~= nil, "`get` prints false: " .. got)
  assertFalse(reg.shown, "the button stays hidden")
  assertEqual(sv.global.minimap.minimapPos, 200, "the dragged position is untouched")
  assertEqual(sv.global.minimap.hide, true, "the stored key is still LibDBIcon's `hide`")
  assertNil(sv.global.minimap.shown, "no `shown` key after load")

  slashOut(NS2, mocks2, "set global.minimap.shown true")
  assertEqual(sv.global.minimap.hide, false, "set true lands on `hide`")
  assertTrue(reg.shown, "and brings the button back")
  assertEqual(sv.global.minimap.minimapPos, 200, "at its old dragged position")
  assertNil(sv.global.minimap.shown, "no `shown` key is ever written to the raw SV after a set")
end)

test("launcher: LibDBIcon was handed the SAME table the row writes", function()
  -- red under: a copy passed to Register, which would be two records of one state -- and LibDBIcon
  -- writes `minimapPos` into it when the player drags the button (architecture-§5).
  assertEqual(registration().db, NS.db.global.minimap)
  NS.SetByPath(MINIMAP_PATH, false)
  assertEqual(registration().db.hide, true, "the row's write is visible in LibDBIcon's own table")
  NS.SetByPath(MINIMAP_PATH, true)
end)

test("launcher: the minimap table is GLOBAL -- a profile switch leaves it alone", function()
  -- red under: a profile-scoped table. launcher-§3 fixes the scope because a profile is how a player
  -- configures what an addon DRAWS, while the ring of buttons around the minimap is furniture they
  -- arranged once -- so switching profiles must not move a player's buttons, and profile-scoped the
  -- button would appear and vanish on a switch made for an entirely unrelated reason.
  assertNil(NS.db.profile.minimap, "nothing under the profile")
  NS.SetByPath(MINIMAP_PATH, false)
  NS.db:SetProfile("launcher-scope")
  assertEqual(NS.db.global.minimap.hide, true, "the switch did not move the button")
  NS.db:SetProfile("Default")
  NS.SetByPath(MINIMAP_PATH, true)
  while mocks.__fireTimers() > 0 do end
end)

-- --- THE ROW SURVIVES EVERY RESET THIS ADDON SHIPS (launcher-§3, standard v2.54.0) ---------------
--
-- Not one reset: BOTH. Whether the button is shown is a per-installation display preference, in the
-- same class as the POSITION the player dragged it to, which LibDBIcon keeps in the very same table
-- and which no reset touches -- so the survival is a property of the setting rather than a
-- consequence of where it is stored. The two cases below run the REAL resets and read the stored
-- boolean back; asserting `skipRestoreAll` returns true would pass over a second reset that never
-- consults it, which is exactly the hole the standard's old reasoning left.

test("launcher: *Reset all settings* leaves a hidden button hidden", function()
  -- Why it does not reach the row HERE, twice over: the library narrows its walk to the sessionOnly
  -- rows once `resetProfile` is supplied and this row is stored, this addon's own veto skips it
  -- again, and the reset itself is AceDB's ResetProfile -- which empties `db.profile` while the
  -- minimap table lives in `db.global`.
  NS.SetByPath(MINIMAP_PATH, false)
  assertEqual(NS.db.global.minimap.hide, true, "the player hid the button")
  assertFalse(registration().shown, "and it is off the minimap")

  NS.Helpers.RestoreAllDefaults()
  while mocks.__fireTimers() > 0 do end

  assertEqual(NS.db.global.minimap.hide, true, "the stored choice survived")
  assertFalse(NS.GetSetting(MINIMAP_PATH), "the checkbox still reads hidden")
  assertFalse(registration().shown, "and the button did not come back")
  NS.SetByPath(MINIMAP_PATH, true)
end)

test("launcher: the page-scoped General *Defaults* button leaves a hidden button hidden", function()
  -- red under: the row reaching O.RestoreDefaults' page walk at all. That walk vetoes NOTHING -- it
  -- hands every row on the page to applyDefault -- and the composed row carries `default = true`,
  -- so before the exemption a press of Defaults on General put a deliberately hidden button back on
  -- the minimap. The profile reasoning never covered this button: it only ever spoke about *Reset
  -- all settings*.
  NS.SetByPath(MINIMAP_PATH, false)
  assertEqual(NS.db.global.minimap.hide, true, "the player hid the button")

  NS.Helpers.RestoreDefaults("general")

  assertEqual(NS.db.global.minimap.hide, true, "Defaults left the stored choice alone")
  assertFalse(NS.GetSetting(MINIMAP_PATH), "the checkbox still reads hidden")
  assertFalse(registration().shown, "and the button did not come back")

  -- The exemption is one row, not a Defaults button that stopped working: the rows beside it on the
  -- page went back to their own defaults in the very same press.
  NS.SetByPath("general.provider", "blizzard")
  NS.Helpers.RestoreDefaults("general")
  assertEqual(NS.GetSetting("general.provider"), "auto", "the rest of General still resets")
  assertEqual(NS.db.global.minimap.hide, true, "and the button is still hidden")

  NS.SetByPath(MINIMAP_PATH, true)
  while mocks.__fireTimers() > 0 do end
end)

test("launcher: neither reset re-HIDES a shown button either", function()
  -- The rule cuts both ways: a reset may not move the row in either direction. Trivial today,
  -- because the row's default is SHOWN -- and that is precisely why it needs saying, since the day
  -- a default flips the other way this is the case that notices.
  NS.SetByPath(MINIMAP_PATH, true)
  NS.Helpers.RestoreDefaults("general")
  assertEqual(NS.db.global.minimap.hide, false, "Defaults left it shown")
  NS.Helpers.RestoreAllDefaults()
  while mocks.__fireTimers() > 0 do end
  assertEqual(NS.db.global.minimap.hide, false, "and so did Reset all settings")
  assertTrue(registration().shown)
end)

test("launcher: `/pfe reset global.minimap.shown` still works -- the exemption is for SWEEPS", function()
  -- The veto sits on the OPTIONS descriptor's applyDefault, which only the two panel resets call.
  -- A player naming the path themselves is a deliberate act on one row, not a sweep that happened
  -- to reach it, so the schema CLI keeps answering (slash-commands-§2 keeps `reset` live besides).
  NS.SetByPath(MINIMAP_PATH, false)
  NS.Slash:OnSlash("reset " .. MINIMAP_PATH)
  assertEqual(NS.db.global.minimap.hide, false, "the named reset put the row back to its default")
  assertTrue(registration().shown, "and the button came back with it")
end)

-- --- degradation (launcher-§1) ------------------------------------------------------------------

test("launcher: a host with NEITHER broker library loads, reports, and does not raise", function()
  -- red under: a LibStub lookup taken at load, a hard dependency, or a raise. tests/run.lua's own
  -- world is this one -- `libs\` lines are skipped by Loader.tocFiles -- so every other suite in
  -- this repo is already running against it; this case says so on purpose.
  local NS2 = loadLauncher(false)
  assertTrue(NS2.Launcher ~= nil, "the instance is still built -- only Register degrades")
  assertFalse(NS2.Launcher:IsRegistered(), "and honestly reports itself not wired")
  assertNil(NS2.Launcher:Object(), "no broker object without LibDataBroker")
  assertFalse(NS2.Launcher:Register(), "a later Register is still honest, and still does not raise")

  -- The row is still a real setting: the store is the addon's, not the button's.
  NS2.SetByPath(MINIMAP_PATH, false)
  assertEqual(NS2.db.global.minimap.hide, true, "the write landed")
  assertFalse(NS2.GetSetting(MINIMAP_PATH), "and the checkbox reflects what the player chose")
  assertFalse(NS2.Launcher:SetShown(true), "SetShown reports the button could not be moved")
  assertEqual(NS2.db.global.minimap.hide, false, "but the store was updated either way")
end)

test("launcher: the main harness -- no broker libraries at all -- never raised", function()
  -- The whole point of the bargain: LibKa0s is vendored into eleven addons whose libs/ folders are
  -- not identical, so neither broker library may be a dependency.
  assertNil(T.NS.Launcher:Object(), "this repo's default world has no LibDataBroker")
  assertFalse(T.NS.Launcher:IsRegistered())
  assertTrue(T.NS.GetSetting(MINIMAP_PATH), "and the row still answers from the store")
end)
