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
