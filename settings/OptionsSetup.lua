local _, NS = ...

-- settings/OptionsSetup.lua — the LibKa0s-Options-1.0 seam (options-ui-§1). The canvas shell, the
-- widget makers, the flow engine, the header and the scrollbar patch are the library's; this file
-- says where a value lives, which rows belong to which page, how a color is stored, and what a
-- global reset must not touch.
--
-- LOAD-BEARING POSITION: after settings/Slash.lua, before every settings/<page>.lua, because page
-- files call NS.Helpers (composers, LSMValues) at file load.

local print = NS.Print

-- THE ONE ROW NO RESET THIS ADDON SHIPS MAY REWRITE (launcher-§3). Whether the minimap button is
-- shown is a PER-INSTALLATION DISPLAY PREFERENCE, in the same class as the POSITION the player
-- dragged it to — which LibDBIcon keeps in the very same `db.global.minimap` table and which
-- nothing here touches. Nobody has ever wanted *reset my settings* to mean *and put the button back
-- on my minimap, at the default angle*. That is a property of the setting, so it is stated here
-- rather than derived from where the value happens to live.
--
-- A GLOBAL ROW IS THE TEST, and it is this repo's own word for exactly that class: a stored row
-- outside the profile, registered through NS.RegisterGlobalSetting (settings/Schema.lua). Today
-- there is one, `global.minimap.hide`. Read at CALL time, because this file loads before
-- settings/General.lua registers it.
local function exemptFromReset(row)
    return type(row.path) == "string" and NS.IsGlobalSetting(row.path)
end

-- The one rule about what a global reset leaves alone, named once and enforced twice — by the
-- library through skipRestoreAll, and by the degraded stub's own loop. The global reset IS a profile
-- reset (options-ui-§12), so every profile-backed row is vetoed as well as the Profiles page; what
-- the walk keeps is the sessionOnly rows, which a profile reset cannot reach.
local function vetoedFromResetAll(row)
    if row.page == "profiles" or exemptFromReset(row) then return true end
    return not row.sessionOnly
end

local lib = LibStub and LibStub("LibKa0s-Options-1.0", true)

local descriptor = {
    parentTitle   = "Ka0s Party Frame Enhanced",
    mainPanelName = "PartyFrameEnhancedMainPanel",

    print = function(line) print(line) end,
    debug = function(tag, fmt, ...) NS.Debug(tag, fmt, ...) end,

    -- The single write seam, so a panel change takes exactly the path `/pfe set` takes.
    get          = function(path) return NS.GetSetting(path) end,
    set          = function(path, value) NS.SetByPath(path, value) end,
    -- WHERE THE EXEMPTION ACTUALLY BITES, and it has to be here rather than on skipRestoreAll.
    -- `skipRestoreAll` is read by ONE reset. The page-scoped *Defaults* button is the other, and
    -- O.RestoreDefaults vetoes nothing at all — it hands every row on the page to this seam, and the
    -- composed Minimap button row declares `default = true`, so before this guard a press of
    -- Defaults on General put a deliberately hidden button straight back on the minimap. This is the
    -- one call BOTH panel resets make, so naming the rule once here covers both.
    --
    -- Not on NS.ApplyDefault itself: that is also the schema CLI's seam, and `/pfe reset
    -- global.minimap.hide` is a player naming one row on purpose rather than a sweep that happened
    -- to reach it. The exemption is for sweeps.
    applyDefault = function(row)
        if exemptFromReset(row) then return end
        NS.ApplyDefault(row)
    end,
    allRows      = function() return NS.Schema end,
    rowsForPage  = function(pageKey) return NS.SchemaForPage(pageKey) end,

    skipRestoreAll = vetoedFromResetAll,

    -- RESET ALL SETTINGS IS A PROFILE RESET (options-ui-§12). AceDB empties the ACTIVE profile only,
    -- the defaults merge back, and OnProfileReset rebuilds every element off one PROFILE message.
    -- Free-placement positions live in the profile, so they come back with it.
    resetProfile = function()
        local db = NS.db
        if db and db.ResetProfile then NS.ResetProfileCounted(db) end
    end,
    -- settings/Profiles.lua ships the AceDBOptions page, so Reset all settings' tooltip names the
    -- equivalence with Profiles → Reset Profile.
    profilesPage = true,

    -- The bulk bracket (debug-logging-§10), always as a pair.
    bulkBegin = function(act, scope) NS.Bulk.Begin(act, scope) end,
    bulkEnd   = function(act, scope, count, err, info) NS.Bulk.End(act, scope, count, err, info) end,

    scheduleTimer = function(fn, delay) return NS.addon:ScheduleTimer(fn, delay) end,
    getLSM        = function() return NS.GetLSM() end,
    validate      = function() NS.ValidateSchema() end,
    onAceGUI      = function(AceGUI) NS.AceGUI = AceGUI end,

    -- The landing page's body; settings/About.lua decorates BuildMainContent onto the instance.
    buildMain = function(ctx)
        if NS.Helpers and NS.Helpers.BuildMainContent then NS.Helpers.BuildMainContent(ctx) end
    end,

    -- Colors are stored as { r, g, b, a } named keys, the library's default shape — written out
    -- because the stored shape is a contract with the render code.
    colorDecode = function(c)
        if type(c) ~= "table" then c = {} end
        return c.r or 1, c.g or 1, c.b or 1, c.a or 1
    end,
    colorEncode = function(r, g, b, a) return { r = r, g = g, b = b, a = a or 1 } end,
}

-- ── the degradation stub — LOAD-COMPLETING, not member-answering (options-ui-§1) ─────────────
--
-- Page files call into NS.Helpers INSIDE schema-row literals at file load (LSMValues, the five
-- composers). With any of those nil the page file raises, its rows never register, and the CLI and
-- the defaults lose a third of the schema without a word. So this stub publishes every member a
-- page touches at load — measured by deleting one and re-running the library-absent load — keeps the
-- global reset real (the player whose panel will not open is the one who needs it), and makes the
-- rest no-ops. The composers are HOLLOW (options-ui-§1: the no-copy MUST wins over the load-completing
-- one): they answer an empty row list, and tests/test_optionssetup.lua pins the resulting row delta.
-- No widget maker, flow engine, header or LAYOUT constant is copied here.
if not lib then
    local MISSING = NS.LIBKA0S_MISSING .. ", so the settings panel is unavailable."
    local Helpers = {}
    NS.Helpers = Helpers

    Helpers.LSMValues = function() return function() return {} end end

    Helpers.MASTER_GROUP = "Master controls"
    Helpers.ColorPair   = function() return {} end
    Helpers.FontGroup   = function() return {} end
    Helpers.BorderGroup = function() return {} end
    Helpers.BarGroup    = function() return {} end
    Helpers.MasterControls = function() return {}, function() end end

    Helpers.RestoreAllDefaults = function()
        NS.Bulk.Run("reset", "all", function(info)
            for _, row in ipairs(NS.Schema or {}) do
                if not vetoedFromResetAll(row) then NS.ApplyDefault(row) end
            end
            local db = NS.db
            if db and db.ResetProfile then
                NS.ResetProfileCounted(db)
                info.profileReset = true
            end
        end)
    end

    -- Reached only from a builder, a render or a user action: a no-op is the honest answer.
    for _, name in ipairs({
        "CreatePanel", "EnsureDefaultsButton", "EnsureScroll", "ClearScroll", "Section",
        "AddSpacer", "AttachTooltip", "InlineButtonPair", "RenderField", "RenderGrid", "RenderRows",
        "RenderSchema", "SessionCheckbox", "RefreshAllPanels", "RestoreDefaults",
        "PatchAlwaysShowScrollbar", "SetRenderer",
        "SetChromeHeight", "TabStrip", "PageHeader", "RenderTabbedSchema",
        "SelectTab", "ChoiceGrid", "IdInput", "IdList",
    }) do
        Helpers[name] = function() end
    end
    Helpers.ResolveId         = function() return nil end
    Helpers.UnnamedCandidates = function() return nil end
    Helpers.ID_NAME_HINT      = {}
    Helpers.__panels   = function() return {} end
    Helpers.__panelFor = function() return nil end

    NS.RegisterOptionsPage = function() end
    NS.RefreshOptionsPanel = function() end
    NS.CreateOptionsPanel  = function() print(MISSING) end
    NS.OpenOptionsPanel    = function() print(MISSING) end
    return
end

-- ── the live wiring ───────────────────────────────────────────────────────────────────────────

-- The process-global LSM30_Border widget fixup, published once by the library and idempotent across
-- every vendored copy. Libraries load before this file, so AceGUI-SharedMediaWidgets is registered.
lib.__PatchLSM30Border()

-- NS.Helpers IS the library instance, decorated in place, never a copy-across (options-ui-§1).
NS.Helpers = lib:New(descriptor)
local Helpers = NS.Helpers

NS.RegisterOptionsPage = function(key, name, builder) Helpers.RegisterOptionsPage(key, name, builder) end
NS.CreateOptionsPanel  = function() Helpers.CreateOptionsPanel() end
NS.OpenOptionsPanel    = function() Helpers.OpenOptionsPanel() end
NS.RefreshOptionsPanel = function() Helpers.RefreshAllPanels() end
