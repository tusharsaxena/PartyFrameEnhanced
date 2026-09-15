# Report — 20260915-161824

What the client printed for this capture, copied from the debug-log window. Nothing below is edited;
the `HH:MM:SS | [Tag]` prefixes are the client's own timestamps. The JSON record is
[`dump.json`](dump.json).

## The report (`/pfe perf report`)

```
16:18:24 | [Perf] capture: 2026-09-15 16:14  (PartyFrameEnhanced, schema 2, v0.1.0)
16:18:24 | [Perf] who:       Nylexia-Frostmourne, level 90 Vengeance Demon Hunter
16:18:24 | [Perf] where:     Silvermoon City — The Bazaar
16:18:24 | [Perf] group:     solo
16:18:24 | [Perf] active:       68.6s    3432 frames    50.0 fps   19.99 ms/frame
16:18:24 | [Perf] suspended:    62.8s    3421 frames    54.5 fps   18.37 ms/frame
16:18:24 | [Perf] delta:                                                   +1.63 ms/frame
16:18:24 | [Perf] 
16:18:24 | [Perf] bucket            calls   total ms       ms/s    max ms
16:18:24 | [Perf] castEvent           261       7.81      0.114     0.228
16:18:24 | [Perf]   castRender         58       4.85      0.071     0.222
16:18:24 | [Perf] castTick           2829      14.42      0.210     0.049
16:18:24 | [Perf] targetEvent         164      13.93      0.203     0.162
16:18:24 | [Perf] targetTick          343      22.92      0.334     0.192
16:18:24 | [Perf]   targetRender     1676      16.71      0.244     0.141
16:18:24 | [Perf] (buckets nest: castRender observed inside castEvent, targetRender observed inside targetTick — do not sum)
```

## Run log (lifecycle)

The capture's provenance: both arms combat-gated, arm B suspended, and no `/reload` between them.

```
16:14:26 | [Perf] run started — 2026-09-15 16:14
16:14:26 | [Perf] who:       Nylexia-Frostmourne, level 90 Vengeance Demon Hunter
16:14:26 | [Perf] where:     Silvermoon City — The Bazaar
16:14:26 | [Perf] group:     solo
16:14:26 | [Perf] perf run STARTED — 2026-09-15 16:14
16:15:07 | [Perf] experiment A armed (addon active) — waiting for combat
16:15:12 | [Perf] Experiment A RECORDING — combat started
16:16:21 | [Perf] Experiment A ENDED — 68.6s, 3432 frames, 50.0 fps
16:17:15 | [Perf] addon SUSPENDED — inert
16:17:15 | [Perf] experiment B armed (addon SUSPENDED) — waiting for combat
16:17:18 | [Perf] Experiment B RECORDING — combat started
16:18:21 | [Perf] Experiment B ENDED — 62.8s, 3421 frames, 54.5 fps
16:18:23 | [Perf] run finished — A 68.6s / 3432 frames, B 62.8s / 3421 frames
16:18:23 | [Perf] addon RESUMED — events and frames restored
16:18:23 | [Perf] perf run FINISHED — saved; `Report` or `Dump` in the panel to read it, `/reload` to flush it to SavedVariables
```
