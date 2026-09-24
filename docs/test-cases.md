# Test Cases

The full inventory of every headless test case in this repo, grouped by the suite file it
lives in. The `## Totals` table below is the **authoritative pass count** — the README test
badge and any count quoted in the docs must agree with it.

**Generated — do not hand-edit.** Regenerate with `lua tests/run.lua --list > docs/test-cases.md`.

### test_loadorder.lua (13)

- loadorder: tocFiles returns the addon's files, locale first and settings last
- loadorder: core/MediaSetup.lua loads before core/Constants.lua, and the TOC says why
- loadorder: CoreSetup loads after Namespace and before PerfSetup and DebugLogSetup
- loadorder: OptionsSetup loads before every settings page
- loadorder: Schema loads before every settings file, and the TOC says why
- loadorder: PerfSetup loads before every module
- loadorder: Preview loads after StandIn, and the TOC says why
- loadorder: tocFiles skips libs, directives and comments, and uses forward slashes
- loadorder: every derived path exists on disk
- loadorder: the runner loaded exactly the TOC's files, in the TOC's order
- loadorder: the runner loaded exactly the vendored XML's library files, in its order
- loadorder: tests/perf.lua derives both halves of its list too
- loadorder: the loaded library registered — NS.Perf is the lib, not the stub

### test_schema.lua (20)

- schema: validates with no shape errors and no unresolved paths
- schema: the General page opens on the Master controls tab, in the canonical order
- schema: General visibility is the four-value dropdown, not a boolean
- schema: a write through the seam stores the value and publishes CONFIG once, by section
- schema: a flat Master controls row publishes the master section
- schema: the session-only debug console row publishes nothing and stores nothing
- schema: GetSetting falls back to the shipped default when the profile lacks the key
- schema: ApplyDefault writes a COPY of a table default
- schema: ResolvePath and SetPath walk dotted paths and leave flat keys flat
- schema: a write stores, logs one [Set] line, reacts, then publishes CONFIG, once each
- schema: a refused write stores nothing, logs nothing, reacts to nothing and publishes nothing
- schema: a write to a path no row declares is refused and not stored
- schema: a table value is copied into the store, never aliased
- schema: a bulk act is ONE [Set] line counting only the rows it changed
- schema: a bracket that raises still closes, says so, and re-raises the same error
- schema: the counted profile reset counts rows off default, and never the global minimap row
- schema: before the db opens, GetSetting answers the shipped default
- schema: without the library, /pfe disable and /pfe enable still write the stored path
- schema: without the library, /pfe unlock and /pfe lock still write the stored path
- schema: without the library, a row-less path outside writeThrough is refused and not stored

### test_database.lua (6)

- database: InitDB stamps NS.SCHEMA_VERSION over a default of 0
- database: RunMigrations is idempotent
- database: a profile step runs over every stored profile, then stamps
- database: a raising step leaves the stamp and prints one line; a rerun is a no-op
- database: a counted profile reset restores defaults and publishes PROFILE once
- database: a profile switch publishes PROFILE and VISIBILITY

### test_coresetup.lua (4)

- coresetup: NS.Print is the library printer, reclaimed from AceConsole's embed
- coresetup: printed lines carry the cyan [PFE] tag
- coresetup: NS.MakeCloseButton hands the library this addon's folder name
- coresetup: without LibKa0s the printer still prints, and says the library is missing once

### test_envsetup.lua (2)

- envsetup: NS.Version never answers nil — the fallback constant when no reader answers
- envsetup: without LibKa0s, Meta and Version read C_AddOns, then fall back to NS.version

### test_mediasetup.lua (3)

- mediasetup: the console's monospace face is the library's, under this addon's folder
- mediasetup: NS.Icon builds catalog paths from this addon's folder
- mediasetup: without LibKa0s the face falls back to a real client font and icons answer nil

### test_debuglog.lua (3)

- debuglog: NS.Debug is the instance's gated sink, bound bare
- debuglog: enabling logging flips NS.State.debug and writes nothing to the profile
- debuglog: without LibKa0s, `debug on` still sets the flag and acknowledges it

### test_perfsetup.lua (5)

- perfsetup: every bucket is declared, in report order
- perfsetup: suspend and resume reach every registered module and republish visibility
- perfsetup: `/pfe perf` answers lines to print
- perfsetup: live and stub both carry every Perf member the addon's source reads
- perfsetup: without LibKa0s the stub carries every member the addon calls

### test_lifecycle.lua (4)

- lifecycle: a secure write out of combat runs at once
- lifecycle: in combat a secure write queues, the same key replaces, and regen flushes in order
- lifecycle: the regen events drive NS.State.inCombat and republish visibility
- lifecycle: a blocked action blamed on this addon is logged, ungated

### test_bus.lua (12)

- bus: two receivers of one message on their own targets both fire
- bus: every message is prefixed Ka0s_PartyFrameEnhanced_
- bus: no message has more than one sending file
- bus: a stand-down takes a receiver's events AND messages down, and a stand-up puts both back
- bus: a stand-up replays the record as it is NOW, not a snapshot from the way down
- bus: a method-name handler survives the round trip and is called as a method
- bus: re-registering a key after forgetting it never grows the record
- bus: a registration made while the addon is stood down is recorded and NOT live until it stands up
- bus: NS.MSG is strict, so a mistyped key raises instead of sending nil
- bus: without the library, a receiver still gets a private target that hears the bus
- bus: without the library nothing is recorded, so a stand-down leaves the receivers live (a stated limitation)
- bus: without the library NS.MSG declares the same four names

### test_compat.lua (10)

- compat: IsSecret answers false without the client's issecretvalue
- compat: FrameUnit prefers displayedUnit, then unit, then unitToken, then the attribute
- compat: FrameUnit rejects a secret, an empty string and a non-string, and moves on
- compat: FrameVisible fails open on a secret and closed on nil or an error
- compat: UseRaidStyleParty reads Edit Mode first and the CVar second
- compat: IsAddOnLoaded goes through C_AddOns and answers false without it
- compat: IsSecret answers exactly one boolean, true only for what the client marks secret
- compat: IsSecret is the library's member on the live load
- compat: without the library the guard stub answers what the library answers, fixture for fixture
- compat: NS.Compat carries every LibKa0s-Compat-1.0 member it wires

### test_providers.lua (16)

- providers: Blizzard classic maps party1..4 by unitToken and never the player
- providers: Blizzard raid-style maps the player too, and follows a re-sort
- providers: EllesmereUI outranks Blizzard in Automatic, and reads the secure unit attribute
- providers: the General page can pin Blizzard even with EllesmereUI on screen
- providers: EllesmereUI's frames are ignored unless the addon is loaded
- providers: hidden member frames and raid tokens are skipped
- providers: a raid group puts the map to sleep
- providers: solo puts the map to sleep
- providers: a resolve that finds what it already had sends no LAYOUT
- providers: any number of requests before the next frame cost one resolve
- providers: a hooked member frame's unit change requests a resolve
- providers: enabled, exactly one EditMode.Exit callback is registered, owned by Providers
- providers: suspended, the Edit Mode burst arms nothing even when reached directly
- providers: suspended, requests do nothing and events come off
- providers: a refused event name costs only itself, and is recorded once across a disable/enable
- providers: /pfe status names the events the client refused

### test_anchor.lua (9)

- anchor: attached pins each element to its unit's frame by the configured points
- anchor: a pass that changes nothing makes no SetPoint call
- anchor: match width pins both edges instead of one point
- anchor: free placement stacks included units down from the holder
- anchor: a secure feature in combat fades what would move and defers the pass to regen
- anchor: a drag saves the holder's position and ResetPositions clears it
- anchor: LAYOUT re-applies every registered feature
- anchor: a section stripped of its defaulted point still pins, from the shipped default
- anchor: unlocking gives the name plate a grabbable body and arms every element's drag

### test_profile_switch.lua (4)

- profile switch: Anchor places by the NEW profile even when it hears PROFILE first
- profile switch: a real SetProfile each way follows the profile
- profile switch: Reset all settings on a free profile returns it to attached
- profile switch: copying a free profile in places by the copy

### test_castbars.lua (14)

- castbars: each included unit's bar registers exactly the cast events, for its own unit
- castbars: nothing in the addon registers a UNIT_SPELLCAST event globally
- castbars: turning the feature off unregisters every unit; on registers them again
- castbars: a refused UNIT_SPELLCAST name leaves the bar's other cast events registered
- castbars: a cast start shows the bar with the name, icon and an engine-driven fill timer
- castbars: a channel drains, and without the engine timer the bar is driven from the same object
- castbars: the time text shows seconds left, refreshed at most ten times a second
- castbars: an interrupt holds the bar in the failed color with the client's word, then hides
- castbars: a stop that arrives after the next cast began keeps the bar on the new cast
- castbars: a stop the client never sent is caught by the tick
- castbars: a secret notInterruptible picks the fill and the shield on the C side
- castbars: the show decision hides a casting bar for master off, Never, and a missing frame
- castbars: preview shows every included bar with placeholder content, and clears on exit
- castbars: suspended, every bar unregisters and hides; resumed, they come back

### test_targetframes.lua (25)

- targetframes: every button is a secure unit button acting on its owner's target
- targetframes: the state driver folds General visibility in, and hides what is not allowed
- targetframes: attached with no party frame on screen, the driver is hide
- targetframes: in combat a driver change is queued, never written, and lands at regen
- targetframes: a driver changed and changed back in combat ends on the last request
- targetframes: click to target unticked and re-ticked in combat stays on after combat
- targetframes: click to target sets the attribute and the mouse, both ways
- targetframes: UNIT_TARGET paints the name, health, percent and marker
- targetframes: NPCs color by reaction, players by class when asked, the swatch otherwise
- targetframes: a secret class and a secret reaction never reach a table lookup
- targetframes: the ticker runs only while someone has a target, and repaints health
- targetframes: a secret UnitExists never makes the tick repaint a hidden button
- targetframes: an unchanged plain health is not repainted by the tick
- targetframes: Update health off draws the bar full with no percent, and the ticker never runs
- targetframes: a new Health refresh pace restarts a running ticker at it
- targetframes: the marker sits on its configured point of the bar, nudged by its offsets
- targetframes: preview shows every allowed button with placeholder content
- targetframes: PLAYER_TARGET_CHANGED is registered ONCE, on the module, not per button
- targetframes: PLAYER_TARGET_CHANGED repaints the player's target button
- targetframes: suspended, no events, no ticker, every driver unregistered
- targetframes: a target that had not resolved at paint time is repainted by the ticker
- targetframes: with Update health off, the ticker runs only until a pending target resolves
- targetframes: the marker draws above the border
- targetframes: the module's own events are held only while the feature is on and in a party
- targetframes: the debug line's UnitName is not evaluated with debug off

### test_petframes.lua (11)

- petframes: each button acts on its owner's pet token
- petframes: click to target unticked and re-ticked in combat stays on after combat
- petframes: UNIT_PET listens on the owner, the health events on the pet token
- petframes: a new pet paints fully; a health event repaints health only
- petframes: Use class color takes the OWNER's class
- petframes: Update health off drops the health events and draws the bar full
- petframes: suspended, events come off and every driver is unregistered
- petframes: a new pet paints its raid marker; RAID_TARGET_UPDATE repaints it
- petframes: the marker sits on its configured point of the bar, nudged by its offsets
- petframes: the marker draws above the border
- petframes: RAID_TARGET_UPDATE is held only while the feature is on and in a party

### test_rangefade.lua (8)

- rangefade: every cast bar, target frame and pet frame sits under its unit's fade frame
- rangefade: Blizzard raid-style — the member frame's SetAlpha is copied to its unit
- rangefade: EllesmereUI — a secret range flag is replayed through SetAlphaFromBoolean
- rangefade: a secret alpha the client refuses falls back to the frame's own outOfRange
- rangefade: Blizzard classic has no fade to copy — UnitInRange drives it instead
- rangefade: off, in preview, or with no party frame, every fade is full alpha
- rangefade: status names which way the fade is running
- rangefade: a perf run's suspend drops the range event and restores full alpha

### test_party.lua (6)

- party: InParty is a party of 2-5 — not solo, not a raid
- party: solo, nothing shows — free placement included — and no unit events are registered
- party: in a raid, nothing shows — free placement included — and no unit events are registered
- party: a roster change republishes VISIBILITY only when the party answer flips
- party: preview skips the rule — unlocked solo, the free-placement placeholders show
- party: /pfe status says so when you're not in a party

### test_preview.lua (8)

- preview: unlocking turns preview on and makes free-placement holders grabbable
- preview: unlocking in combat is refused, the stored lock stays, and the player is told why
- preview: the lock is the only switch, and there is no hold API left
- preview: one VISIBILITY each way, and a redundant write sends nothing
- preview: neither /pfe preview nor /pfe test exists — lock and unlock are the switch
- preview: a profile saved unlocked comes back in preview
- status: names the frame system, each unit, each feature, and anything switched off
- preview: PLAYER_REGEN_DISABLED is held only while unlocked, and combat still re-locks

### test_standin.lua (12)

- standin: Automatic imitates EllesmereUI when loaded, else raid-style or classic by Edit Mode
- standin: a pinned Frame system wins — EllesmereUI even unloaded, Blizzard by Edit Mode
- standin: the source is the imitated system's first member frame
- standin: copies the source's size and top-left through the effective-scale ratio
- standin: a zero size takes the system's fallback, and no position goes to the center
- standin: a secret size or position is never compared — fallback and center
- standin: draws beneath what attaches to it (LOW strata), as a real party frame does
- standin: marks the player's name (test), with no corner tag for an element to cover, and drags
- standin: imitating EllesmereUI, its configured party size beats what the hidden button measures
- standin: fills party1 only when no real frame holds it, and clearing it restores the real map
- standin: setting and clearing it resolve at once, each sending LAYOUT
- standin: cleared while suspended, it leaves the map at once and the resume re-sends LAYOUT

### test_preview_standin.lua (17)

- preview: solo, unlocking raises the stand-in in party1's place; locking ends it
- preview: in a party, unlocking is placeholders on the real frames and no stand-in
- preview: in a raid it is the stand-in too
- preview: it switches live — joining hides the stand-in, leaving brings it back, it stays on
- preview: unlocking is refused in combat, disabled or suspended — one line each
- preview: locking is never refused, so a refusal cannot strand the elements unlocked
- preview: combat re-locks at PLAYER_REGEN_DISABLED (stand-in)
- preview: combat re-locks at PLAYER_REGEN_DISABLED (party)
- preview: the master switch going off re-locks
- preview: a perf-run suspend re-locks, and the stand-in leaves the map at once
- preview: party1's target button pins to the stand-in, and after the lock its driver hides it
- preview: unlocking out of a party is what creates the stand-in
- preview: a Frame system change re-dresses the stand-in
- preview: with Match party frame width, party1's cast bar pins both edges to the stand-in
- preview: the placeholder cast is drawn full, so the whole bar shows
- preview: Lock frame is the switch, and no Test mode row survives beside it
- preview: status names what preview is showing, and neither verb survives in NS.COMMANDS

### test_perf_buckets.lua (3)

- perf: every declared bucket is reached by a real bracket
- perf: each nested bucket is observed inside the parent it declares
- perf: capture off, no bracket calls the sink

### test_prose.lua (15)

- prose: no authored file carries a British spelling from localization-§5's published list
- prose: the gate carries localization-§5's two lists whole, and nothing of its own
- prose self-test: the carve-out suppresses the named generated folder, and only it
- prose self-test: a path the carve-out does not name is not covered by one that looks like it
- prose self-test: a carve-out that is not a set of path strings is a failure, not a silence
- prose self-test: a TOC's file lines are read as paths, and its directives and comments are not
- prose self-test: a .pkgmeta's ignore block is read, and the keys around it are not
- prose self-test: an ignore entry covers a path exactly, by folder, and by wildcard
- prose self-test: the carve-out admits a generated dump and refuses a file the TOC loads
- prose self-test: a waiver-file exclusion meets the same two refusals as the carve-out
- prose self-test: each list is refused on the matching rule its own scan uses
- prose self-test: the scan and the refusals read the added exclusions through one reader
- prose self-test: a narrowing is refused by what it suppresses, not by how it is written
- prose self-test: the disclosure names what each entry suppressed, and says when it is bounded
- prose self-test: a malformed waived is a failure, not a silence

### test_slash.lua (23)

- slash: every NS.COMMANDS entry is a positional {name, desc, fn} triple
- slash: the reserved verbs are all present
- slash: a bare /pfe opens the settings panel through `config`, not the help
- slash: whitespace-only input is a bare /pfe
- slash: `help` prints the command list and opens nothing
- slash: /pfe and /partyframeenhanced are both registered through AceConsole
- slash: `version` prints the TOC version
- slash: `unlock` and `lock` write `locked` through the seam
- slash: `set` parses and stores a schema value, `reset` puts it back
- slash: `perf` prints what the harness returns
- slash: `profile` with no argument prints the sub-verb list
- slash: an unknown verb says so and prints help
- slash: `enable` and `disable` are ALIASES for the Enable row -- no state of their own
- slash: `enable` echoes the stored value in the shared `path = value` shape
- slash: the dispatcher answers while the addon is DISABLED -- the pair is never one-way
- slash: a feature verb REFUSES while disabled -- one line, and it does NOT act
- slash: `unlock` refuses at the DISPATCHER, before the write seam
- slash: the gate is DENY BY DEFAULT -- every verb outside the live set refuses
- slash: the live set still ANSWERS and still ACTS while the addon is off
- slash: `profile new` on an existing name refuses and does NOT wipe it
- slash: `profile use` on a missing name refuses and creates nothing
- slash: `profile copy` refuses a missing name and the current profile, with no Lua error
- slash: `profile delete` on a missing name refuses instead of claiming it deleted

### test_disabled.lua (18)

- disabled: the baseline — enabled, the addon registers and draws
- disabled: every registration the addon owns is UNREGISTERED, not gated
- disabled: nothing is left armed to wake up
- disabled: leaving Edit Mode while disabled arms nothing
- disabled: every frame that was on screen is hidden, and refused at the source
- disabled: the fade frames and the free-placement holders are hidden
- disabled: no game event produces a write, a line, or a frame
- disabled: the whole reserved surface still answers, and only feature verbs refuse
- disabled: re-enabled, the addon rebuilds from CURRENT state
- disabled: re-enabled, the fade frames and the holders are shown again
- disabled: two holds, one latch — releasing one never resurrects the other's addon
- disabled: the launcher's LEFT click is refused and its RIGHT click is not
- disabled: out of combat, the target and pet state drivers are UNREGISTERED
- disabled: re-enabled, the released state drivers are re-installed
- disabled: in combat, the release is queued and PLAYER_REGEN_ENABLED completes it
- disabled: in combat, the fade frames and holders hide once combat ends
- disabled: unlocking through the seam prints only the collection line and writes nothing
- disabled: the suite leaves the world enabled for the suites after it

### test_launcher.lua (17)

- launcher: one object, registered twice under the addon's FOLDER name
- launcher: Register is idempotent -- a second call builds no second button
- launcher: the icon is the addon's own 128 logo, and the TOC's IconTexture names that file
- launcher: the broker label is the BRAND NAME in plain text, never the Title or the folder
- launcher: LEFT click toggles the lock through the addon's own seam -- rung (b)
- launcher: the left click and `/pfe unlock` are the same seam, not two
- launcher: RIGHT click always opens the settings panel
- launcher: the Minimap button row is composed, stored, and in its canonical position
- launcher: the row's get/set INVERT onto LibDBIcon's `hide`, and move the button
- launcher: LibDBIcon was handed the SAME table the row writes
- launcher: the minimap table is GLOBAL -- a profile switch leaves it alone
- launcher: *Reset all settings* leaves a hidden button hidden
- launcher: the page-scoped General *Defaults* button leaves a hidden button hidden
- launcher: neither reset re-HIDES a shown button either
- launcher: `/pfe reset global.minimap.hide` still works -- the exemption is for SWEEPS
- launcher: a host with NEITHER broker library loads, reports, and does not raise
- launcher: the main harness -- no broker libraries at all -- never raised

### test_optionssetup.lua (10)

- optionssetup: the live and degraded builds veto the same rows from Reset All
- optionssetup: the degraded load registers every host-declared row; the gap is the composers'
- optionssetup: every feature page has a Size & Position tab that opens with Size
- optionssetup: Size & Position draws only the placement block the anchor mode uses (shownWhen)
- optionssetup: the hidden block stays in the schema and /pfe set still reaches it
- optionssetup: Match party frame width dims in free placement, and Width with Match width
- optionssetup: one Health updates tab drives both features; health rows dim with it, marker rows with the marker
- optionssetup: the stub publishes every member a page file touches at load
- optionssetup: Reset All resets the active profile only — the list and the active profile stay
- optionssetup: without the library, opening the panel prints one honest line

### test_surface_parity.lua (10)

- parity: the Core stub publishes everything core/CoreSetup.lua publishes live
- parity: the Core stub's SafeRegister* pcall a raising target, answer false and append once
- parity: the DebugLog stub carries the whole live surface
- parity: the Bus stub carries the whole LibKa0s-Bus-1.0 surface
- parity: the Schema stub instance carries every member of the live instance
- parity: the Schema stub library carries the lib-level primitives
- parity: the Options stub carries every helper the degraded build can reach
- parity: the Slash stub carries every dispatcher member the addon calls
- parity: a bare /pfe runs `config` in the library-absent build too
- parity: the Slash stub dispatches verbs, aliases, typos and the disabled gate as the library does

### test_vendor_sync.lua (3)

- libs/LibKa0s is the LibKa0s release CLAUDE.md says this addon bundles
- tests/_kit is the test kit that shipped with that release
- the automated-test runner is recorded executable (100755)

### test_eol.lua (2)

- eol: every tracked file carries the terminator .gitattributes declares for it
- eol: .gitattributes is line-endings-§5's canonical body for this repo kind

### test_layout_cap.lua (13)

- layoutcap: every authored file over the 1500-line cap is named in the census
- layoutcap: no census row outlives the breach it records
- layoutcap: every over-cap census row carries one of layout-§1's three terminal states
- layoutcap: the census and the exempt set agree about which paths were exempted
- layoutcap: an empty census is written as a result rather than left standing empty
- layoutcap self-test: the parser reads the census nested under the register, and stops there
- layoutcap self-test: a census outside its register, or at the wrong level, is not read
- layoutcap self-test: an over-cap file missing from the census is reported, and an exempt one is not
- layoutcap self-test: a census row that outlives its breach is reported
- layoutcap self-test: an over-cap row that names no terminal state is reported
- layoutcap self-test: the census and the exempt set are held to naming the same paths
- layoutcap self-test: a census that states nothing is told apart from one that states none
- layoutcap self-test: the exempt set takes folders as well as paths

## Totals

| Suite | Cases |
|-------|------:|
| test_loadorder.lua | 13 |
| test_schema.lua | 20 |
| test_database.lua | 6 |
| test_coresetup.lua | 4 |
| test_envsetup.lua | 2 |
| test_mediasetup.lua | 3 |
| test_debuglog.lua | 3 |
| test_perfsetup.lua | 5 |
| test_lifecycle.lua | 4 |
| test_bus.lua | 12 |
| test_compat.lua | 10 |
| test_providers.lua | 16 |
| test_anchor.lua | 9 |
| test_profile_switch.lua | 4 |
| test_castbars.lua | 14 |
| test_targetframes.lua | 25 |
| test_petframes.lua | 11 |
| test_rangefade.lua | 8 |
| test_party.lua | 6 |
| test_preview.lua | 8 |
| test_standin.lua | 12 |
| test_preview_standin.lua | 17 |
| test_perf_buckets.lua | 3 |
| test_prose.lua | 15 |
| test_slash.lua | 23 |
| test_disabled.lua | 18 |
| test_launcher.lua | 17 |
| test_optionssetup.lua | 10 |
| test_surface_parity.lua | 10 |
| test_vendor_sync.lua | 3 |
| test_eol.lua | 2 |
| test_layout_cap.lua | 13 |
| **Total** | **326** |
