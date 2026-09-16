local addonName, NS = ...

-- core/PerfSetup.lua — the LibKa0s-Perf-1.0 seam (performance). The probe, the step panel, the
-- capture ring and the report are the library's; this file says which hot paths get buckets, what
-- "suspended" means here, and where output goes.
--
-- LOAD-BEARING POSITION: modules take `local Perf = NS.Perf` at file scope, so NS.Perf — the
-- instance or the stub — exists before the # Modules block.

local lib = LibStub and LibStub("LibKa0s-Perf-1.0", true)
if not lib then
    -- Degrade, never error. Every member the addon calls: the bracket gate and sink, the ladder's
    -- `suspended`, and OnCommand, because `/pfe perf` is registered unconditionally.
    NS.Perf = {
        on        = false,
        suspended = false,
        Note      = function() end,
        OnCommand = function()
            return { NS.LIBKA0S_MISSING .. ", so performance measurement is unavailable." }
        end,
    }
    return
end

NS.Perf = lib:New({
    name      = addonName,
    -- The FOLDER name, which the panel's close control builds its texture path from. Same string as
    -- `name` here, passed explicitly because the two fields answer different questions.
    addonName = addonName,
    title     = "Party Frame Enhanced",
    slash     = "/pfe",
    version   = NS.version,
    sv        = "PartyFrameEnhancedPerfDB",

    -- Report order, and nesting DECLARED rather than explained (performance-§3). Every nested
    -- bracket also passes its parent to Perf.Note, so the capture records what it observed.
    buckets = {
        { key = "resolve" },                             -- Providers: one unit → frame resolve pass
        { key = "anchor" },                              -- Anchor: one feature's placement pass
        { key = "castEvent" },                           -- CastBars: a UNIT_SPELLCAST_* handler
        { key = "castRender",   within = "castEvent" },  -- CastBars: start/update render in it
        { key = "castTick" },                            -- CastBars: every OnUpdate frame a bar shows
        { key = "targetEvent" },                         -- TargetFrames: UNIT_TARGET / marker handler
        { key = "targetTick" },                          -- TargetFrames: one health-ticker pass
        { key = "targetRender", within = "targetTick" }, -- TargetFrames: one frame inside that pass
        { key = "petEvent" },                            -- PetFrames: a pet unit event
        { key = "reskin" },                              -- any feature's config-driven restyle
    },

    -- THE LATCH, NOT A SUSPEND PAIR (slash-commands-§7). From Perf minor 8 the harness takes the
    -- `perf` hold on the host's one latch instead of calling a `suspend`/`resume` pair of its own,
    -- and `NS.Perf.suspended` is a VIEW of that latch rather than a second boolean beside it. The
    -- teardown those two functions used to name is now core/LifecycleSetup.lua's `standDown`, which
    -- is the same teardown the DISABLED hold reaches — one mechanism, so the perf arm and the
    -- disable arm cannot drift about what inert means (anti-pattern #85).
    lifecycle = NS.lifecycle,

    -- Not gated on NS.State.debug: a perf run is an explicit user act, and a console that stayed
    -- empty while a capture ran would read as a broken harness.
    log = function(line)
        if NS.DebugLog and NS.DebugLog.Add then
            NS.DebugLog:Add("Perf", line)
        else
            NS.Print(line)
        end
    end,
    print = function(line) NS.Print(line) end,
    showLog = function()
        if NS.DebugLog and NS.DebugLog.Show and not NS.DebugLog:IsShown() then
            NS.DebugLog:Show()
        end
    end,
    -- No `decorate`: the library draws the panel's close control from addonName, matching the debug
    -- console with nothing wired (performance-§4, anti-pattern #65).
})
