# Candidates (PartyFrameEnhanced)

One new surface, and it is the reason for the re-vendor.

| Candidate | Where | Recommendation |
|---|---|---|
| Slash minor 17 profile verb: the `profiles` descriptor field, `cli:CliProfile(rest)` and `cli:ProfileSwitch(name)` | `LibKa0s/docs/api/Slash/version-17-docs.md`, *The profile verb* | **Adopt**, in item SP-PF-02's second commit. `settings/Slash.lua`'s own `profile` sub-tree already refuses an unknown `use` name; routing it through the library gives the collection one wording and adds the bare `profile <name>` form (owner decisions D1 and D3). |

`lib.ProfileNames(store)` is not adopted on its own: the library's list already renders through
`CliProfile("")`, which the reworked sub-tree calls.
