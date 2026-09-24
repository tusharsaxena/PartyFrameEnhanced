Delta: LibKa0s v1.37.0 -> v1.54.2 (span: v1.37.0 v1.38.0 v1.39.0 v1.42.0 v1.43.0 v1.44.0 v1.45.0 v1.46.1 v1.47.0 v1.50.0 v1.51.0 v1.52.0 v1.53.0 v1.54.2)

# 01 - Delta: the lapsed span, LibKa0s v1.37.0 through v1.54.2

A consolidated span bundle (`audit-review-history`, `revendor-libka0s` Step 3h as amended by
WA-01), written 2026-09-24 as remediation item PF-24 of the 2026-09-23 review and standards-audit
remediation. Between the scaffold on 2026-09-15 and the store's first bundle,
`docs/revendor/2026-09-23-v1.55.0/`, this repo vendored 14 LibKa0s tags and wrote no bundle for
any of them. This folder records all 14 at once. It holds `01_DELTA.md` and `05_SUMMARY.md` only:
the tags were carried by sweeps and feature work, and nothing about them is decided in retrospect.

**The true previous base is v1.36.1.** It is the tag the `CLAUDE.md` provenance line named at
`246dba6` (2026-09-15, *Scaffold the standards skeleton*). That commit is this addon's first
vendoring, not a re-vendor: there was no earlier payload to replace. So v1.36.1 is the span's
base and does not appear on its line. The span runs from the first re-vendored tag, v1.37.0, to
the last, v1.54.2. v1.54.2 is also the base that the frozen `docs/revendor/2026-09-23-v1.55.0/`
bundle names (`v1.54.2 -> v1.55.0`), and that base is correct (see v1.54.2 below).

## How the tag list was derived

The listing is the amended re-vendor check (`AUDIT.md`, *Check every re-vendor commit has its
bundle*, WS-01; `revendor-libka0s` Step 3h, WA-01), run before this bundle was written. It used
the horizon the 2026-09-23 audit used, the scaffold day `docs/audits/2026-09-15/` records, instead
of the store's first bundle:

```sh
horizon=2026-09-15
tag_at() {
  git show "$1:CLAUDE.md" 2>/dev/null |
    grep -oE 'Bundles \[LibKa0s\]\([^)]*\) v[0-9]+\.[0-9]+\.[0-9]+' |
    grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1
}
{ git log --since="$horizon 00:00" --format=%H -- libs/LibKa0s tests/_kit
  git log --since="$horizon 00:00" --format=%H -- CLAUDE.md | while read -r c; do
    [ "$(tag_at "$c")" != "$(tag_at "$c^")" ] && echo "$c"
  done
} | while read -r c; do tag_at "$c"; done | sed '/^$/d' | sort -uV > vendored.txt
# (recorded.txt: the audit's loop over docs/revendor/*/)
grep -vxF -f recorded.txt vendored.txt
```

```
vendored:   v1.36.1 v1.37.0 v1.38.0 v1.39.0 v1.42.0 v1.43.0 v1.44.0 v1.45.0 v1.46.1 v1.47.0
            v1.50.0 v1.51.0 v1.52.0 v1.53.0 v1.54.2 v1.55.0 v1.56.0
recorded:   v1.55.0 v1.56.0
unrecorded: v1.36.1 v1.37.0 v1.38.0 v1.39.0 v1.42.0 v1.43.0 v1.44.0 v1.45.0 v1.46.1 v1.47.0
            v1.50.0 v1.51.0 v1.52.0 v1.53.0 v1.54.2
```

v1.36.1 is the scaffold's first vendoring and the span's base, as stated above. The other 14 are
the span. The per-commit listing behind them:

```
git log --format='%h %ad %s' --date=short -- libs/LibKa0s tests/_kit
  7eea3d0 2026-09-22 Adopt the kit's US-English gate, and delete the copy this repo was keeping
  2a18e3b 2026-09-22 Re-vendor LibKa0s v1.53.0
  382b928 2026-09-22 Re-vendor LibKa0s v1.52.0
  e1fcef9 2026-09-22 Re-vendor LibKa0s v1.51.0
  9977587 2026-09-21 Re-vendor LibKa0s v1.50.0
  f14b096 2026-09-20 Re-vendor LibKa0s v1.47.0
  d40aee9 2026-09-19 Re-vendor LibKa0s v1.46.1
  c2577a5 2026-09-19 Re-vendor LibKa0s v1.45.0
  6e2f387 2026-09-19 Re-vendor LibKa0s v1.44.0
  f111ee0 2026-09-17 Re-vendor LibKa0s v1.43.0: kit revision 23 bounds every run and stops holding built instances
  a8e3a44 2026-09-17 Disabling the addon stands it down, and a perf run takes the same latch
  9089559 2026-09-16 Re-vendor LibKa0s v1.39.0: the Launcher major and the minimap seam
  d912a94 2026-09-16 Re-vendor LibKa0s v1.38.0: a bare /pfe opens the settings panel
  c381dc8 2026-09-16 Re-vendor LibKa0s v1.37.0; Test mode becomes a Master controls checkbox
  246dba6 2026-09-15 Scaffold the standards skeleton: TOC, LibKa0s seams, schema, slash, settings, harness
```

A subject grep would miss two of them. `a8e3a44` folded the v1.39.0 -> v1.42.0 re-vendor into
the Lifecycle feature commit, and `7eea3d0` is the kit-only v1.54.2 re-vendor. Its library bytes
are identical to v1.53.0 (`git -C ../LibKa0s diff --quiet v1.53.0 v1.54.2 -- LibKa0s` exits 0).
No provenance roll happened without a payload commit, so the `CLAUDE.md` branch of the walk adds
no commit. LibKa0s tags this repo never vendored (v1.36.2, v1.40.0, v1.41.0, v1.46.0, v1.48.0, v1.48.1,
v1.49.0, v1.49.1, v1.54.0, v1.54.1) are not on the span line: the addon never carried them, so
there is nothing to record.

Every carrier commit's payload is byte-identical to its tag. The tree hashes match for both
folders at all 14 commits (and at `246dba6` for v1.36.1):

```sh
[ "$(git rev-parse <c>:libs/LibKa0s)" = "$(git -C ../LibKa0s rev-parse <tag>:LibKa0s)" ] &&
[ "$(git rev-parse <c>:tests/_kit)"   = "$(git -C ../LibKa0s rev-parse <tag>:testkit)" ]
# lib:same kit:same, for every row of the table below
```

## The library across the span

```
git -C ../LibKa0s log --oneline v1.36.1..v1.54.2 | wc -l        # 81
git -C ../LibKa0s diff --stat v1.36.1 v1.54.2 -- LibKa0s testkit
  LibKa0s/Launcher.lua           |  295 ++++++
  LibKa0s/LibKa0s.xml            |    4 +
  LibKa0s/Lifecycle.lua          |  208 ++++
  LibKa0s/Options.lua            |  250 ++++-
  LibKa0s/OptionsCompose.lua     |   56 +-
  LibKa0s/OptionsTabs.lua        | 1197 ++++++++++++++++++++++
  LibKa0s/OptionsWidgets.lua     | 2172 ++++++++++++++++++++++------------------
  LibKa0s/Perf.lua               |  119 ++-
  LibKa0s/Slash.lua              |  177 +++-
  LibKa0s/WidgetsDragHandle.lua  |  520 ++++++++++
  testkit/README.md              |   97 +-
  testkit/framework.lua          |  320 +++++-
  testkit/mock_base.lua          |  305 +++---
  testkit/mock_record.lua        |  618 ++++++++++++
  testkit/run-automated-tests.sh |  110 +-
  testkit/test_prose.lua         |  335 +++++++
  16 files changed, 5530 insertions(+), 1253 deletions(-)
```

## Per tag: the carrier commit and the diff from the previous vendored tag

`<prev>` is the tag this repo carried before, not the library's previous tag. The stat is
`git -C ../LibKa0s diff --stat <prev> <tag> -- LibKa0s testkit | tail -1`.

| Tag | LibKa0s commit | Repo commit | Date | `diff --stat <prev> <tag>` | Files moved |
|---|---|---|---|---|---|
| v1.37.0 | `a7409f8` | `c381dc8` | 2026-09-16 | v1.36.1: 3 files, +29 -44 | Options, OptionsCompose, OptionsWidgets |
| v1.38.0 | `efcb4ba` | `d912a94` | 2026-09-16 | v1.37.0: 1 file, +11 -3 | Slash |
| v1.39.0 | `62040f3` | `9089559` | 2026-09-16 | v1.38.0: 6 files, +1343 -918 | Launcher (new), LibKa0s.xml, Options, OptionsCompose, OptionsTabs (new), OptionsWidgets |
| v1.42.0 | `d0751cb` | `a8e3a44` | 2026-09-17 | v1.39.0: 9 files, +1302 -203 | LibKa0s.xml, Lifecycle (new), Perf, Slash; kit README, framework, mock_base, mock_record (new), run-automated-tests.sh |
| v1.43.0 | `c091705` | `f111ee0` | 2026-09-17 | v1.42.0: 4 files, +371 -16 | kit only: README, framework, mock_base, run-automated-tests.sh |
| v1.44.0 | `7ae5b3b` | `6e2f387` | 2026-09-19 | v1.43.0: 1 file, +33 -3 | OptionsWidgets |
| v1.45.0 | `a7053ca` | `c2577a5` | 2026-09-19 | v1.44.0: 1 file, +93 -2 | OptionsWidgets |
| v1.46.1 | `6504429` | `d40aee9` | 2026-09-19 | v1.45.0: 3 files, +441 -42 | Options, OptionsTabs, OptionsWidgets |
| v1.47.0 | `a8feebe` | `f14b096` | 2026-09-20 | v1.46.1: 1 file, +331 -24 | OptionsWidgets |
| v1.50.0 | `c45833c` | `9977587` | 2026-09-21 | v1.47.0: 3 files, +887 -45 | LibKa0s.xml, OptionsWidgets, WidgetsDragHandle (new) |
| v1.51.0 | `1da039f` | `e1fcef9` | 2026-09-22 | v1.50.0: 1 file, +162 -16 | OptionsWidgets |
| v1.52.0 | `0beb76c` | `382b928` | 2026-09-22 | v1.51.0: 2 files, +205 -21 | Options, OptionsWidgets |
| v1.53.0 | `44758ed` | `2a18e3b` | 2026-09-22 | v1.52.0: 1 file, +21 -1 | OptionsWidgets |
| v1.54.2 | `85d32f2` | `7eea3d0` | 2026-09-22 | v1.53.0: 3 files, +388 -2 | kit only: README, framework, test_prose (new) |

The LibKa0s commit is `git -C ../LibKa0s rev-list -n1 <tag>`. The repo date is the carrier
commit's author date.

## Per-file minors at each tag

For each file `LibKa0s.xml` lists at v1.54.2:

```sh
git -C ../LibKa0s show <tag>:LibKa0s/<file> |
  grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR *= *("[^"]+", *)?[0-9]+' | head -1
git -C ../LibKa0s show <tag>:testkit/framework.lua | grep -oE '^Kit.VERSION *= *[0-9]+'
```

A dash means the file does not exist at that tag. The base column, v1.36.1, is the scaffold's
payload. A bold cell is a minor that moved from the column before it.

| File | v1.36.1 (base) | 1.37.0 | 1.38.0 | 1.39.0 | 1.42.0 | 1.43.0 | 1.44.0 | 1.45.0 | 1.46.1 | 1.47.0 | 1.50.0 | 1.51.0 | 1.52.0 | 1.53.0 | 1.54.2 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `Core.lua` | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 7 |
| `Env.lua` | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| `Lifecycle.lua` | - | - | - | - | **1** | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| `Pool.lua` | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 |
| `Item.lua` | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| `Media.lua` | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 |
| `Widgets.lua` | 9 | 9 | 9 | 9 | 9 | 9 | 9 | 9 | 9 | 9 | 9 | 9 | 9 | 9 | 9 |
| `WidgetsDragHandle.lua` (`DRAG_MINOR`) | - | - | - | - | - | - | - | - | - | - | **2** | 2 | 2 | 2 | 2 |
| `DebugLog.lua` | 12 | 12 | 12 | 12 | 12 | 12 | 12 | 12 | 12 | 12 | 12 | 12 | 12 | 12 | 12 |
| `Slash.lua` | 10 | 10 | **11** | 11 | **14** | 14 | 14 | 14 | 14 | 14 | 14 | 14 | 14 | 14 | 14 |
| `Launcher.lua` | - | - | - | **1** | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| `Options.lua` | 19 | **20** | 20 | **21** | 21 | 21 | 21 | 21 | **23** | 23 | 23 | 23 | 23 | 23 | 23 |
| `OptionsWidgets.lua` (`WIDGETS_MINOR`) | 18 | **19** | 19 | **20** | 20 | 20 | **21** | **22** | **23** | **24** | **27** | **28** | **29** | **30** | 30 |
| `OptionsTabs.lua` (`TABS_MINOR`) | - | - | - | **1** | 1 | 1 | 1 | 1 | **3** | 3 | 3 | 3 | 3 | 3 | 3 |
| `OptionsCompose.lua` (`COMPOSE_MINOR`) | 5 | **6** | 6 | **7** | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 7 |
| `OptionsScroll.lua` (`SCROLL_MINOR`) | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 |
| `Perf.lua` | 11 | 11 | 11 | 11 | **12** | 12 | 12 | 12 | 12 | 12 | 12 | 12 | 12 | 12 | 12 |
| `PerfPanel.lua` (`PANEL_MINOR`) | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 |
| kit revision (`Kit.VERSION`) | 21 | 21 | 21 | 21 | **22** | **23** | 23 | 23 | 23 | 23 | 23 | 23 | 23 | 23 | **24** |

No file moves backwards and no file was removed. Four files are new across the span: Launcher and
OptionsTabs at v1.39.0, Lifecycle at v1.42.0, and WidgetsDragHandle at v1.50.0. WidgetsDragHandle
arrived at minor 2 because the addon skipped v1.48.0 and v1.48.1. The v1.54.2 minors are the
`v1.54.2` column that `docs/revendor/2026-09-23-v1.55.0/01_DELTA.md` compares against.
