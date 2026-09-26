# Debug surfaces

Party Frame Enhanced has two debug surfaces, and both write into the same window:

- **The debug console** is `LibKa0s-DebugLog-1.0`'s window. Tagged `NS.Debug` lines land there while
  the session flag is on, and a blocked or forbidden action this addon caused lands there whatever
  the flag says.
- **The diagnostics report** is a one-shot snapshot of the addon's state, written into the console
  by `/pfe diagnostics` (`debug-logging-§14`). It is the reason this page exists (`documentation-§3`,
  Tier 2): every Ka0s addon ships the report, and a maintainer reading a pasted one needs to know what
  each line means.

The console itself is the library's, and its contract lives in LibKa0s's
[`docs/api/DebugLog/version-14.1-docs.md`](https://github.com/tusharsaxena/LibKa0s/blob/master/docs/api/DebugLog/version-14.1-docs.md)
(DebugLog 14.1 is the vendored minor, from LibKa0s v1.60.0). This page covers only what Party Frame
Enhanced adds on top. `/pfe status` is a third way to look inside, but it prints a short summary to
chat and is not a debug surface; [slash-dispatch.md](slash-dispatch.md) has it.

## The console

| Command | Effect |
|---|---|
| `/pfe debug` | Shows or hides the console window. The logging flag is unchanged. |
| `/pfe debug on` / `off` | Sets or clears the logging flag through `NS.DebugLog:SetEnabled`, which confirms on one chat line. |
| `/pfe debug diagnostics` | Writes the diagnostics report (below). |
| `/pfe debug <anything else>` | Shows or hides the window, like the bare `/pfe debug`. |

What Party Frame Enhanced supplies, all in `core/DebugLogSetup.lua`:

- **The flag is ours, and session-only.** It is `NS.State.debug`: off at login, never written to
  SavedVariables, and reset by every `/reload`. The General page's **Debug console** checkbox shows
  and hides the window; it does not set the flag.
- **The buffer is the library's** (`lib.MAX_BUFFER`, 3000 lines in DebugLog 14.1). The footer
  counter reads `N / 3000 lines` and pins there, and Copy pastes out of the same buffer, so a long
  capture keeps only its newest 3000 lines.
- **The `[Init]` line** opens a session when the flag goes on:
  `PartyFrameEnhanced v<version>, schema v<n>, profile '<name>', frames '<frame system>'`. The
  report's identity header prints the same line.
- **The sink is `NS.Debug(tag, fmt, ...)`**, bound bare to the library's gated `Debug`. A call with
  the flag off does nothing and allocates nothing.

On an install without LibKa0s the flag still works and `on` / `off` still confirm. The window is gone,
and the stub says so once.

### Tags in use

| Tag | Emitted by | What it logs |
|---|---|---|
| `Init` | the library, from `core/DebugLogSetup.lua`'s summary | The session summary when logging goes on |
| `Set` | the schema write seam (`settings/Schema.lua`), `core/PartyFrameEnhanced.lua` | Every setting write, profile reset and profile copy |
| `Profile` | `core/PartyFrameEnhanced.lua` | A profile switch |
| `Migrate` | `core/Database.lua` | The schema migration steps that ran |
| `Party` | `core/PartyFrameEnhanced.lua` | Joining or leaving a party, which turns the addon's display on or off |
| `Combat` | `core/PartyFrameEnhanced.lua` | Leaving combat, with what was deferred during it |
| `Secure` | `core/PartyFrameEnhanced.lua`, `modules/UnitButtons.lua` | A secure write queued in combat and the flush after it; a unit button's state driver set or released; a blocked or forbidden action blamed on this addon (ungated) |
| `Bus` | `core/Bus.lua` | A message or event the client refused on stand-up |
| `Provider` | `modules/Providers.lua` | Which frame system resolved |
| `Anchor` | `modules/Anchor.lua` | A placement pass: moved, no frame, faded |
| `Cast` | `modules/CastBars.lua` | A cast bar hidden while its unit casts, and why; a bar's lifecycle; how many units it listens for |
| `Target` | `modules/TargetFrames.lua` | Who each member targets; the health ticker starting and stopping |
| `Pet` | `modules/PetFrames.lua` | A member's pet appearing or going |
| `Preview` | `modules/Preview.lua` | Preview on and off, and the stand-in's look and size |
| `Cfg` | the library, from `settings/OptionsSetup.lua` | The settings panel opened, or refused in combat |
| `Launcher` | the library, from `core/LauncherSetup.lua` | The launcher's clicks and menu |
| `Diag` | the library | The report's markers, identity header, failed sections and `truncated` line |

A new tag is a one-word string at the call site. Add its row here in the same change.

## The diagnostics report

### Running it

There are exactly two forms, and no third:

- `/pfe diagnostics`, a row of the `COMMANDS` table in `settings/Slash.lua`;
- `/pfe debug diagnostics`, the first word `runDebug` tests, in any case.

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
- **It is ungated.** It writes through the library's raw append, not `NS.Debug`, so it lands in full
  with logging off, and it does not read or change the flag: the header reads the same afterwards.
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
| secure | `Secure` | How many secure writes are queued and their keys, in the order they were queued; whether the flush listener is armed; the blocked or forbidden actions blamed on this addon this session |
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

- **It writes nothing.** No setting, no secure write queued or flushed, no event, message or timer
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
README's `## Reporting a bug`. The in-game checks are steps 21 to 23f in
[smoke-tests.md](smoke-tests.md). The suites are `tests/test_diagnostics.lua` (this addon's
sections), the kit's shared `tests/_kit/test_diagnostics_contract.lua` (wired in `tests/run.lua`),
`tests/test_disabled.lua` and `tests/test_slash.lua`.
