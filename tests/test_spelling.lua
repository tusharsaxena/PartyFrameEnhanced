-- tests/test_spelling.lua — US English is the source dialect (localization-§5), checked mechanically
-- over every authored file the repo tracks: Lua (comments, identifiers, strings), Markdown and the TOC.
--
-- The two lists are copied WHOLE from localization-§5's "The canonical list" — every BRITISH entry,
-- every ALLOWED entry, nothing added. A spelling the lists miss is amended upstream in the standard
-- first and arrives here on the next sync; a private addition would make this gate's green mean
-- something no reader outside this repo can check.
--
-- Out of scope, and why: libs/ and tests/_kit/ are vendored (checked in their own repos); frozen
-- evidence bundles (docs/automated-tests/<run>/, docs/perf-analysis/<run>/, docs/audits/,
-- docs/reviews/) are never edited once written; and this file, which has to spell the list out.

local T = _G.PFE_TEST
local test, assertTrue = T.test, T.assertTrue

-- localization-§5 · US English is the source dialect. Copy BOTH lists whole.
-- BRITISH: lowercase substrings, matched case-insensitively.
-- ALLOWED: correct US words that contain a BRITISH substring; removed as WHOLE WORDS first.

local BRITISH = {
  -- -our → -or
  "colour", "behaviour", "favour", "honour", "neighbour", "armour", "flavour",
  "labour", "rumour", "humour", "endeavour", "rigour", "vigour", "saviour",
  -- -re → -er
  "centre", "centring", "metre", "fibre", "calibre", "theatre", "manoeuvre",
  -- -ce → -se
  "defence", "licence", "offence", "pretence", "practis",
  -- -ise / -isation → -ize / -ization, and the -yse verbs
  "initialis", "normalis", "generalis", "specialis", "optimis", "customis",
  "serialis", "summaris", "utilis", "organis", "authoris", "prioritis",
  "alphabetis", "categoris", "sanitis", "visualis", "minimis", "maximis",
  "itemis", "randomis", "tokenis", "capitalis", "localis", "modularis",
  "standardis", "memois", "recognis", "analys", "paralys", "synthesis",
  "emphasis",
  -- a doubled consonant before a suffix, where US English keeps one
  "cancelled", "cancelling", "cancellable", "labelled", "labelling",
  "travelled", "travelling", "modelled", "modelling", "signalled",
  "signalling", "levelled", "levelling", "fuelled", "fuelling", "totalled",
  "totalling", "fulfil",
  -- -ogue → -og
  "catalogue", "dialogue", "analogue",
  -- no family, just British
  "grey", "artefact", "whilst", "amongst", "learnt", "ageing", "enquir",
  "acknowledgement", "judgement", "sceptic", "mould", "sulphur", "programme",
}

local ALLOWED = {
  "analysis", "analyses", "analyst", "analysts",
  "organism", "organisms", "organist",
  "specialist", "specialists", "generalist", "generalists",
  "optimism", "optimist", "optimists", "optimistic", "optimistically",
  "paralysis", "paralyses", "synthesis", "syntheses", "emphasis", "emphases",
  "fulfill", "fulfills", "fulfilled", "fulfilling", "fulfillment",
  "programmer", "programmers", "programmed",
}

local SKIP_PREFIXES = {
  "libs/", "tests/_kit/", "docs/audits/", "docs/reviews/", "tests/test_spelling.lua",
}

local function inScope(path)
  if not (path:match("%.lua$") or path:match("%.md$") or path:match("%.toc$")) then return false end
  for _, prefix in ipairs(SKIP_PREFIXES) do
    if path:sub(1, #prefix) == prefix then return false end
  end
  -- A frozen bundle: docs/automated-tests/<stamp>/… or docs/perf-analysis/<stamp>/…
  if path:match("^docs/automated%-tests/%d") or path:match("^docs/perf%-analysis/%d") then
    return false
  end
  return true
end

local function trackedFiles()
  local p = io.popen and io.popen("git ls-files")
  assertTrue(p ~= nil, "the spelling gate needs io.popen and git to list tracked files")
  local files = {}
  for line in p:lines() do
    if inScope(line) then files[#files + 1] = line end
  end
  p:close()
  return files
end

-- The lowercase line with every ALLOWED word removed as a whole word.
local function scrub(line)
  line = line:lower()
  for _, word in ipairs(ALLOWED) do
    line = line:gsub("%f[%a]" .. word .. "%f[%A]", "")
  end
  return line
end

test("spelling: every authored file is US English (localization-§5)", function()
  local files = trackedFiles()
  assertTrue(#files > 20, "the gate found only " .. #files .. " files — it would pass looking at nothing")
  local hits = {}
  for _, path in ipairs(files) do
    local f = io.open(path, "r")
    if f then
      local n = 0
      for line in f:lines() do
        n = n + 1
        local clean = scrub(line)
        for _, british in ipairs(BRITISH) do
          if clean:find(british, 1, true) then
            hits[#hits + 1] = ("%s:%d: '%s'"):format(path, n, british)
          end
        end
      end
      f:close()
    end
  end
  assertTrue(#hits == 0, "British spellings:\n  " .. table.concat(hits, "\n  "))
end)

test("spelling: the gate is not vacuous — a planted British word is caught", function()
  -- testing-§12: prove the negative assertion can fail.
  local caught = scrub("the bar's colour"):find("colour", 1, true) ~= nil
  local allowed = scrub("see the analysis"):find("analys", 1, true) == nil
  assertTrue(caught, "a British spelling must be reported")
  assertTrue(allowed, "an ALLOWED word must not be")
end)
