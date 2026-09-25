# 04 — Technical design

Keyed to the IDs in `02_DEVIATIONS.md`. No change here needs a re-vendor: the addon is on LibKa0s
v1.55.0, the newest tag, and every fix is addon code or addon docs. Two items (PFE-13's mock-fidelity
half and PFE-23) belong upstream, in LibKa0s and WowAddonStandards. They are named here so the
remediation engagement can route them, and the addon work does not wait on them.

## A. The stand-down residue — PFE-12 (+12a, 12b), PFE-13

**Shape.** The latch, `NS.StandDown` and the bus record are correct and stay as they are. What is
missing is ownership of the two registrations that bypass the bus record, and of the container frames.

1. **The `EditMode.Exit` callback (PFE-12).** In `modules/Providers.lua`:
   - Move the registration into a local `registerCallbacks()` / `unregisterCallbacks()` pair next to
     `registerEvents()`. `EventRegistry:UnregisterCallback("EditMode.Exit", Providers)` is the inverse
     call, with the same owner key used at registration. Keep both behind the existing presence guard
     and `pcall`, because the registry is Blizzard-private.
   - Call `registerCallbacks()` from `OnEnable` and `Resume`, and `unregisterCallbacks()` from
     `Suspend`.
   - Make `burst()` return **before** it bumps `burstGen` or arms `C_Timer.After` while `suspended`.
     Belt and braces: the two follow-ups can no longer be armed by a hook that fires during a
     stand-down (the `HookScript`/`hooksecurefunc` paths reach `Providers.Request`, not `burst`, and
     already return early).
   - Rejected alternative: a generic "tracked callback" helper in the addon. That would be a second
     stand-down record beside `LibKa0s-Bus-1.0`'s, which is the parallel-mechanism shape anti-pattern
     #85 names. If the collection wants EventRegistry callbacks tracked, the place for it is a Bus
     minor upstream.
2. **The suite blind spot (PFE-12a).** In `tests/wow_mock.lua`, add an `EventRegistry` whose
   `RegisterCallback`/`UnregisterCallback` record into the same `__registrations()` list the kit
   exposes (kind `callback`). Then step 3 of `tests/test_disabled.lua` covers it with no change to the
   suite. Falsification: remove the new `unregisterCallbacks()` call and step 3 must go red; note that
   in the comment at step 3.
3. **The Event Subscriptions table (PFE-12b).** Add an `EditMode.Exit` (EventRegistry callback) row
   under `modules/Providers.lua`. `docs/ARCHITECTURE.md:165` then holds as written.
4. **Container frames (PFE-13).** `RangeFade:Suspend` hides the five fade frames and `Resume` shows
   them, and a new `Anchor.Suspend`/`Resume` pair (Anchor is already a registered module, so the
   lifecycle `each()` loop reaches it) does the same for the three holders. **Route both through
   `NS.RunSecure`.** The fade frames are parents of the **secure** target and pet buttons, and the
   holders are anchor targets of those buttons, so a frame with protected children or dependents is
   restricted in combat. Out of combat the hide runs at once; a stand-down that lands in combat queues
   it on the permitted `PLAYER_REGEN_ENABLED` listener, which is the existing combat-deferred path
   (slash-commands-§7). The upstream half: open a LibKa0s testkit issue to make `CreateFrame` start
   **shown**, as the client does, so a consumer suite's `F_on` baseline sees every container. Until
   then, add a direct assertion in `tests/test_disabled.lua` step 5 that `PartyFrameEnhanced_Fade_*`
   and `*_Holder` are hidden after the disable (out of combat).

**Risk.** Low. Hiding a fade frame hides every element for that unit, and a stood-down addon shows
none of them anyway. Before relying on it, verify in game whether `Hide()` on the fade frame is
refused in combat. That is why the change goes through `RunSecure` rather than assuming it is
allowed. Stand-up must show the frames **before** visibility is republished, or the first repaint
lands under a hidden parent. `NS.StandUp` already runs `each("Resume")` before `PublishVisibility()`,
and it runs out of combat in the normal case. A stand-up in combat queues the show under the same
`RunSecure` key, which the `PLAYER_REGEN_ENABLED` flush completes.

## B. Event registration that survives one bad name — PFE-14

**Shape.** One helper in `core/` (a new `core/Events.lua`, loaded after `core/DebugLogSetup.lua`, or
added to `core/Util.lua`):

```lua
NS.RejectedEvents = NS.RejectedEvents or {}
--- Register one event on `target` (an AceEvent target, the addon object, or a raw frame with `unit`).
function NS.SafeRegister(target, event, handler, unit)
  local valid = C_EventUtils and C_EventUtils.IsEventValid
  if valid and not valid(event) then NS.RejectedEvents[event] = "invalid"; return false end
  local ok, err
  if unit then ok, err = pcall(target.RegisterUnitEvent, target, event, unit)
  else ok, err = pcall(target.RegisterEvent, target, event, handler) end
  if not ok then NS.RejectedEvents[event] = tostring(err) end
  return ok
end
```

- Route every registration site through it: `core/PartyFrameEnhanced.lua:140`, `modules/CastBars.lua:336`,
  `modules/Providers.lua:330-336`, `modules/PetFrames.lua:103-107`, `modules/TargetFrames.lua:214,320,326`,
  `modules/RangeFade.lua:168`, `modules/Preview.lua:81,154`.
- **Reachability MUST:** print `NS.RejectedEvents` in `/pfe status` (one line, only when non-empty)
  and add it to the DebugLog `initSummary`.
- **Bus record interplay:** bus-target registrations still go through the tracked target, so the
  record sees them. The helper calls `target:RegisterEvent`, which is the tracked method, so recording
  is unchanged.
- **Test:** set the kit mock's `M.__badEvents` to `{ UNIT_SPELLCAST_EMPOWER_START = true }` and assert
  that the other 12 cast events still register and that `NS.RejectedEvents` names the bad one.
- Record the trade in `docs/midnight-quirks.md` (probing costs the edge that event would have covered).

## C. Register hygiene — PFE-10

Delete the `events-frames-taint-§1` row. Under `## Documented deviations`, write "None." above the
existing `### Files over the 1500-line cap` sub-heading (keep that sub-heading exactly where it is,
because `test_layout_cap` parses it). Put one sentence in *Event Subscriptions* stating that per-unit
events are registered with `RegisterUnitEvent` on the element frames, and that v2.63.0 ruled this is
not a deviation.

## D. Suite SavedVariables read — PFE-15 (+15a)

This is a decision for the owner, and either answer closes it:

1. **Stop reading `EllesmereUIDB`.** Take the size from `ERFPartyHeader`'s own child after
   `ReloadPartyFrames`, if it is ever laid out, and otherwise fall back to `FALLBACK.ellesmere`
   (125×60, `modules/StandIn.lua:35`). Cost: the stand-in can be the wrong size until the player joins
   a party once.
2. **Keep it and ratify it.** Add a `library-stack-§6` row: *What differs*: reads
   `EllesmereUIDB…partyFrameWidth/Height` read-only for the preview stand-in; *Why*: hidden
   EllesmereUI party buttons carry raid size (`modules/Providers.lua:286-291`); *Re-check trigger*:
   "EllesmereUI exposes its configured party size through a frame or API, or its hidden party buttons
   report party size". Optionally raise the question upstream: whether a presence-guarded, read-only
   SV read under §6's integration MAY should be permitted by name.

Either way, correct `docs/scope.md:24-26` and `docs/ARCHITECTURE.md:248-249` (PFE-15a).

## E. TOC annotation — PFE-16

```
# LOAD-BEARING: publishes NS.lifecycle, which core\PerfSetup.lua hands LibKa0s-Perf-1.0 at file load
# (a nil there raises in Perf's descriptor check).
core\LifecycleSetup.lua
# LOAD-BEARING: publishes NS.Perf before any module takes `local Perf = NS.Perf` at file scope.
core\PerfSetup.lua
```

Add `tests/test_loadorder.lua`: "LifecycleSetup loads before PerfSetup, and the TOC says why", in the
same shape as the MediaSetup case at `:41`.

## F. One refusal line — PFE-17

In `modules/Preview.lua`, `NS.AcceptLock`'s disabled branch prints the collection line:

```lua
elseif NS.GetSetting("enabled") ~= true then
  why = NS.Slash and NS.Slash.__cli and NS.Slash.__cli:DisabledLine() or nil
```

It must stay **after** the combat check, because in combat the combat reason is the more useful one.
Since `settings/Slash.lua` loads after `modules/Preview.lua`, the lookup happens at call time, which
is fine. A cleaner option is to publish `NS.DisabledLine()` from `settings/Slash.lua` and read that.
Delete `REFUSED_DISABLED` and its key (this also removes one PFE-18-class key). Add a
`tests/test_disabled.lua` case: panel-path `NS.SetByPath("locked", false)` while disabled prints
exactly `cli:DisabledLine()` and writes nothing.

## G. Localization — PFE-18, PFE-05

- Delete `"Position"` and the old refusal key from `locales/enUS.lua`.
- Wrap the provider labels in `L[...]` (`modules/Providers.lua:96,119,138`; `NS.L` is loaded before
  modules) and add the three keys. Route the DebugLog stub's two strings the same way.
- Optional guard: a `tests/test_locale.lua` that loads `enUS.lua`, collects its keys, and fails on any
  key with no reader outside `locales/`. This is the dead-key check this audit ran by hand.

## H. Docs — PFE-19, PFE-01, PFE-20 (+20a)

- **PFE-19:** add Preview to the CONFIG and PROFILE consumer cells. Optional: a `tests/test_bus.lua`
  case that greps `RegisterMessage(NS.MSG.X` per module and compares against the table's cells.
- **PFE-01:** one `sync-docs` pass over the seven sites listed in 02. For the compat count, write the
  grep and its result (14) so the next audit re-derives it rather than reading the number.
- **PFE-20 / 20a:** a mechanical sweep over the ten files. Line 1 becomes `local _, NS = ...` (or
  `local addonName, NS = ...` where `addonName` is read), and the existing header comment moves
  directly beneath it. Add path headers to `core/Namespace.lua`, `core/Constants.lua` and
  `core/State.lua`. No code moves, so `tests/test_loadorder.lua` is unaffected. Lint and the suite are
  the check.

## I. Config and observations — PFE-21, PFE-22, PFE-23, PFE-24, PFE-08, PFE-09

- **PFE-21:** comment out `.pkgmeta:12-13` in the template's own shape.
- **PFE-22:** no change now. When the first migration step is written, apply it to every profile in
  `NS.db.profiles` (AceDB exposes them as `db.profiles`) inside the load pass, and add a two-profile
  test.
- **PFE-23:** upstream question to WowAddonStandards and LibKa0s: export the refusal format from
  `LibKa0s-Slash-1.0` as data, or let `slash-commands-§1` name the degraded refusal line as a
  permitted copy. No addon change until that is ruled.
- **PFE-24:** `C.LOGO_PATH = "Interface\\AddOns\\" .. addonName .. "\\media\\logos\\" .. addonName:lower() .. ".logo.tga"`
  (Constants needs `local addonName, NS = ...`, which PFE-20 already makes line 1).
- **PFE-08 / PFE-09:** none. At the next release, run `tests/_kit/run-automated-tests.sh --release <v>`
  over the tagged tree.

## Ordering constraints

1. **PFE-20 before PFE-24.** Both edit `core/Constants.lua` line 1.
2. **PFE-14 before PFE-12's test.** The helper and the mock's `EventRegistry` recorder both touch
   registration. Land the helper, then the stand-down fixes, then the mock recorder, so each step's
   failing test is attributable.
3. **PFE-17 before PFE-18.** Deleting `REFUSED_DISABLED` removes a key; do the key cleanup after, so it
   is one pass.
4. **Docs (PFE-01, PFE-19, PFE-12b, PFE-15a, PFE-10) last,** so they describe the code as changed.
5. Nothing here changes stored data, so no `schemaVersion` bump.
