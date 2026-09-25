# 05 - Summary: LibKa0s v1.37.0 -> v1.54.2 (consolidated span)

Written 2026-09-24 as remediation item PF-24 of the 2026-09-23 review and standards-audit
remediation. The previous base was v1.36.1, the scaffold's first vendoring (`246dba6`,
2026-09-15). That was not a re-vendor, and no bundle records it.

The feature work and re-vendor sweeps of 2026-09-16 to 2026-09-22 carried these 14 tags into
`libs/LibKa0s/` and `tests/_kit/` and wrote no bundle for any of them. Each carrier commit, its
diff from the tag before it, and the per-file minors at every tag are in `01_DELTA.md`. Nothing
is decided here in retrospect, so this bundle has no `02_CANDIDATES.md`, `03_DECISIONS.md` or
`04_EXECUTION_PLAN.md`.

## The adoptions the span brought

- **The Master controls Test mode row, v1.37.0** (`c381dc8`): Test mode became the session-only
  checkbox that options-ui-§15 makes canonical, composed from `testModePath`.
- **Bare slash to the config verb, v1.38.0** (`d912a94`): a bare `/pfe` opens the settings panel,
  and the library-absent stub does the same.
- **The launcher, v1.39.0** (`0ef382e`): one LibKa0s-Launcher-1.0 object and the Minimap button
  row on General.
- **The Lifecycle latch, v1.42.0** (`a8e3a44`): `core/LifecycleSetup.lua` takes
  LibKa0s-Lifecycle-1.0 as the one stand-down latch, with the `disabled` and `perf` holds. Perf
  minor 12 takes that latch, and the disabled-state slash refusal moved onto Slash minor 14.
- **`shownWhen`, v1.45.0** (`ea6f8ff`): Size & Position draws only the placement block that the
  anchor mode uses.
- **The kit's US-English gate, v1.54.2** (`7eea3d0`): `tests/_kit/test_prose.lua` replaces the
  repo's own `tests/test_spelling.lua`.

## One line per tag

- v1.37.0: adopted in `c381dc8` (the Master controls Test mode row)
- v1.38.0: adopted in `d912a94` (a bare `/pfe` opens the settings panel)
- v1.39.0: adopted in `0ef382e` (the launcher and the Minimap button row)
- v1.42.0: adopted in `a8e3a44` (Lifecycle latch, Perf minor 12, Slash minor 14)
- v1.43.0: carried by sweep, nothing adopted (kit revision 23, library bytes unchanged)
- v1.44.0: carried by sweep, nothing adopted (no `O.IdList` call site)
- v1.45.0: adopted in `ea6f8ff` (`shownWhen` on Size & Position)
- v1.46.1: carried by sweep, nothing adopted (the combat lock needs no opt-in; `996570f` updated the docs)
- v1.47.0: carried by sweep, nothing adopted (no `O.IdList` call site)
- v1.50.0: carried by sweep, nothing adopted
- v1.51.0: carried by sweep, nothing adopted
- v1.52.0: carried by sweep, nothing adopted
- v1.53.0: carried by sweep, nothing adopted
- v1.54.2: adopted in `7eea3d0` (the kit's US-English gate replaces this repo's own copy)

## The v1.55.0 bundle's base

The frozen `docs/revendor/2026-09-23-v1.55.0/` bundle reads `v1.54.2 -> v1.55.0`. That base is
**correct**. `7eea3d0` re-vendored v1.54.2 whole. It changed only `tests/_kit/`, because the
library bytes are identical to v1.53.0, and it rolled the `CLAUDE.md` provenance line from v1.53.0
to v1.54.2. The frozen bundle stays as written.

## After this bundle

The amended re-vendor check, run with the store's own horizon (its first bundle, 2026-09-23),
reports no unrecorded tag. Run with the 2026-09-15 horizon that the 2026-09-23 audit used, it
reports only v1.36.1, the scaffold's first vendoring. That is the base above, not a re-vendor.
