Delta: LibKa0s v1.58.0 -> v1.60.0

# Re-vendor delta

Written per `revendor-libka0s` Step 3, for plan item DR-PF-01 of the 2026-09-25 diagnostics rollout
(`Ka0sAddonsCommonTasks/docs/2026-09-25-DIAGNOSTICS_COMMAND/`, milestone M3). Every figure below
carries the command that produced it. `<tag>` is `git -C ../LibKa0s archive v1.60.0 LibKa0s testkit`
extracted into a scratch folder outside this repo.

## Tag

v1.60.0 (`bed0eb1`) is the newest tag in `../LibKa0s`, read with `git archive`, never checked out.
The range spans two releases, because this addon skipped v1.59.0 (it was re-vendored into
AuraMaster only).

```sh
git -C ../LibKa0s log --oneline v1.58.0..v1.60.0 | wc -l      # 18 commits
```

## 3a. Claimed version, and the base

```sh
grep -n '[Bb]undles' CLAUDE.md
# 39:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.58.0 (MIT).
```

The base is **v1.58.0**, which matches the newest bundle, `docs/revendor/2026-09-25-v1.58.0/`.

## 3b/3c. Actual version, and the per-file minor delta

```sh
grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR *= *("[^"]+", *)?[0-9]+' libs/LibKa0s/*.lua     # vendored
grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR *= *("[^"]+", *)?[0-9]+' <tag>/LibKa0s/*.lua     # tag
grep -n 'Script file' <tag>/LibKa0s/LibKa0s.xml                                         # 22 files
```

The vendored minors agree with the v1.58.0 CHANGELOG block, so the line and the bytes agree.

| File | Constant | v1.58.0 (vendored) | v1.60.0 (tag) |
|---|---|---|---|
| `WidgetsDragHandle.lua` | `DRAG_MINOR` | 2 | **3** (v1.59.0) |
| `DebugLog.lua` | `MINOR` | 13 | **14** |
| `DebugLogDiagnostics.lua` | `DIAG_MINOR` | absent | **1** (new file, DebugLog major) |
| `Slash.lua` | `MINOR` | 15 | **16** |
| every other file | -- | unchanged | unchanged |

No `NEEDS_*` floor rises and no major is added. The consumer is behind on nothing after the copy,
so there is no cross-major skew.

## 3d. Both diffs

```sh
diff -rq --strip-trailing-cr <tag>/LibKa0s libs/LibKa0s
# DebugLog.lua, LibKa0s.xml, Slash.lua, WidgetsDragHandle.lua differ; Only in <tag>: DebugLogDiagnostics.lua
diff -rq --strip-trailing-cr <tag>/testkit tests/_kit
# README.md, framework.lua differ; Only in <tag>: test_diagnostics_contract.lua
```

Content differs only where the library moved. There is no `Only in libs/LibKa0s` or
`Only in tests/_kit` line, so nothing is deleted.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' --include='*.lua' . | grep -vE '^(\./)?(libs|tests)/'
```

Consumed: Env (`core/EnvSetup.lua:10`), Media (`core/MediaSetup.lua:16`), Lifecycle
(`core/LifecycleSetup.lua:17`), DebugLog (`core/DebugLogSetup.lua:11`), Compat (`core/Compat.lua:13`),
Core (`core/CoreSetup.lua:16`), Bus (`core/Bus.lua:40`), Launcher (`core/LauncherSetup.lua:42`), Perf
(`core/PerfSetup.lua:10`), Options (`settings/OptionsSetup.lua:38`), Schema (`settings/Schema.lua:262`),
Slash (`settings/Schema.lua:360`, `settings/Slash.lua:17`). Widgets (and so `WidgetsDragHandle.lua`)
is reached only by the library itself; this addon has no DragHandle strip (its own Anchor grips).

## 3f. Kit revision, and the pairing rule

```sh
grep -n 'Kit.VERSION =' <tag>/testkit/framework.lua tests/_kit/framework.lua
# tag: 27; vendored: 26
```

Revision **26 -> 27** (the shared `test_diagnostics_contract.lua`). Both payloads are copied whole in
one commit, which satisfies the pairing rule by construction.

## 3g. Contract delta

Majors to read = (minor moved) intersected with (consumed) = `DebugLog`, `Slash`. Read from
`git -C ../LibKa0s show v1.60.0:docs/api/DebugLog/version-14.1-docs.md` (Compatibility, `:605-619`),
`.../Slash/version-16-docs.md` (Compatibility, `:713-722`) and the CHANGELOG's *What a consumer owes
on re-vendoring v1.60.0*. `grep -rn '__Attach' --include='*.lua' . --exclude-dir=libs --exclude-dir=_kit`
finds no attach site in this addon.

| Major | What moved | Reaches this addon as |
|---|---|---|
| DebugLog 14.1 | the buffer 1500 -> 3000 lines, slack 64 -> 128; `TIME_COPY`; `RunDiagnostics`, `BuildDiagnostics`, `DebugVerb` on every instance; descriptor fields `brandName`, `diagnostics` | the console keeps 3000 lines unasked. No host suite writes a 1500 literal (`grep -rn '1500\|MAX_BUFFER' tests/*.lua` is empty). **The library-absent stub in `core/DebugLogSetup.lua` is an instance surface**, so `test_surface_parity`'s DebugLog case goes red until it gains the three members |
| Slash 16 | `lib.LIVE_VERBS` gains `diagnostics` | this addon passes a **literal** `liveVerbs` (`LIVE_WHILE_DISABLED`, `settings/Slash.lua:90`), so it keeps its own set until it adds the verb |
| Kit 27 | `test_diagnostics_contract` | `tests/run.lua` must list it or the kit inventory fails; with `Kit.diagnostics` unset it is one declared skip |

### Blockers

The stub parity is a contract a re-vendor cannot land without, so it is fixed in the copy's commit,
per the changelog: `RunDiagnostics` prints `L["%s is unavailable: the LibKa0s library did not load."]`
with `/pfe diagnostics`, writes nothing and returns 0; `BuildDiagnostics` and `DebugVerb` are carried
beside it. The same commit adds `diagnostics` to `LIVE_WHILE_DISABLED` (the plan's C1 host copy) and
the kit suite to `tests/run.lua`. No decision is needed for any of them.
