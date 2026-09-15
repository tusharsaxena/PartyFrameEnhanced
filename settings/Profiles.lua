-- settings/Profiles.lua — the Profiles sub-page: AceDBOptions' table rendered by AceConfigDialog
-- into an AceGUI group inside our canvas (options-ui-§3, the one sanctioned use of AceConfig). No
-- Defaults button: profile management carries its own destructive controls. Skipped silently when
-- AceDBOptions / AceConfigDialog is absent.

local _, NS = ...

local APPNAME = "PartyFrameEnhanced-Profiles"

local function build(mainCategory)
    if not (Settings and Settings.RegisterCanvasLayoutSubcategory) then return nil end
    if not LibStub then return nil end

    local AceDBOptions    = LibStub("AceDBOptions-3.0",    true)
    local AceConfig       = LibStub("AceConfig-3.0",       true)
    local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
    local AceGUI          = LibStub("AceGUI-3.0",          true)
    if not (AceDBOptions and AceConfig and AceConfigDialog and AceGUI) then return nil end
    if not (NS.db and NS.db.profile) then return nil end

    local H = NS.Helpers
    if not (H and H.CreatePanel) then return nil end

    AceConfig:RegisterOptionsTable(APPNAME, AceDBOptions:GetOptionsTable(NS.db))

    local ctx = H.CreatePanel("PartyFrameEnhancedProfilesPanel", "Profiles", {
        pageKey        = "profiles",
        defaultsButton = false,
    })

    -- Built on first show, never in the builder (options-ui-§5). Re-opened on every render so a
    -- profile switch — which marks this page dirty — redraws AceConfigDialog's tree.
    local container
    H.SetRenderer(ctx, function()
        if not container then
            container = AceGUI:Create("SimpleGroup")
            container:SetLayout("Fill")
            container.frame:SetParent(ctx.body)
            container.frame:ClearAllPoints()
            container.frame:SetPoint("TOPLEFT",     ctx.body, "TOPLEFT",      8, -8)
            container.frame:SetPoint("BOTTOMRIGHT", ctx.body, "BOTTOMRIGHT", -8, 8)
        end
        -- Shown explicitly: a pooled AceGUI frame comes back hidden, and AceConfigDialog would fill
        -- a hidden frame — a blank page under the header.
        container.frame:Show()
        AceConfigDialog:Open(APPNAME, container)
    end)

    return Settings.RegisterCanvasLayoutSubcategory(mainCategory, ctx.panel, "Profiles")
end

if NS.RegisterOptionsPage then
    NS.RegisterOptionsPage("profiles", "Profiles", build)
end
