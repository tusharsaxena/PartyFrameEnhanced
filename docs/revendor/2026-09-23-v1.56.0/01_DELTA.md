Delta: LibKa0s v1.55.0 -> v1.56.0

# Re-vendor delta

Written per `revendor-libka0s` Step 3 (the local `../wow-addon/commands/revendor-libka0s.md`, as
amended by WA-01), for plan item RV-PF of the 2026-09-23 review and standards-audit remediation.
Every figure below carries the command that produced it. `<tag>` is
`git -C ../LibKa0s archive v1.56.0 LibKa0s testkit` extracted into a scratch folder outside this
repo, and `<base>` is the same for v1.55.0.

## Tag

v1.56.0 is a **local** tag in `../LibKa0s` (not pushed). It was read with `git archive`, never
checked out.

```sh
git -C ../LibKa0s log --oneline v1.55.0..v1.56.0 | wc -l      # 53 commits (LK-01 .. LK-34, their review rounds, and the v1.55.0 follow-ups)
git -C ../LibKa0s diff --stat v1.55.0 v1.56.0 -- LibKa0s testkit docs/api | tail -1
# 65 files changed, 10441 insertions(+), 884 deletions(-)
```

## 3a. Claimed version, and the base

```sh
grep -n '[Bb]undles' CLAUDE.md
# 38:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.55.0 (MIT).
c=$(git log -1 --format=%H -- libs/LibKa0s tests/_kit)          # e331135 Re-vendor LibKa0s v1.55.0
git show "$c:CLAUDE.md" | grep -oE 'Bundles \[LibKa0s\]\([^)]*\) v[0-9]+\.[0-9]+\.[0-9]+'
# Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.55.0
git log --format='%h %s' "$c..HEAD" -- CLAUDE.md                  # (no output: no roll since)
diff -rq <base>/LibKa0s libs/LibKa0s && diff -rq <base>/testkit tests/_kit && echo payload-matches
# payload-matches
```

The base is **v1.55.0**: the provenance line, the last payload commit and the bytes on disk agree.

Step 0 pre-flight: the newest existing bundle, `docs/revendor/2026-09-23-v1.55.0/`, states base
v1.54.2 on line 1, and `git show e331135^:CLAUDE.md` names v1.54.2. No base correction is owed.

## 3b/3c. Actual version, and the per-file minor delta

```sh
for f in $(grep -oE 'file="[^"]+\.lua"' <tag>/LibKa0s/LibKa0s.xml | cut -d'"' -f2); do
  grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR *= *("[^"]+", *)?[0-9]+' libs/LibKa0s/$f <tag>/LibKa0s/$f
done
```

| File | Constant | v1.55.0 (vendored) | v1.56.0 (tag) |
|---|---|---|---|
| `Core.lua` | `MINOR` | 7 | **8** |
| `Env.lua` | `MINOR` | 1 | 1 |
| `Compat.lua` | `MINOR` | 1 | 1 |
| `Lifecycle.lua` | `MINOR` | 1 | **2** |
| `Bus.lua` | `MINOR` | 1 | **2** |
| `Schema.lua` | `MINOR` | 1 | **2** |
| `Pool.lua` | `MINOR` | 3 | 3 |
| `Item.lua` | `MINOR` | 1 | **2** |
| `Media.lua` | `MINOR` | 3 | **4** |
| `Widgets.lua` | `MINOR` | 9 | **10** |
| `WidgetsDragHandle.lua` | `DRAG_MINOR` | 2 | 2 |
| `DebugLog.lua` | `MINOR` | 12 | **13** |
| `Slash.lua` | `MINOR` | 14 | **15** |
| `Launcher.lua` | `MINOR` | 1 | **2** |
| `Options.lua` | `MINOR` | 23 | **24** |
| `OptionsWidgets.lua` | `WIDGETS_MINOR` | 30 | **31** |
| `OptionsTabs.lua` | `TABS_MINOR` | 3 | **4** |
| `OptionsCompose.lua` | `COMPOSE_MINOR` | 7 | 7 |
| `OptionsScroll.lua` | `SCROLL_MINOR` | 3 | **4** |
| `Perf.lua` | `MINOR` | 12 | **13** |
| `PerfPanel.lua` | `PANEL_MINOR` | 5 | 5 |

The claim (v1.55.0) and the vendored minors agree. No file is new in this range (every row has an
`old` value), and no vendored file is ahead of or behind the tag on a mixed basis: every file moves
forward together, so there is **no cross-major skew**. The composite keys move Options
23.30.3.7.3 -> 24.31.4.7.4, Perf 12.5 -> 13.5 and Widgets 9.2 -> 10.2. The library's own
`CHANGELOG.md` v1.56.0 block calls the release additive: no `NEEDS_*` floor rises and no major
changes.

## 3d. Both diffs

```sh
diff -rq --strip-trailing-cr <tag>/LibKa0s libs/LibKa0s     # content
diff -rq                     <tag>/LibKa0s libs/LibKa0s     # bytes
diff -rq --strip-trailing-cr <tag>/testkit tests/_kit
diff -rq                     <tag>/testkit tests/_kit
```

Taken before the copy:

- `libs/LibKa0s`: content and bytes agree on the same list, the fifteen files whose minor moved in
  3c (`Bus`, `Core`, `DebugLog`, `Item`, `Launcher`, `Lifecycle`, `Media`, `Options`,
  `OptionsScroll`, `OptionsTabs`, `OptionsWidgets`, `Perf`, `Schema`, `Slash`, `Widgets`). Nothing
  is `Only in` either side, so nothing is added or deleted.
- `tests/_kit`: content and bytes agree on the same list. `Only in <tag>`: `asserts.lua`,
  `mock_events.lua`, `prose_lists.lua`. Differing: `README.md`, `framework.lua`, `mock_base.lua`,
  `mock_record.lua`, `run-automated-tests.sh`, `test_eol.lua`, `test_layout_cap.lua`,
  `test_prose.lua`. Nothing is `Only in tests/_kit`.

No line-ending-only drift in either payload (the byte and content lists are identical). After the
copy, `diff -r <tag>/LibKa0s libs/LibKa0s` and `diff -r <tag>/testkit tests/_kit` are both empty,
and `tests/_kit/run-automated-tests.sh` keeps mode 100755.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -vE '^(\./)?(libs|tests)/'
```

| Major | Lookup site(s) |
|---|---|
| `LibKa0s-Core-1.0` | `core/CoreSetup.lua:15` |
| `LibKa0s-Env-1.0` | `core/EnvSetup.lua:10` |
| `LibKa0s-Compat-1.0` | `core/Compat.lua:13` |
| `LibKa0s-Bus-1.0` | `core/Bus.lua:40` |
| `LibKa0s-Media-1.0` | `core/MediaSetup.lua:16` |
| `LibKa0s-Lifecycle-1.0` | `core/LifecycleSetup.lua:17` |
| `LibKa0s-DebugLog-1.0` | `core/DebugLogSetup.lua:11` |
| `LibKa0s-Launcher-1.0` | `core/LauncherSetup.lua:36` |
| `LibKa0s-Perf-1.0` | `core/PerfSetup.lua:10` |
| `LibKa0s-Slash-1.0` | `settings/Slash.lua:16`, `settings/Schema.lua:294` |
| `LibKa0s-Options-1.0` | `settings/OptionsSetup.lua:37` |

Unconsumed majors in the payload: `Pool`, `Item`, `Widgets` (reached transitively through the
library) and `Schema` (declined at v1.55.0 as issue #14; its adoption is this addon's M3 item
PF-11, which v1.56.0's `writeThrough` was built for).

## 3f. Kit revision, and the pairing rule

```sh
grep -n 'Kit.VERSION' <tag>/testkit/framework.lua tests/_kit/framework.lua
# <tag>/testkit/framework.lua:20:Kit.VERSION = 26
# tests/_kit/framework.lua:20:Kit.VERSION = 25
```

Kit revision **25 -> 26**. Both payloads are copied whole in one commit, which satisfies the pairing
rule by construction (a consumer on LibKa0s v1.9.0 or newer takes kit revision 11 or newer in the
same commit). Revision 26 peels the asserts into `asserts.lua` and the prose lists into
`prose_lists.lua`, adds `mock_events.lua` (a recording `EventRegistry`, `__badEvents`),
`Kit.assertErrorMatches` and `Kit.assertLibraryConstant`, and flips several fakes to the client's
behavior (below).

## 3g. Contract delta

Majors to read = (minor moved, per 3c) intersected with (consumed, per 3e) = `Core`, `Lifecycle`,
`Bus`, `Media`, `DebugLog`, `Slash`, `Launcher`, `Options`, `Perf`. Read from each superseded
document's `Superseded by` row (`git -C ../LibKa0s show v1.56.0:docs/api/<Major>/version-<old>-docs.md`,
line 15 or 16) and from `CHANGELOG.md`'s v1.56.0 block, *What a consumer owes on re-vendoring
v1.56.0* (`git -C ../LibKa0s show v1.56.0:CHANGELOG.md`).

```sh
grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=Libs --exclude-dir=_kit
# (no output: this addon hands the library no __Attach* members)
```

| Major | What moved | Reaches this addon as |
|---|---|---|
| Core 8 | `printer.Format` survives a secret in a numeric slot; new `SafeRegisterEvent` / `SafeRegisterUnitEvent` / `SafeRegisterEvents` | a fix for free; the new family is an opt-in (M3 item PF-10). `tests/test_surface_parity.lua`'s Core case compares the host stub with the host live table and stays green |
| Lifecycle 2 | documents and pins the nested-edge behavior; code unchanged | nothing |
| Bus 2 | tracking wrappers re-stamped at every edge after a newer AceEvent-3.0 re-embed | a fix for free; `Bus:New` and the catalog are unchanged |
| Media 4 | `RegisterLSM` flags the face western + ruRU and counts only what LSM holds | a fix for free |
| DebugLog 13 | the buffer trim is batched at the cap | a fix for free |
| Slash 15 | `CliSet` / `CliReset` print the write seam's refusal | arrives unasked; a CLI write the seam refuses now prints a line |
| Launcher 2 | optional `isEnabled` / `disabledLine` gate; missing-library notices print once, without the `[LibKa0s] ` prefix | the gate is opt-in; the notice change arrives unasked |
| Options 24.31.4.7.4 | `CreateOptionsPanel` parks in combat and replays at `PLAYER_REGEN_ENABLED`; `OpenOptionsPanel` answers a boolean; `RenderTabbedSchema` moves to `OptionsTabs.lua` and takes an optional `opts`; the drag throttles keep their own armed flag; page chrome stops leaking a widget per render | arrives unasked. This addon calls `NS.CreateOptionsPanel()` from `core/PartyFrameEnhanced.lua:192` with no park of its own (its `regenWatch` frame at `core/PartyFrameEnhanced.lua:116` serves the secure-write queue, not the panel), so there is no host park to delete. The four-argument `RenderTabbedSchema` call (`settings/General.lua:222`, `settings/ElementRows.lua:149`) is unchanged |
| Perf 13 | raw `false` state fields; depth reset at windows | a fix for free |

No host-supplied member's call site moved, and no surface this addon uses changed what it requires
back. The kit contract does move (revision 26), and the owner's standing ruling is that a red it
causes is fixed in the addon, never by weakening an assertion. Its flips are recorded under *Suite
after the copy*.

### Blockers

None.

## Suite after the copy

```sh
/home/tushar/.claude/wow-addon/bin/ka0s-bounded luacheck .          # 0 warnings / 0 errors in 71 files
/home/tushar/.claude/wow-addon/bin/ka0s-bounded lua5.1 tests/run.lua
# 280 passed, 9 failed, 0 skipped, 289 total
/home/tushar/.claude/wow-addon/bin/ka0s-bounded lizard -l lua -x "./libs/*" -x "./tests/_kit/*" -C 15 -w .
# (no output: no function above CCN 15)
```

The baseline at v1.55.0 was 289 passed, 0 failed. The nine reds are the stricter kit revision 26,
not the library:

| Case | Failure | Kit change behind it | Cleared by |
|---|---|---|---|
| `providers: hidden member frames and raid tokens are skipped` | `a hidden frame shows nobody (got <table>)` | `CreateFrame` starts frames shown (LK-05) | M3, at the latest PF-DOCS |
| `disabled:` the baseline; every registration UNREGISTERED; re-enabled rebuilds; two holds, one latch; leaves the world enabled (5 cases) | `tests/test_disabled.lua:32: attempt to index field 'target' (a nil value)` | `EventRegistry` callbacks are recorded in `__registrations()` as kind `callback`, with no frame target (LK-04) | PF-05 (the stand-down suite reads callback registrations) |
| `disabled: every frame that was on screen is hidden, and refused at the source` | `nothing of the addon's is left on screen (expected 0, got 8)` | `CreateFrame` starts frames shown, so the holders and fade frames count (LK-05) | PF-06 (and PF-04) |
| `disabled: no game event produces a write, a line, or a frame` | `tests/test_disabled.lua:149: attempt to index local 'bar' (a nil value)` | knock-on: `F_on` is filled by the baseline case, which fails at line 32 first (LK-04) | PF-05 |
| `optionssetup: Reset All resets the active profile only` | `every element rebuilds off the PROFILE message` | the AceDB fake raises and strips defaults as AceDB-3.0 does (LK-03) | M3, at the latest PF-DOCS |

`docs/test-cases.md` and the README test badge are regenerated by PF-DOCS, not by this commit.
