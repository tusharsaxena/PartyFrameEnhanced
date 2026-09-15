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
| test_slash.lua | 9 |
| test_optionssetup.lua | 4 |
| test_surface_parity.lua | 4 |
| test_vendor_sync.lua | 3 |
| test_eol.lua | 1 |
| **Total** | **66** |
