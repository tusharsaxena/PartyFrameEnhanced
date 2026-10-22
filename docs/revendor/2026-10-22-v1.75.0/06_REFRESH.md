# 06 — Refresh: LibKa0s v1.75.0 from the moved local tag

Run 2026-10-23, plan item PF-RV2, on branch `feat/2026-10-22-libka0s-issues-45-58`. Files 01, 02 and
05 are frozen and record the PF-RV copy; this file records what happened after it.

## Why

The local tag `v1.75.0` moved after PF-RV vendored it. It went from `265a89e` to `6bf5f3e` (LK-26:
Sim minor 2, SimTimeline minor 2) and then to `9e5c4e2` (LK-27: SimPanel minor 2), its final
position. This refresh brings the vendored payload from **`265a89e`** to **`9e5c4e2`**.

## What changed

`libs/LibKa0s/` and `tests/_kit/` were compared with `git -C ../LibKa0s archive v1.75.0 LibKa0s
testkit` at `9e5c4e2`. The only differences, apart from the icons the declaration prunes, were three
files, which were copied whole:

| File | Before (`265a89e`) | After (`9e5c4e2`) |
|---|---|---|
| `libs/LibKa0s/Sim.lua` | `LibKa0s-Sim-1.0` minor 1 | minor 2 |
| `libs/LibKa0s/SimTimeline.lua` | `TIMELINE_MINOR` 1 | 2 |
| `libs/LibKa0s/SimPanel.lua` | `SIM_PANEL_MINOR` 1 | 2 |

`tests/_kit/` is identical to the tag's `testkit/` (kit revision unchanged, 41). The icon set is
unchanged: the `LibKa0s icons: clear, close, copy.` line in `CLAUDE.md` was not edited, and the three
kept Open Iconic marks and their license are byte-identical to the tag's. The `CLAUDE.md` provenance
line stays `v1.75.0`.

## Ripple

Nothing in this addon binds `LibKa0s-Sim-1.0`, and no test pins a Sim, SimTimeline or SimPanel minor.
One doc did: `docs/smoke-tests.md` INSTALL-4 lists v1.75.0's minors, and now reads Sim 2,
SimTimeline 2 and SimPanel 2. Its Result stays owed. The addon version and the TOC are unchanged.
