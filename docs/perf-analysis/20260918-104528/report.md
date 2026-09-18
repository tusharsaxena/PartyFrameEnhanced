# Report — 20260918-104528

What the client printed for this capture, copied from the debug-log window. Nothing below is edited;
the `HH:MM:SS | [Tag]` prefixes are the client's own timestamps. The JSON record is
[`dump.json`](dump.json).

The player's note that came with the paste: *"this time with the health updates on"*.

## The report (`/pfe perf report`)

```
10:45:28 | [Perf] capture: 2026-09-18 10:40  (PartyFrameEnhanced, schema 2, v0.1.0)
10:45:28 | [Perf] who:       Sacrìlege-Frostmourne, level 90 Protection Paladin
10:45:28 | [Perf] where:     Murder Row
10:45:28 | [Perf] group:     party (5) / party
10:45:28 | [Perf] active:       51.0s    3015 frames    59.2 fps   16.90 ms/frame
10:45:28 | [Perf] suspended:    55.1s    3439 frames    62.4 fps   16.02 ms/frame
10:45:28 | [Perf] delta:                                                   +0.89 ms/frame
10:45:28 | [Perf] 
10:45:28 | [Perf] bucket            calls   total ms       ms/s    max ms
10:45:28 | [Perf] castEvent           160       3.61      0.071     0.111
10:45:28 | [Perf]   castRender         40       2.50      0.049     0.107
10:45:28 | [Perf] castTick           2426      10.04      0.197     0.062
10:45:28 | [Perf] targetEvent         149       9.17      0.180     0.118
10:45:28 | [Perf] targetTick          254      17.94      0.352     0.119
10:45:28 | [Perf]   targetRender     1119      15.04      0.295     0.048
10:45:28 | [Perf] (buckets nest: castRender observed inside castEvent, targetRender observed inside targetTick — do not sum)
```

## Run log (lifecycle)

The capture's provenance: both arms combat-gated, arm B suspended, and no `/reload` between them.

```
10:40:08 | [Perf] run started — 2026-09-18 10:40
10:40:08 | [Perf] who:       Sacrìlege-Frostmourne, level 90 Protection Paladin
10:40:08 | [Perf] where:     Murder Row
10:40:08 | [Perf] group:     party (5) / party
10:40:08 | [Perf] perf run STARTED — 2026-09-18 10:40
10:40:12 | [Perf] experiment A armed (addon active) — waiting for combat
10:40:18 | [Perf] Experiment A RECORDING — combat started
10:41:09 | [Perf] Experiment A ENDED — 51.0s, 3015 frames, 59.2 fps
10:44:23 | [Perf] addon SUSPENDED — inert
10:44:23 | [Perf] experiment B armed (addon SUSPENDED) — waiting for combat
10:44:28 | [Perf] Experiment B RECORDING — combat started
10:45:23 | [Perf] Experiment B ENDED — 55.1s, 3439 frames, 62.4 fps
10:45:27 | [Perf] run finished — A 51.0s / 3015 frames, B 55.1s / 3439 frames
10:45:27 | [Perf] addon RESUMED — events and frames restored
10:45:27 | [Perf] perf run FINISHED — saved; `Report` or `Dump` in the panel to read it, `/reload` to flush it to SavedVariables
```
