# Test Cases

The full inventory of every headless test case in this repo, grouped by the suite file it
lives in. The `## Totals` table below is the **authoritative pass count** — the README test
badge and any count quoted in the docs must agree with it.

**Generated — do not hand-edit.** Regenerate with `lua tests/run.lua --list > docs/test-cases.md`.

### test_loadorder.lua (11)

- loadorder: tocFiles returns the addon's files, locale first and settings last
- loadorder: core/MediaSetup.lua loads before core/Constants.lua, and the TOC says why
- loadorder: CoreSetup loads after Namespace and before PerfSetup and DebugLogSetup
- loadorder: OptionsSetup loads before every settings page
- loadorder: PerfSetup loads before every module
- loadorder: tocFiles skips libs, directives and comments, and uses forward slashes
- loadorder: every derived path exists on disk
- loadorder: the runner loaded exactly the TOC's files, in the TOC's order
- loadorder: the runner loaded exactly the vendored XML's library files, in its order
- loadorder: tests/perf.lua derives both halves of its list too
- loadorder: the loaded library registered — NS.Perf is the lib, not the stub

### test_schema.lua (9)

- schema: validates with no shape errors and no unresolved paths
- schema: the General page opens on the Master controls tab, in the canonical order
- schema: General visibility is the four-value dropdown, not a boolean
- schema: a write through the seam stores the value and publishes CONFIG once, by section
- schema: a flat Master controls row publishes the master section
- schema: the session-only debug console row publishes nothing and stores nothing
- schema: GetSetting falls back to the shipped default when the profile lacks the key
- schema: ApplyDefault writes a COPY of a table default
- schema: ResolvePath and SetPath walk dotted paths and leave flat keys flat

### test_database.lua (4)

- database: InitDB opens the store with the shipped defaults and schema v1
- database: RunMigrations is idempotent
- database: a counted profile reset restores defaults and publishes PROFILE once
- database: a profile switch publishes PROFILE and VISIBILITY

### test_coresetup.lua (4)

- coresetup: NS.Print is the library printer, reclaimed from AceConsole's embed
- coresetup: printed lines carry the cyan [PFE] tag
- coresetup: NS.MakeCloseButton hands the library this addon's folder name
- coresetup: without LibKa0s the printer still prints, and says the library is missing once

### test_mediasetup.lua (3)

- mediasetup: the console's monospace face is the library's, under this addon's folder
- mediasetup: NS.Icon builds catalog paths from this addon's folder
- mediasetup: without LibKa0s the face falls back to a real client font and icons answer nil

### test_debuglog.lua (3)

- debuglog: NS.Debug is the instance's gated sink, bound bare
- debuglog: enabling logging flips NS.State.debug and writes nothing to the profile
- debuglog: without LibKa0s, `debug on` still sets the flag and acknowledges it

### test_perfsetup.lua (4)

- perfsetup: every bucket is declared, in report order
- perfsetup: suspend and resume reach every registered module and republish visibility
- perfsetup: `/pfe perf` answers lines to print
- perfsetup: without LibKa0s the stub carries every member the addon calls

### test_lifecycle.lua (4)

- lifecycle: a secure write out of combat runs at once
- lifecycle: in combat a secure write queues, the same key replaces, and regen flushes in order
- lifecycle: the regen events drive NS.State.inCombat and republish visibility
- lifecycle: a blocked action blamed on this addon is logged, ungated

### test_bus.lua (3)

- bus: two receivers of one message on their own targets both fire
- bus: every message is prefixed Ka0s_PartyFrameEnhanced_
- bus: no message has more than one sending file

### test_compat.lua (7)

- compat: IsSecret answers false without the client's issecretvalue
- compat: FrameUnit prefers displayedUnit, then unit, then unitToken, then the attribute
- compat: FrameUnit rejects a secret, an empty string and a non-string, and moves on
- compat: FrameVisible fails open on a secret and closed on nil or an error
- compat: UnitIsUnit answers nil when the comparison is refused or secret
- compat: UseRaidStyleParty reads Edit Mode first and the CVar second
- compat: IsAddOnLoaded goes through C_AddOns and answers false without it

### test_providers.lua (11)

- providers: Blizzard classic maps party1..4 by unitToken and never the player
- providers: Blizzard raid-style maps the player too, and follows a re-sort
- providers: EllesmereUI outranks Blizzard in Automatic, and reads the secure unit attribute
- providers: the General page can pin Blizzard even with EllesmereUI on screen
- providers: EllesmereUI's frames are ignored unless the addon is loaded
- providers: hidden member frames and raid tokens that cannot be compared are skipped
- providers: a raid group puts the map to sleep
- providers: a resolve that finds what it already had sends no LAYOUT
- providers: any number of requests before the next frame cost one resolve
- providers: a hooked member frame's unit change requests a resolve
- providers: suspended, requests do nothing and events come off

### test_anchor.lua (7)

- anchor: attached pins each element to its unit's frame by the configured points
- anchor: a pass that changes nothing makes no SetPoint call
- anchor: match width pins both edges instead of one point
- anchor: free placement stacks included units down from the holder
- anchor: a secure feature in combat fades what would move and defers the pass to regen
- anchor: a drag saves the holder's position and ResetPositions clears it
- anchor: LAYOUT re-applies every registered feature

### test_slash.lua (9)

- slash: every NS.COMMANDS entry is a positional {name, desc, fn} triple
- slash: the reserved verbs are all present
- slash: /pfe and /partyframeenhanced are both registered through AceConsole
- slash: `version` prints the TOC version
- slash: `unlock` and `lock` write `locked` through the seam
- slash: `set` parses and stores a schema value, `reset` puts it back
- slash: `perf` prints what the harness returns
- slash: `profile` with no argument prints the sub-verb list
- slash: an unknown verb says so and prints help

### test_optionssetup.lua (4)

- optionssetup: the live and degraded builds veto the same rows from Reset All
- optionssetup: the degraded load registers every host-declared row; the gap is the composers'
- optionssetup: the stub publishes every member a page file touches at load
- optionssetup: without the library, opening the panel prints one honest line

### test_surface_parity.lua (4)

- parity: the Core stub publishes everything core/CoreSetup.lua publishes live
- parity: the DebugLog stub carries the whole live surface
- parity: the Options stub carries every helper the degraded build can reach
- parity: the Slash stub carries every dispatcher member the addon calls

### test_vendor_sync.lua (3)

- libs/LibKa0s is the LibKa0s release CLAUDE.md says this addon bundles
- tests/_kit is the test kit that shipped with that release
- the automated-test runner is recorded executable (100755)

### test_eol.lua (1)

- eol: every tracked file carries the terminator .gitattributes declares for it

## Totals

| Suite | Cases |
|-------|------:|
| test_loadorder.lua | 11 |
| test_schema.lua | 9 |
| test_database.lua | 4 |
| test_coresetup.lua | 4 |
| test_mediasetup.lua | 3 |
| test_debuglog.lua | 3 |
| test_perfsetup.lua | 4 |
| test_lifecycle.lua | 4 |
| test_bus.lua | 3 |
| test_compat.lua | 7 |
| test_providers.lua | 11 |
| test_anchor.lua | 7 |
| test_slash.lua | 9 |
| test_optionssetup.lua | 4 |
| test_surface_parity.lua | 4 |
| test_vendor_sync.lua | 3 |
| test_eol.lua | 1 |
| **Total** | **91** |
