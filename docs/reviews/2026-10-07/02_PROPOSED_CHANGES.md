# Proposed changes — Ka0s Party Frame Enhanced (2026-10-07)

Standard resolved: **Ka0s WoW Addon Standard v2.76.1 (2026-10-07)**. `standalone-windows.md` was read from the local `../WowAddonStandards` checkout because its fetch timed out. No change below touches `standalone-windows`.

## HLD

### Theme A: one combat gate for the preview switch (F-001)

Today the combat refusal for preview lives only in the `locked` row's validate (`NS.AcceptLock`). The PROFILE handler is a second way to turn preview on, and it skips that refusal. The fix closes that path without adding a second gate: when the new profile is stored unlocked and the client is in lockdown, the handler re-locks through the write seam (`NS.SetByPath`), the same path the combat re-lock's `forceLock` and the stand-down already take. This keeps the stored value and the display in agreement, and the player gets the same "Locked — combat started" line.

- **Rejected: honor the stored unlock silently, but keep preview off until regen.** That leaves the stored `locked=false` disagreeing with the display, which is one state recorded twice (anti-pattern #80's shape). It would also need a regen listener of its own.
- **Rejected: refuse the profile switch itself during combat.** A profile switch carries every setting, not only the lock. Refusing it is a far larger UX change than the defect warrants.

### Theme B: a flush that cannot strand its own queue (F-002, F-003)

Each deferred write runs isolated. A raising write costs only itself, is logged ungated on the console like an `ADDON_ACTION_BLOCKED` line, and is reported through `geterrorhandler()` so BugSack or BugGrabber still see it. The queue bookkeeping (`pending`, `pendingOrder`) is fully consumed whatever happens. The one unguarded secure-API call that can raise inside a deferred write, the re-wrap in `unwrapFrame`, gets its own `pcall` so the unwrap pass continues.

- **Rejected: wrap the whole flush in a single `pcall`.** It leaves the orphaned keys in place, which is the actual defect.
- **Rejected: swallow the error silently.** It hides a real bug in this addon's secure handling. The project's convention (`OnActionBlocked`) is to log these ungated.

### Theme C: status and profile-verb polish (F-004, F-005)

- `/pfe status` prints one unlocked flag. The preview branch already says which unlocked view is showing.
- `/pfe profile new` drops the redundant reset. On a name that has never existed, `SetProfile` already yields defaults.

### Theme D: precompute what the secure paths rebuild (F-006)

The driver string is cached per button against its inputs, and the in-combat anchor key and closure are built once at `Anchor.Register`. A perf scenario is added first so the before and after figures are measured rather than asserted.

## Upstream change-set

None. No finding lands in LibKa0s or in any third-party library.

## LLD

### C-001 (F-001): re-lock a profile switched to in combat

- **Files.** `modules/Preview.lua`, the PROFILE receiver.
- **Before → after.**
  ```lua
  ev:RegisterMessage(NS.MSG.PROFILE, function()
      if NS.GetSetting("enabled") ~= true then
          applyLock(false)
      elseif NS.GetSetting("locked") == false and InCombatLockdown() then
          -- The row's validate refuses an unlock in combat; a profile switch must not be a way round
          -- it (preview-mode: refused during combat). Re-lock through the seam -- its onChange runs
          -- applyLock(false) -- and say so as the combat re-lock does.
          NS.SetByPath("locked", true)
          NS.Print(L["Locked \226\128\148 combat started"])
      else
          applyLock(NS.GetSetting("locked") == false)
      end
  end)
  ```
  This reuses the existing locale key and the write seam, and it never paints placeholders, even for one frame. `forceLock` is not reused, because it returns early unless preview is already on, and preview may be off at this point.
- **Risk.** It writes `locked` into the newly selected profile. That matches what the combat re-lock already does to the active profile.
- **Tests.** Two new cases in `tests/test_profile_switch.lua`. (a) In lockdown, switching to a profile stored unlocked leaves `NS.State.preview == false`, stores `locked == true`, and prints the combat line. Red under: the current handler. (b) Out of combat, the same switch still comes back unlocked (a characterization case). This moves `docs/test-cases.md` and the README badge in the same change, from 455 to 457.

### C-002 (F-002): isolate each deferred write

- **Files.** `core/PartyFrameEnhanced.lua`, `flushSecure`.
- **Before → after.**
  ```lua
  local function flushSecure()
      if #pendingOrder == 0 then return end
      local order = pendingOrder
      pendingOrder = {}
      local n, failed = 0, 0
      for _, key in ipairs(order) do
          local fn = pending[key]
          pending[key] = nil
          if fn then
              local ok, err = pcall(fn)
              if ok then
                  n = n + 1
              else
                  failed = failed + 1
                  -- Ungated, like OnActionBlocked: a raising secure write is a bug here.
                  if NS.DebugLog and NS.DebugLog.Add then
                      NS.DebugLog:Add("Secure", ("deferred %s raised: %s"):format(key, NS.SafeToString(err)))
                  end
                  local handler = geterrorhandler and geterrorhandler()
                  if handler then handler(err) end
              end
          end
      end
      NS.Debug("Secure", "flushed %d deferred write(s), %d failed", n, failed)
  end
  ```
  The per-entry `pcall` lets the loop finish even if the error handler itself raises, provided the handler is invoked inside the `pcall`'s failure branch. Wrap the handler call in its own `pcall` if a lint or test shows it can raise. `geterrorhandler` is added to `.luacheckrc` `read_globals`.
- **Risk.** Low. The success path is unchanged. The format string is built only on failure, so a flush allocates nothing extra.
- **Tests.** Two new cases in `tests/test_lifecycle.lua` or a new `tests/test_secure_queue.lua` (if a new file, it must be added to `tests/run.lua`'s suite list). (a) Three keys are queued in combat and the middle one raises. After regen, the first and third ran and `NS.PendingSecureCount() == 0`. Red under: the current loop. (b) After that failed flush, the same three keys are queued again in a second combat and all three run. Red under: the orphaned-key bug. Moves the count from 457 to 459.

### C-003 (F-003): guard the re-wrap

- **Files.** `modules/SecureFollow.lua`, `unwrapFrame`.
- **Before → after.** `SecureHandlerWrapScript(frame, SCRIPT, h, pre, post)` becomes `local rok, rerr = pcall(SecureHandlerWrapScript, frame, SCRIPT, h, pre, post)`. On failure, write one `NS.DebugOnce("Follow:rewrap:" .. msg, "Follow", ...)` line naming the frame and the error, and return `false`, so the frame stays recorded as gated and the loop continues.
- **Tests.** One case in `tests/test_securefollow.lua`. The mock's re-wrap raises for the first of two foreign-wrapped frames, and both frames are still visited and counted as kept. Moves the count from 459 to 460.

### C-004 (F-004): one unlocked flag in `/pfe status`

- **Files.** `settings/Slash.lua`, `statusFlags`.
- **Change.** Delete `if NS.Anchor.IsUnlocked() then flags[#flags + 1] = L["unlocked"] end`, then remove the now-unused `"unlocked"` key from `locales/enUS.lua`. Before deleting the key, check with grep that nothing else reads it. Today `settings/Slash.lua:208` is the only reader.
- **Tests.** One case in `tests/test_preview_standin.lua`. While unlocked, the status output contains exactly one occurrence of `unlocked`. Red under: the current code. `tests/test_preview.lua:93` still passes, because it asserts only the substring. Moves the count from 460 to 461.

### C-005 (F-005): `/pfe profile new` without the redundant reset

- **Files.** `settings/Slash.lua`, `PROFILE_VERBS.new`.
- **Change.** Remove `NS.ResetProfileCounted(db)`. The `exists` refusal stays, and so does the acknowledgment.
- **Tests.** One case in `tests/test_slash.lua`. `profile new X` fires exactly one PROFILE message, counted with a private bus target, and X reads every default. Moves the count from 461 to 462. Existing case to keep green: `slash: profile new on an existing name refuses and does NOT wipe it`.

### C-006 (F-006): cache the driver string and the anchor closure

- **Files.** `modules/UnitButtons.lua` (`Driver`, `ApplyDriver`), `modules/Anchor.lua` (`Register`, `deferSecure`), `tests/perf.lua`.
- **Change.**
  1. Add a `visibilityFlip` scenario to `tests/perf.lua` that publishes VISIBILITY with the party set up. It measures bytes/iter before any code change. It is not a test case (`testing-§7`).
  2. `UnitButtons.Create` precomputes (named `__driverStr`, because the kit mock already records installed drivers on `__drivers`) `btn.__driverStr = { always = "[@"..token..",exists] show; hide", inCombat = "[nocombat] hide; ...", outOfCombat = "[combat] hide; ..." }`. `Driver` then indexes that table instead of concatenating.
  3. `Anchor.Register` sets `spec.__secureKey = "anchor:" .. spec.key` and `spec.__apply = function() Anchor.Apply(spec.key) end`, and `deferSecure` passes those.
- **Expected direction.** `visibilityFlip` bytes/iter goes down. The size of the drop is what C-006's before and after run shows. No number is claimed here.
- **Tests.** No new case. `tests/test_targetframes.lua` and `tests/test_petframes.lua` already pin the exact driver strings.

## Standards conformance

| Change | Conformance |
|---|---|
| C-001 | Keeps `preview-mode` ("refused during [combat]") and `options-ui-§15` (the lock is the only preview switch). It writes through the single seam (`architecture-§5`) and adds no second state (anti-pattern #80). It reuses an existing locale key (`localization-§1`). |
| C-002 | Matches `events-frames-taint-§2` (the deferred queue replays on `PLAYER_REGEN_ENABLED`). The ungated console line follows the project's `OnActionBlocked` convention, and the error is surfaced rather than swallowed. |
| C-003 | Same rule as C-002. It leaves the Documented-deviations row on the gated residue unchanged. |
| C-004 | `slash-commands-§4` output, with one key fewer in `locales/enUS.lua`. |
| C-005 | Keeps the existing AceDB profile semantics. No change to the verb surface (`slash-commands-§2`). |
| C-006 | `performance-§9`: the scenario is measured before and after, and is not counted as a test case. |

Test-count movement: 455 → 462 (7 new cases). `docs/test-cases.md` (regenerated by `lua tests/run.lua --list`) and the README `[tests]` badge move in each change that adds cases, never later. Complexity watch list: none of these changes adds a branch-heavy function. `flushSecure` gains one `if`, which keeps it far under CCN 15, and the next release's regeneration should confirm that.
