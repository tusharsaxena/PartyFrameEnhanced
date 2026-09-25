Delta: LibKa0s v1.56.0 -> v1.57.0

# Re-vendor delta

Written per `revendor-libka0s` Step 3 (the local `../wow-addon/commands/revendor-libka0s.md`, as
amended by WA-01), for plan item M5-PF of the 2026-09-23 review and standards-audit remediation
(milestone M5, the always-on launcher status tooltip). Every figure below carries the command that
produced it. `<tag>` is `git -C ../LibKa0s archive v1.57.0 LibKa0s testkit` extracted into a
scratch folder outside this repo.

## Tag

v1.57.0 is a **local** tag in `../LibKa0s` (not pushed). It was read with `git archive`, never
checked out.

```sh
git -C ../LibKa0s log --oneline v1.56.0..v1.57.0 | wc -l      # 2 commits (LK-36 and its release run)
git -C ../LibKa0s diff --stat v1.56.0 v1.57.0 -- LibKa0s testkit docs/api | tail -1
# 5 files changed, 433 insertions(+), 7 deletions(-)
```

## 3a. Claimed version, and the base

```sh
grep -n '[Bb]undles' CLAUDE.md
# Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.56.0 (MIT).
git log -1 --format='%h %s' -- libs/LibKa0s tests/_kit
# 3edf817 RV-PF: Re-vendor LibKa0s v1.56.0 and record its delta bundle
```

The base is **v1.56.0**: the provenance line and the last payload commit agree, and after `rm -rf`
and a whole copy of the v1.57.0 payload `git status` shows exactly one changed file under either
payload, `libs/LibKa0s/Launcher.lua`. Every other vendored byte already was v1.56.0's, which
v1.57.0 left untouched. The newest existing bundle, `docs/revendor/2026-09-23-v1.56.0/`, states
base v1.55.0 on line 1, and `git show 3edf817^:CLAUDE.md` names v1.55.0. No base correction is
owed.

## 3b/3c. Actual version, and the per-file minor delta

| File | Constant | v1.56.0 (vendored) | v1.57.0 (tag) |
|---|---|---|---|
| `Launcher.lua` | `MINOR` | 2 | **3** |
| every other file | -- | unchanged | unchanged |

The library's `CHANGELOG.md` v1.57.0 block names the rest: `Core` 8, `Env` 1, `Compat` 1,
`Lifecycle` 2, `Bus` 2, `Schema` 2, `Pool` 3, `Item` 2, `Media` 4, `Widgets` 10 and
`WidgetsDragHandle` 2, `DebugLog` 13, `Slash` 15, `Options` key 24.31.4.7.4, `Perf` 13 and
`PerfPanel` 5. No `NEEDS_*` floor rises, no major is added, no file is added or removed, and there
is no cross-major skew.

## 3d. Both diffs

```sh
diff -rq <tag>/LibKa0s libs/LibKa0s       # before the copy: Launcher.lua differs
diff -r  <tag>/LibKa0s libs/LibKa0s       # after the copy: empty
diff -r  <tag>/testkit tests/_kit         # after the copy: empty (kit 26 on both sides)
```

`libs/LibKa0s/Launcher.lua` is the only file that moved (109 insertions, 4 deletions). The kit is
byte-identical to v1.56.0's, and `tests/_kit/run-automated-tests.sh` keeps mode 100755.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -vE '^(\./)?(libs|tests)/'
```

`LibKa0s-Launcher-1.0` is consumed at `core/LauncherSetup.lua:38`, the one file this release
reaches. The other consumed majors (Core, Env, Compat, Bus, Media, Lifecycle, DebugLog, Perf,
Slash, Schema, Options) did not move.

## 3f. Kit revision, and the pairing rule

```sh
grep -n 'Kit.VERSION' <tag>/testkit/framework.lua tests/_kit/framework.lua
# both: Kit.VERSION = 26
```

Revision **26 -> 26**. Both payloads are still copied whole in one commit, which satisfies the
pairing rule by construction.

## 3g. Contract delta

Majors to read = (minor moved) intersected with (consumed) = `Launcher`. Read from
`git -C ../LibKa0s show v1.57.0:docs/api/Launcher/version-3-docs.md` and the CHANGELOG's *What a
consumer owes on re-vendoring v1.57.0*.

```sh
grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit
# (no output: this addon hands the library no __Attach* members)
```

| Major | What moved | Reaches this addon as |
|---|---|---|
| Launcher 3 | the LDB object's `OnTooltipShow` is always the library's `drawTooltip`; five new optional descriptor fields (`version`, `isLocked`, `isTestMode`, `leftClickLabel`, `slash`); `onTooltipShow` now appends between the status block and the hints; fourteen `TOOLTIP_*` strings | **arrives unasked**: the button answers a hover with the library's tooltip. Before this re-vendor the addon passed no `onTooltipShow`, so its button had no tooltip at all, and nothing of the host's has to be deleted. **Owed by launcher-§1** (standard v2.66.0): `version`, `leftClickLabel` (rung b), `isLocked` (the addon has a lock), and a truthful *Enabled* line, which needs `isEnabled` + `disabledLine`. The addon gated the click inside `NS.ToggleLock` and passed neither. No `isTestMode`: the addon has none (options-ui-§15's exemption) |

No member was added (`members-3.json` lists the surface `members-2.json` did), so no degradation
stub moves, and no host-supplied member's call site moved.

### Blockers

None. The owed adoption is the second M5-PF commit.

## Suite after the copy

Every run through `/home/tushar/.claude/wow-addon/bin/ka0s-bounded`, from the repo root.

| Suite | Result |
|---|---|
| `luacheck .` | 0 warnings / 0 errors in 72 files |
| `lua5.1 tests/run.lua` | 342 passed, 0 failed, 0 skipped (baseline at v1.56.0: the same 342, 0 failed) |
| `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" -C 15 -w .` | no function above CCN 15 |

No red: no case of this addon's asserted on the LDB object's `OnTooltipShow`.
