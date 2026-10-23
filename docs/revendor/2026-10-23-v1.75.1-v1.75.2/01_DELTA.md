Delta: LibKa0s v1.75.1 -> v1.75.2 (span: v1.75.1 v1.75.2)

# LibKa0s v1.75.1 and v1.75.2: the consolidated span (PartyFrameEnhanced)

Written 2026-10-23 by `PF-RV` (the v1.76.0 re-vendor of the 2026-10-23 sim auto-run, QC preview
selector, mode strips and MM/KCD simulators run), as the revendor-libka0s Step 3h back-fill. Both tags
were carried by plain re-vendor commits after the 2026-10-22 run, which wrote no `docs/revendor/`
bundle. Nothing is decided here in retrospect.

## The listing

```sh
horizon=$(ls -1 docs/revendor | sort | head -1 | cut -c1-10)     # 2026-09-23
# vendored: every tag the provenance line named at a payload commit or a CLAUDE.md roll since the horizon
# recorded: every tag a docs/revendor/ bundle names
grep -vxF -f recorded.txt vendored.txt
v1.75.1
v1.75.2
```

(The full script is revendor-libka0s Step 3h.)

## The carriers

| Tag | Library tag / commit | Carrier commit here | Non-payload files it touched |
|---|---|---|---|
| v1.75.1 | `a86ab6a` / `39dfb98` | `b27a600` 2026-10-23 `Re-vendor LibKa0s v1.75.1 (SimPanel minor 3)` | `CLAUDE.md` (provenance) |
| v1.75.2 | `2722544` / `154599c` | `8e069a8` 2026-10-23 `Re-vendor LibKa0s v1.75.2 (SimPanel minor 4)` | `CLAUDE.md` (provenance) |

## Per-file minors (LibStub), v1.75.0 -> v1.75.2

`git -C ../LibKa0s diff --stat v1.75.0 v1.75.1 -- LibKa0s testkit` and `... v1.75.1 v1.75.2 ...`
each name one file, `LibKa0s/SimPanel.lua`.

| File | v1.75.0 | v1.75.1 | v1.75.2 |
|---|---|---|---|
| `SimPanel.lua` (`SIM_PANEL_MINOR`) | 2 | 3 (rows and controls keep hover while disabled) | 4 (the scenario dropdown fits its label) |
| every other file (39) | — | unchanged | unchanged |

Test kit revision 41 throughout.

## Consumption

`LibKa0s-Sim-1.0` is vendored and not wired here (LibKa0s#54), so neither tag reached any code path
this addon drives. No consumed major moved a minor across the span, so no contract change applied.
