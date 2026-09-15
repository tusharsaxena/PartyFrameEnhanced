-- settings/General.lua — the General page (options-ui-§13/§15):
--
--     [ Master controls ][ Party frames ]
--
--     Master controls  [Enable Party Frame Enhanced]  [General visibility]
--                      [Master scale]                 [Master alpha]
--                      [Lock frame]                   [Debug console]
--                      [Test mode]                                           <- session-only checkbox
--                      [Reset position]               [Reset all settings]   <- afterGroup pair
--     Party frames     [Frame system]                 [Include my own row]
--
-- Master controls is COMPOSED from one declaration (options-ui-§15, anti-pattern #73). Not
-- frameless: the free-placement stacks are movable, so scale, alpha, lock and reset position apply.

local _, NS = ...

local L = NS.L
local print = NS.Print
local H = NS.Helpers
local D = NS.defaults.profile

local PAGE = "general"
local PARTY_GROUP = L["Party frames"]

-- The console toggle is session state bound to the console window itself (options-ui-§15); both arms
-- of core/DebugLogSetup.lua answer ConsoleCheckbox, so a library-less build still gets an honest row.
local DEBUG_CONSOLE_PATH = "state.debugConsole"
if NS.DebugLog and NS.DebugLog.ConsoleCheckbox then
    NS.RegisterSessionSetting(DEBUG_CONSOLE_PATH, NS.DebugLog:ConsoleCheckbox())
end

-- Test mode is Master controls' own row (options-ui-§15, standard v2.46.0): a session-only checkbox
-- the composer emits from `testModePath` (LibKa0s v1.37.0), ticked exactly while test mode is on. Its
-- set goes through TestMode.Toggle, so a refused start (combat, disabled, suspended) prints why and the
-- panel redraws the box unticked; modules/TestMode.lua refreshes the panel on every start and stop.
local TEST_MODE_PATH = "state.testMode"
NS.RegisterSessionSetting(TEST_MODE_PATH, {
    get = function() return NS.State.test ~= nil end,
    set = function(v)
        if (NS.State.test ~= nil) ~= (v and true or false) then print(NS.TestMode.Toggle()) end
        if NS.RefreshOptionsPanel then NS.RefreshOptionsPanel() end
    end,
})
local TEST_MODE_TIP = L["Show placeholders on every element: on your party frames in a party, on a stand-in party frame out of one. Combat ends it. The same as /pfe test."]

local masterRows, masterTail = H.MasterControls({
    prefix           = "",
    page             = PAGE,
    addonName        = "Party Frame Enhanced",
    frameless        = false,
    debugConsolePath = DEBUG_CONSOLE_PATH,
    testModePath     = TEST_MODE_PATH,
    defaults         = {
        enabled    = D.enabled,
        visibility = D.visibility,
        scale      = D.scale,
        alpha      = D.alpha,
        locked     = D.locked,
    },
    -- Resolved at click time: modules/Anchor.lua owns the free-placement positions.
    onResetPosition  = function()
        if NS.Anchor and NS.Anchor.ResetPositions then NS.Anchor.ResetPositions() end
    end,
    onResetAll       = function() StaticPopup_Show("PARTYFRAMEENHANCED_RESET_ALL") end,
})

-- The composer emits data; the host's onChange is attached by PATH, so an upstream reorder cannot
-- move a handler onto the wrong row. Scale and alpha need nothing extra: the seam publishes CONFIG
-- ("master") and every element restyles from it.
local masterOnChange = {
    enabled    = function() NS.PublishVisibility() end,
    visibility = function() NS.PublishVisibility() end,
    -- Unlocking is preview mode (preview-mode); modules/Preview.lua owns what that means.
    locked     = function(v) if NS.OnLockChanged then NS.OnLockChanged(v) end end,
    -- Declared empty on purpose: the console's own set() is the whole act.
    [DEBUG_CONSOLE_PATH] = function() end,
    -- The same for test mode: the session setting's set() is TestMode.Toggle.
    [TEST_MODE_PATH] = function() end,
}

for _, row in ipairs(masterRows) do
    local fn = masterOnChange[row.path]
    if fn then row.onChange = fn end
    -- The composer's tooltip is generic; this addon's says what test mode shows.
    if row.path == TEST_MODE_PATH then row.tooltip = TEST_MODE_TIP end
    if not row.sessionOnly then row.section = "master" end
    -- An unlock in combat is refused at the seam, before it is stored (modules/Preview.lua).
    if row.path == "locked" then
        row.validate = function(v) return not NS.AcceptLock or NS.AcceptLock(v) end
    end
end
NS.RegisterSchemaRows(masterRows)

NS.RegisterSchemaRows({
    {
        path    = "general.provider",
        page    = PAGE,
        group   = PARTY_GROUP,
        order   = 10,
        type    = "string",
        label   = L["Frame system"],
        desc    = L["Which party frames the elements attach to. Automatic uses EllesmereUI's party frames when they are shown and Blizzard's otherwise."],
        default = D.general.provider,
        values  = { auto = L["Automatic"], blizzard = L["Blizzard"], ellesmere = L["EllesmereUI"] },
        sorting = { "auto", "blizzard", "ellesmere" },
    },
    {
        path    = "general.includePlayer",
        page    = PAGE,
        group   = PARTY_GROUP,
        order   = 20,
        type    = "bool",
        label   = L["Include my own row"],
        desc    = L["Show a cast bar, target frame and pet frame for yourself too, wherever your party frames show you (and always in free placement)."],
        default = D.general.includePlayer,
    },
})

-- The Health updates tab: one switch and one pace for both unit-button features, so target and pet
-- frames can never disagree. Pet frames follow the switch only; their health comes from the game's
-- own events, so the pace is the target ticker's.
local HEALTH_GROUP = L["Health updates"]
local function healthOff() return NS.GetSetting("general.updateHealth") ~= true end

NS.RegisterSchemaRows({
    {
        path    = "general.updateHealth",
        page    = PAGE,
        group   = HEALTH_GROUP,
        order   = 10,
        type    = "bool",
        label   = L["Update health"],
        desc    = L["Track health on target and pet frames. Off: their bars stay full with no percent, and no health updates run."],
        default = D.general.updateHealth,
    },
    {
        path       = "general.tickInterval",
        page       = PAGE,
        group      = HEALTH_GROUP,
        order      = 20,
        type       = "number",
        label      = L["Health refresh (seconds)"],
        desc       = L["How often a shown target frame's health updates. Lower is smoother and costs more. Pet frames update on the game's own health events."],
        default    = D.general.tickInterval,
        min        = 0.1,
        max        = 1.0,
        step       = 0.05,
        disabledIf = healthOff,
    },
})

-- The global reset's confirmation (options-ui-§12): the collection's one wording, verbatim.
StaticPopupDialogs["PARTYFRAMEENHANCED_RESET_ALL"] = {
    text         = L["Reset this profile to the addon's defaults? Everything you have configured or added in it is discarded \226\128\148 your other profiles are not affected."],
    button1      = L["Yes"],
    button2      = L["No"],
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
    OnAccept     = function()
        if NS.Helpers and NS.Helpers.RestoreAllDefaults then
            NS.Helpers.RestoreAllDefaults()
            print(L["All settings reset to defaults."])
        else
            print(L["Cannot reset settings \226\128\148 the settings helpers failed to load."])
        end
    end,
}

local function build(mainCategory)
    if not (Settings and Settings.RegisterCanvasLayoutSubcategory) then return nil end

    local ctx = H.CreatePanel("PartyFrameEnhancedGeneralPanel", "General", {
        pageKey         = PAGE,
        defaultsButton  = true,
        defaultsTooltip = L["Restore every General setting on this profile to its addon default."],
    })
    -- Parked: the Defaults button is built on first OnShow (options-ui-§5).
    ctx.panel.defaultsOnClick = function() H.RestoreDefaults(PAGE, ctx) end

    -- Through SetRenderer, which builds the Defaults button, refuses in combat and draws on first
    -- show (and again when a refresh marked the page dirty) — so the body starts from a clear scroll.
    H.SetRenderer(ctx, function(c)
        H.ClearScroll(c)
        H.RenderTabbedSchema(c, PAGE, { [H.MASTER_GROUP] = masterTail })
    end)

    return Settings.RegisterCanvasLayoutSubcategory(mainCategory, ctx.panel, "General")
end

if NS.RegisterOptionsPage then
    NS.RegisterOptionsPage(PAGE, "General", build)
end
