local addonName, NS = ...

-- core/MediaSetup.lua — the LibKa0s-Media-1.0 seam: the shared icon catalog, the monospace face and
-- the bar textures, all of which ship inside the vendored payload (library-stack-§8).
--
-- WHY THE LIBRARY IS TOLD OUR NAME. A texture path is absolute from Interface\AddOns\, and LibKa0s is
-- vendored, so a copy cannot know which folder it was copied into. `addonName` is the first vararg
-- every TOC-loaded file gets. A wrong path draws nothing and raises nothing.
--
-- LOAD-BEARING POSITION: core/Constants.lua resolves FONT_MONO from NS.MediaFont at file load, so this
-- file loads first (the TOC says so, tests/test_loadorder.lua pins it).
--
-- DEGRADED INSTALL: no LibKa0s means no art. Both functions answer nil, and callers draw something
-- else — Constants falls back to a real client font. Nil is never papered over with a guessed path.

local Media = LibStub and LibStub("LibKa0s-Media-1.0", true)

--- The texture path for one catalog icon (extensionless, as the catalog stores it), or nil.
--- No caller yet: every mark this addon shows today is drawn inside libs/LibKa0s (the console, the
--- perf panel), which builds its own paths from the addonName its descriptors receive.
function NS.Icon(name)
    if not Media then return nil end
    return Media.Icon(addonName, name)
end

--- The path of one shipped font face, or nil.
function NS.MediaFont(name)
    if not Media then return nil end
    return Media.Font(addonName, name)
end

-- At FILE LOAD, not PLAYER_LOGIN: LibSharedMedia is vendored under libs/ and has already run, and a
-- shipped default naming a face or texture LSM has not heard of yet would resolve to nothing.
if Media then Media.RegisterLSM(addonName) end
