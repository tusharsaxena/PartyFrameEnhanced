# Analysis — 20260915-161824

- **Addon:** Ka0s Party Frame Enhanced 0.1.0 (record schema 2, client interface 120100)
- **Captured:** 2026-09-15 16:18 local, label `2026-09-15 16:14`
- **Who / where:** Nylexia-Frostmourne, level 90 Vengeance Demon Hunter · Silvermoon City — The Bazaar · solo
- **Delta:** +1.63 ms/frame — above the floor, but not attributable to the addon (see *The arms*)
- **Previous capture:** none — this is the first

## Headline

A solo run in a city, so it exercised only your own row: one cast bar and one target frame. The
addon's own code cost **0.861 ms per second of combat (0.0172 ms/frame)**, about **1%** of the
+1.63 ms/frame frame-time delta. The rest of that delta is the environment or unbracketed client work,
and this capture can't tell which. One thing to act on: the target-frame health tick rendered
**4.89 buttons per pass** in a solo fight where only one row can have a target. That looks like
hidden buttons being repainted every 0.2 s.

## The arms

Both figures come from [`dump.json`](dump.json)'s `fps` block; the rounded forms are in
[`report.md`](report.md).

| Arm | Seconds | Frames | Avg fps | ms/frame |
|---|---|---|---|---|
| active (addon running) | 68.6180 | 3432 | 50.0160 | 19.9936 |
| suspended (addon inert) | 62.8280 | 3421 | 54.4502 | 18.3654 |
| **delta** | | | | **+1.6282** |

The delta is above the ~0.5 ms/frame resolution floor and has the expected sign (the active arm is
slower), so it did resolve *something*. But the buckets below account for only 0.0172 ms/frame of it
(1.06%). That leaves about 1.61 ms/frame outside every bracket. It's either the environment moving
between the arms (a city square with other players, the case `performance-§7` warns about), or client
work the brackets can't see: drawing the visible bar and target frame, the timer-driven fill, and the
secure state drivers. This capture can't separate those, so the delta **is not a measure of the
addon**. Arm B ran 8.4% shorter than arm A (62.8 s against 68.6 s). Combat gating matches the two
arms in duration only roughly, and not at all in environment.

## The buckets — what the addon actually cost

Every figure from [`dump.json`](dump.json)'s `buckets`; `ms/s` is `totalMs` over the **active** arm's
seconds, as [`report.md`](report.md) computes it. Buckets nest — **do not sum the column**.

| Bucket | Calls | Total ms | ms/s | Max ms | Parent |
|---|---|---|---|---|---|
| castEvent | 261 | 7.8066 | 0.114 | 0.2278 | — |
| castRender | 58 | 4.8514 | 0.071 | 0.2225 | `castEvent` — declared and **observed** |
| castTick | 2829 | 14.4208 | 0.210 | 0.0492 | — |
| targetEvent | 164 | 13.9309 | 0.203 | 0.1624 | — |
| targetTick | 343 | 22.9201 | 0.334 | 0.1922 | — |
| targetRender | 1676 | 16.7103 | 0.244 | 0.1407 | `targetTick` — declared and **observed** |

**Total accounted cost:** the four top-level buckets (castEvent, castTick, targetEvent, targetTick) add
up to 59.0784 ms over 68.618 s, which is **0.861 ms/s**, or **0.0172 ms/frame** over 3432 frames.
No single call exceeded 0.23 ms (castEvent's max, 0.2278).

The ratios that survive a change of combat duration, all derived from `dump.json`:

- **targetTick: 5.00 calls/s** (68.618 s / 343 = 0.200 s per pass), exactly the configured 0.2 s
  interval. The ticker ran through the whole arm, so your own row had a target throughout.
- **targetRender: 4.89 per targetTick pass** (1676 / 343), at 0.0100 ms each. Solo, only the player
  row can have a target, so at most 1 render per pass should happen. The source explains the rest.
  `tick()` renders a button when `btn.__allowed and Compat.UnitExists(btn.token)`
  (`modules/TargetFrames.lua`). `Units.IsIncluded` counts party1–party4 whether or not they exist
  (`core/Units.lua:38-43`). And `Compat.UnitExists` **returns true when the game answers with a secret
  value** (`core/Compat.lua:215-220`). In combat `partyNtarget` likely comes back secret, so all five
  buttons render every pass. They're hidden by their state drivers, so nothing visible goes wrong, but
  each render writes `SetMinMaxValues`/`SetValue`, and a secret reading can't be skipped. This is an
  inference from the ratio plus the code, not something the capture proves on its own.
- **castTick: 41.23 calls/s, on 82.4% of active frames** (2829 / 3432), at 0.0051 ms each. The bracket
  wraps every frame's `OnUpdate` while the bar is casting, holding or fading (`modules/CastBars.lua`
  `onUpdate`). The 0.1 s throttle is *inside* it, in `tickCasting`, so this bucket counts frames, not
  throttled passes. `core/PerfSetup.lua` describes it as "the throttled time-text tick", which reads
  as if the throttle were broken. It isn't.
- **castRender: 22.2% of castEvents** (58 / 261). The other 203 events were stops, updates and
  failures, which don't open a new bar. castRender costs 0.0836 ms per call and castEvent 0.0299.
- **targetEvent: 2.39 calls/s**, 0.0849 ms per call (a full repaint). 164 `UNIT_TARGET`s in 68.6 s
  seems high for a one-person fight. With no `[Target]` debug lines in the run log, this capture can't
  say what the target changes were.

Declared buckets **absent** from the table never fired, which is a result about what the run
exercised:

- `petEvent`: no pet (solo Vengeance Demon Hunter).
- `resolve` and `anchor`: no roster or layout change during combat.
- `reskin`: no setting changed during combat.

None of the pet-frame path and nothing party-related was measured.

## What the capture did not hold constant

- **Environment.** Silvermoon City — The Bazaar, a city square where other players come and go; the
  report's `where:` line. `performance-§7` names exactly this as not a repeatable arm.
- **Arm duration.** 68.6 s against 62.8 s.
- **Time between arms.** Arm A ended 16:16:21, arm B was armed 16:17:15 and started recording 16:17:18.
  That's 57 s between the arms, and the run log doesn't say what happened in it.
- **What stayed constant:** one session, with no `/reload` between the arms (the run log goes straight
  from `ENDED` to `SUSPENDED` to `RECORDING`). Both arms were combat-gated. Arm B was suspended, and the
  addon was resumed only after it ended. Solo throughout.
- **Not recorded:** which frame system and anchor mode were active, and which commit of 0.1.0 was
  installed. The record carries neither.

## What moved

First capture — nothing to diff against; every figure above is a baseline reading.

## Actions

1. **Stop the health tick from repainting hidden target buttons.** In `modules/TargetFrames.lua`,
   `tick()` and `TargetFrames.UpdateTicker()` decide "has a target" with `Compat.UnitExists`, which
   answers true for a secret value (`core/Compat.lua:215-220`). Gate them on the button's own
   visibility instead (`btn:IsVisible()`): the secure state driver already resolves
   `[@token,exists]`, and it's never secret. Add a test where a secret `UnitExists` doesn't make a
   hidden button render or keep the ticker alive. That's the upper bound of the saving:
   (4.89 − 1) / 4.89 of targetRender's 0.244 ms/s ≈ 0.19 ms/s. It's also why the ticker would keep
   running in a solo fight with no target at all. New here; no issue tracks it.
2. **Fix the castTick description.** In `core/PerfSetup.lua` and `docs/performance.md`, describe
   `castTick` as the per-frame `OnUpdate` pass while a bar is showing, throttled inside. That way a
   reading of about 41 calls/s isn't mistaken for a broken throttle. New here.
3. **Take the next capture in a party, somewhere quiet.** Use an instance or a remote spot, not a city.
   A party pull exercises party cast bars, several target frames and the pet frames (`petEvent`
   never fired here), and a quiet spot gives a delta that has a chance of meaning something. Note the
   frame system and anchor mode in the label. This is plan P10's remaining in-game work.
