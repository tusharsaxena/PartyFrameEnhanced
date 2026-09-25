-- tests/perf.lua — the offline performance runner (performance-§9).
--
--   lua tests/perf.lua [--out <path>] [--label <text>]
--
-- DELIBERATELY OUTSIDE THE GREEN GATE: `lua tests/run.lua` never runs it, and no commit depends on
-- it. It asserts only deterministic quantities — API calls on the addon's own elements and bytes
-- allocated per iteration, each isolated by a full collect either side — and prints timings for
-- orientation only (compare scenarios within a run, never across machines).
--
-- The reference point is SimplePartyTargets' measured history: ~7 full passes/s over 11 blocks and
-- 46 SetPoint calls per block per pass before per-owner updates, an anchor memo and event filtering.
-- The scenarios below pin the equivalent properties here: one resolve per burst, zero SetPoint on an
-- unchanged pass, per-unit events, a gated ticker that skips unchanged health.
--
-- Output with --out is the shared record schema, encoded by the same NS.Perf.EncodeJSON the in-game
-- probe uses.

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

-- ── environment ─────────────────────────────────────────────────────────────────────────────

local mocks = buildMocks()
local NS = {}

-- A party: the addon is party-only, and the scenarios below measure it active.
mocks.__context.inGroup, mocks.__context.inRaid = true, false

-- Both halves derived, never copied (tests/test_loadorder.lua checks).
Loader.loadAll(Loader.xmlFiles("libs/LibKa0s/LibKa0s.xml"), NS, mocks)
Loader.loadAll(Loader.tocFiles("PartyFrameEnhanced.toc"), NS, mocks)
NS:InitDB()
NS.addon:OnEnable()
while mocks.__fireTimers() > 0 do end

-- The worst realistic case: all five units in a party, every feature on, attached to Blizzard's
-- raid-style frames (which include the player), elements locked (not previewing).
local p = NS.db.profile
p.locked, p.enabled, p.visibility = true, true, "always"
local container = mocks.CreateFrame("Frame")
container:Show()
container.memberUnitFrames = {}
for i, unit in ipairs(NS.Units.LIST) do
  local f = mocks.CreateFrame("Frame")
  rawset(f, "unit", unit)
  f:Show()
  container.memberUnitFrames[i] = f
end
mocks.CompactPartyFrame = container
mocks.EditModeManagerFrame = { UseRaidStylePartyFrames = function() return true end }
NS.Providers.Resolve()
NS.PublishVisibility()
while mocks.__fireTimers() > 0 do end

-- ── the API counting layer ──────────────────────────────────────────────────────────────────
--
-- Counted on the addon's OWN elements and their regions — the calls this addon makes into the
-- client per pass. Installed here rather than in tests/wow_mock.lua so the gated suite keeps
-- measuring the addon, not a counting shim.

local apiCalls = 0
local COUNTED = {
  "SetPoint", "ClearAllPoints", "SetValue", "SetMinMaxValues", "SetText", "SetFormattedText",
  "SetStatusBarColor", "SetAlpha", "Show", "Hide", "SetTexture", "SetTimerDuration",
  "SetVertexColor", "SetTextColor", "SetAttribute",
}
local setPoints = 0

local function count(obj)
  if type(obj) ~= "table" or obj.__counted then return end
  obj.__counted = true
  for _, m in ipairs(COUNTED) do
    local orig = obj[m]
    if type(orig) == "function" then
      local isSetPoint = m == "SetPoint"
      rawset(obj, m, function(self, ...)
        apiCalls = apiCalls + 1
        if isSetPoint then setPoints = setPoints + 1 end
        return orig(self, ...)
      end)
    end
  end
end

local function countElement(el)
  count(el)
  for _, key in ipairs({ "bar", "bg", "text", "text2", "icon", "spark", "shield", "marker", "border" }) do
    count(el[key])
  end
end

for _, unit in ipairs(NS.Units.LIST) do
  countElement(NS.CastBars.__bars[unit])
  countElement(NS.TargetFrames.__buttons[unit])
  countElement(NS.PetFrames.__buttons[unit])
end

-- ── measurement ─────────────────────────────────────────────────────────────────────────────

local results, failures = {}, {}

local function assert_(cond, msg)
  if not cond then failures[#failures + 1] = msg end
  return cond
end

local function measure(name, iterations, fn)
  collectgarbage("collect")
  collectgarbage("collect")
  apiCalls, setPoints = 0, 0
  local kbBefore = collectgarbage("count")
  local t0 = os.clock()
  for i = 1, iterations do fn(i) end
  local elapsed = os.clock() - t0
  local kbAfter = collectgarbage("count")
  local r = {
    name = name, iterations = iterations,
    totalMs = elapsed * 1000, msPerIter = (elapsed * 1000) / iterations,
    apiCalls = apiCalls, apiPerIter = apiCalls / iterations,
    setPointsPerIter = setPoints / iterations,
    bytesPerIter = ((kbAfter - kbBefore) * 1024) / iterations,
  }
  results[#results + 1] = r
  return r
end

local N = 1000

-- 1. Resolve coalescing: a burst of layout triggers in one frame costs ONE resolve. Forty is a
--    SecureGroupHeader re-sort firing OnAttributeChanged on every child several times.
local coalesced
do
  while mocks.__fireTimers() > 0 do end
  local before = #mocks.__timers
  for _ = 1, 40 do NS.Providers.Request() end
  coalesced = #mocks.__timers - before
  while mocks.__fireTimers() > 0 do end
  assert_(coalesced == 1, ("resolve coalescing: 40 requests armed %d resolves, expected 1"):format(coalesced))
end

-- 2. A resolve that finds the frames it already had.
local resolveSame = measure("resolveUnchanged", N, function() NS.Providers.Resolve() end)
assert_(resolveSame.apiPerIter == 0, "an unchanged resolve touched an element")

-- 3. The anchor memo: a full pass over all three features with nothing changed makes no SetPoint.
local anchorSame = measure("anchorUnchanged", N, function() NS.Anchor.ApplyAll() end)
assert_(anchorSame.setPointsPerIter == 0,
  ("an unchanged anchor pass made %.1f SetPoint calls, expected 0"):format(anchorSame.setPointsPerIter))

-- 4. A cast lifecycle per unit: start then stop, all five units — the busiest event path. The cast
--    records are built once, outside the measured loop: they are the client's data, not the addon's.
local bars = NS.CastBars.__bars
local CASTS = {}
for _, unit in ipairs(NS.Units.LIST) do
  CASTS[unit] = { kind = "cast", name = "Heal", remaining = 1, total = 2 }
end
local castBurst = measure("castStartStop", N, function()
  for _, unit in ipairs(NS.Units.LIST) do
    mocks.__casts[unit] = CASTS[unit]
    bars[unit]:__fire("OnEvent", "UNIT_SPELLCAST_START", unit)
    mocks.__casts[unit] = nil
    bars[unit]:__fire("OnEvent", "UNIT_SPELLCAST_STOP", unit)
  end
end)

-- 5. The cast tick: five bars mid-cast, one frame each at the 0.1 s text refresh.
for _, unit in ipairs(NS.Units.LIST) do
  mocks.__casts[unit] = CASTS[unit]
  bars[unit]:__fire("OnEvent", "UNIT_SPELLCAST_START", unit)
end
local castTick = measure("castTick", N, function()
  for _, unit in ipairs(NS.Units.LIST) do
    local el = bars[unit]
    el:GetScript("OnUpdate")(el, 0.11)
  end
end)
for _, unit in ipairs(NS.Units.LIST) do
  mocks.__casts[unit] = nil
  bars[unit]:__fire("OnEvent", "UNIT_SPELLCAST_STOP", unit)
end

-- 6. The target-health ticker: five members all targeting something, health unchanged (the common
--    case between hits) and then changing every pass.
local tbuttons = NS.TargetFrames.__buttons
for _, unit in ipairs(NS.Units.LIST) do
  mocks.__units[NS.Units.TARGET[unit]] = { name = "Boar", health = 50, healthMax = 100, pct = 50, reaction = 2 }
  tbuttons[unit]:__fire("OnEvent", "UNIT_TARGET", unit)
end
-- The client's state-driver manager shows the five buttons; the tick paints only shown ones.
mocks.__runStateDrivers()
-- The ticker's own pass, called directly: through the kit's AceTimer every repeat also queues a
-- fresh timer entry, which is the harness's garbage, not the addon's.
local runTicker = NS.TargetFrames.__tick
local tickSame = measure("targetTickUnchanged", N, runTicker)
assert_(tickSame.apiPerIter == 0,
  ("an unchanged ticker pass made %.1f calls; unchanged plain health must be skipped"):format(tickSame.apiPerIter))
local tickMoving = measure("targetTickMoving", N, function(i)
  for _, unit in ipairs(NS.Units.LIST) do mocks.__units[NS.Units.TARGET[unit]].health = i % 100 end
  runTicker()
end)
for _, unit in ipairs(NS.Units.LIST) do mocks.__units[NS.Units.TARGET[unit]] = nil end
mocks.__runStateDrivers()
runTicker()
while mocks.__fireTimers() > 0 do end

-- 7. A settings drag: a color picker commits every 50 ms, each a full restyle of one feature.
local drag = measure("settingsDrag", 200, function(i)
  NS.SetByPath("castbar.barColor", { r = (i % 10) / 10, g = 0.5, b = 0, a = 1 })
end)

-- 8. Zero overhead: the busiest event path with capture off, pinned against the instrumentation
--    being absent (performance-§2, §9). The bracket `local t0 = Perf.on and debugprofilestop()`
--    cannot be compiled out, so "absent" is stood in for by counting the bracket's only two entry
--    points — the clock read and Perf.Note — and requiring zero of either per iteration while
--    Perf.on is false. A dormant bracket that reaches neither does exactly what an absent one does
--    apart from one table read and one branch. Comparing capture-off with capture-on instead would
--    pass a dormant bracket that allocated as much as an armed one. Modules resolve
--    `debugprofilestop` through the mock environment and read `Perf.Note` off the shared instance
--    at call time, so both wrappers see every bracket. No wall-clock assertion: timings here are
--    orientation only.
local function castOnce()
  mocks.__casts.party1 = CASTS.party1
  bars.party1:__fire("OnEvent", "UNIT_SPELLCAST_START", "party1")
  mocks.__casts.party1 = nil
  bars.party1:__fire("OnEvent", "UNIT_SPELLCAST_STOP", "party1")
end
local bracketCalls = 0
local origClock, origNote = mocks.debugprofilestop, NS.Perf.Note
mocks.debugprofilestop = function(...) bracketCalls = bracketCalls + 1; return origClock(...) end
NS.Perf.Note = function(...) bracketCalls = bracketCalls + 1; return origNote(...) end
local probeOff = measure("probeOverheadOff", N, castOnce)
local bracketOffPerIter = bracketCalls / N
bracketCalls = 0
NS.Perf.on = true
local probeOn = measure("probeOverheadOn", N, castOnce)
NS.Perf.on = false
local bracketOnPerIter = bracketCalls / N
mocks.debugprofilestop, NS.Perf.Note = origClock, origNote
assert_(bracketOffPerIter == 0,
  ("a dormant bracket made %.1f clock/Perf.Note calls per pass; capture off must reach neither"):format(
    bracketOffPerIter))
-- The counters are live: the same path, armed, does reach them — otherwise the zero above is vacuous.
assert_(bracketOnPerIter > 0, "the bracket counters saw no calls with capture on; the zero-overhead check is blind")
assert_(probeOff.apiPerIter == probeOn.apiPerIter, "the probe changed how many API calls a pass makes")

-- ── ceilings ────────────────────────────────────────────────────────────────────────────────
--
-- Set on 2026-09-15, after the perf pass (docs/performance.md records the before/after): every
-- hot path at 0 bytes/iter except castStartStop at 16.6 then, five full start/stop cycles per
-- iteration. Re-measured on 2026-09-24: castStartStop is 3.6 (it dropped at a8e3a44, the
-- stand-down latch, and reads 3.6 or 5.4 from one commit to the next with no cast-path change;
-- one tree always gives the same figure), and every other hot path is still 0. The ceilings were
-- left where they were set. Each ceiling is its figure plus 24: SMALLER than the cheapest regression
-- it exists to catch — one extra table per iteration costs 64 bytes under this interpreter — so the
-- smallest allocation anyone can add to one of these paths trips it. Raise one only by re-measuring
-- and saying why; a rise IS the finding.
--
-- settingsDrag is reported and deliberately unasserted: it runs only while a player drags a control,
-- a guessed ceiling would gate on nothing, and 288 of its 925.9 bytes are the kit mock's own garbage
-- (six no-op closures its catch-all __index builds for RegisterForDrag and EnableMouse, which it
-- does not define). docs/performance.md attributes each move by commit.
local CEILINGS = {
  resolveUnchanged     = 24,
  anchorUnchanged      = 24,
  castStartStop        = 41,   -- set from 16.6 (2026-09-15) + 24; measures 3.6 on 2026-09-24
  castTick             = 24,
  targetTickUnchanged  = 24,
  targetTickMoving     = 24,
  probeOverheadOff     = 24,
}
for _, r in ipairs(results) do
  local ceiling = CEILINGS[r.name]
  if ceiling then
    assert_(r.bytesPerIter <= ceiling,
      ("%s allocated %.1f bytes/iter, over its %d-byte ceiling"):format(r.name, r.bytesPerIter, ceiling))
  end
end

-- ── report ──────────────────────────────────────────────────────────────────────────────────

print(("Ka0s Party Frame Enhanced \226\128\148 offline perf  (v%s, label '%s')"):format(NS.version, opts.label))
print(("40 layout requests coalesced into %d resolve%s"):format(coalesced, coalesced == 1 and "" or "s"))
print()
-- Five columns, exactly: tests/_kit/run-automated-tests.sh counts scenarios structurally as the
-- five-field rows under this header, so a sixth column makes every row invisible to it (the first
-- release-candidate run recorded "0 scenarios" for that reason). SetPoint counts get their own line.
print(("%-20s %8s %11s %9s %11s"):format("scenario", "iters", "ms/iter", "api/iter", "bytes/iter"))
for _, r in ipairs(results) do
  print(("%-20s %8d %11.5f %9.1f %11.1f"):format(
    r.name, r.iterations, r.msPerIter, r.apiPerIter, r.bytesPerIter))
end
print()
local sp = {}
for _, r in ipairs(results) do sp[#sp + 1] = ("%s %.1f"):format(r.name, r.setPointsPerIter) end
print("SetPoint calls/iter: " .. table.concat(sp, ", "))
print(("probeOverheadOff %g bracket calls/iter (capture on: %g)"):format(bracketOffPerIter, bracketOnPerIter))
print()
print("timings are for orientation only \226\128\148 compare scenarios within a run, never across machines")
if #failures > 0 then
  print()
  print(("%d assertion%s FAILED:"):format(#failures, #failures == 1 and "" or "s"))
  for _, f in ipairs(failures) do print("  - " .. f) end
end

-- Keep the unused locals honest: these are reported, not asserted beyond the table above.
local _ = castBurst and castTick and tickMoving and drag

if opts.out then
  local buckets = {}
  for _, r in ipairs(results) do
    buckets[r.name] = { calls = r.iterations, totalMs = r.totalMs, maxMs = r.msPerIter,
                        apiPerIter = r.apiPerIter, bytesPerIter = r.bytesPerIter }
  end
  local fh, err = io.open(opts.out, "w")
  if not fh then
    io.stderr:write("cannot write " .. opts.out .. ": " .. tostring(err) .. "\n")
    os.exit(2)
  end
  fh:write(NS.Perf.EncodeJSON({
    schema = NS.Perf.SCHEMA, addon = "PartyFrameEnhanced", source = "offline",
    version = NS.version, interface = 0, timestamp = os.time(), label = opts.label,
    buckets = buckets, coalescing = { requests = 40, resolves = coalesced }, failures = failures,
    fps = { active = { seconds = 0, frames = 0, avgFps = 0, msPerFrame = 0 },
            suspended = { seconds = 0, frames = 0, avgFps = 0, msPerFrame = 0 },
            deltaMsPerFrame = 0 },
  }), "\n")
  fh:close()
  print("wrote " .. opts.out)
end

os.exit(#failures == 0 and 0 or 1)
