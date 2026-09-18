# Report — 20260918-102842

What the client printed for this capture, copied from the debug-log window. Nothing below is edited;
the `HH:MM:SS | [Tag]` prefixes are the client's own timestamps. The JSON record is
[`dump.json`](dump.json).

## The report (`/pfe perf report`)

```
10:28:42 | [Perf] capture: 2026-09-18 10:26  (PartyFrameEnhanced, schema 2, v0.1.0)
10:28:42 | [Perf] who:       Sacrìlege-Frostmourne, level 90 Protection Paladin
10:28:42 | [Perf] where:     Murder Row
10:28:42 | [Perf] group:     party (5) / party
10:28:42 | [Perf] active:       57.0s    3194 frames    56.0 fps   17.85 ms/frame
10:28:42 | [Perf] suspended:    44.6s    2720 frames    61.0 fps   16.39 ms/frame
10:28:42 | [Perf] delta:                                                   +1.45 ms/frame
10:28:42 | [Perf] 
10:28:42 | [Perf] bucket            calls   total ms       ms/s    max ms
10:28:42 | [Perf] castEvent           182       4.92      0.086     0.124
10:28:42 | [Perf]   castRender         46       3.02      0.053     0.119
10:28:42 | [Perf] castTick           2725      12.07      0.212     0.040
10:28:42 | [Perf] targetEvent         134       8.73      0.153     0.117
10:28:42 | [Perf] (buckets nest: castRender observed inside castEvent — do not sum)
```

## Run log (lifecycle)

The capture's provenance: both arms combat-gated, arm B suspended, and no `/reload` between them.

The first block is an **earlier run that was canceled** in Silvermoon City after its arm A. The client
discarded it and it isn't in the record. It's kept here because it's the same session, and it shows a
suspend followed by a resume just before this capture's run started.

```
10:23:46 | [Perf] run started — 2026-09-18 10:23
10:23:46 | [Perf] who:       Sacrìlege-Frostmourne, level 90 Protection Paladin
10:23:46 | [Perf] where:     Silvermoon City — The Bazaar
10:23:46 | [Perf] group:     solo
10:23:46 | [Perf] perf run STARTED — 2026-09-18 10:23
10:24:15 | [Perf] experiment A armed (addon active) — waiting for combat
10:24:24 | [Perf] Experiment A RECORDING — combat started
10:25:14 | [Perf] Experiment A ENDED — 50.2s, 2808 frames, 55.9 fps
10:25:18 | [Perf] addon SUSPENDED — inert
10:25:18 | [Perf] experiment B armed (addon SUSPENDED) — waiting for combat
10:25:53 | [Perf] addon RESUMED — events and frames restored
10:25:53 | [Perf] run CANCELED — measurements discarded, nothing saved
```

The run this bundle records:

```
10:26:06 | [Perf] run started — 2026-09-18 10:26
10:26:06 | [Perf] who:       Sacrìlege-Frostmourne, level 90 Protection Paladin
10:26:06 | [Perf] where:     Murder Row
10:26:06 | [Perf] group:     party (5) / party
10:26:06 | [Perf] perf run STARTED — 2026-09-18 10:26
10:26:07 | [Perf] experiment A armed (addon active) — waiting for combat
10:26:16 | [Perf] Experiment A RECORDING — combat started
10:27:13 | [Perf] Experiment A ENDED — 57.0s, 3194 frames, 56.0 fps
10:27:47 | [Perf] addon SUSPENDED — inert
10:27:47 | [Perf] experiment B armed (addon SUSPENDED) — waiting for combat
10:27:53 | [Perf] Experiment B RECORDING — combat started
10:28:37 | [Perf] Experiment B ENDED — 44.6s, 2720 frames, 61.0 fps
10:28:41 | [Perf] run finished — A 57.0s / 3194 frames, B 44.6s / 2720 frames
10:28:41 | [Perf] addon RESUMED — events and frames restored
10:28:41 | [Perf] perf run FINISHED — saved; `Report` or `Dump` in the panel to read it, `/reload` to flush it to SavedVariables
```
