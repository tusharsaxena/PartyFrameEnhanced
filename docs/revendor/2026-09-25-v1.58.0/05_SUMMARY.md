# Summary: LibKa0s v1.57.0 -> v1.58.0

Step 8 of `revendor-libka0s`, for plan item M6-PF of the 2026-09-23 remediation (milestone M6: the
launcher's left click opens settings and its right click opens the options menu). One commit carries
the payload copy, the `CLAUDE.md` provenance line and the adoption launcher-§2 now owes, because the
payload alone leaves the harness red. The candidate walk was not run, because the milestone names
the adoption, so this bundle has no `02_CANDIDATES.md`, `03_DECISIONS.md` or `04_EXECUTION_PLAN.md`.

## The tag and the minors

v1.57.0 to v1.58.0 (a local tag in `../LibKa0s`, read with `git archive`). One file moved a minor:
**Launcher 3 -> 4**. Every other file and the kit (revision 26) are byte-identical to v1.57.0's.
Detail in `01_DELTA.md`.

## Delivered for free (class A)

- Left-click opens the settings panel, enabled or disabled. It used to toggle the lock (rung b).
- The tooltip's hints read `Left-click: Open settings` and `Right-click: Options menu`.

## Contract blockers

None (`01_DELTA.md`, 3g).

## Adopted

In `core/LauncherSetup.lua`, because launcher-§2 (standard v2.67.0) makes the menu a MUST built from
the addon's real toggles. The entries match ADDONS.md's row for this addon, `Enabled · Locked`:

- `setEnabled` = `NS.SetEnabled`, newly published from `settings/Slash.lua` as the one handler
  behind `/pfe enable` and `/pfe disable` (`runEnabled`: the `enabled` write, the panel refresh and
  the `enabled = …` echo). Paired with the existing `isEnabled`.
- `toggleLock` = `NS.ToggleLock`, the seam that drives the `locked` row `/pfe lock`, `/pfe unlock`
  and the Lock frame checkbox write. Paired with the existing `isLocked`.
- Removed: `onClick`, `leftClickLabel`, `disabledLine`. The two enUS keys only the label read
  (`Unlock frame`, `Lock frame`) went with it.
- Kept from M5: `isLocked`, `version`, `isEnabled`.

## Declined

- `toggleTestMode` / `isTestMode`: the addon has no test mode. Unlocking is its preview, and
  options-ui-§15 exempts it from a Test mode row.
- `toggleWindow` / `isWindowShown`: the addon has no primary window.

## Tests

`tests/mock_menu.lua` is a verbatim copy of the library's v1.58.0 menu fake (the kit ships none),
installed by `tests/launcher_env.lua` as `mocks.__menu`. `tests/test_launcher.lua` re-pins the two
buttons and the hints, and drives the menu: its title and entries, the states read at open, each
entry routing to the slash handler (`NS.ToggleLock`, `NS.SetEnabled`) with the same `locked` write
and the same echo the verbs produce, *Locked* grayed while disabled with *Enabled* live, and the
no-`MenuUtil` fallback to the panel. `tests/test_disabled.lua`'s launcher case now pins the disabled
state's left click (panel) and menu (grayed, no write, no line).

## Gates

| Point | Harness | `luacheck` | `lizard` (CCN > 15) |
|---|---|---|---|
| Baseline (v1.57.0 payload) | 348 passed, 0 failed | 0 / 0 in 72 files | none |
| After the copy (v1.58.0 payload) | 341 passed, 7 failed | 0 / 0 in 72 files | not run |
| After the adoption | 353 passed, 0 failed | 0 / 0 in 73 files | none |
