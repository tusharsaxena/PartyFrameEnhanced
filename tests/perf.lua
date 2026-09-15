-- tests/perf.lua — the offline performance runner (performance-§9).
--
--   lua tests/perf.lua [--out <path>] [--label <text>]
--
-- DELIBERATELY OUTSIDE THE GREEN GATE: `lua tests/run.lua` never runs it, and no commit depends on
-- it. It asserts only deterministic quantities — API calls and bytes allocated per iteration — and
-- prints timings for orientation. Scenarios arrive with the features (plan P7).

local Loader     = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")
Loader.addonName = "PartyFrameEnhanced"

local opts = { out = nil, label = "offline" }
do
  local i = 1
  while arg and arg[i] do
    local a = arg[i]
    if a == "--out" then opts.out = arg[i + 1]; i = i + 2
    elseif a == "--label" then opts.label = arg[i + 1] or opts.label; i = i + 2
    else
      io.stderr:write("unknown argument: " .. tostring(a) .. "\n")
      io.stderr:write("usage: lua tests/perf.lua [--out <path>] [--label <text>]\n")
      os.exit(2)
    end
  end
end

local mocks = buildMocks()
local NS = {}

-- Both halves derived, never copied (tests/test_loadorder.lua checks).
Loader.loadAll(Loader.xmlFiles("libs/LibKa0s/LibKa0s.xml"), NS, mocks)
Loader.loadAll(Loader.tocFiles("PartyFrameEnhanced.toc"), NS, mocks)
NS:InitDB()

local results, failures = {}, {}

print(("Ka0s Party Frame Enhanced \226\128\148 offline perf  (v%s, label '%s')"):format(NS.version, opts.label))
print(("%d scenario(s), %d failure(s)"):format(#results, #failures))

if opts.out then
  local fh, err = io.open(opts.out, "w")
  if not fh then
    io.stderr:write("cannot write " .. opts.out .. ": " .. tostring(err) .. "\n")
    os.exit(2)
  end
  fh:write(NS.Perf.EncodeJSON({
    schema = NS.Perf.SCHEMA, addon = "PartyFrameEnhanced", source = "offline",
    version = NS.version, interface = 0, timestamp = os.time(), label = opts.label,
    buckets = {}, failures = failures,
  }), "\n")
  fh:close()
end

os.exit(#failures == 0 and 0 or 1)
