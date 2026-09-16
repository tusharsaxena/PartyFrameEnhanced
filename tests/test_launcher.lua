-- tests/test_launcher.lua -- the launcher (launcher-§1/§2/§3/§4): ONE object registered twice, the
-- rung (b) left click driving the addon's OWN lock seam, right-click always opening the panel, the
-- Minimap button row's inversion onto LibDBIcon's `hide`, and a host with neither broker library.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local loadLauncher = dofile("tests/launcher_env.lua")

local MINIMAP_PATH = "global.minimap.hide"
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

-- --- the rung (launcher-§2) ---------------------------------------------------------------------

test("launcher: LEFT click toggles the lock through the addon's own seam -- rung (b)", function()
  -- red under: a left click that opens the settings panel (which would make a skipped rule look like
  -- a choice), or one that holds a second copy of the lock instead of writing the `locked` row.
  local opens = 0
  local savedOpen = NS.OpenOptionsPanel
  NS.OpenOptionsPanel = function() opens = opens + 1 end

  NS.SetByPath("locked", true)
  click("LeftButton")
  assertFalse(NS.GetSetting("locked"), "the first left click unlocked -- the preview switch")
  assertEqual(NS.db.profile.locked, false, "it landed in the profile, not in a launcher-local flag")
  click("LeftButton")
  assertTrue(NS.GetSetting("locked"), "the second left click locked again")
  assertEqual(opens, 0, "left click never opened the settings panel")

  NS.OpenOptionsPanel = savedOpen
end)

test("launcher: the left click and `/pfe unlock` are the same seam, not two", function()
  -- red under: a launcher that drove preview mode directly and left the Lock frame checkbox behind.
  local seen = {}
  local saved = NS.SetByPath
  NS.SetByPath = function(path, value)
    seen[#seen + 1] = path .. "=" .. tostring(value)
    return saved(path, value)
  end
  NS.SetByPath("locked", true)
  seen = {}
  click("LeftButton")
  NS.Slash:OnSlash("lock")
  NS.SetByPath = saved
  assertEqual(table.concat(seen, ","), "locked=false,locked=true",
    "both surfaces wrote the one `locked` path through the one seam")
end)

test("launcher: RIGHT click always opens the settings panel", function()
  -- red under: a right click doing anything else. The panel being one right click away is what lets
  -- rungs (a) and (b) spend the left button on something better (launcher-§2).
  local opens = 0
  local savedOpen = NS.OpenOptionsPanel
  NS.OpenOptionsPanel = function() opens = opens + 1 end
  NS.SetByPath("locked", true)
  click("RightButton")
  assertEqual(opens, 1, "the panel opened")
  assertTrue(NS.GetSetting("locked"), "and the lock did not move")
  NS.OpenOptionsPanel = savedOpen
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

test("launcher: `/pfe reset global.minimap.hide` still works -- the exemption is for SWEEPS", function()
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
