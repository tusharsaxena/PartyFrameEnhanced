-- tests/test_class_color_preview.lua — "Use class color" in the preview and after a roster change
-- (FB-PFE-01, finding P of Ka0sAddonsCommonTasks docs/2026-11-24-FEEDBACK_BATCH).
--
-- The owner, out of a party with preview on, ticked Cast Bars > Bar > Fill > "Use class color for
-- fill" and saw the normal cast color, and the Text tab's class color drew the white font color.
-- The ladder (Element.Drawn) was right; the class never resolved, because the preview draws on
-- party1, which does not exist. A preview resolves the stand-in, the player (options-ui-§17,
-- standard v2.119.0: "A preview shows a class"; LibKa0s Core minor 20's standIn). The text colors
-- were also painted only on a config change, so a member joining or swapping kept the previous
-- occupant's class.

local T = _G.PFE_TEST
local test, assertEqual = T.test, T.assertEqual
local NS, mocks = T.NS, T.mocks
local bars = NS.CastBars.__bars
local Core = mocks.LibStub("LibKa0s-Core-1.0")

local function rgb(c) return ("%s,%s,%s"):format(c.r, c.g, c.b) end
local function rgb3(r, g, b) return ("%s,%s,%s"):format(r, g, b) end

--- Run `fn` in a world where the player is a warrior, `party` says which party units exist (and
--- their class), and an absent unit answers no class, as the client does. Everything is put back.
local function world(party, fn)
  local realClass, realExists = mocks.UnitClass, mocks.UnitExists
  local savedUnits = {}
  for _, u in ipairs(NS.Units.LIST) do savedUnits[u] = mocks.__units[u] end
  mocks.UnitExists = function(u)
    if u == "player" then return true end
    if u:find("^party%d$") then return party[u] ~= nil end
    return realExists(u)
  end
  mocks.UnitClass = function(u)
    if u == nil or u == "player" then return "Warrior", "WARRIOR" end
    if u:find("^party%d$") then
      local tok = party[u]
      if tok then return tok, tok end
      return nil
    end
    return realClass(u)
  end
  Core.__ResetClassColor()
  local ok, err = pcall(fn)
  mocks.UnitClass, mocks.UnitExists = realClass, realExists
  for _, u in ipairs(NS.Units.LIST) do mocks.__units[u] = savedUnits[u] end
  Core.__ResetClassColor()
  NS.State.preview = false
  NS.PublishVisibility()
  if not ok then error(err, 0) end
end

--- Record the last color each of `el`'s two text lines took (the stub region keeps none); the
--- record's `stop` puts the stub's setter back.
local function textSpy(el)
  local rec = {}
  el.text.SetTextColor = function(_, r, g, b) rec.text = rgb3(r, g, b) end
  el.text2.SetTextColor = function(_, r, g, b) rec.text2 = rgb3(r, g, b) end
  rec.stop = function() el.text.SetTextColor, el.text2.SetTextColor = nil, nil end
  return rec
end

local function prep()
  local cfg = NS.db.profile.castbar
  cfg.anchorMode, cfg.fadeOut = "free", false
end

local function set(path, v) NS.SetByPath("castbar." .. path, v) end
local function restore(...)
  for _, k in ipairs({ ... }) do set(k, NS.defaults.profile.castbar[k]) end
end

local WARRIOR = mocks.RAID_CLASS_COLORS.WARRIOR

for _, fromSkin in ipairs({ false, true }) do
  test("class preview: out of a party the cast bar fill draws the player's class, skin companion "
      .. tostring(fromSkin), function()
    -- red under: Element.UnitResolver resolving party1 with no stand-in (the orange cast color, or
    -- the skin's with the companion on)
    world({}, function()
      prep()
      set("useClassColorBar", true)
      set("barColorFromSkin", fromSkin)
      NS.State.preview = true
      NS.PublishVisibility()
      local c = bars.party1.bar.__color
      assertEqual(rgb3(c[1], c[2], c[3]), rgb(WARRIOR), "the preview's fill")
    end)
    restore("useClassColorBar", "barColorFromSkin")
  end)

  test("class preview: out of a party the cast bar text draws the player's class, skin companion "
      .. tostring(fromSkin), function()
    -- red under: Element.ApplyColors run only from reskinAll, and resolving party1 with no stand-in
    world({}, function()
      prep()
      set("useClassColorFont", true)
      set("fontColorFromSkin", fromSkin)
      local rec = textSpy(bars.party1)
      NS.State.preview = true
      NS.PublishVisibility()
      rec.stop()
      assertEqual(rec.text, rgb(WARRIOR), "the spell name")
      assertEqual(rec.text2, rgb(WARRIOR), "the time")
    end)
    restore("useClassColorFont", "fontColorFromSkin")
  end)
end

test("class preview: out of preview, an absent unit has no stand-in", function()
  world({}, function()
    prep()
    local rec = textSpy(bars.party1)
    set("useClassColorFont", true)
    set("fontColorFromSkin", false)
    rec.stop()
    assertEqual(rec.text, rgb(NS.db.profile.castbar.fontColor), "the stored swatch")
  end)
  restore("useClassColorFont", "fontColorFromSkin")
end)

test("class preview: a real party member wins over the stand-in", function()
  world({ party1 = "PRIEST" }, function()
    prep()
    local rec = textSpy(bars.party1)
    set("useClassColorFont", true)
    set("fontColorFromSkin", false)
    NS.State.preview = true
    NS.PublishVisibility()
    rec.stop()
    assertEqual(rec.text, rgb(mocks.RAID_CLASS_COLORS.PRIEST))
  end)
  restore("useClassColorFont", "fontColorFromSkin")
end)

test("class preview: a roster change repaints the cast bar text in the new member's class", function()
  -- red under: the cast bars' text colors painted only on CONFIG/PROFILE/skin
  local party = { party1 = "PRIEST" }
  world(party, function()
    prep()
    local rec = textSpy(bars.party1)
    set("useClassColorFont", true)
    set("fontColorFromSkin", false)
    local before = rec.text
    party.party1 = "MAGE"
    mocks.__fireEvent("GROUP_ROSTER_UPDATE")
    rec.stop()
    assertEqual(before, rgb(mocks.RAID_CLASS_COLORS.PRIEST), "before")
    assertEqual(rec.text, rgb(mocks.RAID_CLASS_COLORS.MAGE), "after the swap")
  end)
  restore("useClassColorFont", "fontColorFromSkin")
end)

test("class preview: the target frames' preview draws the player's class with reaction off", function()
  -- red under: previewColors' Element.ClassResolver(nil), which can never show a class
  local buttons = NS.TargetFrames.__buttons
  world({}, function()
    local tc = NS.db.profile.target
    tc.anchorMode, tc.enabled = "free", true
    NS.SetByPath("target.colorReaction", false)
    NS.SetByPath("target.useClassColorBar", true)
    NS.State.preview = true
    NS.PublishVisibility()
    local c = buttons.party1.bar.__color
    assertEqual(rgb3(c[1], c[2], c[3]), rgb(WARRIOR), "class fill")
    NS.SetByPath("target.colorReaction", true)
    c = buttons.party1.bar.__color
    assertEqual(rgb3(c[1], c[2], c[3]), rgb(tc.hostileColor), "reaction still first: the preview is hostile")
  end)
  NS.SetByPath("target.useClassColorBar", NS.defaults.profile.target.useClassColorBar)
  NS.SetByPath("target.colorReaction", NS.defaults.profile.target.colorReaction)
end)

test("class preview: the pet frames' preview draws the player's class", function()
  local buttons = NS.PetFrames.__buttons
  world({}, function()
    local pc = NS.db.profile.pet
    pc.anchorMode, pc.enabled = "free", true
    NS.SetByPath("pet.useClassColorBar", true)
    NS.State.preview = true
    NS.PublishVisibility()
    local c = buttons.party1.bar.__color
    assertEqual(rgb3(c[1], c[2], c[3]), rgb(WARRIOR), "the owner stand-in's class")
  end)
  NS.SetByPath("pet.useClassColorBar", NS.defaults.profile.pet.useClassColorBar)
end)
