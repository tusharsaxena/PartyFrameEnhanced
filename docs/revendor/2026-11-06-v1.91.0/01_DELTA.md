Delta: LibKa0s v1.90.0 -> v1.91.0

Part of Ka0sAddonsCommonTasks `docs/2026-11-06-FOLLOWUPS_V1_91/` (item FU-RV-PFE). The tag is **local**, not
pushed, at library commit `55bfbb4` (`git -C ../LibKa0s rev-parse v1.91.0^{commit}`). `git ls-remote --tags origin
v1.91.0` shows nothing, which is expected: this is a new tag over the addon's v1.90.0 provenance, not a refresh.
Extracted with `git -C ../LibKa0s archive v1.91.0 LibKa0s testkit tools | tar -x` into a scratch directory under
`/tmp/claude-1000/`, never the working tree.

## Step 0 pre-flight

Skipped. The installed skill's roster regex expects markdown links, but `ADDONS.md` writes `` `../../<Folder>/` ``,
so it matches nothing; the run's plan fixes it upstream (dev-copilot 2.7.1, FU-DC1). For this addon alone: the newest
single-tag bundle `2026-11-06-v1.90.0` states base v1.89.0, and the v1.90.0 re-vendor commit's parent names v1.89.0
(the previous bundle's 3a recorded the same). No correction owed.

## Base (3a)

- `grep -n '[Bb]undles' CLAUDE.md` gives `41:Bundles [LibKa0s](…) v1.90.0 (MIT).`
- `git log -1 --format=%h -- libs/LibKa0s tests/_kit` gives `2da8bb4` (the v1.90.0 refresh), whose `CLAUDE.md` line
  names v1.90.0. The two agree: the base is **v1.90.0**.

## Actual version (3b)

`diff -rq <v1.90.0 extract>/LibKa0s libs/LibKa0s` prints only `Only in <extract>/…/media/icons` lines (the undeclared
icons), and the kit diff is empty: the line and the bytes agree.

## Per-file minors (3c), moved files only

The loop over the tag's `LibKa0s/LibKa0s.xml`, old against tag:

| File | old | new |
|---|---|---|
| Core.lua | 16 | 17 |
| CorePixel.lua (`PIXEL_MINOR`) | (new) | 1 |
| SkinPaintExtras.lua (`EXTRAS_MINOR`) | 18 | 19 |
| SkinPaintHud.lua (`HUD_MINOR`) | (new) | 1 |
| SkinAceConfirm.lua (`CONFIRM_MINOR`) | (new) | 1 |
| Widgets.lua | 25 | 26 |
| WidgetsDropdown.lua (`DROPDOWN_MINOR`) | (new) | 1 |
| WidgetsLineChart.lua (`CHART_MINOR`) | 6 | 7 |

Four files are new in this range (the FU-L2 peels). No file is behind the tag after the copy (no cross-major skew).
Library range: `git -C ../LibKa0s log --oneline v1.90.0..v1.91.0` (7 commits: FU-L1 line-chart pixels, four FU-L2
peels, two FU-L3 release commits). `git -C ../LibKa0s diff --stat v1.90.0 v1.91.0 -- LibKa0s testkit`: 9 files,
the eight above plus `LibKa0s.xml` (+4 lines); the kit is unchanged.

## Diffs before the copy (3d)

`diff -rq --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s`, `media/icons` lines aside: the files above differ or are
`Only in <scratch>`. Every `media/icons` line is `Only in <scratch>/…` (the undeclared icons). No `Only in
libs/LibKa0s` line. Kit: empty.

## Consumption map (3e)

Unchanged (`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v /libs/ | grep -v
/tests/`): Env, Media, Core, Compat, Launcher, DebugLog, Skin (`core/Database.lua`, `core/SkinSetup.lua`), Lifecycle,
Bus, Perf, Slash, Options, Schema. Widgets is not looked up directly, and this addon draws no LineChart.

## Kit revision (3f)

`grep -n 'Kit.VERSION' <scratch>/testkit/framework.lua tests/_kit/framework.lua`: 51 -> **51** (unchanged). Both
payloads still move together in one commit (pairing rule, v1.9.0+ needs kit 11+).

## Contract delta (3g)

Majors that moved and that this addon looks up: **Core** and **Skin**. Widgets moved too but is not looked up.

- Core 16 -> 17.1 (`docs/api/Core/version-17.1-docs.md:23-27`): "A pure move … no public or internal member and no
  behavior changes, so `members-17.1.json` lists the same names as version 16."
- Skin 17.1.27.8.19.18.17.4.9 -> 17.1.27.8.19.19.1.1.17.4.9
  (`docs/api/Skin/version-17.1.27.8.19.19.1.1.17.4.9-docs.md`, *What changed at this version: the SkinPaintExtras
  peel*): "no member of the major or of a facade and no behavior changes, so the member manifest lists the same
  names and a host's Skin facade owes nothing."
- Widgets 25.6.13.6.8.5 -> 26.1.6.13.7.8.5 (`docs/api/Widgets/version-26.1.6.13.7.8.5-docs.md:21-33`): the dropdown
  peel is a pure move; the line chart's lines become physical pixels, "What a host owes: nothing."
- `grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit`: no site.

### Blockers

None.

- **Library file lists:** `tests/run.lua:24`, `tests/perf.lua:46`, `tests/launcher_env.lua:82` and
  `tests/test_securefollow.lua:485` all read the list from `libs/LibKa0s/LibKa0s.xml` through `Loader.xmlFiles`, and
  `tests/test_loadorder.lua:166` asserts that list against the XML. No hand list exists, so the four new files load in
  the tag's order with no edit.
- **Minor pins:** `grep -rnE 'MINOR|minor' tests --include='*.lua' | grep -v /_kit/` finds comments naming Launcher,
  Slash, Lifecycle, Options, Skin and compose minors, none of them a moved file and none an assertion on a minor.
- **Stub mirrors:** `grep -rn '__Pixel\|__WatchPixels\|__OnPixelScale\|__releaseChrome' . --include='*.lua'` outside
  `libs/` and `_kit/` finds nothing. `core/SkinSetup.lua:449`'s no-library facade lists `Dropdown` as a no-op name,
  which is a Skin facade name, not a moved Widgets member; the Skin manifest is unchanged.

## Span check (3h)

The audit's listing (horizon 2026-09-23, both payload paths plus the `CLAUDE.md` rolls; `tag_at` rewritten with a
named variable) prints nothing. No span bundle.

## Icon declaration (3i)

`grep -n 'LibKa0s icons:' CLAUDE.md` gives `42:LibKa0s icons: chevron-down, chevron-up, clear, close, confirm, copy,
eye, info, move, reset, settings, volume-high.`, the next non-blank line under the provenance line. Kept as decided
(the run's call: keep the icons line). No new library-drawn name arrives in this range. Hand lists have drifted
before (KickCD `tests/test_mediasetup.lua:28`, WhatGroup `tests/test_mediasetup.lua:19`); the owner's in-client
smoke is the backstop.

## Tests that assume the whole icon folder (3j)

`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v /_kit/`: only
`tests/test_optionssetup.lua:295-296`, which opens `info.tga`, a declared name. No blocker.
