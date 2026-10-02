# Debug surfaces

Party Frame Enhanced has two debug surfaces, and both write into the same window:

- **The debug console** is `LibKa0s-DebugLog-1.0`'s window. Tagged `NS.Debug` lines land there while
  the session flag is on. Three kinds of line land there whatever the flag says: a blocked or
  forbidden action this addon caused, a settings migration step that failed, and a perf capture's
  output.
- **The diagnostics report** is a one-shot snapshot of the addon's state, written into the console
  by `/pfe diagnostics` (`debug-logging-§14`). It is the reason this page exists (`documentation-§3`,
  Tier 2): every Ka0s addon ships the report, and a maintainer reading a pasted one needs to know what
  each line means.

The console itself is the library's, and its contract lives in LibKa0s's
[`docs/api/DebugLog/version-19.2.1-docs.md`](https://github.com/tusharsaxena/LibKa0s/blob/master/docs/api/DebugLog/version-19.2.1-docs.md)
(DebugLog 19.2.1 is the vendored minor, from LibKa0s v1.67.0). This page covers only what Party Frame
Enhanced adds on top. `/pfe status` is a third way to look inside, but it prints a short summary to
chat and is not a debug surface; [slash-dispatch.md](slash-dispatch.md) has it.

## The console

| Command | Effect |
|---|---|
| `/pfe debug` | Shows or hides the console window. The logging flag is unchanged. |
| `/pfe debug on` / `off` | Sets or clears the logging flag through `NS.DebugLog:SetEnabled`, which confirms on one chat line. |
| `/pfe debug diagnostics` | Writes the diagnostics report (below), turning logging on first if it was off. |
| `/pfe debug <anything else>` | Shows or hides the window, like the bare `/pfe debug`. |

What Party Frame Enhanced supplies, all in `core/DebugLogSetup.lua`:

- **The flag is ours, and session-only.** It is `NS.State.debug`: off at login, never written to
  SavedVariables, and reset by every `/reload`. The General page's **Debug console** checkbox shows
  and hides the window; it does not set the flag.
- **The buffer is the library's** (`lib.MAX_BUFFER`, 3000 lines in DebugLog 19.2.1). The footer
  counter reads `N / 3000 lines` and pins there, and Copy pastes out of the same buffer, so a long
  capture keeps only its newest 3000 lines.
- **The `[Init]` line** opens a session when the flag goes on:
  `PartyFrameEnhanced v<version>, schema v<n>, profile '<name>', frames '<frame system>',
  EllesmereUI raid frames loaded|not loaded`. The report's identity header prints the same line.
- **The sink is `NS.Debug(tag, fmt, ...)`**, bound bare to the library's gated `Debug`. A call with
  the flag off does nothing and allocates nothing.

The console's title bar carries an orange **Diagnostics** text link beside the Debug On/Off label.
It is the library's: a click runs the report exactly as `/pfe diagnostics` does.

On an install without LibKa0s the flag still works and `on` / `off` still confirm. The window is gone,
and the stub says so once.

## Coverage

What the console carries while the flag is on, tag by tag (`debug-logging-§8`: the flows and the
Diagnosis checklist). Every row is one gated line per event, with its string built behind the gate.
A line marked **change-gated** is on a repeating path and is written only when its own text differs
from the last one it wrote (`debug-logging-§9`, quiet steady state), so a fight full of repeats adds
nothing to the buffer. The gate is the console's (`NS.DebugChanged` / `NS.DebugOnce`, DebugLogGates
1), not a memo of this addon's: **Clear** and turning logging on re-arm it, so a cleared console
says the current state again on its next pass rather than staying silent until something changes.

**Which lines are the library's.** The rows below whose *Emitted by* names the library are written
by LibKa0s through this addon's `NS.Debug` (each descriptor's `debug`): `Init`, `Lifecycle`, `Perf`,
`Cmd`, `Cfg`, `Launcher` and `Diag`, and the `Set` lines the schema write seam writes. This addon
writes no copy of any of them, and `tests/test_library_lines.lua` pins each landing once.

| Tag | Emitted by | When |
|---|---|---|
| `Init` | the library, from `core/DebugLogSetup.lua`'s summary | Logging goes on: `PartyFrameEnhanced v<version>, schema v<n>, profile '<name>', frames '<frame system>', EllesmereUI raid frames loaded\|not loaded`. The one optional dependency is said here because the flag is off at login |
| `Set` | the schema write seam (`settings/Schema.lua`, through the library), `core/PartyFrameEnhanced.lua` | Every setting write (`path = value`), a bulk reset's count, a profile reset (`N rows` when this addon drove it) and a profile copy |
| `Profile` | `core/PartyFrameEnhanced.lua` | A profile switch; a profile deleted (the Profiles page or `/pfe profile delete`) |
| `Migrate` | `core/Database.lua` | Each schema migration step that ran; a step that failed (ungated) |
| `State` | `core/PartyFrameEnhanced.lua` | Each loading screen (`entered world`), with the party answer it took |
| `Lifecycle` | the library, from `core/LifecycleSetup.lua`'s `debug` | Each stand-down and stand-up edge, one line naming the hold that moved and the resulting set (`stood down: added disabled (holds: disabled)`, `stood up: released perf (holds: none)`). A hold that fires no edge writes nothing. This addon writes no edge line of its own |
| `Party` | `core/PartyFrameEnhanced.lua` | A roster change that flipped the party-only answer (joined or left a party, or the group became a raid) |
| `Combat` | `core/PartyFrameEnhanced.lua` | Entering combat (secure writes queue from here); leaving it, with the rollup of what the fight counted (`castsStarted`, `castsInterrupted`, `targetEvents`, `targetTicks`) |
| `Secure` | `core/PartyFrameEnhanced.lua`, `modules/UnitButtons.lua` | A secure write held under combat lockdown, **once per key** with the count held (a later write under the key replaces it silently); the flush after combat or at a stand-up, with how many ran; how many writes a stand-down or stand-up leaves held, when there are any; a unit button's state driver set or released; a blocked or forbidden action blamed on this addon (ungated) |
| `Bus` | `core/Bus.lua` | A message or event the client refused when the bus came back up |
| `Provider` | `modules/Providers.lua` | A resolve that changed the frame system or any unit's frame (change-gated by the resolve itself); EllesmereUI or its raid frames loading after this addon; the Edit Mode exit callback refused, once per distinct error |
| `Anchor` | `modules/Anchor.lua` | A placement pass that moved, faded or followed something (`moved N, no frame N, faded N, followed N`; a pass that changed nothing is silent). `followed` counts the secure elements an in-combat pass left to `modules/SecureFollow.lua`'s snippet instead of fading; a free-placement stack dropped after a drag, with its stored position; every stack reset to default |
| `Follow` | `modules/SecureFollow.lua` | The in-combat follow (#3): how many member frames a pass wrapped and for which provider (`wrapped N ellesmere frame(s) …`, silent when it wrapped none); a wrap the client refused, **once per distinct error**; how many wraps a stand-down left attached and gated off because another addon's wrap is outermost; at enable, that the client has no `SecureHandlerWrapScript` and the fade stays |
| `Fade` | `modules/RangeFade.lua` | The out-of-range fade's mode (`off`, `idle`, `range`, `copy`), whether it listens and how many frames it hooked, **change-gated** |
| `Cast` | `modules/CastBars.lua` | A cast bar hidden while its unit casts, **change-gated** per unit (once per reason, re-armed when the bar shows); an interrupted or failed cast; how many units it listens for, when that changes |
| `Target` | `modules/TargetFrames.lua` | Who each member targets, **change-gated** per button; the health ticker starting and stopping |
| `Pet` | `modules/PetFrames.lua` | A member's pet appearing or going, **change-gated** per button |
| `Preview` | `modules/Preview.lua`, `settings/Slash.lua` | Preview on and off; the stand-in's look and size, **change-gated** (once per raise); an unlock refused, naming the guard (`in combat`, `addon disabled`, `perf run suspended`); the lock toggle refused while disabled |
| `Perf` | the library's perf harness, through `core/PerfSetup.lua`'s `log` | A perf capture's progress and results (ungated: a capture is an explicit act) |
| `Cmd` | the library, from `settings/Slash.lua`'s `debug` | Each refusal the dispatcher decides, one line after its chat line, `refused <verb>[ <arg>]: <guard>`: the disabled gate, an unknown verb, `get` / `set` / `reset` usage and not-found, a parse or write refusal, a reset with no default, and the profile verb's unavailable, already-current, in-combat and unknown-profile refusals. A refusal `settings/Slash.lua` decides itself (the lock toggle, the profile sub-verbs) is not a `Cmd` line |
| `Cfg` | the library, from `settings/OptionsSetup.lua` | The settings panel opened, refused in combat, or its registration parked in combat and flushed when combat ends; each act an open panel's combat lock refuses, `<what> refused (in combat)` (a write, Defaults, a button, a toggle, a tab), once per text per combat |
| `Launcher` | the library, from `core/LauncherSetup.lua` | The launcher's clicks and menu; `Register`'s state at login (`LibDataBroker-1.1 absent; no launcher`, `LibDBIcon-1.0 absent; broker plugin only`, no minimap table, `registered`), held by the console's at-enable queue (`debugAtEnable`) while the flag is off and written once when logging turns on, after the `[Init]` line |
| `Diag` | the library | The report's markers, identity header, failed sections and `truncated` line |

A new tag is a one-word string at the call site. Add its row here in the same change.

### Quiet steady state

The repeating paths, and why each is quiet when nothing changed:

- **The cast bars' `OnUpdate`**, **the target health ticker** and **the pet health events** log
  nothing per pass. What they did is counted in the `[Combat]` rollup instead.
- **`UNIT_TARGET` / `PLAYER_TARGET_CHANGED`** and **`UNIT_PET`** compare the stringified name with
  the last one logged for that button. A secret name reads `<secret>`, so two secret targets in a
  row log once; `targetEvents` in the rollup still counts every event.
- **The resolve** (every party-frame show, hide and unit attribute change) and **the placement
  pass** log only a pass that changed something.
- **The secure queue** logs a key when it is first held, not each time a later write replaces it,
  so a re-sort in combat that re-queues the same anchor pass many times adds one line.
- **The stand-in** re-dresses on every roster update while you preview out of a party. It logs its
  look once per raise: lowering it forgets the gate's key, so the next raise says itself.
- **The range fade** re-runs on every `LAYOUT`, `VISIBILITY`, `PROFILE` and General write. It logs
  its mode line only when that line changes.

### Deliberately not logged

- **Refused event registrations** at the moment they happen: most registrations run at login, when
  the flag is off. `/pfe status` and the report's `events` section name every refused event.
- **The secret-value `pcall`s in `core/Compat.lua`.** They are guards that fail by design on a
  secret. The value they would have logged is the secret itself.
- **Restriction and spec edges.** The addon does not react to `ADDON_RESTRICTION_STATE_CHANGED` or
  a spec change, so there is no edge to log.

## The diagnostics report

### Running it

There are exactly two slash forms, and no third:

- `/pfe diagnostics`, a row of the `COMMANDS` table in `settings/Slash.lua`;
- `/pfe debug diagnostics`, the first word `runDebug` tests, in any case.

The console's orange **Diagnostics** link runs the same report.

`/partyframeenhanced` reaches both, as it reaches every verb. `diag`, `dump`, `dx` and every other
short name are ordinary words: `/pfe diag` prints `unknown command 'diag'` and the help, and
`/pfe debug diag` shows or hides the window like any other word after `debug`.

`diagnostics` is on this addon's live set (`LIVE_WHILE_DISABLED` in `settings/Slash.lua`), so both
forms answer while the addon is **disabled**. A disabled addon is stood down, and the report says so
on its state lines rather than printing empty data.

### What it does to the console

- **It appends.** The report lands after whatever the console already holds, so the trace a player
  has just reproduced stays above it and one Copy carries both. Nothing the report reaches calls
  `Clear()`.
- **It turns logging on for the session.** With logging off, a run first turns it on through the
  flag's one seam, `NS.DebugLog:SetEnabled(true)`, so the chat ack, the `[Debug] logging enabled`
  line and the `[Init]` summary come before the report, and the player's next reproduction is
  traced (`debug-logging-§14`). With logging already on it writes no second enable line. It never
  turns logging off. The flag is session-only, so a `/reload` turns it off again. This addon keeps
  the library's default: it does not set `diagnosticsEnablesLogging = false`.
- **It is ungated.** It writes through the library's raw append, not `NS.Debug`, so it lands in full
  whatever the flag says. The sections only print the flag; the run is what turns it on.
- **It reveals the console** if it is hidden, then prints one chat line through `NS.L`:
  `Diagnostic report written to the debug console: N lines. Use Copy to share it.`
- **It is plain text.** The library strips color, texture, atlas and hyperlink escapes from every
  line, so the Copy text reads cleanly.

The report body is English diagnostic text and does not go through `NS.L`, like every trace line.

### What it prints

The library writes the frame: the begin marker, the identity header, each section under its own
`pcall`, the cap and the end marker. `modules/Diagnostics.lua` writes the sections in between, in
this order (`Diagnostics.Sections()`). The tag in brackets is what each line carries in the paste.

| Section | Tag | What it reports |
|---|---|---|
| (begin) | `Diag` | `==== Ka0s Party Frame Enhanced diagnostics begin ====` |
| (library identity) | `Diag` | The `[Init]` summary; the client's version, build, date and interface from `GetBuildInfo()`; the locale; the logging flag; `InCombatLockdown` and `UnitAffectingCombat("player")`; the **running** LibKa0s minors, file by file, which under LibStub may come from another addon's vendored copy |
| identity | `State` | The stored and code schema versions and the profile; the stored master switch, whether the addon is stood down and its Lifecycle holds; the preview, unlocked, in-combat and in-party flags; whether a perf capture is on or suspended |
| settings | `Set` | Every row that differs from its default as `path = value (default)`. `enabled`, `locked`, `visibility`, `general.provider` and `general.includePlayer` always print, whatever their value |
| party | `Party` | In a party, in a raid; for each of `player`, `party1`..`party4`, whether the unit is included and its class **token** (an empty slot reads `nil`) |
| frames | `Frames` | The frame-system setting against the one that resolved; the frame showing each unit, **by name**, marked `(stand-in)` when it is the preview's stand-in; the resolver's suspended, scheduled and stale flags; whether the stand-in is shown, whether EllesmereUI and its raid frames are loaded, and whether `ERFPartyHeader` exists. Stood down, one line says so |
| placement | `Place` | For `castbar`, `target` and `pet`: the anchor mode, the stored free-placement position, the one Anchor last applied, and whether the holder is shown |
| elements | `Elem` | Per feature per unit, one line: `shown`, then for a cast bar `state`, `registered`, `ticking`, `hiddenWhy`, `previewing`, and for a target or pet button `registered`, `allowed`, the state driver wanted and set, the click attributes wanted and set, and `pending`. These print stood down too, so a driver released in combat shows here |
| rangefade | `Fade` | The fade mode (`off`, `idle`, `range` or `copy`), whether it listens, how many party frames it hooked, and each unit's hooked frame by name. Stood down, one line says so |
| secure | `Secure` | How many secure writes are queued and their keys, in the order they were queued; whether the flush listener is armed; the blocked or forbidden actions blamed on this addon this session; the in-combat follow, `follow: header=yes\|no wrapped=N refused=N` (#3) |
| events | `Events` | The event names this client refused; whether the bus record is the library's or an untracked stub; any LibKa0s major this addon consumes that did not load (a degraded arm) |
| (end) | `Diag` | `==== Ka0s Party Frame Enhanced diagnostics end: N line(s) ====`, with `N` counting both markers |

A section that raises costs one line, `section <name> failed: <err>`, and the rest of the report
still lands. The elements section runs each feature-and-unit line as its own section, so one bad
element costs its own line and no other. On an install where `modules/Diagnostics.lua` failed to
load, the report is the markers and the identity header around no sections.

### Caps

- **The whole report** stops at `lib.DIAG_MAX_LINES` (1200), which the library clamps to
  `lib.MAX_BUFFER - 100`, so the report never pushes itself out of the buffer. The trace above it is
  kept on a best-effort basis: a trace near the buffer's size loses its oldest lines to the report.
- **Each list** (the queued keys, the rejected events) prints at most `lib.DIAG_MAX_PER_LIST` (40)
  entries and then `(+N more)`. A long joined line wraps at 200 characters.
- A capped report ends with `truncated: N line(s) omitted, per-list caps hit=yes|no`, then the end
  marker.

### What it does not do

- **It writes nothing** beyond the logging flag above. No setting, no secure write queued or flushed, no event, message or timer
  registered, nothing shown, hidden, resolved or built, and no stand-in created
  (`NS.StandIn.IsStandIn` never builds one). A report that repaired the state would describe a state
  the player is not in.
- **It calls no protected API**, so it is safe in combat, stood down or not.
- **It does not read what the client keeps secret.** It never reads a party member's cast
  (`UnitCastingInfo` / `UnitChannelInfo`), a fade frame's alpha, or `UnitIsUnit` on a compound token.
  An element field that holds a secret the client handed a paint call is passed raw to the library,
  which stringifies it through `NS.SafeToString`, so it prints as `<secret>` and never reaches a
  comparison. `tests/test_diagnostics.lua` scans the sections file for these calls.
- **It never calls `GetPoint` on a Blizzard or EllesmereUI frame.** Positions come from the stored
  config and from Anchor's memo of what it last applied, and a foreign frame is reported by name.
- **It does not call `UnitExists`**, which `.luacheckrc` bans; a nil class token already says a party
  slot is empty.
- **Nothing is redacted.** Players send the report to the maintainer privately, so it prints what a
  maintainer needs to reproduce the bug.

With no LibKa0s the stub's `RunDiagnostics` prints
`/pfe diagnostics is unavailable: the LibKa0s library did not load.` for both forms, writes nothing
and returns 0.

## Where else this is pinned

The command rows are in [slash-dispatch.md](slash-dispatch.md), and the player-facing steps are the
README's `## Reporting a bug`. The in-game checks are DIAG-1 to DIAG-14 in
[smoke-tests.md](smoke-tests.md). The suites are `tests/test_diagnostics.lua` (this addon's
sections), the kit's shared `tests/_kit/test_diagnostics_contract.lua` (wired in `tests/run.lua`),
`tests/test_disabled.lua` and `tests/test_slash.lua`.
