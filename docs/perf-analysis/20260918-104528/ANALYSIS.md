# Analysis — 20260918-104528

- **Addon:** Ka0s Party Frame Enhanced 0.1.0 (record schema 2, client interface 120100)
- **Captured:** 2026-09-18 10:45 local, label `2026-09-18 10:40`
- **Who / where:** Sacrìlege-Frostmourne, level 90 Protection Paladin · Murder Row (no subzone) · party (5)
- **Delta:** +0.89 ms/frame. That's above the floor, but the addon doesn't explain it (see *The arms*)
- **Previous capture:** [20260918-102842](../20260918-102842/ANALYSIS.md)

## Headline

This is the first capture with **every party-side bucket but pets measured**: a five-person party with
health updates on (the player's note on the paste). The addon's own code cost **0.800 ms per second of
combat (0.0135 ms/frame)**. The target health ticker is the largest share, 0.352 ms/s, and ran **4.41
renders per pass**, which fits five rows that can each have a target. The +0.89 ms/frame delta is again
about 98% outside the brackets. Nothing here needs fixing for performance. The pet path and the
per-member cast bars are still the unmeasured parts.

## The arms

Both figures come from [`dump.json`](dump.json)'s `fps` block; the rounded forms are in
[`report.md`](report.md).

| Arm | Seconds | Frames | Avg fps | ms/frame |
|---|---|---|---|---|
| active (addon running) | 50.9580 | 3015 | 59.1664 | 16.9015 |
| suspended (addon inert) | 55.0760 | 3439 | 62.4410 | 16.0151 |
| **delta** | | | | **+0.8864** |

The delta is above the ~0.5 ms/frame resolution floor and has the expected sign. The buckets account
for only 0.0135 ms/frame of it (1.5%). The other ~0.87 ms/frame is either work outside every bracket
(the client drawing bars and frames, the secure state drivers) or the two pulls differing. The run log
favors the pulls: arm B ran **8.1% longer** (55.1 s against 51.0 s) and started **3 min 14 s** after
arm A ended, which fits a different pack. So the delta is **not a measure of the addon**. It's smaller
than the previous capture's +1.45, but the drop tells you about the pulls, not the addon.

## The buckets — what the addon actually cost

Every figure from [`dump.json`](dump.json)'s `buckets`; `ms/s` is `totalMs` over the **active** arm's
seconds, as [`report.md`](report.md) computes it. Buckets nest — **do not sum the column**.

| Bucket | Calls | Total ms | ms/s | Max ms | Parent |
|---|---|---|---|---|---|
| castEvent | 160 | 3.6076 | 0.071 | 0.1115 | — |
| castRender | 40 | 2.5014 | 0.049 | 0.1067 | `castEvent` — declared and **observed** |
| castTick | 2426 | 10.0361 | 0.197 | 0.0623 | — |
| targetEvent | 149 | 9.1702 | 0.180 | 0.1184 | — |
| targetTick | 254 | 17.9427 | 0.352 | 0.1191 | — |
| targetRender | 1119 | 15.0351 | 0.295 | 0.0479 | `targetTick` — declared and **observed** |

**Total accounted cost:** the four top-level buckets (castEvent, castTick, targetEvent, targetTick)
add up to 40.7566 ms over 50.958 s. That's **0.800 ms/s**, or **0.0135 ms/frame** over 3015 frames. No
single call took more than 0.12 ms (targetTick's max, 0.1191). Both declared parents were observed at
their call sites, so the nesting above is measured containment, not just a claim.

These ratios hold across fights of different length. All are derived from `dump.json`:

- **targetTick: 4.98 passes/s**, one every 0.2006 s (50.958 / 254). That's the default 0.2 s *Health
  refresh*, running for the whole arm. Each pass costs 0.0706 ms: 0.0592 ms of renders plus 0.0114 ms
  of its own loop over five buttons.
- **targetRender: 4.41 per pass** (1119 / 254), at 0.0134 ms each. The ticker renders only buttons
  that are allowed and `IsVisible()` (`modules/TargetFrames.lua` `tick()`). With five rows that can
  each have a target, 4.41 is at most five, as the smoke suite's step 23a requires. The capture can't
  count how many members actually had a target on each pass, so it can't prove the ticker never
  rendered a hidden button, only that the figure is consistent with not doing so.
- **targetEvent: 2.92 calls/s**, 0.0615 ms per call (a full repaint).
- **castTick: 47.61 calls/s, or 0.805 per active frame** (2426 / 3015), at 0.0041 ms per call. Again
  **less than one bar showing on an average frame** with five members able to cast.
- **castEvent: 3.14 calls/s**, 0.0225 ms per call. **castRender: 25.0% of castEvents** (40 / 160), at
  0.0625 ms each.

Declared buckets **absent** from the table never fired:

- **`petEvent`:** no pet event. The record has no roster, so it can't say whether anyone had a pet
  out. The pet path has now gone unmeasured in three captures.
- **`resolve` and `anchor`:** no roster or layout change during either arm.
- **`reskin`:** no setting changed during combat.

## What the capture did not hold constant

- **The fight.** Two separate pulls in Murder Row (the `where:` line; `subZone` is empty in the
  record). Nothing says they were the same pack.
- **Arm duration.** 51.0 s against 55.1 s.
- **Time between arms.** Arm A ended 10:41:09. Arm B was armed at 10:44:23 and started recording at
  10:44:28, so 3 min 14 s passed between the arms, and the log doesn't say what happened during them.
- **What stayed constant:** one session, with no `/reload` between the arms (the log goes straight from
  `ENDED` to `SUSPENDED` to `RECORDING`). Both arms were combat-gated. Arm B was suspended, and the
  addon resumed only after `run finished`. The group was party (5) throughout.
- **Not recorded:** the frame system and anchor mode (the label is the default timestamp again). The
  health-updates setting comes only from the player's note, not from the record.

## What moved

Compared with [20260918-102842](../20260918-102842/ANALYSIS.md), the same character, zone and group
18 minutes earlier, on rates and per-call cost:

| Figure | 20260918-102842 | This capture | Reading |
|---|---|---|---|
| Accounted cost | 0.451 ms/s | 0.800 ms/s | Up 0.349 ms/s. That's targetTick (0.352 ms/s), which didn't run before |
| targetTick / targetRender | absent | 0.352 / 0.295 ms/s | Measured in a party for the first time |
| targetEvent calls/s | 2.35 | 2.92 | Up. The members changed target more often in this pull |
| targetEvent ms/call | 0.0652 | 0.0615 | Flat |
| castEvent calls/s | 3.19 | 3.14 | Flat |
| castEvent ms/call | 0.0270 | 0.0225 | Flat within noise |
| castRender share / ms per call | 25.3% / 0.0657 | 25.0% / 0.0625 | Flat |
| castTick calls per frame | 0.853 | 0.805 | Flat. Still under one bar per frame |
| Frame-time delta | +1.45 ms/frame | +0.89 ms/frame | Both mostly the pulls differing. Not comparable |

**Why the previous capture's ticker never ran.** Its first action listed three possible readings. The
player's note on this paste says health updates are on *this time*, which settles it as reading 1:
*Update health* was off. So that was a setting, not a defect in `tickerWanted()`. The previous
bundle stays as written; this is where the correction lives.

Against the solo baseline [20260915-161824](../20260915-161824/ANALYSIS.md), the ticker moved from
0.334 to 0.352 ms/s, and renders per pass went from **4.89 solo to 4.41 in a party of five**. Solo,
at most one row can have a target, so 4.89 was the hidden-button repaint. `05d1a82` gated the ticker
on `IsVisible()`, and the party figure is now within the number of rows that can have a target. That
fits the fix working. A solo capture would test it directly: it should read **at most 1** render per
pass.

## Actions

1. **Confirm the hidden-button fix with a short solo capture.** Target a dummy solo with health
   updates on. `targetRender` per `targetTick` pass should be ≤ 1, where 20260915-161824 read 4.89.
   This is the direct test of `05d1a82`, which this party capture can only show is consistent.
2. **Find out how many party cast bars actually showed.** castTick has now read under one bar per frame
   in both party captures (0.853, 0.805). With `/pfe debug on`, the `[Cast]` lines during a pull name
   the unit, which tells "followers rarely cast" apart from "party bars aren't registering". Carried
   over from 20260918-102842; still untracked.
3. **Stop `onEvent` painting target buttons nobody can see** (carried over). It was conditional on
   reading 2 or 3, and reading 1 turned out to be the cause, so it's **withdrawn** as a finding from
   that capture. It only matters when *General visibility* hides the buttons in combat, which neither
   party capture recorded.
4. **Measure the pet path.** Bring a hunter or warlock follower, or play a pet class, so `petEvent`
   fires. Put the setup in the label: `/pfe perf start party <frame system> <anchor mode>`. This is
   still plan P10's open in-game work.
