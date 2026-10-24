-- tests/test_layers.lua — frame layering (frame-layering-§3, §5): the one layers table in
-- core/Constants.lua, the element ladder every cast bar, target frame and pet frame is built on
-- (modules/Element.lua), read back through the kit's frame-layer recorder, and the strata row's
-- tooltip. The fade frames' and holders' stacking is pinned in tests/test_rangefade.lua, the
-- stand-in's in tests/test_standin.lua.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local NS, mocks = T.NS, T.mocks
local LAYERS = NS.Constants.LAYERS

-- Every frame built inside `fn` records its layers through the kit's recorder. The addon's own mock
-- stamps a creation-time level on each frame (tests/wow_mock.lua); that stamp is dropped here, so a
-- level the code did not set is the client's parent + 1, read live through the parent chain.
-- Regions record the frame that made them.
local function withLayers(fn)
  local restore = dofile("tests/_kit/mock_layers.lua")(mocks)
  local recorded = mocks.CreateFrame
  mocks.CreateFrame = function(...)
    local f = recorded(...)
    rawset(f, "__level", nil)
    if rawget(f, "EnableMouse") == nil then
      rawset(f, "EnableMouse", function(self, on) rawset(self, "__mouse", on) end)
    end
    for _, method in ipairs({ "CreateTexture", "CreateFontString" }) do
      local make = rawget(f, method)
      rawset(f, method, function(self, ...)
        local r = make(self, ...)
        rawset(r, "__owner", self)
        return r
      end)
    end
    return f
  end
  local ok, err = pcall(fn)
  mocks.CreateFrame = recorded
  restore()
  if not ok then error(err, 0) end
end

local function element()
  local host = mocks.CreateFrame("Frame")
  host:SetFrameStrata("LOW")
  host:SetFrameLevel(20)
  local root = mocks.CreateFrame("Frame", nil, host)
  return NS.Element.Build(root, { icon = true, spark = true, shield = true, marker = true }), host
end

test("layers: one table names every strata and level the addon writes", function()
  assertEqual(type(LAYERS), "table")
  assertEqual(LAYERS.STRATA.HOST_FALLBACK, "LOW", "where Blizzard's own unit frames live")
  for key, strata in pairs(LAYERS.PLAYER_STRATA) do
    assertTrue(LAYERS.STRATA_RANK[strata] ~= nil, key .. " is a client strata")
  end
  local L = LAYERS.LEVEL
  assertTrue(L.FILL < L.BORDER and L.BORDER < L.OVERLAY, "the element ladder's order")
  assertEqual(L.BACKPLATE, 0, "a holder at its stack's root level, under every element")
end)

test("layers: the element ladder is root < fill < border < overlay, all inherited", function()
  -- red under: text, spark and shield as regions of the bar, under the border frame (a child of the
  -- bar), and the marker on a layer of its own levelled once, at build, against a border that moves.
  withLayers(function()
    local el, host = element()
    local base = el:GetFrameLevel()
    assertEqual(base, host:GetFrameLevel() + 1, "the root over its fade frame")
    assertEqual(el.bar:GetFrameLevel(), base + LAYERS.LEVEL.FILL, "the status bar")
    assertEqual(el.border:GetFrameLevel(), base + LAYERS.LEVEL.BORDER, "the border frame")
    assertTrue(el.overlay ~= nil, "one overlay frame per element")
    assertEqual(el.overlay:GetFrameLevel(), base + LAYERS.LEVEL.OVERLAY, "the overlay frame")
    assertTrue(el.overlay:GetParent() == el.border, "the overlay rides the border by inheritance")
    for _, k in ipairs({ "bar", "border", "overlay" }) do
      assertEqual(rawget(el[k], "__level"), nil, k .. " sets no level of its own")
      assertEqual(el[k]:GetFrameStrata(), "LOW", k .. " inherits the host's strata")
    end
    for _, k in ipairs({ "text", "text2", "spark", "shield", "marker" }) do
      assertTrue(el[k].__owner == el.overlay, k .. " is drawn on the overlay, above the border")
    end
    assertTrue(el.bg.__owner == el and el.icon.__owner == el, "background and icon stay root regions")
    assertEqual(el.markerLayer, nil, "the one-off marker layer is gone")
    -- Moving the stacking root carries the whole ladder: nothing below it was levelled by hand.
    host:SetFrameLevel(40)
    assertEqual(el.overlay:GetFrameLevel(), 41 + LAYERS.LEVEL.OVERLAY, "re-stacked with its root")
  end)
end)

test("layers: the overlay takes no mouse, so a click-to-target button keeps its click", function()
  withLayers(function()
    local el = element()
    assertTrue(rawget(el.overlay, "__mouse") == false, "explicitly mouse-off (frame-layering-§3)")
  end)
end)

test("layers: Show border off clears the border's backdrop and keeps it shown", function()
  -- red under: the border hidden while off, which would hide the overlay riding it.
  withLayers(function()
    local el = element()
    local cleared, hidden = 0, 0
    rawset(el.border, "ClearBackdrop", function() cleared = cleared + 1 end)
    rawset(el.border, "Hide", function() hidden = hidden + 1 end)
    local cfg = {}
    for k, v in pairs(NS.defaults.profile.target) do cfg[k] = v end
    cfg.borderShow = false
    NS.Element.Reskin(el, cfg, nil, true)
    assertEqual(cleared, 1, "the edge is cleared")
    assertEqual(hidden, 0, "the border frame is never hidden")
    cfg.borderShow = true
    NS.Element.Reskin(el, cfg, nil, true)
    assertEqual(cleared, 1, "on again: a backdrop, not a clear")
  end)
end)

test("layers: the Frame strata row's tooltip is the library's strata tooltip", function()
  local row
  for _, r in ipairs(NS.SchemaForPage("general")) do
    if r.path == "general.strata" then row = r end
  end
  assertTrue(row ~= nil, "the row exists")
  local tip = NS.Helpers.StrataTooltip({ "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG" })
  assertTrue(type(tip) == "string" and tip ~= "", "the library answers")
  assertTrue(row.desc:find(tip, 1, true) ~= nil, "the row carries it whole")
  assertTrue(tip:find("Dialog and above", 1, true) ~= nil, "Dialog is offered, so it says what Dialog covers")
  assertEqual(row.default, "auto", "the setting itself is unchanged")
  assertEqual(#row.sorting, 6, "and so is its value set")
end)
