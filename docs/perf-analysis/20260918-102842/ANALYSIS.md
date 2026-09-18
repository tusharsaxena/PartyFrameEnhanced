# Analysis — 20260918-102842

- **Addon:** Ka0s Party Frame Enhanced 0.1.0 (record schema 2, client interface 120100)
- **Captured:** 2026-09-18 10:28 local, label `2026-09-18 10:26`
- **Who / where:** Sacrìlege-Frostmourne, level 90 Protection Paladin · Murder Row (no subzone) · party (5)
- **Delta:** +1.45 ms/frame. That's above the floor, but the addon doesn't explain it (see *The arms*)
- **Previous capture:** [20260915-161824](../20260915-161824/ANALYSIS.md)

## Headline

This is the first party capture: a five-person group, one pull per arm. The addon's own code cost
**0.451 ms per second of combat (0.0081 ms/frame)**. That's about **0.55%** of the +1.45 ms/frame
frame-time delta, so the delta is again mostly the two pulls differing, not the addon. The main
finding is a gap in coverage, not a cost: **the target-frame health ticker never ran** in a party
where members changed target 134 times. `targetTick` and `targetRender` are missing from the record,
so the fix from the last capture (don't repaint hidden target buttons) wasn't measured, and the reason
the ticker stayed off needs checking.

## The arms

Both figures come from [`dump.json`](dump.json)'s `fps` block; the rounded forms are in
[`report.md`](report.md).

| Arm | Seconds | Frames | Avg fps | ms/frame |
|---|---|---|---|---|
| active (addon running) | 57.0060 | 3194 | 56.0292 | 17.8478 |
| suspended (addon inert) | 44.5910 | 2720 | 60.9989 | 16.3938 |
| **delta** | | | | **+1.4541** |

The delta is above the ~0.5 ms/frame resolution floor and has the expected sign: the active arm is
slower. But the buckets below account for only 0.0081 ms/frame of it (0.55%). The other ~1.45
ms/frame is either outside every bracket (the client drawing bars and frames, the secure state
drivers) or the environment changing between the arms. The run log points to the environment. Each
arm was a **different pull**, and arm B ran **21.8% shorter** (44.6 s against 57.0 s). Different packs
mean different numbers of enemies casting, different spell effects and different nameplates. Combat
gating matches the two arms' start and stop, not what happened during them. So this delta is **not a
measure of the addon** either.

## The buckets — what the addon actually cost

Every figure from [`dump.json`](dump.json)'s `buckets`; `ms/s` is `totalMs` over the **active** arm's
seconds, as [`report.md`](report.md) computes it. Buckets nest — **do not sum the column**.

| Bucket | Calls | Total ms | ms/s | Max ms | Parent |
|---|---|---|---|---|---|
| castEvent | 182 | 4.9173 | 0.086 | 0.1239 | — |
| castRender | 46 | 3.0199 | 0.053 | 0.1188 | `castEvent` — declared and **observed** |
| castTick | 2725 | 12.0689 | 0.212 | 0.0397 | — |
| targetEvent | 134 | 8.7313 | 0.153 | 0.1172 | — |

**Total accounted cost:** the three top-level buckets (castEvent, castTick, targetEvent) add up to
25.7175 ms over 57.006 s. That's **0.451 ms/s**, or **0.0081 ms/frame** over 3194 frames. No single
call took more than 0.124 ms (castEvent's max, 0.1239).

These ratios hold across fights of different length. All are derived from `dump.json`:

- **castTick: 47.80 calls/s, or 0.853 per active frame** (2725 / 3194), at 0.0044 ms per call. The
  bucket counts one call per frame for each bar that is casting, holding or fading. With five members
  able to cast, that's **less than one bar showing on an average frame**, barely more than the solo
  capture's 0.824. This record doesn't say how many members cast or whose bars showed. See Actions.
- **castRender: 25.3% of castEvents** (46 / 182), at 0.0657 ms each. castEvent costs 0.0270 ms per call.
- **castEvent: 3.19 calls/s.** That's *lower* than the solo capture's 3.80/s, even though four more
  units could produce cast events. That fits the castTick reading: few party casts reached the addon
  during arm A.
- **targetEvent: 2.35 calls/s**, 0.0652 ms per call (a full repaint: name, health, colors, marker).

Declared buckets **absent** from the table never fired. That's a result about what the run
exercised:

- **`targetTick` and `targetRender`: the health ticker ran no pass during arm A.** This is the
  surprise. The ticker runs only while `tickerWanted()` is true (`modules/TargetFrames.lua`): the
  feature is on, *Update health* is on, preview is off, and at least one allowed target button is
  `IsVisible()`. `onEvent` calls `UpdateTicker()` after every one of the 134 target events, so each
  of those checks found either no visible button or the switch off. The capture can't say which. The
  code allows three readings, none confirmed here:
  1. General → *Update health* was off (step 35b of the smoke suite turns it off).
  2. *General visibility* was *Only out of combat* or *Never*. The state driver is then
     `[combat] hide`, so no target button is visible during combat.
  3. The buttons were allowed but not visible for some other reason, for example a parent hidden or
     no party frame resolved to attach to. That would also mean the target frames weren't on screen
     at all.

  Only reading 3 would be a defect. `onEvent` repaints a button whether or not it's visible, so under
  readings 2 and 3 the 0.153 ms/s of targetEvent went into frames nobody could see.
- **`petEvent`:** no pet event fired. The record has no roster, so it can't say whether anyone in
  the group had a pet out. The pet-frame path is still unmeasured.
- **`resolve` and `anchor`:** no roster or layout change during either arm.
- **`reskin`:** no setting changed during combat.

## What the capture did not hold constant

- **The fight.** Arm A and arm B were separate pulls in Murder Row (the `where:` line; the record's
  `subZone` is empty). Nothing in the log says they were the same pack or the same number of enemies.
- **Arm duration.** 57.0 s against 44.6 s.
- **Time between arms.** Arm A ended 10:27:13. Arm B was armed at 10:27:47 and started recording at
  10:27:53, so 40 s passed between the arms, and the log doesn't say what happened during them.
- **A canceled run just before.** A solo run in Silvermoon City (10:23:46–10:25:53) suspended the addon
  at 10:25:18 and was canceled while arm B was waiting, and the addon was resumed at 10:25:53. This
  capture's arm A started recording 23 s later. The ticker's absence *could* be a resume that didn't
  restore it. But `Resume()` calls `refreshAll()` → `UpdateTicker()`, and 134 later target events
  called it again, so the resume would have had to leave a condition broken, not just a timer stopped.
  This is noted as a possibility, not a finding.
- **What stayed constant:** one session, with no `/reload` between the arms (the log goes straight from
  `ENDED` to `SUSPENDED` to `RECORDING`). Both arms were combat-gated. Arm B was suspended, and the
  addon resumed only after `run finished`. The group was party (5) throughout.
- **Not recorded:** the frame system, anchor mode, *Update health* and *General visibility*. The label
  is the default timestamp, not the setup the store README asks for, and the record carries no addon
  config. Which commit of 0.1.0 was installed isn't recorded either. This is the first capture after
  the stand-down latch (`a8e3a44`), and the `addon SUSPENDED — inert` / `addon RESUMED — events and
  frames restored` lines are that latch's `perf` hold working in a live client.

## What moved

Compared with [20260915-161824](../20260915-161824/ANALYSIS.md) (solo Vengeance Demon Hunter,
Silvermoon City) on rates and per-call cost. Raw totals aren't compared.

| Figure | 20260915-161824 | This capture | Reading |
|---|---|---|---|
| Accounted cost | 0.861 ms/s | 0.451 ms/s | Down, but only because the ticker didn't run. Not an improvement |
| castEvent ms/call | 0.0299 | 0.0270 | Flat within noise |
| castEvent calls/s | 3.80 | 3.19 | Down, with five members instead of one. See the castTick note |
| castRender ms/call | 0.0836 | 0.0657 | Down 21%. Too few calls (58, 46) to call it a change |
| castRender share of castEvent | 22.2% | 25.3% | Flat |
| castTick calls per frame | 0.824 | 0.853 | Flat. A party didn't bring more bars on screen |
| castTick ms/call | 0.0051 | 0.0044 | Flat within noise |
| targetEvent calls/s | 2.39 | 2.35 | Flat |
| targetEvent ms/call | 0.0849 | 0.0652 | Down 23%, same repaint. Different units and machine state, so not attributed |
| targetTick / targetRender | 0.334 / 0.244 ms/s | absent | Not measured. See the buckets |
| Frame-time delta | +1.63 ms/frame | +1.45 ms/frame | Both mostly environment. Not comparable |

The last capture's first action (stop the ticker repainting hidden buttons, done in `05d1a82`)
**isn't confirmed or refuted**: its bucket never fired.

## Actions

1. **Find out why the health ticker stayed off in a party.** Before the next capture, in the same
   setup, run `/pfe get general.updateHealth` and `/pfe get visibility`, then `/pfe debug on`
   and pull. A `[Target] health ticker started` line should appear when a member targets a mob. If
   the setting is on, visibility is *Always*, and the target frames are on screen with no ticker
   line, reading 3 above is a defect in `modules/TargetFrames.lua`'s `tickerWanted()`. Add a test for
   it before the fix. New here; no issue tracks it.
2. **Stop `onEvent` painting target buttons nobody can see.** In `modules/TargetFrames.lua`, `onEvent`
   checks `btn.__allowed` but not `btn:IsVisible()`. The ticker already has that visibility gate,
   and the name and health would need a repaint on `OnShow`, which the existing `onVisibility` hook
   is the place for. Worth doing only if action 1 finds reading 2 or 3; under reading 1 the buttons
   are visible and the repaint is needed. New here.
3. **Find out how many party cast bars actually showed.** castTick at 0.853 per frame and castEvent at
   3.19/s mean the four party members' casts barely registered. With `/pfe debug on`, the `[Cast]`
   lines during a pull name the unit, which is enough to tell "followers rarely cast" from "party
   bars aren't registering". New here.
4. **Take the next capture with the setup in the label and the same pack for both arms.** Use
   `/pfe perf start party <frame system> <anchor mode>`, as the store README asks. Pull one pack for
   arm A, reset, and pull the same pack for arm B, with at least one pet class in the group so
   `petEvent` fires. This is still plan P10's open in-game work, and until the ticker fires, the
   target-frame half of the addon has no party measurement.
