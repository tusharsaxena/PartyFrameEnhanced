# Profiles

AceDB profiles are user-visible: `settings/Profiles.lua` ships the AceDBOptions page (create, switch,
copy, reset, delete, and the per-character/class/realm scopes), and `/pfe profile …` offers the same
acts from chat.

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

| Event | Debug line |
|---|---|
| switch | `[Profile] changed → <name>` |
| copy | `[Set] copied profile '<source>' → '<current>'` |
| reset | `[Set] reset profile '<name>' to defaults (N rows)` — N only when the addon drove the reset |

## Reset all settings

`/pfe resetall`, the General page's *Reset all settings* and Profiles → *Reset Profile* are **one act**:
the active profile back to defaults, the profile list untouched (options-ui-§12).
