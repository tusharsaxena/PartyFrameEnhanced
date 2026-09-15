-- settings/About.lua — the landing page's body (options-ui-§5): logo, the TOC's Notes line, a
-- "Slash Commands" heading and one row per NS.COMMANDS entry, generated so it cannot drift from
-- `/pfe help`. The renderer is the library's (BuildLandingPage); this file only says what goes on it.

local _, NS = ...

local Helpers = NS.Helpers

-- Functions, because both are resolved at render time: the Notes field is not readable at load, and
-- NS.COMMANDS is complete only once every file has loaded.
local SPEC = {
    logo  = NS.Constants.LOGO_PATH,
    notes = function() return NS.Meta("Notes") or "" end,
    sections = {
        {
            heading = NS.L["Slash Commands"],
            rows    = function() return NS.Slash:LandingRows() end,
        },
    },
}

function Helpers.BuildMainContent(ctx)
    Helpers.BuildLandingPage(ctx, SPEC)
end
