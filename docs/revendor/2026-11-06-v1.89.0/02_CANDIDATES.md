# Candidates

Range `git -C ../LibKa0s log --oneline v1.85.0..v1.89.0`; sources: the library `CHANGELOG.md` blocks v1.86.0 to
v1.89.0 and the API documents under `docs/api/` for every major whose minor moved.

## A. Delivered on the copy (not offered)

- **Kit 51** (`docs/api/testkit/version-51-docs.md`): the mock CallbackHandler's `unregister`/`unregisterAll` clear
  a registration only where one exists, so an unregister during a dispatch no longer raises "invalid key to 'next'"
  or skips a registrant. A flake fix for this addon's suite; no host change.
- **DebugLogDiagnostics 7** (`docs/api/DebugLog/version-22.7.1.4-docs.md`, "No member change"): the report's
  `LibKa0s running:` line lists IconBrowser when it runs. This addon does not ship it, so its report reads as before.
- **Widgets 23 flat menus** (`docs/api/Widgets/version-23.5.12.6.7.5-docs.md`): a `W.ContextMenu` without the new
  fields draws what 22 drew. This addon has no `W.ContextMenu` site; library surfaces it wires are unaffected.

## B. Host change required

- **Widgets 23 cascading-menu fields** (`submenu`, `radio`, `selected`, `opts.check`). Not applicable: this addon
  has no `W.ContextMenu` use site (`grep -rn ContextMenu --include='*.lua' --exclude-dir=libs --exclude-dir=_kit .`
  finds only the Launcher's `MenuUtil` mock in `tests/mock_menu.lua`, a library-drawn menu). Recommendation: record,
  no action.
- **Toast 4 stack** (`docs/api/Toast/version-4-docs.md`). Not applicable: this addon does not look up
  `LibKa0s-Toast-1.0` and has no Toast stub. Recommendation: record, no action.

## C. Whole-module adoption

- **`LibKa0s-IconBrowser-1.0`** (new in v1.86.0, `docs/api/IconBrowser/version-1.1.1-docs.md`): a browser over the
  icon catalog for a host that lets the player choose an icon. This addon has no icon chooser; its options pick
  frame and bar settings, never an icon. Blast radius would be additive. Recommendation: settled, not adopted.
