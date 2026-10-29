-- tests/test_skin_literals.lua — the hard-coded color gate (PF-02 of the 2026-10-29 skinning rollout;
-- skinning's anti-pattern #107, binding for this addon since it adopted skins). The shape is
-- LootHistory's tests/test_skin_literals.lua, the leg-1 adopter's gate; only the allow-list is ours.
--
-- WHAT IT PROVES. That no color this addon draws is a literal the skin cannot reach. Two shapes are
-- caught, in every tracked .lua file under core/, modules/ and settings/:
--
--   1. A NUMERIC LITERAL IN A COLOR POSITION of a paint call: the r, g or b argument of
--      SetTextColor, SetColorTexture, SetVertexColor, SetBackdropColor, SetBackdropBorderColor,
--      SetShadowColor and SetStatusBarColor,
--      the r, g, b after AddLine's text, and the two r, g, b triples after AddDoubleLine's texts.
--      `SetColorTexture(0, 0.6, 1, 0.25)` fails; `SetColorTexture(NS.Skin.Color("pf.mover"))`
--      passes. An ALPHA literal over token components (`SetColorTexture(r, g, b, 0.95)`) is not a
--      color: it is the surface's opacity, the same under every skin, and is left alone on purpose.
--   2. A `|cff` (any case) escape in code, i.e. markup that names a color byte for byte. Comments
--      are stripped first.
--
-- core/SkinSetup.lua is out of scope: it IS the seam, and its host copy of the Ka0s Default tokens
-- (NS.SKIN_FALLBACK) and its own tokens' defaults (NS.SKIN_TOKENS) are the literals every other
-- file reads through. The HUD's colors are the player's stored swatches (defaults/Profile.lua, not
-- scanned), drawn through variables, so they pass without an entry.
--
-- THE ALLOW-LIST. Each entry names one file, a plain substring the offending line carries, and the
-- reason it is not chrome (the rollout inventory's exceptions E-PF-3 and E-PF-8). An entry that
-- matches nothing fails the gate, so the list cannot outlive what it excuses.
--
-- IT FAILS RATHER THAN PASSES WHEN IT CANNOT LOOK: no io.popen, no git, or an empty file list is a
-- failure. The last case proves the gate is falsifiable: a planted literal of each shape is reported.

local T = _G.PFE_TEST
local test, assertEqual, assertTrue, fail = T.test, T.assertEqual, T.assertTrue, T.fail
local ROOT = T.root or "."

local SEAM = "core/SkinSetup.lua"

-- call name -> the argument positions that hold color components.
local COLOR_ARGS = {
  SetTextColor = { 1, 2, 3 }, SetColorTexture = { 1, 2, 3 }, SetVertexColor = { 1, 2, 3 },
  SetBackdropColor = { 1, 2, 3 }, SetBackdropBorderColor = { 1, 2, 3 },
  SetShadowColor = { 1, 2, 3 }, SetStatusBarColor = { 1, 2, 3 },
  AddLine = { 2, 3, 4 }, AddDoubleLine = { 3, 4, 5, 6, 7, 8 },
}

local STANDIN = "the preview stand-in imitates the Blizzard / EllesmereUI party frame it stands in for, "
  .. "so offsets tuned against it match a real party (exception E-PF-3)"
local SHADOW = "the HUD text's shadow, drawn only with Font shadow on, is the client's stock text shadow "
  .. "(1, -1, black), the same the library's own P.font draws; not chrome (DECISIONS D5)"
local CHAT = "chat output: the Blizzard chat frame is not a skinned surface (exceptions E-PF-8, X7)"

local ALLOW = {
  { file = "modules/StandIn.lua", find = "SetColorTexture(0.06, 0.06, 0.06, 0.9)", why = STANDIN },
  { file = "modules/StandIn.lua", find = "SetBackdropBorderColor(0, 0, 0, 1)", why = STANDIN },
  { file = "modules/StandIn.lua", find = "SetColorTexture(0, 0, 0, 0.5)", why = STANDIN },
  { file = "modules/StandIn.lua", find = "|cff999999", why = STANDIN .. ": its (test) mark" },
  { file = "modules/Element.lua", find = "SetShadowColor(0, 0, 0, 1)", why = SHADOW },
  { file = "core/Namespace.lua", find = "NS.PREFIX", why = CHAT .. ", the [PFE] tag" },
  { file = "core/DebugLogSetup.lua", find = "|cff40ff40", why = CHAT .. ", the debug ON/OFF line" },
  { file = "modules/Preview.lua", find = "|cff808080", why = CHAT .. ", the preview refusals" },
  { file = "settings/Slash.lua", find = "|cFFFFFF00", why = CHAT .. ", the get/set echo" },
}

--- Strip a line's trailing comment. `--` never occurs inside a string in these files' color code, so
--- a plain cut is enough; a string that did hold one would only shorten what is scanned.
local function code(line) return (line:gsub("%-%-.*$", "")) end

--- Split a call's argument list at its top-level commas (parens, braces and quotes nest).
local function splitArgs(s)
  local args, depth, buf, quote = {}, 0, {}, nil
  local i = 1
  while i <= #s do
    local c = s:sub(i, i)
    if quote then
      buf[#buf + 1] = c
      if c == "\\" then buf[#buf + 1] = s:sub(i + 1, i + 1); i = i + 1
      elseif c == quote then quote = nil end
    elseif c == '"' or c == "'" then quote = c; buf[#buf + 1] = c
    elseif c == "(" or c == "{" or c == "[" then depth = depth + 1; buf[#buf + 1] = c
    elseif c == ")" or c == "}" or c == "]" then depth = depth - 1; buf[#buf + 1] = c
    elseif c == "," and depth == 0 then args[#args + 1] = table.concat(buf); buf = {}
    else buf[#buf + 1] = c end
    i = i + 1
  end
  args[#args + 1] = table.concat(buf)
  return args
end

local function isNumber(arg) return arg:match("^%s*%-?%d*%.?%d+%s*$") ~= nil end

--- Every offending line of one source text: { line = n, text = what was found }.
local function scan(src)
  local lines, hits = {}, {}
  for ln in (src .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = code(ln) end
  local stripped = table.concat(lines, "\n")
  for name, positions in pairs(COLOR_ARGS) do
    local init = 1
    while true do
      local s, e, args = stripped:find("[:%.]" .. name .. "%s*(%b())", init)
      if not s then break end
      init = e + 1
      local list = splitArgs(args:sub(2, -2))
      for _, p in ipairs(positions) do
        if list[p] and isNumber(list[p]) then
          local n = select(2, stripped:sub(1, s):gsub("\n", "")) + 1
          hits[#hits + 1] = { line = n, text = lines[n] }
          break
        end
      end
    end
  end
  for n, ln in ipairs(lines) do
    if ln:find("|c[fF][fF]") then hits[#hits + 1] = { line = n, text = ln } end
  end
  return hits
end

local function allowed(file, text, used)
  for i, a in ipairs(ALLOW) do
    if a.file == file and text:find(a.find, 1, true) then used[i] = true; return true end
  end
  return false
end

local function trackedSources()
  if not io.popen then fail("skin literal gate: io.popen is unavailable, so this gate cannot run") end
  local p = io.popen("git -C " .. ROOT .. " ls-files 'core/*.lua' 'modules/*.lua' 'settings/*.lua' 2>/dev/null")
  if not p then fail("skin literal gate: io.popen returned no handle") end
  local files = {}
  for path in p:lines() do if path ~= SEAM then files[#files + 1] = path end end
  p:close()
  if #files == 0 then fail("skin literal gate: git listed no source files, so nothing was scanned") end
  return files
end

local function readAll(path)
  local f = io.open(ROOT .. "/" .. path, "rb")
  if not f then fail("skin literal gate: cannot read " .. path) end
  local s = f:read("*a")
  f:close()
  return s
end

test("skin literals: no color literal outside core/SkinSetup.lua and the named allow-list", function()
  local bad, used = {}, {}
  for _, path in ipairs(trackedSources()) do
    for _, h in ipairs(scan(readAll(path))) do
      if not allowed(path, h.text, used) then
        bad[#bad + 1] = ("%s:%d: %s"):format(path, h.line, (h.text:gsub("^%s+", "")))
      end
    end
  end
  assertEqual(#bad, 0, "hard-coded colors the skin cannot reach (read a token through NS.Skin, or "
    .. "add an allow-list entry with its reason):\n  " .. table.concat(bad, "\n  "))
  for i, a in ipairs(ALLOW) do
    assertTrue(used[i], ("stale allow-list entry: %s %q matches nothing"):format(a.file, a.find))
  end
end)

test("skin literals: every allow-list entry carries its reason", function()
  for _, a in ipairs(ALLOW) do
    assertTrue(type(a.why) == "string" and #a.why > 10, a.file .. " " .. a.find .. ": no reason")
  end
end)

test("skin literals: the gate is falsifiable, a planted literal of each shape is reported", function()
  local planted = table.concat({
    "local x = 1",
    "fs:SetTextColor(0.85, 0.85, 0.85)",
    "tex:SetColorTexture(r, g,",
    "  0.5, 1)",
    'tt:AddLine("n records", 0.7, 0.7, 0.7)',
    'tt:AddDoubleLine("a", "b", r, g, b, 1, 1, 1)',
    'local s = "|cff808080(none)|r"',
    "fs:SetTextColor(NS.Skin.Color(\"text.body\"))   -- 0.9, 0.9, 0.9 in a comment",
    "tex:SetColorTexture(r, g, b, 0.95)",
    "-- |cffffffff in a comment",
    "fs:SetShadowColor(0, 0, 0, 1)",
    "bar:SetStatusBarColor(0.2, 0.8, 0.2, a)",
    "bar:SetStatusBarColor(r, g, b, (a or 1) * fill)",
  }, "\n")
  local hits = scan(planted)
  local lines = {}
  for _, h in ipairs(hits) do lines[#lines + 1] = h.line end
  table.sort(lines)
  assertEqual(table.concat(lines, ","), "2,3,5,6,7,11,12",
    "the literal lines and only those (a token call, an alpha literal and a comment pass)")
end)
