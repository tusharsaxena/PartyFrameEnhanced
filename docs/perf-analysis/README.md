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
In outline, and with **type placeholders only** (there is no capture here to quote):

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
exercises almost nothing.

## Capture index

No capture has been taken yet. The addon has not been played; the first capture is a separate
`/wow-addon:perf-analysis` run after in-game testing (plan P10).

| Stamp | Addon version | Label | What it measured | Bundle |
|---|---|---|---|---|
