Delta: LibKa0s v1.57.0 -> v1.58.0

# Re-vendor delta

Written per `revendor-libka0s` Step 3 (the local `../wow-addon/commands/revendor-libka0s.md`), for
plan item M6-PF of the 2026-09-23 review and standards-audit remediation (milestone M6: launcher
left-click opens settings, right-click opens the options menu). Every figure below carries the
command that produced it. `<tag>` is `git -C ../LibKa0s archive v1.58.0 LibKa0s testkit` extracted
into a scratch folder outside this repo.

## Tag

v1.58.0 is a **local** tag in `../LibKa0s` (not pushed). It was read with `git archive`, never
checked out.

```sh
git -C ../LibKa0s log --oneline v1.57.0..v1.58.0 | wc -l      # 2 commits (LK-37 and its release run)
git -C ../LibKa0s diff --stat v1.57.0 v1.58.0 -- LibKa0s testkit docs/api | tail -1
# 5 files changed, 546 insertions(+), 97 deletions(-)
```

## 3a. Claimed version, and the base

```sh
grep -n '[Bb]undles' CLAUDE.md
# Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.57.0 (MIT).
git log -1 --format='%h %s' -- libs/LibKa0s tests/_kit
# cb959cc M5-PF: Re-vendor LibKa0s v1.57.0 and record its delta bundle
```

The base is **v1.57.0**: the provenance line and the last payload commit agree. After `rm -rf` and
a whole copy of the v1.58.0 payload, `git status` shows exactly one changed file under either
payload, `libs/LibKa0s/Launcher.lua`. The newest existing bundle,
`docs/revendor/2026-09-24-v1.57.0/`, states base v1.56.0 on line 1. No base correction is owed.

## 3b/3c. Actual version, and the per-file minor delta

| File | Constant | v1.57.0 (vendored) | v1.58.0 (tag) |
|---|---|---|---|
| `Launcher.lua` | `MINOR` | 3 | **4** |
| every other file | -- | unchanged | unchanged |

The library's `CHANGELOG.md` v1.58.0 block names the rest: `Core` 8, `Env` 1, `Compat` 1,
`Lifecycle` 2, `Bus` 2, `Schema` 2, `Pool` 3, `Item` 2, `Media` 4, `Widgets` 10 and
`WidgetsDragHandle` 2, `DebugLog` 13, `Slash` 15, `Options` key 24.31.4.7.4, `Perf` 13 and
`PerfPanel` 5. No `NEEDS_*` floor rises, no major is added, no file is added or removed, and there
is no cross-major skew.

## 3d. Both diffs

```sh
diff -rq <tag>/LibKa0s libs/LibKa0s       # before the copy: Launcher.lua differs
diff -r  <tag>/LibKa0s libs/LibKa0s       # after the copy: empty
diff -r  <tag>/testkit tests/_kit         # after the copy: empty (kit 26 on both sides)
git diff --numstat libs/                  # 163  94  libs/LibKa0s/Launcher.lua
```

`libs/LibKa0s/Launcher.lua` is the only file that moved. The kit is byte-identical to v1.57.0's.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-Launcher-1\.0", true\)' --include='*.lua' . | grep -vE '^(\./)?(libs|tests)/'
# core/LauncherSetup.lua:42
```

`LibKa0s-Launcher-1.0` is consumed at `core/LauncherSetup.lua`, the one file this release reaches.
The other consumed majors (Core, Env, Compat, Bus, Media, Lifecycle, DebugLog, Perf, Slash, Schema,
Options) did not move.

## 3f. Kit revision, and the pairing rule

```sh
grep -n 'Kit.VERSION =' <tag>/testkit/framework.lua tests/_kit/framework.lua
# both: Kit.VERSION = 26
```

Revision **26 -> 26**. Both payloads are still copied whole in one commit, which satisfies the
pairing rule by construction. The kit ships no `MenuUtil` fake (the library's `tests/mock_menu.lua`
is repo-local there), so this addon carries a verbatim copy at `tests/mock_menu.lua`.

## 3g. Contract delta

Majors to read = (minor moved) intersected with (consumed) = `Launcher`. Read from
`git -C ../LibKa0s show v1.58.0:docs/api/Launcher/version-4-docs.md` and the CHANGELOG's *What a
consumer owes on re-vendoring v1.58.0*.

| Major | What moved | Reaches this addon as |
|---|---|---|
| Launcher 4 | left-click always calls `openSettings`; right-click opens `MenuUtil.CreateContextMenu` built from the pairs `isEnabled`+`setEnabled`, `isLocked`+`toggleLock`, `isTestMode`+`toggleTestMode`, `isWindowShown`+`toggleWindow`, grayed while disabled; `onClick`, `leftClickLabel`, `disabledLine`, `slash` retired and ignored; tooltip hints fixed to `Left-click: Open settings` / `Right-click: Options menu` | **arrives unasked**: the left click stops toggling the lock (the rung-(b) `onClick` is ignored) and opens the panel; the disabled refusal is gone; the hints change. Until a pair is passed the right click still opens the panel. **Owed by launcher-§2** (standard v2.67.0): `setEnabled` beside `isEnabled`, and `toggleLock` beside `isLocked`, each the slash verb's own handler; delete `onClick`, `leftClickLabel` and `disabledLine`. No test-mode or window pair: this addon has neither |

`members-4.json` lists the surface `members-3.json` did (only `versionKey` and the minor differ), so
no degradation stub moves.

### Blockers

None. The contract change is the adoption M6 names, and it lands in the same commit, because the
payload alone turns seven of this addon's cases red (they pinned rung (b), the disabled refusal and
minor 3's hints) and the green gate holds for every commit.

## Suite after the copy (before the adoption)

Every run through `/home/tushar/.claude/wow-addon/bin/ka0s-bounded`, from the repo root.

| Suite | Result |
|---|---|
| `luacheck .` | 0 warnings / 0 errors in 72 files |
| `lua5.1 tests/run.lua` | 341 passed, 7 failed (baseline at v1.57.0: 348 passed, 0 failed) |

The seven reds, all expected by the contract: `disabled: the launcher's LEFT click is refused and its
RIGHT click is not`; `launcher: LEFT click toggles the lock ... rung (b)`; `launcher: the left click
and /pfe unlock are the same seam`; the three tooltip cases pinning `Left-click: Unlock frame|Lock
frame|disabled -- /pfe enable`; and the left-click-label locale case.
