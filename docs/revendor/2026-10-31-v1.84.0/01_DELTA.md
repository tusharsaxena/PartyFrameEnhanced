Delta: LibKa0s v1.83.0 -> v1.84.0

# Delta (PartyFrameEnhanced)

Taken from the local tag `v1.84.0` (commit `e917ccd`, not on origin yet) with
`git -C ../LibKa0s archive v1.84.0 LibKa0s testkit tools`. A run of the owner's M2 library release
(Ka0sAddonsCommonTasks `docs/2026-10-31-FINDINGS_REMEDIATION/M2_LIBRARY_RELEASE.md`), so nobody was
interviewed.

## 3a. Claimed version

`grep -n '[Bb]undles' CLAUDE.md` names v1.83.0, and the last payload commit's `CLAUDE.md` names
v1.83.0 too. `diff -rq --strip-trailing-cr` of the v1.83.0 extract against both payloads shows only
the pruned icons, so the base is v1.83.0. No base correction: the newest single-tag bundle
(`2026-10-24-v1.77.0`) states v1.76.0, which the 3a walk confirmed at that re-vendor.

## 3b, 3c. Minors (`LibKa0s.xml` at the tag, old against new)

No file is behind its claim, so there is no cross-major skew. Unchanged files are left out.

| File | Old | New |
|---|---|---|
| `Schema.lua` | 2 | 3 |
| `Skin.lua` | 10 | 11 |
| `SkinOwnerTokens.lua` | new | 1 |
| `SkinDefs.lua` | 18 | 19 |
| `SkinDefsOthers.lua` | new | 1 |
| `Charts.lua` | new | 1 |
| `ChartsRender.lua` | new | 1 |
| `WidgetsDragHandle.lua` | 8 | 10 |
| `DebugLogDiagnostics.lua` | 5 | 6 |
| `Slash.lua` | 20 | 21 |
| `Options.lua` | 34 | 35 |
| `OptionsWidgets.lua` | 38 | 40 |
| `OptionsFlow.lua` | new | 2 |
| `OptionsIds.lua` | 5 | 6 |
| `OptionsIdSuggest.lua` | new | 1 |
| `OptionsTabs.lua` | 11 | 13 |
| `OptionsTabbed.lua` | new | 2 |
| `OptionsCompose.lua` | 14 | 15 |
| `OptionsSkinPicker.lua` | 4 | 5 |
| `OptionsSkinPickerRows.lua` | new | 1 |
| `SimPanel.lua` | 8 | 9 |
| `SimPanelRender.lua` | new | 1 |

## 3d. Diffs

Before the copy, the content differences are the eight peels' moved bytes, the new files, and the
icons the addon does not declare. Nothing was forked.

## 3e. Consumption

`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)'` over the addon outside `libs/` and `tests/`:
Media, Env, Lifecycle, Core, DebugLog, Launcher, Compat, Bus, Perf, Skin, Slash, Options, Schema.
Charts, Sim, Glow, Item, Pool and Toast have no lookup. No unrecorded site.

## 3f. Kit

`Kit.VERSION` 46 -> 47 (`testkit/mock_ace.lua` is new). Both payloads move in one commit, per the
pairing rule.

## 3g. Contract delta

Read `docs/api/<Major>/` old against new for Options, Schema, Slash and Skin, the moved majors this
addon looks up. Only version rows changed under existing surfaces; the release's own changelog calls
every new surface additive. No `__Attach*` member is supplied by this addon.

### Blockers

- `O.PositionBlock` is a new public member (`docs/api/Options/version-35.4.40.2.6.1.7.13.2.3.15.9.4.3.6.5.5.1.1.1-docs.md`),
  and `Kit.assertSurfaceParity` requires the degradation stub to answer it or exempt it. Fixed in the
  re-vendor commit.

## 3h. Unrecorded tags

The listing printed nothing, so there is no span bundle. `2026-10-31-v1.80.0-v1.83.0` already covers
those tags.

## 3i. Icons

`LibKa0s icons: clear, close, copy, eye, settings.` kept, directly under the provenance line. The
releasing table's library-drawn set is unchanged at the tag. No provenance split.

## 3j. Icon assumptions in tests

`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests` finds `tests/test_optionssetup.lua:260` and `:294`,
which name `info.tga`. These were already reconciled by v1.75.0's re-vendor; the gate below decides
whether they still hold.
