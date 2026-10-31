-- tests/test_settings_layout.lua — the settings layout (item 020, 2026-10-24): where every row is
-- drawn, under which tab and heading, in which order, with which words. And the guard that a layout
-- change stays a layout change: every stored path, its page, type, default, range, values, and
-- whether it has an onChange, a dim or a shownWhen, pinned as it was before the layout moved.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local NS = T.NS

-- ── the guard: the SET of settings, and everything stored or behavioral about each ──────────

local function ser(v)
  if type(v) == "table" then
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for _, k in ipairs(keys) do parts[#parts + 1] = tostring(k) .. "=" .. ser(v[k]) end
    return "{" .. table.concat(parts, ",") .. "}"
  elseif type(v) == "function" then return "fn"
  else return tostring(v) end
end

local function valueKeys(values)
  if type(values) ~= "table" then return ser(values) end
  local keys = {}
  for k in pairs(values) do keys[#keys + 1] = tostring(k) end
  table.sort(keys)
  return table.concat(keys, ",")
end

-- What a layout change must leave alone. Labels, tooltips, group, subgroup and order are absent on
-- purpose: those are exactly what a layout change moves.
local function signature(row)
  return table.concat({ tostring(row.page), tostring(row.type), ser(row.default), ser(row.min),
    ser(row.max), ser(row.step), valueKeys(row.values), tostring(row.sessionOnly == true),
    "onChange=" .. tostring(row.onChange ~= nil), "dim=" .. tostring(row.disabledIf ~= nil),
    "shown=" .. ser(row.shownWhen) }, "|")
end

-- Pinned from the schema at the commit before item 020's first edit (93e4eb3). Regenerate only for
-- a change that is MEANT to add, remove or redefine a setting, never for a layout move.
local PINNED = {
  ["alpha"] = "general|number|1|0|1|0.05|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.anchorMode"] = "castbar|string|attached|nil|nil|nil|attached,free|false|onChange=false|dim=false|shown=nil",
  ["castbar.barAlpha"] = "castbar|number|1|0|1|0.05|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.barColor"] = "castbar|color|{a=1,b=0,g=0.7,r=1}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.barTexture"] = "castbar|string|Blizzard|nil|nil|nil|fn|false|onChange=false|dim=true|shown=nil",
  ["castbar.barTextureFromSkin"] = "castbar|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.bgColor"] = "castbar|color|{a=0.6,b=0,g=0,r=0}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.borderColor"] = "castbar|color|{a=1,b=0,g=0,r=0}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.borderShow"] = "castbar|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.borderSize"] = "castbar|number|8|0|16|1|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.borderStyle"] = "castbar|string|Blizzard Tooltip|nil|nil|nil|fn|false|onChange=false|dim=true|shown=nil",
  ["castbar.borderStyleFromSkin"] = "castbar|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.channelColor"] = "castbar|color|{a=1,b=1,g=0.7,r=0.3}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.empowerColor"] = "castbar|color|{a=1,b=1,g=0.5,r=0.8}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.enabled"] = "castbar|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.fadeOut"] = "castbar|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.failedColor"] = "castbar|color|{a=1,b=0.2,g=0.2,r=0.9}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.font"] = "castbar|string|Friz Quadrata TT|nil|nil|nil|fn|false|onChange=false|dim=true|shown=nil",
  ["castbar.fontFromSkin"] = "castbar|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.fontColor"] = "castbar|color|{a=1,b=1,g=1,r=1}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.fontFlags"] = "castbar|string|@skin|nil|nil|nil|,@skin,MONOCHROME,OUTLINE,OUTLINE, MONOCHROME,THICKOUTLINE|false|onChange=false|dim=false|shown=nil",
  ["castbar.fontShadow"] = "castbar|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.fontSize"] = "castbar|number|11|6|32|1|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.growth"] = "castbar|string|DOWN|nil|nil|nil|DOWN,LEFT,RIGHT,UP|false|onChange=false|dim=false|shown={equals=free,path=castbar.anchorMode}",
  ["castbar.height"] = "castbar|number|16|8|60|1|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.iconSide"] = "castbar|string|LEFT|nil|nil|nil|LEFT,RIGHT|false|onChange=false|dim=false|shown=nil",
  ["castbar.matchWidth"] = "castbar|bool|true|nil|nil|nil|nil|false|onChange=false|dim=true|shown=nil",
  ["castbar.offsetX"] = "castbar|number|0|-200|200|1|nil|false|onChange=false|dim=false|shown={equals=attached,path=castbar.anchorMode}",
  ["castbar.offsetY"] = "castbar|number|0|-200|200|1|nil|false|onChange=false|dim=false|shown={equals=attached,path=castbar.anchorMode}",
  ["castbar.point"] = "castbar|string|TOP|nil|nil|nil|BOTTOM,BOTTOMLEFT,BOTTOMRIGHT,CENTER,LEFT,RIGHT,TOP,TOPLEFT,TOPRIGHT|false|onChange=false|dim=false|shown={equals=attached,path=castbar.anchorMode}",
  ["castbar.relativePoint"] = "castbar|string|TOP|nil|nil|nil|BOTTOM,BOTTOMLEFT,BOTTOMRIGHT,CENTER,LEFT,RIGHT,TOP,TOPLEFT,TOPRIGHT|false|onChange=false|dim=false|shown={equals=attached,path=castbar.anchorMode}",
  ["castbar.showIcon"] = "castbar|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.showName"] = "castbar|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.showShield"] = "castbar|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.showSpark"] = "castbar|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.showTime"] = "castbar|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.spacing"] = "castbar|number|4|0|40|1|nil|false|onChange=false|dim=false|shown={equals=free,path=castbar.anchorMode}",
  ["castbar.uninterruptibleColor"] = "castbar|color|{a=1,b=0.6,g=0.6,r=0.6}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.useClassColorBar"] = "castbar|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.useClassColorBg"] = "castbar|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.useClassColorBorder"] = "castbar|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.useClassColorFont"] = "castbar|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["castbar.width"] = "castbar|number|140|40|400|1|nil|false|onChange=false|dim=true|shown=nil",
  ["enabled"] = "general|bool|true|nil|nil|nil|nil|false|onChange=true|dim=false|shown=nil",
  ["general.includePlayer"] = "general|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["general.provider"] = "general|string|auto|nil|nil|nil|auto,blizzard,ellesmere|false|onChange=false|dim=false|shown=nil",
  ["general.rangeFade"] = "general|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["general.strata"] = "general|string|auto|nil|nil|nil|auto,background,dialog,high,low,medium|false|onChange=false|dim=false|shown=nil",
  ["general.tickInterval"] = "general|number|0.2|0.1|1|0.05|nil|false|onChange=false|dim=true|shown=nil",
  ["general.updateHealth"] = "general|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["global.minimap.shown"] = "general|bool|true|nil|nil|nil|nil|false|onChange=true|dim=false|shown=nil",
  ["locked"] = "general|bool|true|nil|nil|nil|nil|false|onChange=true|dim=false|shown=nil",
  ["pet.anchorMode"] = "pet|string|attached|nil|nil|nil|attached,free|false|onChange=false|dim=false|shown=nil",
  ["pet.barAlpha"] = "pet|number|1|0|1|0.05|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.barColor"] = "pet|color|{a=1,b=0.35,g=0.7,r=0.35}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.barTexture"] = "pet|string|Blizzard|nil|nil|nil|fn|false|onChange=false|dim=true|shown=nil",
  ["pet.barTextureFromSkin"] = "pet|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.bgColor"] = "pet|color|{a=0.6,b=0,g=0,r=0}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.borderColor"] = "pet|color|{a=1,b=0,g=0,r=0}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.borderShow"] = "pet|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.borderSize"] = "pet|number|8|0|16|1|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.borderStyle"] = "pet|string|Blizzard Tooltip|nil|nil|nil|fn|false|onChange=false|dim=true|shown=nil",
  ["pet.borderStyleFromSkin"] = "pet|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.clickToTarget"] = "pet|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.enabled"] = "pet|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.font"] = "pet|string|Friz Quadrata TT|nil|nil|nil|fn|false|onChange=false|dim=true|shown=nil",
  ["pet.fontFromSkin"] = "pet|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.fontColor"] = "pet|color|{a=1,b=1,g=1,r=1}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.fontFlags"] = "pet|string|@skin|nil|nil|nil|,@skin,MONOCHROME,OUTLINE,OUTLINE, MONOCHROME,THICKOUTLINE|false|onChange=false|dim=false|shown=nil",
  ["pet.fontShadow"] = "pet|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.fontSize"] = "pet|number|9|6|32|1|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.growth"] = "pet|string|DOWN|nil|nil|nil|DOWN,LEFT,RIGHT,UP|false|onChange=false|dim=false|shown={equals=free,path=pet.anchorMode}",
  ["pet.height"] = "pet|number|14|8|60|1|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.markerOffsetX"] = "pet|number|0|-100|100|1|nil|false|onChange=false|dim=true|shown=nil",
  ["pet.markerOffsetY"] = "pet|number|0|-100|100|1|nil|false|onChange=false|dim=true|shown=nil",
  ["pet.markerPoint"] = "pet|string|TOP|nil|nil|nil|BOTTOM,BOTTOMLEFT,BOTTOMRIGHT,CENTER,LEFT,RIGHT,TOP,TOPLEFT,TOPRIGHT|false|onChange=false|dim=true|shown=nil",
  ["pet.matchWidth"] = "pet|bool|false|nil|nil|nil|nil|false|onChange=false|dim=true|shown=nil",
  ["pet.offsetX"] = "pet|number|4|-200|200|1|nil|false|onChange=false|dim=false|shown={equals=attached,path=pet.anchorMode}",
  ["pet.offsetY"] = "pet|number|-20|-200|200|1|nil|false|onChange=false|dim=false|shown={equals=attached,path=pet.anchorMode}",
  ["pet.point"] = "pet|string|TOPLEFT|nil|nil|nil|BOTTOM,BOTTOMLEFT,BOTTOMRIGHT,CENTER,LEFT,RIGHT,TOP,TOPLEFT,TOPRIGHT|false|onChange=false|dim=false|shown={equals=attached,path=pet.anchorMode}",
  ["pet.relativePoint"] = "pet|string|TOPRIGHT|nil|nil|nil|BOTTOM,BOTTOMLEFT,BOTTOMRIGHT,CENTER,LEFT,RIGHT,TOP,TOPLEFT,TOPRIGHT|false|onChange=false|dim=false|shown={equals=attached,path=pet.anchorMode}",
  ["pet.showMarker"] = "pet|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.showName"] = "pet|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.showPercent"] = "pet|bool|false|nil|nil|nil|nil|false|onChange=false|dim=true|shown=nil",
  ["pet.spacing"] = "pet|number|4|0|40|1|nil|false|onChange=false|dim=false|shown={equals=free,path=pet.anchorMode}",
  ["pet.useClassColorBar"] = "pet|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.useClassColorBg"] = "pet|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.useClassColorBorder"] = "pet|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.useClassColorFont"] = "pet|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["pet.width"] = "pet|number|80|40|400|1|nil|false|onChange=false|dim=true|shown=nil",
  ["scale"] = "general|number|1|0.5|2|0.05|nil|false|onChange=false|dim=false|shown=nil",
  ["skin.font"] = "general|string||nil|nil|nil|nil|false|onChange=true|dim=false|shown=nil",
  ["skin.ignoreFonts"] = "general|bool|false|nil|nil|nil|nil|false|onChange=true|dim=false|shown=nil",
  ["skin.ignorePanel"] = "general|bool|true|nil|nil|nil|nil|false|onChange=true|dim=false|shown=nil",
  ["skin.outline"] = "general|string|hud|nil|nil|nil|all,hud,off|false|onChange=true|dim=false|shown=nil",
  ["skin.pickerSeen"] = "general|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["skin.skin"] = "general|string|ka0s|nil|nil|nil|azeroth,contrast,ember,forever,glass,ka0s,midnight,obsidian,wow|false|onChange=true|dim=false|shown=nil",
  ["skin.source"] = "general|string|ka0s|nil|nil|nil|eui,ka0s|false|onChange=true|dim=false|shown=nil",
  ["skin.texture"] = "general|string||nil|nil|nil|nil|false|onChange=true|dim=false|shown=nil",
  ["state.debugConsole"] = "general|bool|nil|nil|nil|nil|nil|true|onChange=true|dim=false|shown=nil",
  ["target.anchorMode"] = "target|string|attached|nil|nil|nil|attached,free|false|onChange=false|dim=false|shown=nil",
  ["target.barAlpha"] = "target|number|1|0|1|0.05|nil|false|onChange=false|dim=false|shown=nil",
  ["target.barColor"] = "target|color|{a=1,b=0.25,g=0.75,r=0.25}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.barTexture"] = "target|string|Blizzard|nil|nil|nil|fn|false|onChange=false|dim=true|shown=nil",
  ["target.barTextureFromSkin"] = "target|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.bgColor"] = "target|color|{a=0.6,b=0,g=0,r=0}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.borderColor"] = "target|color|{a=1,b=0,g=0,r=0}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.borderShow"] = "target|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.borderSize"] = "target|number|8|0|16|1|nil|false|onChange=false|dim=false|shown=nil",
  ["target.borderStyle"] = "target|string|Blizzard Tooltip|nil|nil|nil|fn|false|onChange=false|dim=true|shown=nil",
  ["target.borderStyleFromSkin"] = "target|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.clickToTarget"] = "target|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.colorReaction"] = "target|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.enabled"] = "target|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.font"] = "target|string|Friz Quadrata TT|nil|nil|nil|fn|false|onChange=false|dim=true|shown=nil",
  ["target.fontFromSkin"] = "target|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.fontColor"] = "target|color|{a=1,b=1,g=1,r=1}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.fontFlags"] = "target|string|@skin|nil|nil|nil|,@skin,MONOCHROME,OUTLINE,OUTLINE, MONOCHROME,THICKOUTLINE|false|onChange=false|dim=false|shown=nil",
  ["target.fontShadow"] = "target|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.fontSize"] = "target|number|10|6|32|1|nil|false|onChange=false|dim=false|shown=nil",
  ["target.friendlyColor"] = "target|color|{a=1,b=0.25,g=0.75,r=0.25}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.growth"] = "target|string|DOWN|nil|nil|nil|DOWN,LEFT,RIGHT,UP|false|onChange=false|dim=false|shown={equals=free,path=target.anchorMode}",
  ["target.height"] = "target|number|20|8|60|1|nil|false|onChange=false|dim=false|shown=nil",
  ["target.hostileColor"] = "target|color|{a=1,b=0.2,g=0.2,r=0.85}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.markerOffsetX"] = "target|number|0|-100|100|1|nil|false|onChange=false|dim=true|shown=nil",
  ["target.markerOffsetY"] = "target|number|0|-100|100|1|nil|false|onChange=false|dim=true|shown=nil",
  ["target.markerPoint"] = "target|string|TOP|nil|nil|nil|BOTTOM,BOTTOMLEFT,BOTTOMRIGHT,CENTER,LEFT,RIGHT,TOP,TOPLEFT,TOPRIGHT|false|onChange=false|dim=true|shown=nil",
  ["target.matchWidth"] = "target|bool|false|nil|nil|nil|nil|false|onChange=false|dim=true|shown=nil",
  ["target.neutralColor"] = "target|color|{a=1,b=0.2,g=0.8,r=0.9}|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.offsetX"] = "target|number|4|-200|200|1|nil|false|onChange=false|dim=false|shown={equals=attached,path=target.anchorMode}",
  ["target.offsetY"] = "target|number|0|-200|200|1|nil|false|onChange=false|dim=false|shown={equals=attached,path=target.anchorMode}",
  ["target.point"] = "target|string|TOPLEFT|nil|nil|nil|BOTTOM,BOTTOMLEFT,BOTTOMRIGHT,CENTER,LEFT,RIGHT,TOP,TOPLEFT,TOPRIGHT|false|onChange=false|dim=false|shown={equals=attached,path=target.anchorMode}",
  ["target.relativePoint"] = "target|string|TOPRIGHT|nil|nil|nil|BOTTOM,BOTTOMLEFT,BOTTOMRIGHT,CENTER,LEFT,RIGHT,TOP,TOPLEFT,TOPRIGHT|false|onChange=false|dim=false|shown={equals=attached,path=target.anchorMode}",
  ["target.showMarker"] = "target|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.showName"] = "target|bool|true|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.showPercent"] = "target|bool|true|nil|nil|nil|nil|false|onChange=false|dim=true|shown=nil",
  ["target.spacing"] = "target|number|4|0|40|1|nil|false|onChange=false|dim=false|shown={equals=free,path=target.anchorMode}",
  ["target.useClassColorBar"] = "target|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.useClassColorBg"] = "target|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.useClassColorBorder"] = "target|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.useClassColorFont"] = "target|bool|false|nil|nil|nil|nil|false|onChange=false|dim=false|shown=nil",
  ["target.width"] = "target|number|110|40|400|1|nil|false|onChange=false|dim=true|shown=nil",
  ["visibility"] = "general|string|always|nil|nil|nil|always,inCombat,never,outOfCombat|false|onChange=true|dim=false|shown=nil",
}

test("layout: every stored path, its page, default, range, values and wiring are unchanged", function()
  local seen, count = {}, 0
  for _, row in ipairs(NS.Schema) do
    if row.path then
      count = count + 1
      seen[row.path] = true
      -- red under: a moved key, a changed default or range, a row re-stamped to another page's
      -- Defaults, or a dim added or dropped (none of which a layout change may do)
      assertEqual(signature(row), PINNED[row.path] or "(not pinned)", row.path)
    end
  end
  for path in pairs(PINNED) do assertTrue(seen[path], path .. " is still a setting") end
  assertEqual(count, 143, "the set of settings")
end)

-- ── the layout ───────────────────────────────────────────────────────────────────────────────

local function tip(row) return row.tooltip or row.desc or "" end

local function endsWith(s, tail) return s:sub(-#tail) == tail end

-- `page`'s rows in drawn order: tabs in first-registration order of `group`, rows by `order`
-- inside a tab (settings/Schema.lua), registration order breaking a tie.
local function drawn(page)
  local tabs, byTab = {}, {}
  for i, row in ipairs(NS.SchemaForPage(page)) do
    if row.group and not byTab[row.group] then
      byTab[row.group] = {}
      tabs[#tabs + 1] = row.group
    end
    if row.group then byTab[row.group][#byTab[row.group] + 1] = { row = row, i = i } end
  end
  for _, list in pairs(byTab) do
    table.sort(list, function(a, b)
      local oa, ob = a.row.order or 0, b.row.order or 0
      if oa ~= ob then return oa < ob end
      return a.i < b.i
    end)
    for k, e in ipairs(list) do list[k] = e.row end
  end
  return tabs, byTab
end

-- The subsection headings a tab draws, in order: one each time `subgroup` changes.
local function headings(rows)
  local out, last = {}, false
  for _, row in ipairs(rows) do
    if row.subgroup ~= last then
      if row.subgroup then out[#out + 1] = row.subgroup end
      last = row.subgroup
    end
  end
  return table.concat(out, ",")
end

local function paths(rows, prefix)
  local out = {}
  for _, row in ipairs(rows) do out[#out + 1] = (row.path or ""):gsub("^" .. prefix:gsub("%.", "%%."), "") end
  return table.concat(out, ",")
end

local function byPath(page)
  local out = {}
  for _, row in ipairs(NS.SchemaForPage(page)) do if row.path then out[row.path] = row end end
  return out
end

test("layout: General has three tabs; All elements holds Party frames, then Health updates", function()
  local L = NS.L
  local tabs, byTab = drawn("general")
  -- red under: the old Party frames and Health updates tabs still standing on their own. The third
  -- is the skin rows' group, "Appearance", the key of the library's Skin tab (skinning-§3), last.
  assertEqual(table.concat(tabs, ","), NS.Helpers.MASTER_GROUP .. "," .. L["All elements"] .. ",Appearance")
  local tab = byTab[L["All elements"]]
  assertEqual(paths(tab, ""), "general.provider,general.includePlayer,general.rangeFade,general.strata,"
    .. "general.updateHealth,general.tickInterval")
  assertEqual(headings(tab), L["Party frames"] .. "," .. L["Health updates"])
  local rows = byPath("general")
  assertEqual(rows["general.tickInterval"].label, L["Target health refresh (seconds)"])
end)

test("layout: Lock frame says it is the preview switch, in the library's words and a combat note", function()
  local locked = byPath("general")["locked"]
  local text = tip(locked)
  -- red under: the composer's generic "Stop the frame being dragged." alone (no lockIsPreview)
  assertTrue(text:find("this is the addon's test mode", 1, true) ~= nil, text)
  assertTrue(endsWith(text, NS.L["Unlocking is refused in combat, and combat locks it again."]), text)
end)

test("layout: every feature page's tabs, with Border merged into Bar", function()
  local L = NS.L
  local expect = {
    castbar = { L["General"], L["Size and position"], L["Bar"], L["Text"], L["Icon"] },
    target  = { L["General"], L["Size and position"], L["Bar"], L["Text"], L["Marker"] },
    pet     = { L["General"], L["Size and position"], L["Bar"], L["Text"], L["Marker"] },
  }
  local barHeadings = {
    castbar = { L["Fill"], L["Cast state colors"], L["Background"], L["Border"] },
    target  = { L["Fill"], L["Reaction colors"], L["Background"], L["Border"] },
    pet     = { L["Fill"], L["Background"], L["Border"] },
  }
  for page, want in pairs(expect) do
    local tabs, byTab = drawn(page)
    assertEqual(table.concat(tabs, ","), table.concat(want, ","), page .. ": tabs")
    local bar = byTab[L["Bar"]]
    assertEqual(headings(bar), table.concat(barHeadings[page], ","), page .. ": Bar headings")
    assertEqual(bar[#bar].path, page .. ".borderStyleFromSkin", page .. ": the border block closes Bar")
    local rows = byPath(page)
    assertEqual(rows[page .. ".borderShow"].subgroup, L["Border"])
    assertEqual(rows[page .. ".borderShow"].order, 120, page .. ": border after the background")
  end
end)

test("layout: Text opens with Shown text, then the font block", function()
  local L = NS.L
  local first = { castbar = "showName,showTime", target = "showName,showPercent", pet = "showName,showPercent" }
  for page, shown in pairs(first) do
    local _, byTab = drawn(page)
    local text = byTab[L["Text"]]
    assertEqual(headings(text), L["Shown text"] .. "," .. L["Font"], page)
    assertEqual(paths(text, page .. "."),
      shown .. ",font,fontSize,fontColor,useClassColorFont,fontFlags,fontShadow,fontFromSkin", page)
  end
end)

test("layout: Size and position keeps Size first, and its tooltips say why a row is dimmed", function()
  local L = NS.L
  for _, page in ipairs({ "castbar", "target", "pet" }) do
    local rows = byPath(page)
    assertEqual(rows[page .. ".width"].group, L["Size and position"])
    assertTrue(endsWith(tip(rows[page .. ".width"]), "Dimmed while attached with Match party frame width on."))
    assertEqual(tip(rows[page .. ".matchWidth"]), "Attached only (dimmed in free placement): stretch each "
      .. "element across its party frame, edge to edge. Width is then ignored.")
  end
end)

test("layout: the Cast Bars words, and Show spark rides the Fill block", function()
  local L = NS.L
  local rows = byPath("castbar")
  assertEqual(rows["castbar.fadeOut"].label, L["Fade out when a cast ends"])
  assertEqual(tip(rows["castbar.fadeOut"]), "Fade the bar out when a cast ends, including after an "
    .. "interrupted cast's hold, instead of hiding it at once.")
  assertEqual(rows["castbar.barColor"].label, L["Normal cast color"])
  assertEqual(rows["castbar.channelColor"].subgroup, L["Cast state colors"])
  local _, byTab = drawn("castbar")
  assertEqual(paths(byTab[L["Bar"]], "castbar."), "barTexture,barAlpha,barColor,useClassColorBar,"
    .. "barTextureFromSkin,showSpark,channelColor,empowerColor,uninterruptibleColor,failedColor,bgColor,"
    .. "useClassColorBg,borderShow,borderStyle,borderSize,borderColor,useClassColorBorder,borderStyleFromSkin")
  assertEqual(rows["castbar.showSpark"].subgroup, L["Fill"])
  assertEqual(paths(byTab[L["Icon"]], "castbar."), "showIcon,iconSide,showShield")
end)

test("layout: dependants say what they need, and the marker's point names the bar", function()
  local L = NS.L
  for _, page in ipairs({ "target", "pet" }) do
    local rows = byPath(page)
    assertTrue(endsWith(tip(rows[page .. ".showPercent"]),
      "Needs Update health (the General page > All elements)."), page)
    assertEqual(rows[page .. ".markerPoint"].label, L["Bar anchor point"], page)
  end
  local rows = byPath("target")
  for _, key in ipairs({ "hostileColor", "neutralColor", "friendlyColor" }) do
    assertTrue(endsWith(tip(rows["target." .. key]), "Needs Color NPCs by reaction."), key)
  end
end)
