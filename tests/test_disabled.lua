-- tests/test_disabled.lua — the stand-down conformance suite (slash-commands-§7, anti-pattern #85).
--
-- WHAT THIS SUITE IS FOR, AND WHAT IT REFUSES TO BE. "Disabled" is total: the addon stops drawing,
-- stops watching, stops writing, and the only thing left alive is the surface that can turn it back
-- on. Eleven addons in this collection implemented that as a DRAW GATE — a rung in a show ladder, a
-- boolean an early return consults — and every one of them passed its own tests, because a suite
-- written against a handler's early return CANNOT tell a draw gate from a stand-down. An early
-- return means the addon did not stop watching, it stopped reacting, and it still pays the dispatch
-- on every event.
--
-- So every negative assertion below reads the REGISTRATION SET out of the kit's recording mock. Not
-- a handler's return value, not a flag, not "did the frame hide". If a case here could be satisfied
-- by an `if disabled then return end`, it is the wrong case and it is certifying the thing it exists
-- to catch.
--
-- `__fire` on a frame reaches its OnEvent whether or not the frame ever registered, so a case that
-- only fires an event proves nothing about a stand-down. Step 6 fires through the LIVE registry
-- (`__fire`, which walks the registrations) and then deliberately reaches a handler anyway
-- (`__fireUnconditional`) to prove the harness can still dispatch — otherwise "nothing ran" would be
-- a statement about the mock rather than about the addon.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local NS, mocks = T.NS, T.mocks

local function settle() while mocks.__fireTimers() > 0 do end end

-- One registration rendered as a comparable string. The target is named where it has a name — which
-- is every frame this addon creates — because the per-unit filter is what a careless rebuild widens,
-- and `UNIT_SPELLCAST_START` on the wrong bar has the same count and a different set. Kit revision
-- 26 also records every live EventRegistry callback, as `{ kind = "callback", event, owner }` with no
-- `target` (LK-04), so the registrant is whichever of the two the entry carries.
local function sig(r)
  local who = r.target or r.owner
  local name = type(who) == "table" and who.__name or r.kind
  return name .. "|" .. r.kind .. "|" .. tostring(r.event) .. "|" .. tostring(r.unit)
end

local function regs()
  local out = {}
  for _, r in ipairs(mocks.__registrations()) do out[#out + 1] = sig(r) end
  table.sort(out)
  return out
end

--- The frames this ADDON shows. Filtered by name rather than taken whole: the kit hands out a
--- parentless stub for every CreateTexture and CreateFontString, those stubs land in the mock's
--- frame set, and nothing ever hides them because nothing ever showed them. Every frame this addon
--- creates carries a name, so the name is the filter that separates the addon's screen from the
--- mock's bookkeeping.
--- The DIAGNOSTIC windows, which are not the addon's display and are not stood down with it. `debug`
--- and `perf` answer while disabled (slash-commands-§2) precisely because the usual reason to reach
--- for either is that the addon is misbehaving, and a console that closed itself the moment the
--- player switched the addon off would be useless at the one moment it is wanted.
local function isDiagnostic(name)
  return name:find("PerfPanel", 1, true) ~= nil or name:find("DebugLog", 1, true) ~= nil
end

local function shownOwn()
  local out = {}
  for _, f in ipairs(mocks.__shownFrames()) do
    local name = type(f.__name) == "string" and f.__name or ""
    if name:find("PartyFrameEnhanced", 1, true) and not isDiagnostic(name) then
      out[#out + 1] = f
    end
  end
  return out
end

local function enable(on) NS.SetByPath("enabled", on) settle() end

-- Brought up ENABLED and unlocked, so there is something on screen to take away: preview is this
-- addon's only display switch outside a live cast (options-ui-§15), and an addon with an empty
-- baseline would pass every assertion below trivially.
local R_on, F_on = {}, {}

test("disabled: the baseline — enabled, the addon registers and draws", function()
  enable(true)
  NS.SetByPath("locked", false)
  settle()
  mocks.__runStateDrivers()

  R_on = regs()
  F_on = shownOwn()
  assertTrue(#R_on > 0, "an addon that registers nothing when enabled proves nothing when disabled")
  assertTrue(#F_on > 0, "and it has something on screen to take away")
  assertEqual(#mocks.__timers(), 0, "nothing was left armed by the baseline itself")
end)

test("disabled: every registration the addon owns is UNREGISTERED, not gated", function()
  -- red under: drop the each("Suspend") / NS.BusStandDown() pair in NS.StandDown, or replace either
  -- with a flag the handlers read — the handlers would still early-return, every assertion about
  -- behavior would still pass, and this one would go red, which is the entire point of it.
  --
  -- red under: drop editModeCallback(false) from Providers:Suspend — the 'callback|EditMode.Exit'
  -- row the kit's recording EventRegistry reports (LK-04) survives the stand-down.
  --
  -- Written through the WRITE SEAM, never by calling NS.StandDown directly: the route the checkbox
  -- and `/pfe disable` take is the route that has to work.
  enable(false)

  local after = regs()
  assertEqual(#after, 0, "by count: " .. table.concat(after, ", "))
  for _, s in ipairs(after) do assertTrue(false, "still registered: " .. s) end
end)

test("disabled: nothing is left armed to wake up", function()
  -- red under: a Suspend that leaves a ticker or an OnUpdate running. A coalescing repaint timer
  -- that re-arms ten times a second and then finds nothing to paint is the most expensive shape
  -- slash-commands-§7 exists to kill.
  assertEqual(#mocks.__timers(), 0, "no AceTimer handle, no C_Timer ticker, no OnUpdate")
  settle()
  assertEqual(#mocks.__timers(), 0, "and none is armed for the rest of the run")
end)

test("disabled: leaving Edit Mode while disabled arms nothing", function()
  -- red under: drop editModeCallback(false) from Providers:Suspend AND the suspended guard in burst.
  -- Leaving Edit Mode is the one trigger the bus record cannot stand down on its own. Two defenses
  -- hold it: step 3 falsifies the unregister, and test_providers reaches burst() directly to
  -- falsify the guard, because with the callback gone the client cannot reach it from here.
  mocks.EventRegistry:TriggerEvent("EditMode.Exit")
  assertEqual(#mocks.__timers(), 0, "no resolve and no follow-up is armed")
end)

test("disabled: every frame that was on screen is hidden, and refused at the source", function()
  for _, f in ipairs(F_on) do
    assertFalse(f:IsShown(), "still shown: " .. tostring(f.__name))
  end
  -- At the SOURCE, not imperatively: a hidden frame comes back on a combat transition or a settings
  -- change, so the show ladder itself has to answer no.
  assertFalse(NS.Element.MasterShows(), "the show ladder's step 0 answers no")
  assertEqual(#shownOwn(), 0, "and nothing of the addon's is left on screen")
end)

-- The eight container frames the addon owns and the kit's census only sees because CreateFrame now
-- starts a frame shown (LK-05): one fade frame per unit, which the elements are parented to, and one
-- free-placement holder per feature, which secure elements anchor to. Named directly, not filtered
-- out of the census, so the step-5 claim about them does not rest on the baseline having caught them.
local function containers()
  local out = {}
  for _, unit in ipairs(NS.Units.LIST) do out[#out + 1] = NS.RangeFade.Parent(unit) end
  for _, key in ipairs(NS.Anchor.__order) do out[#out + 1] = NS.Anchor.__features[key].holder end
  return out
end

local function assertContainers(shown, why)
  local list = containers()
  assertEqual(#list, #NS.Units.LIST + #NS.Anchor.__order, "every fade frame and every holder")
  for _, f in ipairs(list) do
    assertEqual(f:IsShown(), shown, tostring(f.__name) .. " " .. why)
  end
end

test("disabled: the fade frames and the free-placement holders are hidden", function()
  -- red under: drop the Hide from RangeFade:Suspend / Anchor:Suspend. Nothing in them is visible
  -- while the elements are down, so only a direct look can tell (slash-commands-§7).
  assertContainers(false, "is hidden while disabled")
end)

test("disabled: no game event produces a write, a line, or a frame", function()
  -- red under: any handler that acts on the disabled state — the collection's live example is an
  -- addon that writes `locked = true` and prints to chat on entering combat WHILE DISABLED, which is
  -- the failure in its purest form, because the absence of that line is the player's evidence that
  -- the addon is off.
  mocks.__resetSvWrites()
  mocks.__resetPrinted()
  local shownBefore = #shownOwn()

  local fired = {}
  local ran = 0
  for _, s in ipairs(R_on) do
    local event = s:match("|[^|]*|([^|]*)|")
    if event and event ~= "nil" and not fired[event] then
      fired[event] = true
      ran = ran + mocks.__fire(event, "player")
    end
  end
  -- By name, because this is the one the collection's live example fails on.
  ran = ran + mocks.__fire("PLAYER_REGEN_DISABLED")
  assertEqual(ran, 0, "the client had nobody to dispatch to")

  assertEqual(#mocks.__svWrites(), 0, "zero SavedVariables writes")
  assertEqual(#mocks.__printed(), 0, "zero lines to the player")
  assertEqual(#shownOwn(), shownBefore, "zero frames shown")

  -- THE FALSIFICATION HALF. `__fire` over an empty registry runs nothing, so "no write, no line, no
  -- frame" is equally true of a harness that lost the ability to dispatch at all. Reach a handler
  -- the addon still owns but the client can no longer see, and prove it is still there.
  local bar = F_on[1]
  assertEqual(mocks.__fireUnconditional(bar, "UNIT_SPELLCAST_START", bar.unit), 1,
    "the handler is still callable — it is simply no longer reachable from the client")
  assertEqual(#mocks.__svWrites(), 0, "and even reached directly it wrote nothing")
end)

test("disabled: the whole reserved surface still answers, and only feature verbs refuse", function()
  -- This step is NOT the stand-down — the five above are. It pins slash-commands-§2's surface, which
  -- v2.56.0 narrowed to `enable` and `help` and v2.57.0 REVERSED: every reserved verb answers while
  -- disabled, and the bare `/pfe` opens the settings panel, which is the case that settled it.
  local live = NS.Slash.__liveWhileDisabled
  local line = NS.Slash.__cli:DisabledLine()

  local function dispatch(msg)
    local before = #mocks.__chat
    NS.Slash:OnSlash(msg)
    local out = {}
    for i = before + 1, #mocks.__chat do out[#out + 1] = mocks.__chat[i] end
    return out
  end

  local opens = 0
  local savedOpen = NS.OpenOptionsPanel
  NS.OpenOptionsPanel = function() opens = opens + 1 end

  assertEqual(#dispatch(""), 0, "the bare /pfe printed no refusal")
  assertEqual(opens, 1, "it opened the settings panel, exactly as it does when the addon is running")

  local refused = {}
  for _, e in ipairs(NS.COMMANDS) do
    local verb = e[1]
    -- Re-asserted before EVERY verb, because the live set contains verbs that legitimately turn the
    -- addon back on: `enable` by name, and `resetall`, whose defaults have it on. Walking the table
    -- without this would test the first few verbs disabled and the rest enabled, and pass.
    NS.SetByPath("enabled", false)
    local before = #mocks.__chat
    NS.Slash:OnSlash(verb == "debug" and "debug off" or verb)
    local out = {}
    for i = before + 1, #mocks.__chat do out[#out + 1] = mocks.__chat[i] end
    if live[verb] then
      -- `help` carries the line under its header — it is a statement about the rows below it, not a
      -- refusal of help, and the index prints in full so the player can SEE `enable`.
      if verb ~= "help" then
        assertTrue(table.concat(out, "\n"):find(line, 1, true) == nil, verb .. " was refused")
      end
    else
      assertEqual(#out, 1, verb .. " answered on more than one line")
      assertTrue(out[1]:find(line, 1, true) ~= nil, verb .. " did not print the collection's line")
      refused[#refused + 1] = verb
    end
  end
  NS.OpenOptionsPanel = savedOpen

  assertEqual(table.concat(refused, ","), "resetposition,lock,unlock",
    "the three verbs that drive what this addon draws, and only those")
  assertEqual(NS.GetSetting("enabled"), false, "and none of that turned the addon back on")
end)

test("disabled: re-enabled, the addon rebuilds from CURRENT state", function()
  -- red under: a stand-up that replays a snapshot taken on the way down. The second half changes a
  -- setting WHILE the addon is off, which a snapshot cannot know about (performance-§6).
  -- `resetall` ran in the step above and put `locked` back to its shipped default, which ends
  -- preview; the baseline was taken unlocked. Restored explicitly rather than left to luck, because
  -- what this case compares is the registration set and preview owns one of its rows.
  enable(true)
  NS.SetByPath("locked", false)
  settle()
  mocks.__runStateDrivers()
  assertEqual(table.concat(regs(), "\n"), table.concat(R_on, "\n"), "the same set came back")

  enable(false)
  NS.SetByPath("castbar.enabled", false)
  enable(true)
  local without = regs()
  assertTrue(#without < #R_on, "the rebuild reflects the setting changed while it was off")

  -- Unlocked again for the same reason as above: standing down force-locks, because an addon the
  -- player switched off must not leave placeholders on their screen.
  NS.SetByPath("castbar.enabled", true)
  NS.SetByPath("locked", false)
  settle()
  assertEqual(table.concat(regs(), "\n"), table.concat(R_on, "\n"), "and putting it back restores it")
end)

test("disabled: re-enabled, the fade frames and the holders are shown again", function()
  -- red under: drop the Show from RangeFade:Resume / Anchor:Resume. The elements would come back as
  -- children of a hidden frame, and every one of them would stay invisible.
  assertContainers(true, "is shown again")
end)

test("disabled: two holds, one latch — releasing one never resurrects the other's addon", function()
  -- red under: a resume that calls a bare stand-up, or a `disable` that stands the addon up on its
  -- way out. This is the trap the latch exists for and it is reachable in the client: `/pfe disable`
  -- and `/pfe enable` are both live, so a player can use either DURING a suspended perf arm.
  local lc = NS.lifecycle

  lc:Hold("perf")
  enable(false)
  assertEqual(#regs(), 0, "both holds taken")
  lc:Release("perf")
  assertEqual(#regs(), 0, "the perf arm ended and the addon the player disabled stayed down")
  enable(true)
  assertTrue(#regs() > 0, "releasing the LAST hold is the only thing that stands it up")

  -- The other order, because hold order must not matter.
  enable(false)
  lc:Hold("perf")
  assertEqual(#regs(), 0, "both holds taken")
  enable(true)
  assertEqual(#regs(), 0, "the capture still has it, so it is still down")
  lc:Release("perf")
  assertTrue(#regs() > 0, "and only now does it come back")

  assertFalse(lc:IsHeld("perf"), "nothing was left holding")
  assertEqual(#lc:Holds(), 0, "the hold set is empty")
end)

test("disabled: the launcher's LEFT click opens the panel and its menu grays every feature toggle", function()
  -- launcher-§2 (standard v2.67.0) with slash-commands-§7: left-click opens the settings panel in
  -- either state (the panel is setup, and where the addon is re-enabled), and right-click's menu
  -- keeps *Enabled* live while *Locked* -- this addon's preview switch, a feature -- is grayed and
  -- calls nothing. Neither click writes a SavedVariable or prints a line.
  --
  -- Its own world: tests/run.lua's harness deliberately has neither broker library, so the object
  -- with the OnClick on it only exists in the one tests/launcher_env.lua builds.
  local NS2, mocks2 = dofile("tests/launcher_env.lua")()
  local obj = NS2.Launcher:Object()

  NS2.SetByPath("locked", true)
  NS2.SetByPath("enabled", false)
  while mocks2.__fireTimers() > 0 do end
  mocks2.__resetSvWrites()
  mocks2.__resetPrinted()

  local opens = 0
  NS2.OpenOptionsPanel = function() opens = opens + 1 end

  obj.OnClick(obj, "LeftButton")
  assertEqual(opens, 1, "left click opens the settings panel while disabled")

  obj.OnClick(obj, "RightButton")
  local menu = mocks2.__menu.last
  assertTrue(menu ~= nil, "right click opens the options menu")
  assertEqual(opens, 1, "and not the panel")
  assertTrue(menu:Find("Enabled").enabled, "Enabled stays live")
  assertFalse(menu:Find("Locked").enabled, "Locked is grayed")
  menu:ForceClick("Locked")

  assertEqual(#mocks2.__printed(), 0, "no line printed")
  assertEqual(#mocks2.__svWrites(), 0, "a click on a disabled addon writes no SavedVariables")
  assertEqual(NS2.GetSetting("locked"), true, "the lock did not move")
end)

-- The ten secure buttons (five target, five pet) whose visibility state drivers the stand-down
-- releases. Their drivers are the one piece of the addon the registration census above cannot see:
-- a state driver is registered with the client's secure state-driver manager, not as an event.
local function unitButtons()
  local out = {}
  for _, feature in ipairs({ NS.TargetFrames, NS.PetFrames }) do
    for _, unit in ipairs(NS.Units.LIST) do out[#out + 1] = feature.__buttons[unit] end
  end
  return out
end

local function driven()
  local out = {}
  for _, btn in ipairs(unitButtons()) do
    if btn.__drivers and btn.__drivers.visibility then out[#out + 1] = btn.__key end
  end
  return out
end

local driversOn = {}

test("disabled: out of combat, the target and pet state drivers are UNREGISTERED", function()
  -- red under: keep the "hide" driver. A constant "hide" hides the buttons just as well, and every
  -- visual assertion would still pass, but the secure state-driver manager keeps evaluating ten
  -- conditions for an addon the player switched off (slash-commands-§7).
  -- Unlocked, so preview puts a "show" driver on what it can: a baseline of all-"hide" drivers
  -- would let a stand-up that re-installs "hide" everywhere pass the next case.
  -- Free placement too: attached, a button with no party frame to sit on is not allowed even in
  -- preview, and this harness has no frame system loaded. Restored after the combat case.
  enable(true)
  NS.SetByPath("target.anchorMode", "free")
  NS.SetByPath("pet.anchorMode", "free")
  NS.SetByPath("locked", false)
  settle()
  for _, btn in ipairs(unitButtons()) do driversOn[btn.__key] = btn.__drivers and btn.__drivers.visibility end
  assertEqual(#driven(), #unitButtons(), "the baseline: every button has a driver while enabled")

  enable(false)
  assertEqual(table.concat(driven(), ", "), "", "no target or pet button keeps a visibility driver")
  for _, btn in ipairs(unitButtons()) do
    assertFalse(btn:IsShown(), btn.__key .. " is hidden")
  end
end)

test("disabled: re-enabled, the released state drivers are re-installed", function()
  -- red under: a Release that leaves the request memo (`__driverWant`) set, so the stand-up's
  -- ApplyDriver skips the write as unchanged and the buttons never show again.
  -- Standing down force-locks, so the baseline's preview is restored explicitly.
  enable(true)
  NS.SetByPath("locked", false)
  settle()
  for _, btn in ipairs(unitButtons()) do
    assertTrue(btn.__drivers and btn.__drivers.visibility ~= nil, btn.__key .. " has a driver again")
    assertEqual(btn.__drivers.visibility, driversOn[btn.__key], btn.__key .. " got its old driver back")
  end
  assertEqual(NS.TargetFrames.__buttons.party1.__drivers.visibility, "show", "the preview driver")
end)

test("disabled: in combat, the release is queued and PLAYER_REGEN_ENABLED completes it", function()
  -- red under: keep the "hide" driver, or run UnregisterStateDriver under lockdown, which the client
  -- blocks and blames on the addon.
  local saved = mocks.InCombatLockdown
  mocks.InCombatLockdown = function() return true end
  enable(false)
  assertEqual(#driven(), #unitButtons(), "nothing secure was touched under lockdown")
  assertTrue(NS.PendingSecureCount() > 0, "the release is queued")

  mocks.InCombatLockdown = saved
  local ran = mocks.__fire("PLAYER_REGEN_ENABLED")
  assertEqual(ran, 1, "exactly one listener — the pending-secure watcher — was live to receive it")
  assertEqual(table.concat(driven(), ", "), "", "and the queued release ran")
  assertEqual(NS.PendingSecureCount(), 0, "nothing is left queued")
  assertEqual(#regs(), 0, "and the watcher let go of the event the moment it fired")
  enable(true)
  settle()
  assertEqual(#driven(), #unitButtons(), "back up, every driver returns")
  NS.SetByPath("target.anchorMode", "attached")
  NS.SetByPath("pet.anchorMode", "attached")
end)

test("disabled: in combat, the fade frames and holders hide once combat ends", function()
  -- red under: hide them outside NS.RunSecure. Secure buttons are parented to the fade frames and
  -- anchored to the holders, so a hide under lockdown is the client's to block and blame on us.
  enable(true)
  settle()
  assertContainers(true, "is shown while enabled")
  local saved = mocks.InCombatLockdown
  mocks.InCombatLockdown = function() return true end
  enable(false)
  assertContainers(true, "is left alone under lockdown")
  assertTrue(NS.PendingSecureCount() > 0, "the hide is queued")

  mocks.InCombatLockdown = saved
  mocks.__fire("PLAYER_REGEN_ENABLED")
  assertContainers(false, "is hidden once combat ends")
  assertEqual(NS.PendingSecureCount(), 0, "nothing is left queued")
  enable(true)
  settle()
  assertContainers(true, "is shown again on stand-up")
end)

test("disabled: unlocking through the seam prints only the collection line and writes nothing", function()
  -- slash-commands-§7: the one refusal a disabled addon prints is cli:DisabledLine(), and the Lock
  -- frame row (NS.AcceptLock, the `locked` row's validate) MUST NOT print a second wording.
  -- red under: restore REFUSED_DISABLED
  enable(false)
  NS.db.profile.locked = true
  local before = #mocks.__chat
  local ok = NS.SetByPath("locked", false)
  local out = {}
  for i = before + 1, #mocks.__chat do out[#out + 1] = mocks.__chat[i] end
  assertEqual(ok, false, "the seam reports the refused write")
  assertEqual(#out, 1, "exactly one chat line")
  local gate = #mocks.__chat
  NS.Slash:OnSlash("unlock")
  assertEqual(out[1], mocks.__chat[gate + 1], "byte for byte the line the slash gate prints")
  assertTrue(out[1]:find(NS.Slash.__cli:DisabledLine(), 1, true) ~= nil, "the collection's line")
  assertEqual(NS.db.profile.locked, true, "the stored lock did not move")
end)

test("disabled: the suite leaves the world enabled for the suites after it", function()
  enable(true)
  NS.SetByPath("locked", true)
  settle()
  assertTrue(#regs() > 0)
end)
