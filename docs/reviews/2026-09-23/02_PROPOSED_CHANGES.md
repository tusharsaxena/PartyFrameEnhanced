# Proposed changes — PartyFrameEnhanced review (2026-09-23)

**Standard resolved:** Ka0s WoW Addon Standard **v2.64.0 (2026-09-23)**. The index and all 27
section files were fetched verbatim with `curl` from
`raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master`. Every change below was checked
against it as a *guardrail* (no new deviation). This is not a compliance audit.

Finding IDs refer to `01_FINDINGS.md`. Change IDs are `C-xxx`.

---

## HLD — themes

### T1. Profile adoption must not depend on bus dispatch order (F-001, F-008)

CallbackHandler fans a message out in `next()` order over its target tables, so "Anchor runs first"
is an accident of hashing, not a property of the code. The durable fix is to remove the dependency
rather than try to order it. Anchor reads each feature's section **live** from the store, which
AceDB has already swapped by the time `OnProfileChanged` fires.

- **Chosen:** `spec.config = function() return NS.db.profile.<key> end` in the three features. There
  is one source of truth, and no ordering between receivers matters.
- **Rejected: a next-frame deferral of Anchor's PROFILE pass.** It would let a stale placement show
  for one frame. It also adds a timer to a path `test_disabled` counts, and it hides the problem
  rather than removing it.
- **Rejected: an explicit ordered fan-out (a second, ordered PROFILE message, or Anchor called from
  each feature).** A second message would break "one sender per message" (architecture-§4) or grow
  the catalog for an ordering concern. Calling Anchor from each feature is acceptable as a
  belt-and-braces addition, but it leaves the stale-upvalue read in place.
- **Trade-off:** one extra table index per `spec.config()` call. `anchorUnchanged` is 0 B/iter today,
  and a field read allocates nothing. `tests/perf.lua` re-run confirms.

### T2. Profile sub-verbs validate names before touching AceDB (F-002, F-004, F-008)

`new` refuses an existing name. `use`, `copy` and `delete` refuse a missing one. `copy` also refuses
the current profile. Each refusal is one tagged line through the existing printer, and none of them
writes anything. Existence is read from `db:GetProfiles()`, the same list `profile list` prints, so
the verbs and the listing cannot disagree.

- **Rejected: wrapping AceDB calls in `pcall` and printing the error.** It would hide an AceDB usage
  error rather than prevent it, it would print AceDB's English with no localization, and `new` would
  still wipe.
- **Rejected: `use` auto-creating, as AceDBOptions' *New* field does.** `/pfe` already has `new` for
  that, and two verbs creating is the drift. `use` of an unknown name refuses and points at `new`.

### T3. Secure-write memos record the latest REQUEST, not the last APPLIED write (F-003)

`ApplyClicks` and `ApplyDriver` set a `__want*` field at request time and early-return against
that. The applied memo is kept separately and stays set inside the deferred closure. A reverted
in-combat change then re-queues the latest value under the same key, and the queue's latest-wins rule
does the rest.

### T4. The stand-down covers every registration with a real unregister (F-005, F-006)

- `Providers:Suspend` unregisters the `EditMode.Exit` callback, and `Resume` re-registers it.
  `burst()` returns early while suspended, so nothing is armed.
- Secure buttons: while stood down, `UnregisterStateDriver(btn, "visibility")` and `btn:Hide()`
  through `NS.RunSecure` (this is already the combat-deferral seam §7 names). Stand-up re-registers
  from current state through the ordinary `refresh` path.
- **Rejected: a second, disable-only teardown path.** Both changes live in the existing `Suspend`
  hooks that the latch already reaches (slash-commands-§7, anti-pattern #85).

### T5. Evidence that can go red (F-007, F-008, F-009)

- The zero-overhead scenario gains a true "instrumentation absent" arm (details in C-007).
- Integration cases cover a real profile switch, reset and copy, plus every `profile` sub-verb.
- `docs/performance.md` figures are regenerated from a fresh run in the same change that touches
  perf.

### T6. Hygiene (F-010, F-013, F-014, F-015, F-016, F-017, F-018)

These are small, independent edits: trim the lint whitelist, remove a dead locale key, unify
wording, make the migration runner walk every profile, set `SetDontSavePosition`, gate a few
registrations, and add a `.pkgmeta` ignore.

---

## Upstream change-set (lands in LibKa0s, NOT in this repo)

No entry below edits anything under this addon's `libs/` or `tests/_kit/`. This repo's only
deliverable is the **re-vendor commit** once the library ships.

| Finding | Owning repo / file | Change | Version bump | Consumer action |
|---|---|---|---|---|
| F-011 | LibKa0s `testkit/mock_record.lua` (AceDB fake) | `CopyProfile`: raise `Cannot copy profile %q as it does not exist.` / `Cannot have the same source and destination profiles (%q).` like AceDB-3.0 (`AceDB-3.0.lua:581-587`). `DeleteProfile`: raise on the active profile, and raise on a missing profile unless `silent`. `SetProfile`: run a `removeDefaults`-equivalent strip on the outgoing profile | kit revision +1 (README "Revision N" entry) | re-vendor the whole `tests/_kit/` into every consumer, one commit each |
| F-012 | LibKa0s `testkit/mock_base.lua` + `mock_record.lua` | an additive recording `EventRegistry` (`RegisterCallback(event, fn, owner)`, `UnregisterCallback(event, owner)`, `TriggerEvent`) whose live registrations appear in `__registrations()` with `kind = "callback"` | kit revision +1 (may share F-011's bump) | same re-vendor |
| F-010 (optional) | LibKa0s `LibKa0s/Slash.lua` and docs/api Slash "Degradation" | publish the **prescribed** library-absent Slash stub shape in the Slash API document (the form options-ui-§1 names for other majors), so a host's stub stops improvising a dispatcher. Doc-only, or doc plus an exported format constant a host cannot reach anyway when the lib is absent | doc change; no minor unless code changes | none until adopted |

Remediation wording, applied to each row: **fix it in the library's own repo, bump the minor or kit
revision, then re-vendor the whole folder into this addon and every other consumer as its own
commit. It is never an edit in place here.** `tests/test_vendor_sync.lua` will fail the moment a
local edit lands, as it should.

---

## LLD — per change

### C-001 — Anchor reads live sections; fix the ordering comments (F-001)

**Files:**
- `modules/CastBars.lua` (Anchor.Register spec, `:370-375`)
- `modules/TargetFrames.lua` (`:256-264`)
- `modules/PetFrames.lua` (`:137-145`)
- `modules/Anchor.lua` (comment `:119-126`)
- `tests/test_anchor.lua` (comment `:178-183`)

```lua
-- before (CastBars.lua:372)
config = function() return cfg end,
-- after
config = function() return NS.db.profile.castbar end,   -- LIVE: PROFILE dispatch order is undefined
```

The same change applies to `target` and `pet`. `slotSize` closures read `cfg.width`/`cfg.height`,
and `Anchor.applyFree` reaches them during Anchor's PROFILE pass, so they switch to the same live
read.

Rewrite the Anchor comment. It should say that CallbackHandler order is undefined, that Anchor
therefore reads the store directly, and that the `shipped()` fallback stays for keys AceDB strips on
the outgoing profile.

- **Risk:** low. The features' own `cfg` upvalues are unchanged. `Anchor.SavePosition` writes
  `cfg.position` into the live table, which is more correct than the current behavior.
- **Tests:** add to `tests/test_anchor.lua` (or a new `tests/test_profile_switch.lua`, listed in
  `tests/run.lua`) cases that
  - drive `NS.db:SetProfile` between two profiles differing in `anchorMode` for all three features,
  - assert every element's `__aTarget` matches its profile's mode after each switch, and
  - repeat the check after `NS.Helpers.RestoreAllDefaults()`.

  Add `-- red under: revert config() to the captured upvalue`. The mock's `next()` order already
  reproduces the failure for `pet`, so the case is falsifiable today; state that in the comment.
- **Standards:** architecture-§4 (receivers on their own targets; the sender is unchanged).
  architecture-§5 (reads, not writes, so the single write seam is unaffected).

### C-002 — `profile` sub-verbs validate names (F-002, F-004)

**File:** `settings/Slash.lua:254-307`.

```lua
local function exists(db, name)
    for _, n in ipairs(db:GetProfiles()) do if n == name then return true end end
    return false
end
-- new:    if exists(db, name) then return print(L["Profile '%s' already exists — use /pfe profile use %s"]:format(name, name)) end
-- use:    if not exists(db, name) then return print(L["No profile named '%s' — /pfe profile list shows them, /pfe profile new creates one"]:format(name)) end
-- copy:   if name == db:GetCurrentProfile() then return print(L["Cannot copy a profile onto itself"]) end
--         if not exists(db, name) then return print(<the use line>) end
-- delete: if not exists(db, name) then return print(<the use line>) end
```

- **Locale:** add the new keys to `locales/enUS.lua` in the slash block (localization-§1). Format
  strings, not concatenated fragments. US English (localization-§5).
- **Risk:** `use` of an unknown name no longer creates one. This is a behavior change and must be
  noted in the changelog (see 05). AceDBOptions' Profiles page is untouched.
- **Tests:** add cases to `tests/test_slash.lua` for:
  - `new` on an existing name, which refuses and leaves `castbar.width` untouched
    (`-- red under: drop the exists() guard in new`);
  - `use` of an unknown name, which refuses with the current profile unchanged;
  - `copy` of a missing or current name, which refuses without raising. This one needs F-011's kit
    fidelity to go red against today's code; until the re-vendor, assert on the printed line and
    say so;
  - `delete` of a missing name, which refuses with no "Deleted" line.

  The pass count moves. `docs/test-cases.md` and the README `[tests]` badge **must move in the same
  commit** (testing-§5).
- **Standards:** slash-commands-§3 (host verbs stay in `NS.COMMANDS`; `profile` is on
  `LIVE_WHILE_DISABLED` and is unaffected); slash-commands-§4 (one tagged line).

### C-003 — Request-side memo for secure writes (F-003)

**File:** `modules/UnitButtons.lua:53-71`.

```lua
function UnitButtons.ApplyClicks(btn, on)
    on = on and true or false
    if btn.__clicksWant == on then return end
    btn.__clicksWant = on
    NS.RunSecure("clicks:" .. btn.__key, function()
        btn.__clicks = on
        btn:SetAttribute("*type1", on and "target" or nil)
        btn:EnableMouse(on)
    end)
end
```

`ApplyDriver` gets the same treatment with `__driverWant`. `btn.__driver` and `btn.__clicks` keep
their meaning (applied state). Grep the tests for readers first: `test_targetframes`, `test_party`
and `test_disabled` read `__drivers.visibility` from the mock, not the memo.

- **Risk:** low. Out of combat, `RunSecure` runs immediately, so want and applied stay equal.
- **Tests:** in `tests/test_targetframes.lua`, force `mocks.InCombatLockdown` true, set
  `target.clickToTarget` false then true, and leave combat through `NS.addon:OnLeaveCombat()`. Then
  assert `btn:GetAttribute("*type1") == "target"`. Add `-- red under: compare against btn.__clicks`.
  The same shape covers the driver.
- **Standards:** events-frames-taint-§2 (the queue stays the only combat path).

### C-004 — Providers stands the Edit Mode callback down (F-005)

**File:** `modules/Providers.lua:61-67`, `:339-359`.

```lua
local function registerEditMode(on)
    if not (EventRegistry and type(EventRegistry.RegisterCallback) == "function") then return end
    if on then
        pcall(EventRegistry.RegisterCallback, EventRegistry, "EditMode.Exit", burst, Providers)
    else
        pcall(EventRegistry.UnregisterCallback, EventRegistry, "EditMode.Exit", Providers)
    end
end
local function burst()
    if suspended then return end
    ...
end
-- OnEnable: registerEvents(); registerEditMode(true); burst()
-- Suspend:  ... ev:UnregisterAllEvents(); registerEditMode(false)
-- Resume:   suspended = false; registerEvents(); registerEditMode(true); burst()
```

- **Tests:** after the F-012 re-vendor, `test_disabled`'s registration-set assertion covers this
  automatically. Before then, add a local assertion that `burst()` arms no timer while stood down
  (`#mocks.__timers() == 0` after firing the captured callback). That needs a tiny local
  `EventRegistry` shim inside the suite, which is acceptable as a test-local stub until the kit
  ships one. Add `-- red under: drop the suspended guard in burst`.
- **Standards:** slash-commands-§7 ("every … registration … actually UNREGISTERED"; the
  `hooksecurefunc` carve-out does not apply to a callback with a real unregister).

### C-005 — Unregister secure state drivers while stood down (F-006)

**Files:**
- `modules/UnitButtons.lua` (new `UnitButtons.StandDown(btn)` / reuse `ApplyDriver`)
- `modules/TargetFrames.lua:269-279`, `modules/PetFrames.lua:150-160`

Under `suspended`, `refresh` calls `UnitButtons.Release(btn)`, which runs this through `NS.RunSecure`:

```lua
NS.RunSecure("driver:" .. btn.__key, function()
    UnregisterStateDriver(btn, "visibility"); btn:Hide()
    btn.__driver = nil
end)
```

It sets `btn.__driverWant = nil` at request time (C-003's convention). The next non-suspended
`refresh` re-registers from current settings.

- **Risk:** medium. This is secure code; it needs the combat smoke test. The in-combat stand-down
  path already defers through the queue plus `armPendingRegen` (`core/PartyFrameEnhanced.lua:62-72`,
  `:107-117`), which is exactly §7's "held pending and completed on PLAYER_REGEN_ENABLED".
- **Tests:** in `tests/test_disabled.lua`, assert no `__drivers.visibility` entry remains on any
  button after disable (out of combat), and that re-enable restores
  `"[@party1target,exists] show; hide"`. Also assert the in-combat variant completes after
  `OnLeaveCombat`. Add `-- red under: keep the "hide" driver`.
- **Standards:** slash-commands-§7 (state drivers stood down where they can be; never in combat).

### C-006 — Stale doc figures and ceilings comment (F-009)

**Files:** `docs/performance.md` (scenario table, "Figures from" line), `tests/perf.lua:243-258`
(comment text only; no ceiling changes).

- Re-run `tests/perf.lua` in the same change and copy the numbers.
- Say what grew `settingsDrag`: the structure signature grew three marker fields. It stays unasserted.
- Never hand-edit a number that was not just measured.

### C-007 — A true "instrumentation absent" arm for the zero-overhead scenario (F-007)

**File:** `tests/perf.lua:226-240`.

The brackets read a load-time `local Perf = NS.Perf`, so "absent" cannot be produced by swapping
`NS.Perf` after load. Two compliant options:

1. **Preferred:** load a **second environment** in which `core/PerfSetup.lua` publishes a table whose
   `on` field is a constant `false` and whose `Note` counts calls. Reuse the loader with a
   `NS.Perf` pre-seeded before `Loader.loadAll`. Only if PerfSetup respects an existing `NS.Perf`
   under a test flag, which is intrusive. Otherwise:
2. **Practical:** keep the current off/on arms, and add assertions that hold only if a dormant
   bracket is free.
   - Wrap `debugprofilestop` and `NS.Perf.Note` with counters, and assert **0** calls of each per
     iteration while `Perf.on == false`.
   - Assert `probeOff.bytesPerIter <= castStartStop.bytesPerIter + 1`, where `castStartStop` is the
     same event path, unbracketed-equivalent in allocation.

   Record in the comment why this is the "absent" proxy.

- **Standards:** performance-§9 (outside the gate; deterministic quantities only; no wall-clock
  assertion is added). performance-§2.
- **Evidence note:** this is a scenario, not a test case; it must not enter `docs/test-cases.md`
  (testing-§7).

### C-008 — Hygiene bundle (F-013, F-014, F-015, F-016, F-017, F-018)

| Finding | File(s) | Change |
|---|---|---|
| F-013 | `.luacheckrc:14-38` | remove the 12 unused names. `UnregisterStateDriver` returns with C-005 as a real use. Keep `UnitExists` **out**, with a comment pointing to `core/Compat.lua:205-208` |
| F-014 | `locales/enUS.lua:150`, `:134-136`; `settings/Slash.lua:107,109`; `settings/General.lua:200,202` | delete the dead key; use one spelling per message (no trailing period, per slash-commands-§4 house style) and delete the other key |
| F-015 | `core/Database.lua:37-48` | apply each step to **every** stored profile (`for name, p in pairs(NS.db.profiles or { [cur] = NS.db.profile })`), with defaults-merge caveats commented; stamp the global version only after all profiles. Add a unit case with a fake step (test-local ladder injection) |
| F-016 | `modules/Anchor.lua` after `:257`, `modules/StandIn.lua` after `:153` | `if frame.SetDontSavePosition then frame:SetDontSavePosition(true) end` (presence-guarded; compat) |
| F-017 | `modules/TargetFrames.lua:205`, `:320-332`, `modules/PetFrames.lua:83`, `:189`, `modules/Preview.lua:154` | guard the `NS.Debug` argument construction with `if NS.State.debug then … end`. Move `PLAYER_TARGET_CHANGED`/`RAID_TARGET_UPDATE` registration into each module's `syncEvents` (registered only while the feature is on and in a party). Move Preview's `PLAYER_REGEN_DISABLED` into `listen(on)` |
| F-018 | `.pkgmeta` | add `- media/screenshots` to `ignore` (optionally rename files to `partyframeenhanced.*`; they are unreferenced by code or README) |

- **F-017 check:** the `test_disabled` baseline `R_on` must still be non-empty when enabled in a
  party, which it will be (unit events). Re-run it.
- **Standards (F-017):** events-frames-taint-§1, and no new AceEvent-vs-frame deviation. These are
  bus-target AceEvent registrations already.
- **Standards (F-016):** compat — presence-guarded API use.

### C-009 — Slash stub stops copying the refusal format (F-010)

**File:** `settings/Slash.lua:325-391`.

Keep the stub's dispatch. slash-commands-§1 requires the stub to answer `OnSlash` and friends. But
drop the hand-copied `DISABLED_LINE` color format and render the refusal **plainly**, as §1 asks of
degraded rendering: `"<brand> is disabled; /pfe enable turns it back on (LibKa0s missing)"`.

- **Consequence:** the parity case `tests/test_surface_parity.lua:77-111` currently asserts
  identical text. Change it to assert **one** line naming `/pfe enable` in both arms, and note why
  the texts differ.
- **If the upstream F-010 doc change lands first,** follow the prescribed shape instead.
- **Rejected:** deleting the stub's gate. A degraded build would then act on feature verbs while
  disabled.

---

## Regression pressure

- **Test count:** C-001, C-002, C-003, C-004, C-005 and C-008 (F-015) add cases, roughly 12–15 new.
  `docs/test-cases.md` (regenerated by `lua tests/run.lua --list`) and the README `Tests-289%2F289`
  badge must change **in the same commit** as each count move (testing-§5). No existing case is
  deleted or weakened.
- **Complexity:** C-002 adds guards to `PROFILE_VERBS` closures (small, separate functions). C-004
  adds one function. `NS.SetByPath` (CCN 14, the current max) is untouched. The next release's
  `lizard` regeneration should confirm max CCN ≤ 15. This is a note for the release, not a task now.
- **Perf:** C-001 adds one table index per `spec.config()` and should leave `anchorUnchanged` at
  0 B/iter. C-003 adds one field write per request. Re-run `tests/perf.lua` after M2 and cite the
  numbers in 05.

## Standards conformance (per change)

| Change | Conforms? | Shaping rule(s) | Rejected alternative → rule it broke |
|---|---|---|---|
| C-001 | yes | architecture-§4, §5 | second ordered PROFILE message → architecture-§4 one-sender/closed catalog |
| C-002 | yes | slash-commands-§3/§4, localization-§1/§5 | pcall-and-print AceDB error → localization-§1 (raw English error text) |
| C-003 | yes | events-frames-taint-§2 | dropping the memo entirely → allocation/secure-write churn per refresh (performance-§2 spirit) |
| C-004 | yes | slash-commands-§7 | gate-only (`if suspended`) without unregister → anti-pattern #85 draw gate |
| C-005 | yes | slash-commands-§7, events-frames-taint-§2 | a disable-only teardown beside Suspend → slash-commands-§7 "one latch", anti-pattern #85 |
| C-006 | yes | performance-§9 | hand-editing numbers → testing-§5/performance-§9 (unmeasured figures) |
| C-007 | yes | performance-§2, §9; testing-§7 | wall-clock assertion → performance-§9 (forbidden) |
| C-008 | yes | lint, localization-§1, savedvariables-§1, compat, events-frames-taint-§1, packaging | — |
| C-009 | yes | slash-commands-§1 | keeping the copied format → slash-commands-§1 MUST NOT |
| Upstream U-F011/U-F012 | yes | library-stack-§7, testing-§1/§11, anti-patterns #45/#47 | patching `tests/_kit/` locally → anti-pattern #45 (drift), testing-§11 |
