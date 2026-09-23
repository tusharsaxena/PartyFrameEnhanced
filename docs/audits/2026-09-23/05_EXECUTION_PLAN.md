# 05 — Execution plan

Hand-off to the remediation engagement. Each step names its deviation ID(s). Every step ends green:
`~/.claude/wow-addon/bin/ka0s-bounded lua tests/run.lua` shows 0 failed, and
`~/.claude/wow-addon/bin/ka0s-bounded luacheck .` shows 0/0. Counts quoted here match `02_DEVIATIONS.md`:
**18 roots** (0 High, 1 Medium, 11 Low, 6 Info) and **22 including dependents**.

No LibKa0s re-vendor is required. The addon is on v1.55.0, the newest tag. Upstream items are
collected in Sprint 5, and none of them blocks Sprints 1–4.

## Sprint 1 — Stand-down residue (the Medium first)

- [ ] **1.1 (PFE-14)** Add `NS.SafeRegister` (pcall per event, `C_EventUtils.IsEventValid` front-gate
      when present, rejects into `NS.RejectedEvents`). Write the failing test first: `M.__badEvents`
      naming one cast event, then assert the other 12 still register and the reject is recorded.
- [ ] **1.2 (PFE-14)** Route every registration site through it:
      `core/PartyFrameEnhanced.lua:140`, `modules/CastBars.lua:336`, `modules/Providers.lua:330-336`,
      `modules/PetFrames.lua:103-107`, `modules/TargetFrames.lua:214,320,326`,
      `modules/RangeFade.lua:168`, `modules/Preview.lua:81,154`. Surface `NS.RejectedEvents` in
      `/pfe status` and the DebugLog `initSummary`.
- [ ] **1.3 (PFE-12a)** Add an `EventRegistry` recorder to `tests/wow_mock.lua` that feeds
      `__registrations()`. Confirm `tests/test_disabled.lua` step 3 now goes **red** at `314c95e`'s
      behavior; that is the falsification.
- [ ] **1.4 (PFE-12)** In `modules/Providers.lua`, add a `registerCallbacks()`/`unregisterCallbacks()`
      pair called from `OnEnable`/`Resume` and `Suspend`. Make `burst()` return before touching
      `burstGen`/`C_Timer.After` while suspended. Step 3 goes green again. Add the falsification comment
      (`-- red under: drop unregisterCallbacks() from Providers:Suspend`).
- [ ] **1.5 (PFE-13)** Add hide/show of the fade frames in `RangeFade:Suspend`/`Resume`, and a new
      `Anchor:Suspend`/`Resume` for the three holders, **through `NS.RunSecure`**. They parent or
      anchor secure buttons, so a stand-down in combat defers the hide to the permitted regen flush.
      Add explicit step-5 assertions for `PartyFrameEnhanced_Fade_*` and `*_Holder`. Verify in game
      that an in-combat disable hides them after combat ends (a smoke step).
- [ ] **1.6** Commit: "Stand the Edit Mode callback and the container frames down with the addon".

## Sprint 2 — One refusal line, one locale set

- [ ] **2.1 (PFE-17)** Make `NS.AcceptLock`'s disabled branch print the collection line (publish
      `NS.DisabledLine()` from `settings/Slash.lua`, read it at call time). Delete `REFUSED_DISABLED`.
      Test: unlocking through the panel path while disabled prints exactly one line, the collection's,
      and writes nothing.
- [ ] **2.2 (PFE-18)** Delete the `"Position"` key (`locales/enUS.lua:31`) and the old refusal key
      (`:150`), plus the `REFUSED_DISABLED` key freed in 2.1. Optional: a dead-key test.
- [ ] **2.3 (PFE-05)** Route the provider labels (`modules/Providers.lua:96,119,138`) and the DebugLog
      stub's two strings through `NS.L`, and add the keys.
- [ ] **2.4** Commit.

## Sprint 3 — Structure and the load order

- [ ] **3.1 (PFE-16)** Split the TOC note at `PartyFrameEnhanced.toc:57-59` (LifecycleSetup names
      `NS.lifecycle`, PerfSetup names `NS.Perf`). Add the matching `tests/test_loadorder.lua` case.
- [ ] **3.2 (PFE-20, PFE-20a)** Put the bootstrap on line 1 of the ten files listed in 02, with the
      header directly beneath it. Add headers to `core/Namespace.lua`, `core/Constants.lua` and
      `core/State.lua`.
- [ ] **3.3 (PFE-24)** Build `C.LOGO_PATH` from `addonName`. This depends on 3.2.
- [ ] **3.4 (PFE-15)** Owner decision: (a) drop the `EllesmereUIDB` read in favor of the frame and
      fallback, or (b) keep it and add a `library-stack-§6` register row with its trigger. Implement
      whichever is chosen.
- [ ] **3.5 (PFE-21)** Comment out `.pkgmeta:12-13` in the template's shape.
- [ ] **3.6** Commit.

## Sprint 4 — Docs, register, record

- [ ] **4.1 (PFE-10)** Retire the `events-frames-taint-§1` row, write "None." under the heading, keep
      `### Files over the 1500-line cap` in place, and move the one-sentence rationale into *Event
      Subscriptions*.
- [ ] **4.2 (PFE-12b)** Add the `EditMode.Exit` callback row to the Event Subscriptions table.
- [ ] **4.3 (PFE-19)** Add Preview to the CONFIG and PROFILE consumers.
- [ ] **4.4 (PFE-15a)** Bring `docs/scope.md:24-26` and `docs/ARCHITECTURE.md:248-249` in line with the
      3.4 decision.
- [ ] **4.5 (PFE-01)** Run `sync-docs` over the seven sites in 02: `CLAUDE.md:33`,
      `docs/ARCHITECTURE.md:3-6`, `docs/module-map.md:17`, `docs/compat-layer.md:4,16,22`,
      `docs/ARCHITECTURE.md:324` (write "14, by `grep -cE …`"), `docs/ARCHITECTURE.md:140` and
      `defaults/Profile.lua:4`. Also update `docs/midnight-quirks.md` with the PFE-14 trade and add
      `NS.RejectedEvents` to `docs/slash-dispatch.md`'s `status` row.
- [ ] **4.6** Regenerate `docs/test-cases.md` (`lua tests/run.lua --list`) and update the README
      `[tests]` badge in the same change.
- [ ] **4.7** Commit.

## Sprint 5 — Upstream (routed, not blocking)

- [ ] **5.1 (PFE-13, upstream)** LibKa0s testkit issue: `CreateFrame` in `mock_base.lua` should start
      shown, as the client does, so a consumer's `F_on` sees container frames.
- [ ] **5.2 (PFE-23, upstream)** WowAddonStandards and LibKa0s: rule on the degraded Slash stub's copy
      of the refusal format (export it as data, or name the exception in `slash-commands-§1`).
- [ ] **5.3 (evidence note, upstream)** WowAddonStandards `AUDIT.md`: the re-vendor check's
      `git log --since="$horizon"` needs `"$horizon 00:00"`, or it skips same-day re-vendors.
- [ ] **5.4 (PFE-15, optional upstream)** If 3.4 chose (b), ask whether `library-stack-§6` should
      permit a presence-guarded, read-only suite SV read under its integration MAY.

## At the next release (not a sprint)

- [ ] **(PFE-09)** `tests/_kit/run-automated-tests.sh --release <v>` over the tree being tagged. The
      revision-25 runner writes the commit cell.
- [ ] **(PFE-22)** Re-check only when the first `SCHEMA_STEPS` entry is written. Apply it across every
      profile, with a two-profile test.
- [ ] **(PFE-08)** No action.

## Exit criteria

Every Sprint 1–4 box is ticked. `tests/test_disabled.lua` goes red on the removal of any single new
teardown line. A re-audit at the resulting commit files at most the Info rows (PFE-08, PFE-09,
PFE-22, PFE-23 pending upstream), plus PFE-15 if it was ratified by register row, in which case it is
recorded as accepted.
