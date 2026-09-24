# Summary: LibKa0s v1.56.0 -> v1.57.0

Step 8 of `revendor-libka0s`, for plan item M5-PF of the 2026-09-23 remediation (milestone M5, the
always-on launcher status tooltip). Two commits: the payload copy with the `CLAUDE.md` provenance
line rolled, then the one adoption launcher-§1 now owes. The candidate walk was not run, because
the milestone names the adoption, so this bundle has no `02_CANDIDATES.md`, `03_DECISIONS.md` or
`04_EXECUTION_PLAN.md`.

## The tag and the minors

v1.56.0 to v1.57.0 (a local tag in `../LibKa0s`, read with `git archive`). One file moved a minor:
**Launcher 2 -> 3**. Every other file and the kit (revision 26) are byte-identical to v1.56.0's.
Detail in `01_DELTA.md`.

## Delivered for free (class A)

- Launcher 3: the minimap button and any broker row show the library's status tooltip on hover,
  enabled or disabled. The addon had passed no `onTooltipShow`, so it had no tooltip before.

## Contract blockers

None (`01_DELTA.md`, 3g).

## Adopted

In `core/LauncherSetup.lua` (the second M5-PF commit), because launcher-§1 (standard v2.66.0) makes
the tooltip a MUST that reads the addon's real states:

- `isEnabled` (the Master-controls *Enable* row) and `disabledLine` (`NS.DisabledLine()`, the slash
  gate's line). Without them the tooltip would read *Enabled: Yes* forever. The library's minor-2
  gate now refuses a disabled left click before `NS.ToggleLock` is reached; `NS.ToggleLock` keeps
  its own gate for any other caller.
- `isLocked`: the `locked` row, read the way `modules/Preview.lua` reads it.
- `leftClickLabel`: *Unlock frame* while locked and *Lock frame* while unlocked (rung b; ADDONS.md
  says "lock / unlock -- unlocking is the preview"), through `NS.L`.
- `version`: `NS.Version()`, the TOC's `## Version`.

## Declined

- `isTestMode`: the addon has no test mode. Unlocking is its preview, and options-ui-§15 exempts it
  from a Test mode row, so a *Test mode: Off* line would describe a state it does not have.
- `onTooltipShow`: the addon has nothing of its own to add.
- `slash`: not needed, because the library reads `/pfe enable` out of `disabledLine()`.

## Gates

| Point | Harness | `luacheck` | `lizard` (CCN > 15) |
|---|---|---|---|
| Baseline (v1.56.0 payload) | 342 passed, 0 failed | 0 / 0 in 72 files | none |
| After the copy (v1.57.0 payload) | 342 passed, 0 failed | 0 / 0 in 72 files | none |
| After the adoption | 348 passed, 0 failed | 0 / 0 in 72 files | none |
