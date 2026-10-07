# Review findings — Ka0s Party Frame Enhanced (2026-10-07)

**Verdict: minor issues.** No Critical or High findings. There are two Medium findings: a profile switch during combat can turn preview on mid-fight, and the deferred secure-write flush has no per-entry isolation. There are also four Low findings.

**Resolved scope:** `all`, meaning the whole repository at `feat/2026-10-07-review-audit-remediation` (HEAD `fb5c0b9`, clean tree). That covers the authored Lua in `core/`, `defaults/`, `locales/`, `modules/`, `settings/` and `tests/`, plus the TOC and `.luacheckrc`. `libs/` and `tests/_kit/` are vendored, so the review covers only the descriptors and stubs that touch them. Profile detected: `profile=wow`, `kind=addon`.

Standards guardrail: Ka0s WoW Addon Standard **v2.76.1 (2026-10-07)**. The index and 26 of its 27 section files were fetched with `curl` from `raw.githubusercontent.com/.../master`. `standalone-windows.md` timed out, so it was read from the local sibling checkout `../WowAddonStandards` (HEAD `f472389`).

## Measurement run

All commands ran from the repo root through `/home/tushar/.claude/dev-copilot/bin/ka0s-bounded`. Output went to a scratch path outside the repo, and nothing in the repo was written.

| Suite | Result | Command |
|---|---|---|
| luacheck | **pass**: 0 warnings / 0 errors in 79 files | `ka0s-bounded luacheck .` |
| Headless tests | **pass**: 454 passed, 0 failed, 1 skipped, 455 total (Lua 5.1.5). The one skip is the kit's diagnostics-contract opt-out case, which this addon intentionally leaves at the default. | `ka0s-bounded lua tests/run.lua` |
| Fresh `--list` inventory | **455** cases. Identical to the committed `docs/test-cases.md` (**Total 455**), and the README badge `Tests-454/455_passing` agrees. | `ka0s-bounded lua tests/run.lua --list` |
| Offline perf runner | **ran**, 10 scenarios, 0 `SetPoint`/iter in every scenario. `probeOverheadOff` makes 0 bracket calls/iter (9 with capture on). `settingsDrag` measures 925.9 B/iter, and every other scenario measures ≤ 0.5 B/iter. | `ka0s-bounded lua tests/perf.lua` |
| Complexity (sighted, kit revision 37) | **pass**: 0 warnings, max CCN 14, 11361 NLOC / 1602 functions, avg CCN 2.1. No blind-file note was printed (blindFiles 0). | `ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle` |
| `make test` | **not applicable** (the repo has no `Makefile`) | — |
| Vendor sync | **pass**: both diffs are empty. The LibKa0s checkout is on `feat/2026-10-07-review-audit-remediation`, and its newest tag is `v1.70.0`. The in-suite `test_vendor_sync` also passed. | `diff -rq libs/LibKa0s ../LibKa0s/LibKa0s`; `diff -rq tests/_kit ../LibKa0s/testkit` |
| Cross-addon pass (11 addons, TOC-derived load lists) | **clean on all four classes.** **Class 1:** 22 roots, no duplicates, no raw `SLASH_*`. This addon registers `pfe` and `partyframeenhanced`. **Class 2:** one minors line: `Bus:2 Compat:1 Core:10 DebugLog:19 Env:1 Item:2 Launcher:5 Lifecycle:3 Media:4 Options:28 Perf:14 Pool:3 Schema:2 Slash:19 Widgets:12`. **Class 3:** every `diff -rq` against AbsorbTracker's `libs/LibKa0s` is empty. **Class 4:** `## Interface: 120100` is uniform. The run measured sibling working trees at tag `v1.70.0`. The overlay's recorded baseline (`v1.56.0`) is behind, so this is a stale brief, not drift. | the overlay's four class loops, run from `GIT/` |

Committed artifacts that disagree with today's run:

- **`docs/automated-tests/RESULTS.md`** is stale as of its header. Its newest row is `20260927-030324` at `692cec2`, which the runner reports as "47 commit(s) behind HEAD". The record has tests at 383/0/383, 9976 NLOC / 1318 functions, and 9 perf scenarios. Today's run gives 455 cases, 11361 NLOC / 1602 functions and 10 scenarios. This is stale, not non-compliant: the record regenerates at release (`/dev-copilot:bump-version`), and no release has happened since 1.1.0.
- **`docs/performance.md`** agrees with today's figures (`settingsDrag` 925.9, `probeOverheadOff` 0 bracket calls). `targetTickUnchanged` reads 0.1 B/iter today against 0 on record. That is under the 24-byte ceiling and is for orientation only, so it is not a finding.

Census scope: `git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)' | tr '\n' '\0' | xargs -0 wc -l`. This is the authored, tracked Lua with `tests/` included: 15781 lines in total. The largest file is `tests/test_launcher.lua` at 578 lines, so nothing is in `layout-§1`'s 1000–1500 band.

## Medium

### F-001 — A profile switch during combat turns preview on mid-fight, bypassing the combat refusal `[correctness]` `[ux]`

- **Where.** `modules/Preview.lua:198-204`:
  ```lua
  ev:RegisterMessage(NS.MSG.PROFILE, function()
      if NS.GetSetting("enabled") ~= true then
          applyLock(false)
      else
          applyLock(NS.GetSetting("locked") == false)
      end
  end)
  ```
  It is reached from `/pfe profile use <name>` (`settings/Slash.lua:307`, `use = needsName("use", function(_, name) cli:ProfileSwitch(name) end),`) and from the Profiles page, both through `adoptProfile` (`core/PartyFrameEnhanced.lua:302-311`).
- **Problem.** An unlock is refused in combat only inside the `locked` row's validate, `NS.AcceptLock` (`modules/Preview.lua:126`, `if InCombatLockdown() then`). The PROFILE handler calls `applyLock` directly, so a switch to a profile whose stored `locked` is `false` turns preview on during lockdown. The combat re-lock cannot rescue it: `listen(true)` registers `PLAYER_REGEN_DISABLED` (`modules/Preview.lua:95`), and that event has already fired for this fight.
- **Impact.** For the rest of the fight, every cast bar shows the "Preview cast" placeholder and ignores real casts (`modules/CastBars.lua:263`, `if el.__previewing then return end`). The target and pet frames' `"show"` drivers queue and land at regen. This is the half-done unlock that `AcceptLock` exists to prevent. It also breaks `preview-mode`'s rule that the preview is "refused during [combat]".
- **Reachability:** a player who runs `/pfe profile use <name>` or switches profiles on the Profiles page during combat, where `<name>` was last left unlocked. A profile keeps `locked = false` whenever the player switched away from it while unlocked. It happens on a default install through a documented command, but the precondition is rare.
- **Coverage.** Nothing covers this path. `tests/test_preview.lua` covers the combat refusal through the row only, and `tests/test_profile_switch.lua` never switches profiles in combat.

### F-002 — One raising deferred secure write aborts the flush and orphans every later key for the session `[error-handling]`

- **Where.** `core/PartyFrameEnhanced.lua:92-101` (flushSecure):
  ```lua
  local order = pendingOrder
  pendingOrder = {}
  ...
  for _, key in ipairs(order) do
      local fn = pending[key]
      pending[key] = nil
      if fn then
          fn()
  ```
  The guard that makes the orphaning permanent is `core/PartyFrameEnhanced.lua:66`, `if not pending[key] then`.
- **Problem.** The flush calls each queued closure with no per-entry isolation. If one closure raises, the loop stops. Every key after it stays in `pending` but has already been removed from `pendingOrder`. From then on, `RunSecure` sees `pending[key]` set during combat, never re-appends the key to the order list, and no later flush ever runs that key's writes. Out-of-combat calls still run immediately, so only the in-combat queue is lost. The error also unwinds `OnLeaveCombat` (`core/PartyFrameEnhanced.lua:264-267`) before `NS.PublishVisibility()`, and unwinds the stood-down listener (`:123-126`).
- **Impact.** Until `/reload`, every later combat silently drops the queued writes for the orphaned keys. Elements that `deferSecure` faded can stay at alpha 0, drivers stay stale, and `/pfe diagnostics` reports `pending=0` because it counts `pendingOrder`. The show ladders also miss the post-combat VISIBILITY republish.
- **Reachability:** nobody, as far as is known today. It needs a deferred closure to raise. The in-tree candidates are a `SetPoint` dependency-loop error inside `Anchor.Apply` and the unprotected re-wrap in F-003. This is a resilience hazard on an error path, which caps it at Medium.

## Low

### F-003 — `unwrapFrame` re-wraps another addon's handler without a guard, inside the secure queue `[error-handling]`

- **Where.** `modules/SecureFollow.lua:195-201`:
  ```lua
  local ok, h, pre, post = pcall(SecureHandlerUnwrapScript, frame, SCRIPT)
  if not ok then return false end
  if h == header or h == nil then
      wrapped[frame] = nil
      return true
  end
  SecureHandlerWrapScript(frame, SCRIPT, h, pre, post)
  ```
- **Problem.** The unwrap is `pcall`ed, but the call that restores the other addon's wrap is not. A refusal there raises out of `unwrapAll`, which always runs as the `"follow:wrap"` closure in the secure queue.
- **Impact.** The stand-down's unwrap pass stops partway, so later frames keep the gated wrap. In combat, the raise also triggers F-002's orphaning. In the case being guarded against, the other addon's wrap has already been popped and is not put back.
- **Reachability:** only a player running another addon that wraps the same EllesmereUI or Blizzard raid-style member frame's `OnAttributeChanged` after this one, and only when they disable the addon or start a perf run. Nothing in the collection does this today.

### F-004 — `/pfe status` prints "unlocked" twice whenever the elements are unlocked `[ux]`

- **Where.** `settings/Slash.lua:201-208`. The first `if` adds `L["unlocked (stand-in)"]` or `L["unlocked (your party frames)"]` whenever `NS.State.preview` is true. Then `if NS.Anchor.IsUnlocked() then flags[#flags + 1] = L["unlocked"] end` adds a second flag.
- **Problem.** `applyLock` (`modules/Preview.lua:147-150`) always sets `Anchor.SetUnlocked` and `setPreview` to the same value, so both flags appear together every time. The output reads, for example, `Note: unlocked (stand-in), unlocked`.
- **Impact.** The diagnostic line repeats itself and suggests two different states.
- **Reachability:** any player who types `/pfe status` while unlocked.

### F-005 — `/pfe profile new` rebuilds everything twice and logs a no-op reset `[perf]` `[ux]`

- **Where.** `settings/Slash.lua:314-315`: `db:SetProfile(name)` followed by `NS.ResetProfileCounted(db)`.
- **Problem.** The earlier `exists` check refuses an existing name, so `SetProfile` always lands on a profile with no stored data, which already reads as defaults. The reset changes nothing, but it fires `OnProfileReset`, which runs `adoptProfile` again. The result is a second PROFILE broadcast and VISIBILITY publish, a second panel refresh, and a `[Set] reset profile '<name>' to defaults (0 rows)` line after the `[Profile] changed` line.
- **Impact.** The full restyle pass of every feature runs twice, and the debug trace shows a reset the player did not ask for.
- **Reachability:** any player who runs `/pfe profile new <name>`. The impact is a one-off cost per command.

### F-006 — Per-pass string and closure building on the driver and in-combat anchor paths `[perf]` (unverified)

- **Where.** `modules/UnitButtons.lua:50-53`, `local exists = "[@" .. token .. ",exists] show; hide"`, plus the two prefixed forms. These run on every `refresh` (`modules/TargetFrames.lua:197`, and the same line in PetFrames), which means 10 buttons on every VISIBILITY, LAYOUT and CONFIG. Also `modules/Anchor.lua:228`, `NS.RunSecure("anchor:" .. spec.key, function() Anchor.Apply(spec.key) end)`, which runs on every in-combat pass of a secure feature.
- **Problem.** The driver string depends only on (token, visibility mode, preview, allowed) and could be precomputed per button. The anchor key and closure could be built once per feature at `Anchor.Register`.
- **Impact.** Small garbage on every combat transition and on each re-sort during combat. **Unverified:** no `tests/perf.lua` scenario covers a VISIBILITY flip or an in-combat anchor pass, so no number backs this finding.
- **Reachability:** any player in a party, on every combat enter or leave and every re-sort during combat. The magnitude is small.

## Upstream findings

None. No defect was found under `libs/` or `tests/_kit/`. Both vendored trees are byte-identical to the LibKa0s checkout.

## Not raised, and why

- The ~200-line `HostSchemaStub` copy in `settings/Schema.lua:51-258` is the library's documented reference stub. The file says it was copied whole, and `tests/test_surface_parity.lua` checks it against the live library, so it is not stub drift.
- The pending-ratification note on the first Documented-deviations row (`docs/ARCHITECTURE.md:427`) is an audit matter (`dev-copilot:wow-standards-audit`), not a review finding.
- The kit's own suites (`test_lizard_sighted` and others) count toward the badge. That is the collection-wide kit convention, wired identically in AbsorbTracker, AuraMaster, KickCD and MultiMeters.
- `CastBars.stop` sets the interrupted fill while an engine timer may still be attached. Smoke step CAST-4 covers exactly this, and no failure is on record.
