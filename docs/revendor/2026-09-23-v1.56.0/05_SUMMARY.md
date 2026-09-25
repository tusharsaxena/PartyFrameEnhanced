# Summary: LibKa0s v1.55.0 -> v1.56.0

Step 8 of `revendor-libka0s`, for plan item RV-PF of the 2026-09-23 remediation. This run is the
payload copy only: both payloads whole, and the `CLAUDE.md` provenance line rolled, in one commit.
Adoption decisions are not taken here. They are this addon's M3 plan items, so this bundle has no
`02_CANDIDATES.md`, `03_DECISIONS.md` or `04_EXECUTION_PLAN.md`.

## The tag and the minors

The tag moved from v1.55.0 to v1.56.0 (a local tag in `../LibKa0s`, read with `git archive`). The
base came from the provenance line, and the last payload commit and the bytes on disk agree with it
(`01_DELTA.md`, 3a). Fifteen files moved a minor: Core 8, Lifecycle 2, Bus 2, Schema 2, Item 2,
Media 4, Widgets 10, DebugLog 13, Slash 15, Launcher 2, Options 24, OptionsWidgets 31,
OptionsTabs 4, OptionsScroll 4 and Perf 13. Env, Compat, Pool, WidgetsDragHandle, OptionsCompose
and PerfPanel are unchanged. No file was added or removed. The kit moved from revision 25 to 26.
The full per-file table is in `01_DELTA.md`, 3b/3c.

No consolidated span bundle was written, and no base correction was owed (the v1.55.0 bundle's
line 1 base, v1.54.2, matches `git show e331135^:CLAUDE.md`). Any span bundle owed for earlier
re-vendors is plan item PF-24's.

## Delivered for free (class A)

- Core 8: `printer.Format` survives a secret in a numeric slot.
- Bus 2: the tracking wrappers are re-stamped after a newer AceEvent-3.0 re-embed.
- Media 4: `RegisterLSM` flags the face western + ruRU and counts only what LSM holds.
- DebugLog 13: the buffer trim is batched at the cap.
- Perf 13: raw `false` state fields, depth reset at windows.
- Options 24.31.4.7.4: `CreateOptionsPanel` called in combat parks and replays at
  `PLAYER_REGEN_ENABLED` (this addon has no park of its own to delete); `OpenOptionsPanel` answers a
  boolean; the page chrome stops leaking a widget per render; the drag throttles keep their own
  armed flag.
- Slash 15: `CliSet` / `CliReset` print the write seam's refusal.
- Launcher 2: the missing-library notice prints once, without the `[LibKa0s] ` prefix.
- Kit 26: `Kit.assertErrorMatches`, `Kit.assertLibraryConstant`, the recording `EventRegistry`,
  the lone-CR `test_eol` gate, the store-root prose files, and the `§`-spelled kit case names.

## Contract blockers

None (`01_DELTA.md`, 3g). No host-supplied member's call site moved, and the addon hands the library
no `__Attach*` members.

## Adopted, declined

Nothing, by design. The opt-ins go to this addon's M3 items: Schema minor 2 with `writeThrough`
(PF-11, the item behind issue #14), Core's `SafeRegisterEvent` family (PF-10), and the Slash stub pinned
with `Kit.assertLibraryConstant` (PF-12).

## Skipped or unreached

The candidate walk (Steps 5 to 7) was not run: the plan assigns every adoption to an M3 item.

## Gates

Every count is from `ka0s-bounded`, run from the repo root.

| Point | Harness | `luacheck` | `lizard` (CCN > 15) |
|---|---|---|---|
| Baseline (v1.55.0 payload) | 289 passed, 0 failed, 0 skipped | 0 / 0 in 71 files | -- |
| After the copy (v1.56.0 payload, kit 26) | 280 passed, **9 failed**, 0 skipped | 0 / 0 in 71 files | none |

All nine reds come from kit revision 26's move to the client's behavior, not from the library:
frames start shown, `EventRegistry` callbacks are recorded without a frame target, and the AceDB fake
behaves as AceDB-3.0 does. `01_DELTA.md`, *Suite after the copy*, lists each case, its failure, the
kit change behind it and the M3 item that clears it. The owner's ruling is that these are fixed in
the addon, never by weakening an assertion. The addon is green again at the latest by PF-DOCS, which
also regenerates `docs/test-cases.md` and the README test badge.
