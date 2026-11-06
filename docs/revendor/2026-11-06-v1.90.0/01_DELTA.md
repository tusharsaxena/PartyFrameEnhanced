Delta: LibKa0s v1.89.0 -> v1.90.0

Part of Ka0sAddonsCommonTasks `docs/2026-11-06-REVENDOR_LIBKA0S_V1_89/` (item SF1-RV-PFE, from
`SF1_SMOKE_FEEDBACK.md`). The tag is **local**, not pushed, at library commit `4485b8f`
(`git -C ../LibKa0s rev-parse v1.90.0^{commit}`). `git ls-remote` shows nothing for it, which is expected:
this is a new tag over the addon's v1.89.0 provenance, not a refresh. Extracted with
`git -C ../LibKa0s archive v1.90.0 LibKa0s testkit tools | tar -x` into a scratch directory under
`/tmp/claude-1000/`, never the working tree.

## Step 0 pre-flight

Newest single-tag bundle `2026-11-06-v1.89.0` states base v1.85.0; `git show ddf71c8^:CLAUDE.md` names v1.85.0
before the v1.89.0 re-vendor commit `ddf71c8`. `ok`; no correction owed.

## Base (3a)

- `grep -n '[Bb]undles' CLAUDE.md` gives `41:Bundles [LibKa0s](…) v1.89.0 (MIT).`
- `git log -1 --format=%h -- libs/LibKa0s tests/_kit` gives `ddf71c8`, whose `CLAUDE.md` line names v1.89.0;
  `git log ddf71c8..HEAD -- CLAUDE.md` lists no roll since. The two agree: the base is **v1.89.0**.

## Actual version (3b)

`grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR …' libs/LibKa0s/*.lua` gives 67 constants, and
`diff -rq <v1.89.0 extract>/LibKa0s libs/LibKa0s` prints only `Only in <extract>/…/media/icons` lines (the
undeclared icons): the line and the bytes agree.

## Per-file minors (3c), moved files only

The loop over the tag's `LibKa0s/LibKa0s.xml`, old against tag:

| File | old | new |
|---|---|---|
| Core.lua | 15 | 16 |
| Skin.lua | 16 | 17 |
| SkinPaint.lua (`PAINT_MINOR`) | 18 | 19 |
| SkinPaintExtras.lua (`EXTRAS_MINOR`) | 17 | 18 |
| Widgets.lua | 23 | 24 |
| WidgetsAutocomplete.lua (`AUTOCOMPLETE_MINOR`) | 7 | 8 |
| OptionsAppearance.lua (`APPEARANCE_MINOR`) | 6 | 7 |

No new file; no file behind the tag after the copy (no cross-major skew). Library range:
`git -C ../LibKa0s log --oneline v1.89.0..v1.90.0` (7 commits: SF1-L1 pixel edges, SF1-L2 keepScope, SF1-L3
release, plus the harvest merge `e809ca3` and its sync-docs commit).

## Diffs before the copy (3d)

`diff -rq --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s`, `media/icons` lines aside: the seven files above
differ. Every `media/icons` line is `Only in <scratch>/…` (the undeclared icons). No `Only in libs/LibKa0s` line.
Kit: `diff -rq --strip-trailing-cr <scratch>/testkit tests/_kit` is empty.

## Consumption map (3e)

Unchanged from the v1.89.0 bundle (`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' |
grep -v /libs/ | grep -v /tests/`): Env, Media, Core, Compat, Launcher, DebugLog, Skin (`core/Database.lua`,
`core/SkinSetup.lua`), Lifecycle, Bus, Perf, Slash, Options, Schema. Widgets is not looked up directly.

## Kit revision (3f)

`grep -n 'Kit.VERSION' <scratch>/testkit/framework.lua tests/_kit/framework.lua`: 51 -> **51** (unchanged). Both
payloads still move together in one commit (pairing rule, v1.9.0+ needs kit 11+).

## Contract delta (3g)

Majors that moved a minor and that this addon looks up: **Core**, **Skin**, **Options**.

- Core 15 -> 16 (`docs/api/Core/version-15-docs.md` against `version-16-docs.md`): "No public member is added,
  removed or renamed"; four internal `__Pixel*` members, which "A host calls none of".
- Skin 16.1.27.8.18.17.17.4.9 -> 17.1.27.8.19.18.17.4.9: additive `RegisterOwner(owner, { keepScope = true })`
  option; no member of the major or a facade moves. This addon's `RegisterOwner` (`core/SkinSetup.lua`, the live
  seam) has no documented Scope deviation, so it owes nothing; `tests/test_surface_parity.lua`'s vocabulary is
  unchanged.
- Options …5.5.7.6… -> …5.5.7.7… (OptionsAppearance 7): `lib.__copySkinTo` skips the Scope of a `keepScope`
  target. "What a host owes: a host whose Scope is a documented deviation registers with `keepScope = true`;
  every other host owes nothing."
- `grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit`: no site.
- No test pins a moved minor (`grep -rnE 'MINOR' tests --include='*.lua' | grep -v /_kit/` finds none).

### Blockers

None.

## Span check (3h)

The audit's listing (horizon 2026-09-23, both payload paths plus the `CLAUDE.md` rolls) prints nothing. No span
bundle.

## Icon declaration (3i)

`grep -n 'LibKa0s icons:' CLAUDE.md` gives `42:LibKa0s icons: chevron-down, chevron-up, clear, close, confirm, copy,
eye, info, move, reset, settings, volume-high.`, the next non-blank line under the provenance line. Kept as decided
(the run's call: keep the icons line). No new library-drawn name arrives in this range. Hand lists have drifted
before (KickCD `tests/test_mediasetup.lua:28`, WhatGroup `tests/test_mediasetup.lua:19`); the owner's in-client
smoke is the backstop.

## Tests that assume the whole icon folder (3j)

`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v /_kit/`: only
`tests/test_optionssetup.lua:295-296`, which opens `info.tga`, a declared name. No blocker.
