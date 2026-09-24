-- settings/General.lua — the General page (options-ui-§13/§15):
--
--     [ Master controls ][ Party frames ]
--
--     Master controls  [Enable Party Frame Enhanced]  [General visibility]
--                      [Master scale]                 [Master alpha]
--                      [Lock frame]                   [Debug console]
--                      [Minimap button]                                      <- stored in db.global
--                      [Reset position]               [Reset all settings]   <- afterGroup pair
--     Party frames     [Frame system]                 [Include my own row]
--                      [Fade with party frames]
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
-- Its get/set are stamped onto the composed row below, so the seam reads and writes the window.
local DEBUG_CONSOLE_PATH = "state.debugConsole"

-- THE MINIMAP BUTTON'S ONE ROW (launcher-§3). The path is the composer's verbatim and unprefixed,
-- because LibDBIcon's own table lives in the GLOBAL store, outside the block's profile prefix. It
-- reads in the row's own sense, `global.minimap.shown` (settings/Schema.lua), and is a CLI name
-- only: nothing is ever stored under `shown`.
--
-- THE INVERSION IS THE ADDON'S, NOT THE LIBRARY'S, and it happens exactly once -- here, on the one
-- write seam every other row goes through (options-ui-§1, architecture-§5). The row's boolean says
-- SHOWN; LibDBIcon's `hide` says hidden. Storing the library's own key is what keeps ONE record of
-- one state: LibDBIcon writes `hide` itself when the player uses the button's right-click menu, and
-- a `show` key beside it would be a second copy free to disagree (anti-pattern #81).
--
-- THE ROW SURVIVES BOTH RESETS (launcher-§3): *Reset all settings* and the page-scoped *Defaults*
-- button. It is not stated here -- settings/Schema.lua's `resetExempt` and NS.IsGlobalSetting are
-- the one place -- but it is why the `default = true` the composer puts on this row never lands on
-- a player who hid the button on purpose.
--
-- The set calls the launcher's SetShown after storing, so the button follows the checkbox
-- immediately rather than at the next reload. SetShown writes `hide` a second time with the same
-- value, which the library documents and intends: a writer that is not this seam (a future verb, a
-- migration) gets the store updated without having to remember the inversion again.
local MINIMAP_PATH = NS.MINIMAP_PATH

-- Where the two composed rows whose value is NOT in the profile keep it: stamped onto the rows by
-- path as their own get/set, which LibKa0s-Schema-1.0's Get and Set honor ahead of the profile.
-- The console is the window's own visibility; the minimap button is LibDBIcon's `hide`, inverted.
local ownStorage = {
    [MINIMAP_PATH] = {
        get = function()
            local m = NS.db and NS.db.global and NS.db.global.minimap
            return not (m and m.hide)
        end,
        set = function(shown)
            local m = NS.db and NS.db.global and NS.db.global.minimap
            if m then m.hide = not shown end
            if NS.Launcher then NS.Launcher:SetShown(shown and true or false) end
        end,
    },
}
-- Both arms of core/DebugLogSetup.lua answer ConsoleCheckbox, so a library-less build still gets
-- an honest binding (its composer is hollow, so there is no row to stamp it on there anyway).
if NS.DebugLog and NS.DebugLog.ConsoleCheckbox then
    local console = NS.DebugLog:ConsoleCheckbox()
    ownStorage[DEBUG_CONSOLE_PATH] = { get = console.get, set = console.set }
end

local masterRows, masterTail = H.MasterControls({
    prefix           = "",
    page             = PAGE,
    addonName        = "Party Frame Enhanced",
    frameless        = false,
    debugConsolePath = DEBUG_CONSOLE_PATH,
    minimapPath      = MINIMAP_PATH,
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
    -- THE ONE WRITE SEAM'S ONE EFFECT (slash-commands-§7). The checkbox, `/pfe enable`,
    -- `/pfe disable` and `/pfe set enabled …` all arrive here, and all they do is take or release
    -- the `disabled` hold on the addon's single latch. The stand-down and the stand-up publish
    -- VISIBILITY themselves, so there is nothing else for this row to do — and nothing here holds a
    -- second copy of the state the checkbox and the verbs would then be free to disagree about.
    enabled    = function(v) NS.ApplyEnabled(v) end,
    visibility = function() NS.PublishVisibility() end,
    -- Unlocking IS preview mode (preview-mode), and the only switch for it: options-ui-§15 exempts
    -- this addon from a Test mode row because unlocking already raises the stand-in and paints the
    -- placeholders. modules/Preview.lua owns what that means.
    locked     = function(v) if NS.OnLockChanged then NS.OnLockChanged(v) end end,
    -- Declared empty on purpose: the console's own set() is the whole act.
    [DEBUG_CONSOLE_PATH] = function() end,
    -- Likewise: the stamped set() stores `hide` and moves the button, and nothing this addon
    -- draws reads the minimap table.
    [MINIMAP_PATH] = function() end,
}

for _, row in ipairs(masterRows) do
    local fn = masterOnChange[row.path]
    if fn then row.onChange = fn end
    local own = ownStorage[row.path]
    if own then row.get, row.set = own.get, own.set end
    if not row.sessionOnly then row.section = "master" end
    -- An unlock is refused at the seam, before it is stored — in combat, with the addon disabled,
    -- or during a perf-run suspend (modules/Preview.lua). Those three refusals came off the removed
    -- Test mode row, which would not start under any of them.
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
    {
        path    = "general.rangeFade",
        page    = PAGE,
        group   = PARTY_GROUP,
        order   = 30,
        type    = "bool",
        label   = L["Fade with party frames"],
        desc    = L["Fade each party member's cast bar, target frame and pet frame along with their party frame when they are out of range. Blizzard's classic party frames don't fade, so there they fade to half opacity past about 40 yards."],
        default = D.general.rangeFade,
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
