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
| `resetposition` | every free-placement stack back to its default position (`NS.Anchor.ResetPositions`) | no |
| `lock` | locks the elements and leaves preview mode | no |
| `unlock` | unlocks them for dragging, with placeholder content; refused in combat with a gray notice | no |
| ~~`test`~~ | **Removed** (options-ui-§15). Unlocking already is this addon's preview, so `unlock` / `lock` are the switch and a second verb for the same state was the finding (anti-pattern #80). What it did — placeholders at the real party frames in a party, a stand-in party frame for party1 out of one, refused in combat, disabled or suspended; ends when combat starts | no |
| `status` | the detected frame system, which units have a frame, each feature's state, whether preview is up and on what, and anything switched off (including not being in a party) | no |
| `debug [on\|off]` | bare: toggles the console window; `on`/`off`: the session logging flag | yes |
| `perf [...]` | the LibKa0s-Perf guided capture; bare opens the step panel | yes |
| `version` | the addon version from the TOC | yes |
| `profile [list\|current\|use\|new\|copy\|delete\|reset]` | profile management | no |

## The disabled state

`Sl:Register` runs in `addon:OnInitialize` and no verb gates on `enabled`, so **every verb keeps
working while the addon is disabled** (slash-commands-§2). *Disabled* means the features stand down;
it does not mean the chat command goes away. `enable` above all — with `help`, `config` and
`version` — must answer, or the switch only goes one way and the player who turned the addon off has
no route back but the settings panel they were trying not to open. `tests/test_slash.lua` pins it.

## Output

The library's shape and colors (slash-commands-§5): green header, azure `[page]` groups, gold paths,
white values, no trailing colon; every line carries the cyan `[PFE]` tag through `NS.Print`.

## Degraded

With LibKa0s absent the stub in `settings/Slash.lua` still dispatches the host verbs; the schema verbs
(`list`, `get`, `set`, `reset`, `resetall`) each print one line naming the missing library. `enable`
and `disable` still WRITE — only their echo degrades to that line — because the pair must never be
one-way, whatever else is missing.
