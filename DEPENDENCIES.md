# Dependencies — Ka0s Party Frame Enhanced

What you need installed to build, run, test or release this addon. Commands are for
**WSL2 / Ubuntu** (the collection's development environment). How to *verify* the addon once
you are set up is [`docs/testing.md`](docs/testing.md); this file only covers *what to install*.

Every entry says what needs it and how that is known. Anything only plausibly required is
marked as such rather than listed as a requirement.

## Runtime (in-game) — what a player needs

- **World of Warcraft (Retail).** Single `## Interface: 120100` line in `PartyFrameEnhanced.toc` —
  Retail only.
- **Nothing else.** Every library is vendored under `libs/` and committed (library-stack), so the
  player installs no separate library addon. `## OptionalDeps:` names the vendored libs for load
  ordering, not as things to download.
- **A broker display — optional.** LibDataBroker-1.1 and LibDBIcon-1.0 are vendored under `libs/`,
  so the minimap button needs nothing installed. A broker display (Titan Panel, ElvUI data texts,
  Bazooka) draws the same object where one is present, and where none is the button is all there is.
- **EllesmereUI — optional.** `## OptionalDeps:` lists `EllesmereUI, EllesmereUIRaidFrames` so they
  load first when present. With them absent the addon attaches to Blizzard's party frames or uses
  free placement; nothing is lost but the EllesmereUI attachment (library-stack-§6). The
  presence guard is `Compat.IsAddOnLoaded("EllesmereUIRaidFrames")` in the EllesmereUI provider's
  `IsAvailable` (`modules/Providers.lua`).

## Development — the contributor toolchain

| Tool | Version | Needed for | Evidence |
|---|---|---|---|
| `lua5.1` (+ `luac5.1`) | **5.1 exactly** | the headless suite, `lua tests/run.lua`, and `lua tests/perf.lua` | `tests/_kit/loader.lua` sandboxes each file with `setfenv` |
| `luacheck` | any recent | `luacheck .`, the other half of the green gate | `.luacheckrc` at the repo root |
| `lizard` | any recent | the `complexity` suite of `tests/_kit/run-automated-tests.sh` (automated-tests) | the runner invokes `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` |
| `git` | any recent | the vendored-payload gate (`tests/test_vendor_sync.lua` reads the LibKa0s tag with `git`), the EOL gate (`tests/_kit/test_eol.lua` runs `git ls-files` / `git check-attr`), the spelling gate (`tests/test_spelling.lua` runs `git ls-files`) | those three files |
| POSIX shell (`bash`) | any | `tests/_kit/run-automated-tests.sh` | its `#!/usr/bin/env bash` line |
| A sibling `../LibKa0s` checkout | — | the vendored-payload gate compares against it; without it those cases **skip** with the reason | `tests/_kit/vendor_sync.lua` |

**Lua 5.1 is a requirement, not a preference.** The harness sandboxes each source file with
`setfenv`, which was removed in 5.2 — "5.2 will probably work" is false and costs an hour to
disprove.

```sh
# Lua 5.1 and luacheck
sudo apt-get update
sudo apt-get install -y lua5.1 luarocks
sudo luarocks install luacheck

# lizard — via pipx, NOT pip. Ubuntu 24.04 marks its Python EXTERNALLY-MANAGED (PEP 668),
# so `pip install lizard` fails; pipx installs it into its own venv and puts it on PATH.
sudo apt-get install -y pipx
pipx ensurepath          # then open a new shell, or: source ~/.bashrc
pipx install lizard

# the LibKa0s sibling checkout the vendored-payload gate compares against
git clone https://github.com/tusharsaxena/LibKa0s.git ../LibKa0s

# verify — each of these must print a version
lua5.1 -v                # Lua 5.1.5 …   (if `lua` is not 5.1, use lua5.1 explicitly)
luacheck --version
lizard --version
git --version
```

Versions are pinned only where a version matters: `lua5.1` is hard, `luacheck` and `lizard` are
"any recent" and pinning them would be false precision.

## Release / assets

**None required to build, run or test the addon.** It is packaged from the committed tree and
nothing is generated at build time.

The in-game logo (`media/logos/partyframeenhanced.logo.tga`, 512×512 RGBA, uncompressed) is converted
from the 2000×2000 `.png` beside it with Python 3 + Pillow (Lanczos downscale). The client loads only
the `.tga` and needs power-of-two sides; the `.png` (the source art) and the `.jpg` are dev-only
and ignored by `.pkgmeta`. Regenerate it only when the art changes:

```sh
python3 -c "from PIL import Image; Image.open('media/logos/partyframeenhanced.logo.png').convert('RGBA').resize((512, 512), Image.LANCZOS).save('media/logos/partyframeenhanced.logo.tga', rle=False)"
```
**None of this group is required to build, run or test the addon.**

## Am I set up correctly?

```sh
lua tests/run.lua                                     # the suite — must be green
luacheck .                                            # must be 0 warnings / 0 errors
lua tests/perf.lua                                    # offline perf scenarios (outside the gate)
lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .     # the complexity report (release-time)
```

See [`docs/testing.md`](docs/testing.md) for what those commands mean and when each is run.
