# Perf analysis — the in-game capture store

**In-game captures only.** A player runs `/pfe perf` in a live client and copies the result out; no
script can produce one (`performance-§8`). **Offline** scenario runs are a different measurement —
`tests/_kit/run-automated-tests.sh` produces them, and they live in the bundle of the run that
produced them under [`../automated-tests/`](../automated-tests/) (`automated-tests-§7`). Offline
`bytes/iter` and `api/iter` say nothing about frame time; an in-game capture says nothing about
allocation.

The store is **standing and cumulative**, so captures compare across addon versions. The protocol and
how to read the numbers are in [../performance.md](../performance.md).

## Bundle naming

```
docs/perf-analysis/<YYYYMMDD-HHMMSS>/
```

One directory per capture, stamped in **local time** from the record's own `timestamp` — when the
capture happened, not when it was written up.

## The three artifacts

| File | What it is |
|---|---|
| `report.md` | What the client printed: the `/pfe perf report` summary plus the run's lifecycle lines |
| `dump.json` | The JSON record the summary was built from — **one line, byte for byte as emitted** |
| `ANALYSIS.md` | The write-up, following the standards repo's root `PERF_ANALYSIS.md` playbook |

`dump.json` is never pretty-printed, re-keyed or rounded: the library emits sorted keys so two records
diff cleanly. Bundles are frozen once written and never pruned; this README is the one file here that
gets rewritten.

## Schema summary

The record shape is the **library's**, versioned there. The field-by-field contract is
[LibKa0s docs/record-schema.md](https://github.com/tusharsaxena/LibKa0s/blob/master/docs/record-schema.md).
In outline, with type placeholders (the captures below carry the real values):

```jsonc
{
  "schema": 2, "addon": "PartyFrameEnhanced", "source": "ingame",
  "version": "<x.y.z>", "interface": <int>, "timestamp": <epoch seconds>, "label": "<text>",
  "context": { "character": "<name>", "class": "<class>", "spec": "<spec>", "zone": "<zone>",
               "group": "<solo | party (N) | …>" },
  "buckets": { "<bucketKey>": { "calls": <int>, "totalMs": <ms>, "maxMs": <ms>,
                                "within": "<declared parent>", "observedWithin": "<observed parent>" } },
  "fps": { "active": { … }, "suspended": { … }, "deltaMsPerFrame": <ms> }
}
```

Buckets nest — never sum a parent and its children. This addon's buckets and their nesting are listed
in [../performance.md](../performance.md).

## Taking a capture

Everything goes through this addon's own verb. `/pfe perf` with no sub-verb prints status and opens
the step panel, which offers only the next legal step.

```
/pfe perf start [label]     out of combat — begins the run, captures character/spec/zone/group
/pfe perf measure a         arms Experiment A (addon active); pull
/pfe perf measure b         arms Experiment B (addon suspended for you); reset and pull again
/pfe perf finish            ends the run and appends it to the ring
/pfe perf report            prints the human-readable summary
/pfe perf dump              writes the run as one line of JSON into the debug console
```

Then use the debug console's **Copy** button. One paste carries the report, the dump and the
lifecycle lines — the three inputs `/wow-addon:perf-analysis` needs. The last 10 runs also persist in
`PartyFrameEnhancedPerfDB.runs`, in `WTF/Account/<ACCOUNT>/SavedVariables/PartyFrameEnhanced.lua`,
outside the AceDB tree.

For this addon the useful arms are a **party** pull (five units casting, targets changing) — solo play
exercises only your own row, and never the pet frames. Take both arms:

- **somewhere quiet** — an instance, or a spot no other player wanders through. A city square moves
  the frame-time delta more than the addon does (the first capture's delta was ~99% environment);
- **in a party with at least one pet class**, so `petEvent` fires and every party row has casts and
  targets;
- **with the setup in the label**, since the record carries no addon config: frame system and anchor
  mode, e.g. `/pfe perf start party ellesmere attached`.

## Capture index

| Stamp | Addon version | Label | What it measured | Bundle |
|---|---|---|---|---|
| 20260915-161824 | 0.1.0 | `2026-09-15 16:14` | Solo Vengeance Demon Hunter in Silvermoon City: your own cast bar and target frame only. 0.861 ms/s of bracketed cost; the +1.63 ms/frame delta is about 99% environment or unbracketed client work; the health tick renders 4.89 buttons a pass solo | [ANALYSIS](20260915-161824/ANALYSIS.md) |
| 20260918-102842 | 0.1.0 | `2026-09-18 10:26` | First party capture: Protection Paladin in a party of five, Murder Row, a different pull per arm. 0.451 ms/s of bracketed cost; the +1.45 ms/frame delta is about 99% environment. The target health ticker never ran (no `targetTick`/`targetRender`), and fewer than one cast bar showed per frame on average | [ANALYSIS](20260918-102842/ANALYSIS.md) |
| 20260918-104528 | 0.1.0 | `2026-09-18 10:40` | Same party and zone with health updates on: every party-side bucket but pets measured. 0.800 ms/s of bracketed cost, 0.352 ms/s of it the health ticker at 4.41 renders per pass; the +0.89 ms/frame delta is about 98% outside the brackets. Settles why 20260918-102842 had no ticker: *Update health* was off | [ANALYSIS](20260918-104528/ANALYSIS.md) |

Still unmeasured: the pet-frame path (`petEvent` has never fired), and a solo capture confirming that
the health ticker no longer renders hidden target buttons.
