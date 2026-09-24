# Slash dispatch

`/pfe` and `/partyframeenhanced` are registered through AceConsole (`settings/Slash.lua`,
`Sl:Register`). Dispatch, help rendering, formatting and value parsing are `LibKa0s-Slash-1.0`'s; the
addon owns the ordered `NS.COMMANDS` table of positional `{name, desc, fn}` triples and passes it in.
The landing page renders the same table.

## Commands

| Verb | What it does | Reserved |
|---|---|---|
| `help` | the command list | yes |
| `config` (alias `options`) | opens the settings panel on its landing page (bare `/pfe` does the same); refused in combat with a gray notice | yes |
| `enable` / `disable` | the addon-wide switch. **Aliases for the Master-controls *Enable Party Frame Enhanced* row** (slash-commands-§2), never a second switch: both write `enabled` through `NS.SetByPath`, run its `onChange` (`NS.PublishVisibility`) and hold no state of their own. The echo is the shared `path = value` formatter, read back from the store after the write | yes |
| `list` | every setting and its value, grouped by page | yes |
| `get <path>` | one setting's value | yes |
| `set <path> <value>` | sets a setting through the write seam; echoes the stored value | yes |
| `reset <path>` | one setting back to its default | yes |
| `resetall` | the global reset: the active profile back to defaults | yes |
| `resetposition` | every free-placement stack back to its default position (`NS.Anchor.ResetPositions`). **Refuses while the addon is disabled** — one line, the library's | no |
| `lock` | locks the elements and leaves preview mode. **Refuses while the addon is disabled** | no |
| `unlock` | unlocks them for dragging, with placeholder content; refused in combat with a gray notice. **Refuses while the addon is disabled**, at the dispatcher — before the write seam | no |
| ~~`test`~~ | **Removed** (options-ui-§15). Unlocking already is this addon's preview, so `unlock` / `lock` are the switch and a second verb for the same state was the finding (anti-pattern #80). What it did — placeholders at the real party frames in a party, a stand-in party frame for party1 out of one, refused in combat, disabled or suspended; ends when combat starts | no |
| `status` | the detected frame system, which units have a frame, each feature's state, how the out-of-range fade is running (copied from a frame system, the classic frames' own range check, waiting, or off), whether preview is up and on what, and anything switched off (including not being in a party) | no |
| `debug [on\|off]` | bare: toggles the console window; `on`/`off`: the session logging flag | yes |
| `perf [...]` | the LibKa0s-Perf guided capture; bare opens the step panel | yes |
| `version` | the addon version from the TOC | yes |
| `profile [list\|current\|use\|new\|copy\|delete\|reset]` | profile management. Every name is checked against the profile list first, and a bad one is refused on one line: `use` no longer creates a profile (a missing name is refused), `new` refuses a name that already exists instead of wiping it, `copy` refuses a missing name and the current profile, and `delete` refuses a missing name as well as the current profile | no |

## The disabled state

**The addon stands down; the command surface does not.** Those are two separate facts and they are
not in tension. The stand-down is total — every registration unregistered, every timer canceled,
nothing drawn, nothing written from a game event (slash-commands-§7, and
[ARCHITECTURE.md](ARCHITECTURE.md#the-disabled-state-is-total)) — while the dispatcher, the
`COMMANDS` table, the settings registration and the launcher registration are **setup**, not
features: they come up on load in either state and stay up. Keeping them live costs nothing the
stand-down was trying to reclaim. The addon is inert; its command surface is not the addon.

`Sl:Register` runs in `addon:OnInitialize` in either state, so `/pfe` is always registered.

**Every reserved verb answers, and the bare `/pfe` opens the settings panel.** `help`, `config`,
`version`, `enable`, `disable`, `debug`, `perf` and the whole schema CLI — `get`, `set`, `list`,
`reset`, `resetall` — all behave exactly as they do when the addon is running. A player must be able
to read and repair settings and to reach the panel while the addon is off, which is precisely when
they are most likely to need to, and `enable` above all or the switch only goes one way. `debug` and
`perf` are diagnostics rather than features: the usual reason to reach for either is that the addon
is misbehaving.

> The standard narrowed this surface to `enable` and `help` at v2.56.0 and **reversed it at
> v2.57.0**, after `/pfe` on a disabled addon answered with a refusal instead of the panel — the one
> surface a player uses to switch it back on by hand. This addon tracks the reversal (LibKa0s
> v1.41.0, `LibKa0s-Slash-1.0` minor 13).

**Only a verb that drives the features refuses.** With `enabled` false, `resetposition`, `lock` and
`unlock` answer on **one** tagged line and do nothing else — no partial work, no side effect, no
second line. All three drive what the addon draws, and unlocking *is* this addon's preview switch
(options-ui-§15). Acting would be wrong twice over: the player asked for something the addon is
standing down from, and a silent no-op leaves them with no clue why nothing happened.

**The gate is the library's.** `settings/Slash.lua` hands `LibKa0s-Slash-1.0` an `isEnabled` reader
and a `brandName`, and the dispatcher does the rest; the refusal's wording lives in
`cli:DisabledLine()` and is the collection's, never re-spelled here. The gate sits **after** the
`COMMANDS` lookup, so a typo still gets `unknown command '<verb>'` and the index: a misspelling is
the addon failing to understand, not the addon refusing. The same answer goes to a reserved verb the
addon never registered: nothing was refused, so nothing says it was (`LibKa0s-Slash-1.0` minor 14).

**The live set this addon declares** is the standard's twelve plus two of its own, on the same
reasoning rather than as exceptions to it: **`status`** is a diagnostic like `debug` (it changes
nothing, and its first flag is `addon disabled`, so refusing it would delete the answer), and
**`profile`** is settings management in the class of the schema CLI. Declaring `liveVerbs` **replaces**
the library's default, so the twelve are spelled out beside them. Widening is conformant; narrowing
would not be.

`tests/test_slash.lua` and `tests/test_disabled.lua` pin all of it: the bare `/pfe` opens the panel
while disabled, every reserved verb answers normally, the three feature verbs answer on exactly one
line matching the library's own, and the seam is never entered.

## Output

The library's shape and colors (slash-commands-§5): green header, azure `[page]` groups, gold paths,
white values, no trailing colon; every line carries the cyan `[PFE]` tag through `NS.Print`.

## Degraded

With LibKa0s absent the stub in `settings/Slash.lua` still dispatches the host verbs; the schema verbs
(`list`, `get`, `set`, `reset`, `resetall`) each print one line naming the missing library. `enable`
and `disable` still WRITE — only their echo degrades to that line — because the pair must never be
one-way, whatever else is missing.

The stub carries the disabled gate too, in the library's shape: the same live set, the same
after-the-lookup ordering (a reserved verb with no registered command is unknown here too), the same one-line refusal built from the same format string, and the same
line under the `help` header. `core/LifecycleSetup.lua` likewise degrades to a hold-set latch of its
own — the library's contract at its smallest, not a second mechanism — so a build without LibKa0s
still stands down, and still stands up only when the last hold is released.
