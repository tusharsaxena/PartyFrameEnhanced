-- tests/test_bus.lua — the closed message bus (architecture-§4): receivers on their own targets
-- both fire, and every message has at most one sending file.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local NS = T.NS

local Loader = dofile("tests/_kit/loader.lua")

test("bus: two receivers of one message on their own targets both fire", function()
  -- The harness keys callbacks by (message, target), as CallbackHandler does, so a shared target
  -- would show as one call here.
  local a, b = 0, 0
  local ta, tb = NS.NewBusTarget(), NS.NewBusTarget()
  ta:RegisterMessage(NS.MSG.LAYOUT, function() a = a + 1 end)
  tb:RegisterMessage(NS.MSG.LAYOUT, function() b = b + 1 end)
  NS.bus:SendMessage(NS.MSG.LAYOUT)
  ta:UnregisterMessage(NS.MSG.LAYOUT)
  tb:UnregisterMessage(NS.MSG.LAYOUT)
  assertEqual(a, 1)
  assertEqual(b, 1)
end)

test("bus: every message is prefixed Ka0s_PartyFrameEnhanced_", function()
  for key, name in pairs(NS.MSG) do
    assertTrue(name:find("^Ka0s_PartyFrameEnhanced_") ~= nil, key .. " = " .. name)
  end
end)

test("bus: no message has more than one sending file", function()
  -- Read from the shipped source: a sender is a SendMessage(NS.MSG.<KEY> …) call site.
  local senders = {}
  for _, path in ipairs(Loader.tocFiles("PartyFrameEnhanced.toc")) do
    local f = io.open(path, "r")
    local src = f:read("*a")
    f:close()
    for key in src:gmatch("SendMessage%(NS%.MSG%.([%u_]+)") do
      senders[key] = senders[key] or {}
      senders[key][path] = true
    end
  end
  for key in pairs(NS.MSG) do
    local files = {}
    for path in pairs(senders[key] or {}) do files[#files + 1] = path end
    table.sort(files)
    assertTrue(#files <= 1, key .. " has " .. #files .. " senders: " .. table.concat(files, ", "))
  end
end)

-- ── the stand-down record (slash-commands-§7) ──────────────────────────────────────────────────
--
-- Characterization of what the record does for a receiver, written against the hand-written record
-- before it moved to LibKa0s-Bus-1.0 and kept unchanged after. Every probe empties itself at the
-- end: a probe made through the tracked factory is part of the record, and a later stand-down case
-- would otherwise replay it (LibKa0s docs/api/Bus/version-1-docs.md, Known limitation 3).

local EVENT = "PLAYER_TARGET_CHANGED"

local function probe()
  local t = NS.NewBusTarget()
  local got = { event = 0, message = 0 }
  t:RegisterEvent(EVENT, function() got.event = got.event + 1 end)
  t:RegisterMessage(NS.MSG.LAYOUT, function() got.message = got.message + 1 end)
  return t, got
end

local function empty(t)
  t:UnregisterAllEvents()
  t:UnregisterAllMessages()
end

test("bus: a stand-down takes a receiver's events AND messages down, and a stand-up puts both back", function()
  local t, got = probe()
  NS.BusStandDown()
  local downEvent = t.__events[EVENT]
  NS.bus:SendMessage(NS.MSG.LAYOUT)
  local downMessages = got.message
  NS.BusStandUp()
  local upEvent = t.__events[EVENT]
  NS.bus:SendMessage(NS.MSG.LAYOUT)
  empty(t)
  assertEqual(downEvent, nil, "the event is unregistered while down")
  assertEqual(downMessages, 0, "a message sent while down reaches no handler")
  assertEqual(type(upEvent), "function", "the event is registered again, with its own handler")
  assertEqual(got.message, 1, "a message sent after the stand-up reaches the handler exactly once")
end)

test("bus: a stand-up replays the record as it is NOW, not a snapshot from the way down", function()
  local t, got = probe()
  NS.BusStandDown()
  t:UnregisterMessage(NS.MSG.LAYOUT)
  NS.BusStandUp()
  NS.bus:SendMessage(NS.MSG.LAYOUT)
  local event = t.__events[EVENT]
  empty(t)
  assertEqual(got.message, 0, "a message dropped while down stays dropped")
  assertEqual(type(event), "function", "the registration that was kept came back")
end)

test("bus: a method-name handler survives the round trip and is called as a method", function()
  local t = NS.NewBusTarget()
  local calls = {}
  function t:OnLayout(message, arg) calls[#calls + 1] = { self = self, message = message, arg = arg } end
  t:RegisterMessage(NS.MSG.LAYOUT, "OnLayout")
  NS.BusStandDown()
  NS.BusStandUp()
  NS.bus:SendMessage(NS.MSG.LAYOUT, "x")
  empty(t)
  assertEqual(#calls, 1, "one call after the round trip")
  assertTrue(calls[1].self == t, "called on its own target")
  assertEqual(calls[1].message, NS.MSG.LAYOUT)
  assertEqual(calls[1].arg, "x")
end)

-- ── what LibKa0s-Bus-1.0 changed (pinned in the adoption commit) ──────────────────────────────

test("bus: re-registering a key after forgetting it never grows the record", function()
  -- red under the hand-written record this replaced: it appended a key-list entry on every
  -- re-register after an unregister, so RangeFade's range-event toggle and Providers' Suspend/Resume
  -- grew it for the whole session.
  local before = NS.BusStandDown()
  NS.BusStandUp()
  local t = NS.NewBusTarget()
  for _ = 1, 5 do
    t:RegisterEvent(EVENT, function() end)
    t:UnregisterEvent(EVENT)
  end
  t:RegisterEvent(EVENT, function() end)
  local after = NS.BusStandDown()
  NS.BusStandUp()
  empty(t)
  assertEqual(after, before + 1, "one key, one entry, however often it was toggled")
end)

test("bus: a registration made while the addon is stood down is recorded and NOT live until it stands up", function()
  local function settle() while T.mocks.__fireTimers() > 0 do end end
  NS.SetByPath("enabled", false)
  settle()
  local t = NS.NewBusTarget()
  local got = 0
  t:RegisterMessage(NS.MSG.LAYOUT, function() got = got + 1 end)
  t:RegisterEvent(EVENT, function() end)
  NS.bus:SendMessage(NS.MSG.LAYOUT)
  local liveWhileDown = t.__events[EVENT]
  NS.SetByPath("enabled", true)
  settle()
  local liveAfter = t.__events[EVENT]
  NS.bus:SendMessage(NS.MSG.LAYOUT)
  empty(t)
  assertEqual(liveWhileDown, nil, "a stood-down addon registers nothing")
  assertEqual(type(liveAfter), "function", "the stand-up made it live")
  assertEqual(got, 1, "the message sent while down never arrived; the one after did, once")
end)

test("bus: NS.MSG is strict, so a mistyped key raises instead of sending nil", function()
  local ok, err = pcall(function() return NS.MSG.LAYOUT_CHANGED end)
  assertTrue(not ok, "an undeclared key raised")
  assertTrue(tostring(err):find("LAYOUT_CHANGED", 1, true) ~= nil, "and named the key: " .. tostring(err))
end)

-- ── the library-absent build ─────────────────────────────────────────────────────────────────

local loadDegraded = dofile("tests/degraded_env.lua")

test("bus: without the library, a receiver still gets a private target that hears the bus", function()
  local NS2 = loadDegraded()
  local a, b = 0, 0
  local ta, tb = NS2.NewBusTarget(), NS2.NewBusTarget()
  assertTrue(ta ~= nil and ta ~= tb, "one target per receiver")
  ta:RegisterMessage(NS2.MSG.LAYOUT, function() a = a + 1 end)
  tb:RegisterMessage(NS2.MSG.LAYOUT, function() b = b + 1 end)
  NS2.bus:SendMessage(NS2.MSG.LAYOUT)
  assertEqual(a, 1)
  assertEqual(b, 1)
end)

test("bus: without the library nothing is recorded, so a stand-down leaves the receivers live (a stated limitation)", function()
  local NS2 = loadDegraded()
  local got = 0
  local t = NS2.NewBusTarget()
  t:RegisterMessage(NS2.MSG.LAYOUT, function() got = got + 1 end)
  assertEqual(NS2.BusStandDown(), 0, "the stub answers no entries")
  NS2.bus:SendMessage(NS2.MSG.LAYOUT)
  assertEqual(NS2.BusStandUp(), 0, "and replays none")
  assertEqual(got, 1, "the registration stayed live through the stand-down")
end)

test("bus: without the library NS.MSG declares the same four names", function()
  local NS2 = loadDegraded()
  local n = 0
  for key, name in pairs(NS.MSG) do
    n = n + 1
    assertEqual(NS2.MSG[key], name, key)
  end
  for _ in pairs(NS2.MSG) do n = n - 1 end
  assertEqual(n, 0, "no key only one build has")
end)
