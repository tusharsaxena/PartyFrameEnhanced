# Ka0s Party Frame Enhanced — v0.1.0 implementation plan

**Spec:** [`../specs/2026-09-15-party-frame-enhanced-design.md`](../specs/2026-09-15-party-frame-enhanced-design.md)
**Repo:** <https://github.com/tusharsaxena/PartyFrameEnhanced> (public, `master`)

## How to resume

This file is the checkpoint. Every phase ends in a commit that is pushed, and the ledger below is
updated **in that same commit**. To resume in a fresh session:

1. `git log --oneline | head` and read the ledger's last `done` row.
2. Run the green gate: `lua tests/run.lua` and `luacheck .` must pass before new work starts.
3. Pick up the first phase whose status is not `done`, at its first unchecked box.

Ground rules for whoever resumes:

- **No LibKa0s changes.** Another agent owns the library repo. Vendor from a tag with
  `git -C ../LibKa0s archive <tag> LibKa0s testkit | tar -x -C <tmp>` and never touch its working
  tree. Anything the library lacks becomes a PFE GitHub issue.
- Deferred work becomes a GitHub issue through `/wow-addon:issue-add`, not a TODO comment.
- Green gate before every commit (testing-§4). Commit and push at the end of each phase.

## Status ledger

| Phase | What | Status | Commit |
|---|---|---|---|
| P0 | Research, spec, this plan, repo + `.gitattributes` | done | see git log |
| P1 | Standards scaffold: TOC, libs, core seams, schema/slash/options skeleton, tests harness, doc set | pending | |
| P2 | Units, Compat, Providers (Blizzard raid-style, Blizzard classic, EllesmereUI), Anchor engine | pending | |
| P3 | Cast bars | pending | |
| P4 | Target frames (secure) + health ticker | pending | |
| P5 | Pet frames (secure) | pending | |
| P6 | Settings pages complete, preview/unlock, `status` verb | pending | |
| P7 | Offline perf pass: `tests/perf.lua` scenarios, allocation ceilings, bucket coverage | pending | |
| P8 | Docs sync, README + de-AI pass, automated-test bundle, DoD walk | pending | |
| P9 | GitHub issues for deferred work; roster row in WowAddonStandards | pending | |
| P10 | In-game smoke + perf capture (needs the player) → `/wow-addon:perf-analysis` | blocked on player | |

## P1 — Standards scaffold

- [ ] Root: `LICENSE` (MIT), `.luacheckrc`, `.pkgmeta`, `.gitignore`, `CLAUDE.md` stub with the
      provenance line `Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.36.1 (MIT).`
- [ ] `libs/`: Ace3 set + LSM + AceGUI-SharedMediaWidgets (copied from AbsorbTracker), `libs/LibKa0s`
      and `tests/_kit` from LibKa0s **v1.36.1**; runner mode 100755 in the index.
- [ ] `PartyFrameEnhanced.toc` — field order, `#` sections, load-bearing comments, Interface 120100.
- [ ] `core/`: Namespace, Compat (stub), MediaSetup, Constants, State, Bus, EnvSetup, CoreSetup,
      PerfSetup, DebugLogSetup, Units (stub), Database, PartyFrameEnhanced.
- [ ] `defaults/Profile.lua`, `locales/enUS.lua`.
- [ ] `settings/`: Schema, Slash, OptionsSetup, About, General (Master controls), Profiles.
- [ ] `tests/`: run.lua, wow_mock.lua, degraded_env.lua, test_loadorder, test_schema,
      test_database, test_coresetup, test_mediasetup, test_envsetup, test_debuglog, test_perfsetup,
      test_slash, test_optionssetup, test_surface_parity, test_bus, test_vendor_sync,
      test_lintconfig, + kit `test_eol`; `tests/perf.lua` skeleton.
- [ ] Logo placeholder under `media/logos/` (`.tga` + source `.png`).
- [ ] Doc set: README (canonical order), DEPENDENCIES.md, docs/ARCHITECTURE.md (10 sections),
      testing.md, smoke-tests.md (incl. the locale step), test-cases.md (generated), performance.md,
      perf-analysis/README.md, automated-tests/README.md, the six Tier 1 docs, slash-dispatch.md.
- [ ] Green gate; commit; push.

## P2 — Units, Compat, Providers, Anchor

- [ ] `core/Units.lua`: LIST, target/pet tokens, labels, `IsIncluded(unit, feature)`.
- [ ] `core/Compat.lua`: `IsSecret`, `SafeUnitIsUnit`, `CastDuration`, `ApplyTimer`,
      `BoolColor`, `AlphaFromBool`, `HealthPercent`, `UseRaidStyleParty`, `RaidTargetIndex`.
- [ ] `modules/Providers.lua`: three providers, Resolve, `FrameFor(unit)`, coalesced request with
      follow-ups, hooks installed once, sleep gate, `[Provider]` trace; publishes `LAYOUT`.
- [ ] `modules/Anchor.lua`: attached pin (memoized), free stack (growth/spacing), drag + position
      owner, `ResetPositions`, combat deferral + fade for secure elements.
- [ ] Tests first: provider detection per system, unit normalization, secret-attribute rejection,
      re-sort → new map → one LAYOUT, anchor memo (no SetPoint when key unchanged), secure deferral.
- [ ] Green gate; commit; push; ledger.

## P3 — Cast bars

- [ ] `modules/Element.lua` shared chrome + reskin signature.
- [ ] `modules/CastBars.lua`: per-unit event frames (RegisterUnitEvent), start/update/stop,
      SetTimerDuration + fallback, time-text OnUpdate (10 Hz, only while casting), interruptibility via
      curves/alpha, interrupted/failed hold + fade, spark, stale-bar check, castBarID matching.
- [ ] `settings/CastBars.lua` + `settings/ElementRows.lua` (Position/Border/Text builders).
- [ ] Tests: event registration set, no global UNIT_SPELLCAST registration, secret name/duration
      never compared (mock returns secret sentinels that raise on compare/arith), stop/interrupt paths,
      disabled feature registers nothing.
- [ ] Green gate; commit; push; ledger.

## P4 — Target frames

- [ ] Ten secure buttons created at enable (target + pet share the builder).
- [ ] State-driver string builder from settings (visibility × preview × enable); deferred-write queue.
- [ ] UNIT_TARGET per owner, RAID_TARGET_UPDATE, the gated ticker (create/cancel rules), class /
      reaction color, UnitHealthPercent text.
- [ ] `settings/TargetFrames.lua`.
- [ ] Tests: driver strings per visibility mode, no SetAttribute/RegisterStateDriver in combat
      (queued, flushed on regen), ticker lifecycle, secret health pushed unchanged.
- [ ] Green gate; commit; push; ledger.

## P5 — Pet frames

- [ ] `modules/PetFrames.lua`: UNIT_PET, per-pet-token health/name events, owner class color.
- [ ] `settings/PetFrames.lua`.
- [ ] Tests; green gate; commit; push; ledger.

## P6 — Settings completion, preview, status

- [ ] `modules/Preview.lua`; lock/unlock/preview verbs; refuse unlock in combat.
- [ ] `/pfe status`; provider picker onChange; include-player rule.
- [ ] Surface parity + degraded-load schema counts re-measured.
- [ ] Green gate; commit; push; ledger.

## P7 — Offline performance pass

Reference point: SimplePartyTargets' measured fixes (per-owner updates, anchor memo, event
filtering, idle gate).

- [ ] Every declared bucket reached (test).
- [ ] Scenarios: provider resolve burst coalescing (N triggers → 1 resolve), cast start/stop burst
      per unit, ticker pass with 5 shown frames, anchor pass with unchanged keys (0 SetPoint),
      zero-overhead (capture off vs on), settings drag (reskin signature skip).
- [ ] Allocation ceilings derived from measurement (the AbsorbTracker three-line method).
- [ ] Fix anything the scenarios find; record numbers in `docs/performance.md`.
- [ ] Commit; push; ledger.

## P8 — Docs, README, record, DoD

- [ ] `/wow-addon:sync-docs`-equivalent pass: module map, schema, settings panel, data flow,
      common tasks, slash dispatch, ARCHITECTURE hub + Documentation map.
- [ ] README de-AI pass (`/humanize`).
- [ ] `lua tests/run.lua --list > docs/test-cases.md`; README tests badge.
- [ ] `tests/_kit/run-automated-tests.sh --release 0.1.0`; write ANALYSIS.md + watch-list dispositions.
- [ ] Walk the context pack's Definition of Done; record gaps.
- [ ] Commit; push; ledger. **No tag** until P10 (in-game smoke) passes.

## P9 — Issues and roster

- [ ] File the spec §10 deferred items with `/wow-addon:issue-add` (labels `state:triaged` +
      severity).
- [ ] Add the addon's row to `WowAddonStandards/standards/ADDONS.md` (separate repo) or report that
      it is still owed.

## P10 — In-game (needs the player)

- [ ] Walk `docs/smoke-tests.md` on Blizzard classic, Blizzard raid-style, EllesmereUI.
- [ ] `/pfe perf` capture in a dungeon pull and at a dummy → `/wow-addon:perf-analysis`.
- [ ] Fix findings; tag `v0.1.0`.
