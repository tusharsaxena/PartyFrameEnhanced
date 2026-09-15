local _, NS = ...

-- core/Units.lua — the five tracked units and the tokens derived from them.
--
-- Every element is bound to a UNIT, never to a party-frame slot (spec §6.4): `party2target` is
-- party2's target whichever frame happens to show party2, so a unit-bound element always shows the
-- right member's data even when a frame system re-sorts in combat.
NS.Units = NS.Units or {}
local U = NS.Units

U.LIST = { "player", "party1", "party2", "party3", "party4" }

U.INDEX = { player = 1, party1 = 2, party2 = 3, party3 = 4, party4 = 5 }

-- What each unit is targeting.
U.TARGET = {
    player = "target",
    party1 = "party1target", party2 = "party2target",
    party3 = "party3target", party4 = "party4target",
}

-- Each unit's pet.
U.PET = {
    player = "pet",
    party1 = "partypet1", party2 = "partypet2",
    party3 = "partypet3", party4 = "partypet4",
}

U.LABEL = {
    player = "Player",
    party1 = "Party 1", party2 = "Party 2", party3 = "Party 3", party4 = "Party 4",
}

--- Whether `unit`'s row is wanted at all. The player's row follows the General page's "Include my
--- own row"; the four party slots always are. Whether a frame system SHOWS the player is a separate
--- question the anchor engine answers (an attached element with no frame is simply not placed).
function U.IsIncluded(unit)
    if unit == "player" then
        return NS.GetSetting("general.includePlayer") == true
    end
    return U.INDEX[unit] ~= nil
end
