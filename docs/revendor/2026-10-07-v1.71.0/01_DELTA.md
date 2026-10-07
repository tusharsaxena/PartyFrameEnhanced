Delta: LibKa0s v1.70.0 -> v1.71.0

# 01 — Delta (PartyFrameEnhanced)

Item `RV-PF` of the 2026-10-07 review and standards audit remediation, branch
`feat/2026-10-07-review-audit-remediation`. A mechanical re-vendor under the owner's ruling for this
run (`OWNER_SCOPE.md` §5): copy both payloads whole, roll the provenance line, write this bundle; no
adoption interview and no GitHub issue filing. Copied from the **local** annotated tag `v1.71.0` (tag
object `3bf1b97`, commit `cb274a4`, not yet pushed) with
`git -C ../LibKa0s archive v1.71.0 LibKa0s testkit | tar -x -C <scratch>`, never a branch tip.

## 3a. Base

`grep -n '[Bb]undles' CLAUDE.md` -> `39:Bundles [LibKa0s](...) v1.70.0 (MIT).` The last commit touching
either payload is `735a111` (`chore: re-vendor LibKa0s v1.70.0`), and `diff -rq` of the v1.70.0 archive
against both payloads printed nothing before the copy. Base **v1.70.0**, from the provenance line (it
is also the library's previous tag, but the base is taken from the line).

`git -C ../LibKa0s log --oneline v1.70.0..v1.71.0`: 20 commits (the LineChart deviation merge, the
2026-10-07 audit bundles, LK-01..LK-10 and the LK-12 release). `git -C ../LibKa0s diff --stat v1.70.0
v1.71.0 -- LibKa0s testkit`: 10 files changed, 369 insertions, 140 deletions.

## 3b/3c. Per-file minors

| File | v1.70.0 | v1.71.0 | Why |
|---|---|---|---|
| `Env.lua` (`LibKa0s-Env-1.0`) | 1 | **2** | `GetAddOnMetadata` drops the dead bare-global rung (LK-06) |
| `OptionsIdList.lua` (`LibKa0s-Options-1.0`) | 3 | **4** | the help-art guard asks `C_AddOns.IsAddOnLoaded` only (LK-06) |
| `Slash.lua` (`LibKa0s-Slash-1.0`) | 19 | **20** | one comment cites `slash-commands-§1` (LK-05) |
| `SlashParse.lua` (`LibKa0s-Slash-1.0`) | 1 | **2** | `ParseValue` refuses `nan` / `inf` / `-inf` / overflow on a number row (LK-05) |
| `WidgetsLineChart.lua` (`LibKa0s-Widgets-1.0`) | 2 | **3** | segments clipped to the plot; a render re-syncs the hover (LK-03) |
| `WidgetsAutocomplete.lua` (`LibKa0s-Widgets-1.0`) | 1 | **2** | hooks re-installed on every call; `maxRows` floored (LK-04) |
| the other 28 files | — | unchanged | |

34 constants, one per file the tag's `LibKa0s.xml` lists. No payload file added or removed,
`LibKa0s.xml` unchanged, so no TOC or `tests/run.lua` row is owed. No cross-major skew.

## 3d. Diffs (before the copy)

- `diff -rq <scratch>/LibKa0s libs/LibKa0s`: exactly the six files above.
- `diff -rq <scratch>/testkit tests/_kit`: `README.md`, `framework.lua`, `inventory.lua` differ, and
  `Only in <scratch>/testkit: secrets.lua`. No `Only in tests/_kit` line, so nothing is deleted.

## 3e. Consumption

The host looks up twelve majors (Bus, Compat, Core, DebugLog, Env, Launcher, Lifecycle, Media, Perf,
Options, Schema, Slash), unchanged from v1.68.1's map. Three of them moved: **Env**
(`core/EnvSetup.lua:10`), **Options** (`settings/OptionsSetup.lua:38`) and **Slash**
(`settings/Slash.lua:17`, `settings/Schema.lua:361`). Widgets is not looked up by the host (DebugLog's
console uses it internally), and neither the line chart nor the autocomplete is drawn here.

## 3f. Kit revision

`tests/_kit/framework.lua` `Kit.VERSION` 37 -> **38** (`docs/api/testkit/version-38-docs.md` at the tag):

- `--list`'s `## Totals` counts only cases that run; a declared skip moves to a `| Skipped | N |` row
  before Total (LK-01). This addon has one declared skip (the diagnostics contract's opt-out case), so
  `docs/test-cases.md` is regenerated in this commit: Total **455 -> 454**, a `Skipped | 1` row, and the
  README Tests badge becomes **454/454**, equal to the Totals row.
- `Kit.secret` / `Kit.isSecret` / `Kit.reveal` / `Kit.SECRET_ERROR` / `Kit.installSecretValue` in the
  new `secrets.lua` (LK-02). Opt-in: nothing installs `issecretvalue` and `Kit.expose` copies none of
  them, so no host behaviour changes.

Both payloads are copied whole in one commit, so the revision-11 pairing rule (kit revision paired with
the library tag it shipped in) holds by construction; `tests/test_vendor_sync.lua` asserts it.

## 3g. Contract delta — blockers

None.

- **Env 2.** `NS.Meta` calls `Env.GetAddOnMetadata(addonName, field)` when the library is present. On
  every admitted client `C_AddOns` exists, so the answer is unchanged; the bare-global rung dropped was
  dead. (This addon's own library-absent branch keeps an identical dead rung; that is item `PF-06`, not
  this re-vendor.)
- **OptionsIdList 4.** This addon draws no IdList help marks, and `settings/OptionsSetup.lua` already
  passes `addonName` in the descriptor (since v1.67.0), so the change is latent.
- **Slash 20.2.** `/pfe set <path> nan` (or `inf`) on a number row is now refused with the existing
  number reason before the clamp. The host's number rows (`settings/ElementRows.lua`) are all bounded;
  no host test pinned the acceptance of a non-finite value, and the suite is green.
- **WidgetsLineChart 3 / WidgetsAutocomplete 2.** Not consumed.

`grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit` is empty.

## 3h. Unrecorded tags

v1.69.0 and v1.70.0 were vendored by plain chore commits with no bundle. They are recorded in the span
bundle written first in the same commit, [`2026-10-07-v1.69.0-v1.70.0/`](../2026-10-07-v1.69.0-v1.70.0/01_DELTA.md).

## After the copy

`rm -rf libs/LibKa0s tests/_kit`, then `cp -r` of both payloads; `diff -r` of `<scratch>/LibKa0s` against
`libs/LibKa0s` and of `<scratch>/testkit` against `tests/_kit` are empty. `tests/_kit/run-automated-tests.sh`
stays recorded `100755`. In the same commit:

- `CLAUDE.md:39`'s provenance line rolled v1.70.0 -> v1.71.0.
- `docs/test-cases.md` regenerated under kit 38 and the README Tests badge set to 454/454.
- The live docs that restated the vendored tag or kit revision now point at the provenance line
  instead of naming one (`PFE-A-11`): `docs/ARCHITECTURE.md:23`, `DEPENDENCIES.md:32`, `docs/debug.md:16`,
  `docs/testing.md:93` and the comment at `tests/test_surface_parity.lua:200`. `docs/smoke-tests.md`'s
  INSTALL-4 step text names the provenance tag (its Result and the owner's results row are untouched).
- `docs/ARCHITECTURE.md`'s Overview re-vendor narrative (v1.46.1 .. v1.68.1, a second copy of this
  folder that had gone stale) is cut to one sentence pointing here (`PFE-A-05`).
