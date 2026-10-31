# Refresh 2: the v1.84.0 re-cut that deletes the border patch

The tag moved again before it was pushed (`git -C ../LibKa0s ls-remote --tags origin v1.84.0` prints
nothing), so this is a refresh under the re-vendor command's refresh rule: no new bundle folder, and line 1
of `01_DELTA.md` stays as it is.

- Old commit: `7a8bc0f133ed118d2c79c7c5288b97964e24fae5`, the commit Refresh 1 vendored. `diff -rq` of its
  payload against the vendored copy before this refresh was empty apart from the pruned icons.
- New commit: `b5229b876e803768322fb4d8c66be69f01c8e4a1`, from `git -C ../LibKa0s rev-parse 'v1.84.0^{commit}'`.
- Why: LK-M4, the owner's ruling of 2026-11-01 that `lib.__PatchLSM30Border` goes, with no stub left behind.

## Per-file minors

| File | Constant | Old | New |
|---|---|---|---|
| `Options.lua` | `MINOR` | 36 | 37 |
| `OptionsDrawer.lua` | `DRAWER_MINOR` | 3 | 4 |
| `OptionsMedia.lua` | `MEDIA_MINOR` | 2 | 3 |

Every other file keeps its minor. The test kit does not move, and `tests/_kit/` has no diff.

## Contract

`lib.__PatchLSM30Border` no longer exists in the library. This addon has no call of it to remove: the
M3-MEDIA commit `b1b2c4a` already took out the one at `settings/OptionsSetup.lua:176`, and no authored file
or test names it now. The mention in Refresh 1 stays, because a bundle records what was true on its date.

## Gate

Icons: re-copied whole, then `tools/prune-icons.lua` at the tag kept 6 files and removed 5834, for the
declaration `clear, close, copy, eye, settings`.

`ka0s-bounded luacheck .`: 0 warnings / 0 errors in 90 files. `ka0s-bounded lua tests/run.lua`: 566 passed,
0 failed, 1 skipped, 567 total.
