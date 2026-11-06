Delta: LibKa0s v1.85.0 -> v1.89.0

Part of Ka0sAddonsCommonTasks `docs/2026-11-06-REVENDOR_LIBKA0S_V1_89/` (item V89-PFE). The tag is pushed,
at library commit `0bd4839`. Extracted with `git -C ../LibKa0s archive v1.89.0 LibKa0s testkit tools`
into a scratch directory, never the working tree.

## Step 0 pre-flight

From the run's `inputs/step0-preflight.txt`:
`PartyFrameEnhanced  2026-11-01-v1.85.0  base v1.84.0  vendored-before v1.84.0@5f06c5b  ok`. No correction owed.

## Base (3a)

- `grep -n '[Bb]undles' CLAUDE.md` gives `41:Bundles [LibKa0s](…) v1.85.0 (MIT).`
- `git log -1 --format=%H -- libs/LibKa0s tests/_kit` gives `1cb3864`, whose `CLAUDE.md` line names v1.85.0.
  `git log "1cb3864..HEAD" -- CLAUDE.md` lists no roll since. The two agree: the base is **v1.85.0**.

## Actual version (3b)

`grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR …' libs/LibKa0s/*.lua` (64 constants) matches the v1.85.0 payload; the
line and the bytes agree.

## Per-file minors (3c), moved or new files only

The loop over the tag's `LibKa0s/LibKa0s.xml`, old against tag:

| File | old | new |
|---|---|---|
| Toast.lua | 3 | 4 |
| Widgets.lua | 22 | 23 |
| DebugLogDiagnostics.lua (`DIAG_MINOR`) | 6 | 7 |
| IconBrowserSources.lua (`LibKa0s-IconBrowser-1.0`) | (new) | 1 |
| IconBrowserWindow.lua (`WINDOW_MINOR`) | (new) | 1 |
| IconBrowser.lua (`BROWSER_MINOR`) | (new) | 1 |

No file is behind the tag on the copy (no cross-major skew). Library range: `git -C ../LibKa0s log --oneline
v1.85.0..v1.89.0` (31 commits: IconBrowser v1.86.0, cascading menus v1.87.0, toast stack v1.88.0, kit 51 v1.89.0).

## Diffs before the copy (3d)

`diff -rq --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s`, `media/icons` lines aside: `DebugLogDiagnostics.lua`,
`LibKa0s.xml`, `Toast.lua`, `Widgets.lua` differ; `IconBrowser.lua`, `IconBrowserSources.lua`,
`IconBrowserWindow.lua` only in the tag. Every `media/icons` line is `Only in <scratch>/…` (the undeclared icons).
No `Only in libs/LibKa0s` line, so nothing upstream removed survives here.
Kit: `diff -rq <scratch>/testkit tests/_kit`: `README.md`, `framework.lua`, `mock_ace.lua` differ.

## Consumption map (3e)

`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v /libs/ | grep -v /tests/`:
Env (`core/EnvSetup.lua:11`), Media (`core/MediaSetup.lua:16`), Core (`core/CoreSetup.lua:16`), Compat
(`core/Compat.lua:13`), Launcher (`core/LauncherSetup.lua:42`), DebugLog (`core/DebugLogSetup.lua:12`), Skin
(`core/Database.lua:117`, `core/SkinSetup.lua:71`), Lifecycle (`core/LifecycleSetup.lua:17`), Bus (`core/Bus.lua:40`,
`modules/Diagnostics.lua:219`), Perf (`core/PerfSetup.lua:10`), Slash (`settings/Slash.lua:17`,
`settings/Schema.lua:358`), Options (`settings/OptionsSetup.lua:38`), Schema (`settings/Schema.lua:262`).

Not looked up: Toast, Widgets (directly), IconBrowser, Glow, Charts, Pool, Item, Sim. No `W.ContextMenu` use site;
the only menu is the Launcher's, which the library draws through `MenuUtil` (`tests/mock_menu.lua`).

## Kit revision (3f)

`grep -n 'Kit.VERSION' <scratch>/testkit/framework.lua tests/_kit/framework.lua`: 50 -> **51**. Both payloads move
together in one commit, which keeps the pairing rule (v1.9.0+ needs kit 11+) by construction.

## Contract delta (3g)

Majors that moved a minor, intersected with this addon's lookups: **DebugLog** only (Diagnostics 6 -> 7). Toast and
Widgets moved but are not looked up; IconBrowser is new.

- `diff <(git -C ../LibKa0s show v1.85.0:docs/api/DebugLog/version-22.6.1.4-docs.md) <(git -C ../LibKa0s show
  v1.89.0:docs/api/DebugLog/version-22.7.1.4-docs.md)`: "No member change"; the report's `LibKa0s running:` line also
  lists IconBrowser when it runs. A host suite pinning `DebugLogDiagnostics 6` re-pins at 7; `grep -rn
  'DebugLogDiagnostics\|DIAG_MINOR' tests` (kit aside) finds no pin here.
- `git -C ../LibKa0s diff v1.85.0 v1.89.0 -- docs/api/Launcher/version-7-docs.md`: prose only (`R7-L1`, what
  `isSimMode` answers). This addon passes no `isSimMode`/`toggleSim` (`grep -n 'isSimMode\|toggleSim'
  core/LauncherSetup.lua` is empty).
- `grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit`: no site.
- Toast 4 owes a host's Toast stub `SetStack`, `Visible`, `FrameFor`; this addon has no Toast stub (`grep -rn Toast`
  outside libs/kit finds nothing).

### Blockers

None.

## Span check (3h)

The audit's listing (horizon 2026-09-23, both payload paths plus the `CLAUDE.md` rolls) prints nothing: every
vendored tag has a bundle. No span bundle.

## Icon declaration (3i)

`grep -n 'LibKa0s icons:' CLAUDE.md` gives `42:LibKa0s icons: chevron-down, chevron-up, clear, close, confirm, copy,
eye, info, move, reset, settings, volume-high.`, the next non-blank line under the provenance line. Kept as decided
(the run plan: keep it unless a fact forces a change). No new library-drawn name arrives on this range for the surfaces
this addon wires (IconBrowser is not wired). Hand lists have drifted before (KickCD `tests/test_mediasetup.lua:28`,
WhatGroup `tests/test_mediasetup.lua:19`); the owner's in-client smoke is the backstop.

## Tests that assume the whole icon folder (3j)

`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v /_kit/`: only
`tests/test_optionssetup.lua:295-296`, which opens `info.tga`, a declared name. No blocker.
