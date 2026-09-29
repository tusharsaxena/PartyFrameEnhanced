# LibKa0s v1.62.0 -> v1.63.0: the delta (PartyFrameEnhanced)

Copied from the local tag `v1.63.0` (`dd7a774`, `git archive v1.63.0 LibKa0s testkit`), never from a
working tree. Item `SP-PF-02` of the 2026-09-29 smoke-rework and `profile` verb run
(`Ka0sAddonsCommonTasks/docs/2026-09-29-SMOKE_REWORK_AND_PROFILE_VERB/`, spec S3). The delta base is
this repo's own CLAUDE.md provenance line, v1.62.0.

## libs/LibKa0s (`diff -rq --strip-trailing-cr`, before the copy)

```
Files <tag>/LibKa0s/Slash.lua and libs/LibKa0s/Slash.lua differ
```

No `Only in` line: no file was added or removed upstream.

| File | v1.62.0 | v1.63.0 |
|---|---|---|
| `Slash.lua` | 16 | 17 |

Every other file is unchanged, and `LibKa0s.xml` is byte-identical, so `tests/run.lua`'s library load
list does not move.

## tests/_kit (`diff -rq --strip-trailing-cr`, before the copy)

No output: the kit is byte-identical at **revision 31**. Both payloads were still copied whole from
the tag, as the pairing rule requires. The runner script stays recorded 100755 in the index.

## Contract delta

Additive only. Slash minor 17 adds the descriptor field `profiles`, two instance members
(`CliProfile`, `ProfileSwitch`), one lib-level function (`ProfileNames`) and nine `PROFILE_*`
strings. `profile` is not added to `lib.LIVE_VERBS`. No `NEEDS_*` floor rises and no member is
removed or repurposed. Source: the v1.63.0 CHANGELOG block and `docs/api/Slash/version-17-docs.md`.

**One test goes red on the copy alone, as the version 17 document's Compatibility section predicts**:
`parity: the Slash stub carries every dispatcher member the addon calls` compares the degraded stub
against the live Slash instance by name, which now has `CliProfile` and `ProfileSwitch`:

```text
LibKa0s-Slash-1.0: the degraded stub diverges from the live surface in 2 place(s) —
CliProfile is missing (live: function); ProfileSwitch is missing (live: function)
```

It is not a blocker: the stub gains both members in the same commit (see 03_DECISIONS.md).
