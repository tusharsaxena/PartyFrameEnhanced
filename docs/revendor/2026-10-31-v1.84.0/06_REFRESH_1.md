# Refresh 1: the re-cut v1.84.0

The tag moved before it was pushed (`git -C ../LibKa0s ls-remote --tags origin v1.84.0` prints nothing), so
this is a refresh under the re-vendor command's refresh rule: no new bundle folder, and line 1 of
`01_DELTA.md` stays as it is.

- Old commit: `e917ccd833768b8fe68e9542d3fbf6b38cab6659`, the v1.84.0 this bundle vendored. `diff -rq` of its
  payload against the vendored copy before this refresh was empty apart from the pruned icons.
- New commit: `7a8bc0f133ed118d2c79c7c5288b97964e24fae5`, from `git -C ../LibKa0s rev-parse 'v1.84.0^{commit}'`.
- Why: LK-M3, the owner's ruling of 2026-11-01 that `Ka0sMedia_*` is the only media picker (LibKa0s#73).

## Per-file minors

| File | Constant | Old | New |
|---|---|---|---|
| `Options.lua` | `MINOR` | 35 | 36 |
| `OptionsWidgets.lua` | `WIDGETS_MINOR` | 40 | 41 |
| `OptionsCompose.lua` | `COMPOSE_MINOR` | 15 | 16 |
| `OptionsScroll.lua` | `SCROLL_MINOR` | 9 | 10 |
| `OptionsMedia.lua` | `MEDIA_MINOR` | 1 | 2 |
| `SkinAce.lua` | `ACE_MINOR` | 5 | 6 |

Every other file keeps its minor. The test kit does not move: revision 47 on both sides, and `tests/_kit/`
has no diff.

## Contract

`lib.__PatchLSM30Border` is a no-op from Options minor 36. This addon's one call sat at
`settings/OptionsSetup.lua:176`, and it still works, so it is no blocker; the M3-MEDIA commit removes it.
The composers now write `dialogControl = "Ka0sMedia_*"`. No authored code or test pins `LSM30_*` on a row,
and the host's `LSMValues` is the library's own, so nothing the addon supplies moved.

## Gate

Icons: re-copied whole, then `tools/prune-icons.lua` at the tag kept 6 files and removed 5834, for the
declaration `clear, close, copy, eye, settings`.

`ka0s-bounded luacheck .`: 0 warnings / 0 errors in 90 files. `ka0s-bounded lua tests/run.lua`: 565 passed,
0 failed, 1 skipped, 566 total.
