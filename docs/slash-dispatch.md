# Slash dispatch

`/pfe` and `/partyframeenhanced` are registered through AceConsole (`settings/Slash.lua`,
`Sl:Register`). Dispatch, help rendering, formatting and value parsing are `LibKa0s-Slash-1.0`'s; the
addon owns the ordered `NS.COMMANDS` table of positional `{name, desc, fn}` triples and passes it in.
The landing page renders the same table.

## Commands

| Verb | What it does | Reserved |
|---|---|---|
| `help` | the command list (bare `/pfe` does the same) | yes |
| `config` (alias `options`) | opens the settings panel; refused in combat with a gray notice | yes |
| `list` | every setting and its value, grouped by page | yes |
| `get <path>` | one setting's value | yes |
| `set <path> <value>` | sets a setting through the write seam; echoes the stored value | yes |
| `reset <path>` | one setting back to its default | yes |
| `resetall` | the global reset: the active profile back to defaults | yes |
| `lock` | locks the elements and leaves preview mode | no |
| `unlock` | unlocks them for dragging, with placeholder content | no |
| `debug [on\|off]` | bare: toggles the console window; `on`/`off`: the session logging flag | yes |
| `perf [...]` | the LibKa0s-Perf guided capture; bare opens the step panel | yes |
| `version` | the addon version from the TOC | yes |
| `profile [list\|current\|use\|new\|copy\|delete\|reset]` | profile management | no |

Arriving later: `resetposition` (plan P2), `preview` and `status` (plan P6).

## Output

The library's shape and colors (slash-commands-§5): green header, azure `[page]` groups, gold paths,
white values, no trailing colon; every line carries the cyan `[PFE]` tag through `NS.Print`.

## Degraded

With LibKa0s absent the stub in `settings/Slash.lua` still dispatches the host verbs; the schema verbs
(`list`, `get`, `set`, `reset`, `resetall`) each print one line naming the missing library.
