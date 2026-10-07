# Profiles

AceDB profiles are user-visible: `settings/Profiles.lua` ships the AceDBOptions page (create, switch,
copy, reset, delete, and the per-character/class/realm scopes), and `/pfe profile …` offers the same
acts from chat.

## The `profile` verb

| Input | What it does |
|---|---|
| `/pfe profile` | lists the profiles, the current one marked, then the sub-verbs |
| `/pfe profile <name>` | switches to an existing profile; `"Tank Two"` or `'Tank Two'` strips the quotes, and case and spaces are kept |
| `/pfe profile list` / `current` | the list; the current profile's name |
| `/pfe profile use <name>` | the same switch as `profile <name>`, and the way to reach a profile named like a sub-verb |
| `/pfe profile new` / `copy` / `delete <name>`, `reset` | create and switch, copy into the current profile, delete, reset the current profile |

A first word is a sub-verb in any case (`/pfe profile LIST`); anything else is a profile name. The
list and the switch are `LibKa0s-Slash-1.0`'s (`cli:CliProfile`, `cli:ProfileSwitch`, minor 17), so
they read the same in every Ka0s addon. A switch goes only to a profile that exists: an unknown name
prints *No profile named*, a *Did you mean* when one profile matches but for case, and the list, and
creates nothing. Switching to the current profile says so, and a switch in combat is refused. The verb
answers while the addon is disabled; a switch to a profile that has the addon on stands it back up.
The switch's one debug line is the handler's below, not the verb's.

## What lives in a profile

Everything in `defaults/Profile.lua`: Master controls, the frame-system choice, and every feature's
settings — including each feature's free-placement position, so switching profile moves the stacks
too. Session state (the debug flag, preview mode, the combat flag) is never in a profile.

The perf capture ring (`PartyFrameEnhancedPerfDB`) is deliberately **outside** the profile tree, so a
copy, reset or switch never touches it.

## What happens on a profile event

`core/Database.lua` registers one handler per AceDB event; each logs its one debug line
(debug-logging-§10) and then publishes **PROFILE** and **VISIBILITY**, and refreshes an open panel.
Every module rebuilds from the new profile off that one message.

The lock state comes with the profile, with one exception: a profile stored unlocked and adopted in
combat (a `/pfe profile copy`, which has no combat check of its own, or another addon's
`SetProfile`) is relocked and stored locked, and prints *Locked — combat started*, so preview never
turns on mid-fight.

| Event | Debug line |
|---|---|
| switch | `[Profile] changed → <name>` |
| copy | `[Set] copied profile '<source>' → '<current>'` |
| reset | `[Set] reset profile '<name>' to defaults (N rows)` — N only when the addon drove the reset |

`/pfe profile new <name>` is a switch and nothing more: it refuses a name that already exists, so
`SetProfile` only ever creates, and a new profile is all defaults already. It writes the one
`[Profile] changed` line and publishes **PROFILE** once; there is no reset after it.

## Reset all settings

`/pfe resetall`, the General page's *Reset all settings* and Profiles → *Reset Profile* are **one act**:
the active profile back to defaults, the profile list untouched (options-ui-§12).
