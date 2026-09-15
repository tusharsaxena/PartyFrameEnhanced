# 04 — Technical design: closing the PFE deviations

This covers the seven Low findings and the three optional Info notes. None of it changes what a
player sees, except PFE-05 (strings routed through `NS.L`, same English text) and PFE-01 (the README
text). Every change lands under the green gate (`lua tests/run.lua`, `luacheck .`).

---

## PFE-03 — a pre-store veto in the write seam (`architecture-§5`)

**Files:** `settings/Schema.lua`, `modules/Preview.lua`, `settings/General.lua`, `tests/test_preview.lua`
(or `tests/test_schema.lua`), `docs/ARCHITECTURE.md` (unchanged claim becomes true).

**Shape.** `NS.SetByPath` gains the validate step `architecture-§5` names ("validate → write →
onChange"), run **before** the store:

```lua
function NS.SetByPath(path, value)
    local row = byPath[path]
    if row and row.validate then
        local ok, why = row.validate(value)
        if not ok then
            if why and NS.Print then NS.Print(why) end
            if NS.RefreshOptionsPanel then NS.RefreshOptionsPanel() end
            return false                     -- nothing stored, no [Set] line, no onChange, no CONFIG
        end
    end
    -- … existing body unchanged …
    return true
end
```

The `locked` row gets `validate = function(v) if v == false and InCombatLockdown() then return false,
REFUSED end return true end`. This is attached by path in `settings/General.lua`, the same way
`masterOnChange` is attached. `NS.OnLockChanged` then keeps only the success path, and
`modules/Preview.lua:35-41` drops its `NS.SetSetting` call. `Preview.Toggle`'s own combat refusal is
untouched: it writes nothing.

**Risks.**

- The `validate` field must not collide with a LibKa0s row field. The library's slash parser and the
  Options widgets both ignore unknown row fields, so check `libs/LibKa0s/Options*.lua` and `Slash.lua`
  for a `validate` key before naming it. If one exists, use `veto`.
- `runLock` (`settings/Slash.lua:77-82`) already reads the value back, so it needs no change.

**Test.** An unlock under a mocked `InCombatLockdown() == true` has to leave four things true:

- `locked` stays `true`;
- no `[Set]` line is appended (debug on);
- `onChange` is not called;
- CONFIG is not published.

The case must be red against the current code, where `[Set] locked = false` is logged. Name that
mutation in the case's comment (testing-§12).

## PFE-02 — annotate and pin `settings\Schema.lua` (`toc-file-§5`)

**Files:** `PartyFrameEnhanced.toc`, `tests/test_loadorder.lua`.

Above `settings\Schema.lua` (`:81`), add:

```
# LOAD-BEARING: publishes NS.RegisterSchemaRows, which every settings page calls at file load.
```

Add a load-order case modeled on `tests/test_loadorder.lua:55-63`. It should assert that
`settings/schema.lua` precedes every `settings/*.lua` page that calls `NS.RegisterSchemaRows` at file
scope, and that the TOC carries the note (a `find` on the comment text, as `:44` does for MediaSetup).
Moving the TOC line changes no behavior.

## PFE-06 — the two missing stub cases (`testing-§8`)

**Files:** `tests/test_perfsetup.lua` (or `tests/test_surface_parity.lua`), a new case for Env
(in `tests/test_slash.lua` or a new `tests/test_envsetup.lua`, which must then be added to the
declared suite list in `tests/run.lua`; the inventory pin enforces this).

- **Env, degraded.** `local NS2 = loadDegraded()`, then check two things on the library-absent load:
  - `NS2.Version()` returns a non-nil string;
  - `NS2.Meta("Version")` answers either the mock's TOC value or nil, without raising.
- **Perf, parity.** Register the live instance in `Kit.setSurfaceSource` (`tests/run.lua:34-38` gains
  `["LibKa0s-Perf-1.0"] = NS.Perf`). Then add
  `T.assertSurfaceParity(NS2.Perf, "LibKa0s-Perf-1.0", { <live-only members, each with its reason> })`,
  so the exclusion list is the declaration.
  - If whole-surface parity is the wrong fit, keep the hand-listed case instead, with a comment naming
    the grep that produced its list:
    `-- members from: grep -rhoE "(NS\.)?Perf[:.][A-Za-z]+" core/ modules/ settings/ | sort -u`
    (today: `on`, `Note`, `suspended`, `OnCommand`).

## PFE-07 — the global reset's blast radius, end to end (`options-ui-§12`)

**File:** `tests/test_optionssetup.lua`.

One case:

1. Record `db:GetCurrentProfile()` and the sorted `db:GetProfiles()`.
2. Create a second profile, then switch back. Change a profile row and set the session row
   (`state.debugConsole`) on.
3. Subscribe a bus target to `NS.MSG.PROFILE`.
4. Call `NS.Helpers.RestoreAllDefaults()`.
5. Assert:
   - the changed row is back at its default;
   - `GetProfiles()` is unchanged, the second profile included;
   - `GetCurrentProfile()` is the original;
   - the session row is off;
   - exactly one `PROFILE` message was received.

This uses the real `ApplyDefault`, not the recorder at `:19-20`. Check that the kit's AceDB fake
supports `SetProfile` and `GetProfiles`. If it does not, extend `tests/wow_mock.lua`, per the
options-ui-§12 harness note, and never `tests/_kit/`.

## PFE-04 — trace the feature flows (`debug-logging-§8`)

**Files:** `modules/CastBars.lua`, `modules/TargetFrames.lua`, `modules/PetFrames.lua`, and optionally
`modules/UnitButtons.lua`.

| Flow | Line (gated, one per event unless noted) | Where |
|---|---|---|
| Cast start / re-derived start | `NS.Debug("Cast", "%s %s", unit, kind)` — the name can be secret, and `NS.Debug` routes it through `safeToString` | `render` / `start` |
| Cast stop / interrupted / failed | `NS.Debug("Cast", "%s stop (%s)", unit, reason or "done")` | `stop` |
| Show decision refused | one summary per refresh pass, e.g. `NS.Debug("Cast", "hidden: %s", reasons)` with the reasons built **only** when `NS.State.debug` | `refreshAll` |
| Target change | `NS.Debug("Target", "%s → changed", unit)` | `onEvent` |
| Ticker on / off | `NS.Debug("Target", "ticker %s", want and "on" or "off")` on transitions only | `UpdateTicker` |
| Pet swap | `NS.Debug("Pet", "%s pet changed", unit)` for `UNIT_PET` only | `onEvent` |

**Constraints.**

- Pass arguments, not preformatted strings (§4).
- No per-frame lines. The `OnUpdate` tick logs nothing, and the per-pass summaries follow §9.
- Keep list-building behind `if NS.State.debug`, since the cast-event path is a Shape A bracket
  region and must stay allocation-free when off.
- Re-run `lua tests/perf.lua`. `probeOverheadOff` must stay within its ceiling (24 bytes), which is
  the evidence the lines are free when off.

**Risk.** A gated call on the cast-event path costs one function call with debug off. That is
acceptable, because the sink's first statement is the gate. The perf scenario confirms it.

## PFE-05 — route the chat strings (`localization-§1`)

**Files:** `settings/Slash.lua`, `settings/About.lua`, `settings/General.lua`, `locales/enUS.lua`.

- Route every chat literal and each `NS.COMMANDS` description through `L[...]`. Use whole sentences
  with placeholders, for example `L["Switched to profile '%s'"]:format(name)`, never
  `L["Switched to profile"] .. name`.
- Route the landing heading `"Slash Commands"` the same way.
- Add each key to `enUS.lua`. The dead-key check in `03_EVIDENCE.md` §E17 must stay at 0 dead keys.
- `tests/test_slash.lua` matches output text, so check its expected strings are still produced (the
  English is unchanged).
- **Alternative, if translation is declined:** close #9 as `state:will-not-do` and add the
  `localization-§1` English-only row, with the trigger `the first non-English locale file added to
  locales/`. The routed strings stay routed either way.

## PFE-01 — one doc sync (`documentation-§5`, `documentation-§7`)

**Files:** `docs/ARCHITECTURE.md` (`:25-26`, `:30`, `:48`), `docs/schema.md` (`:69`), `docs/data-flow.md`
(`:51-54`), `docs/testing.md` (`:19-23`, `:34-35`), `docs/common-tasks.md` (`:29`), `DEPENDENCIES.md`
(`:20`, `:29`), `README.md` (`:27-28`, `:96`).

- State counts by re-deriving them from the tree: TOC lua files = 34, and `212/self` stanzas = 8
  naming eight files. Better still, restate them without a bare number where the number carries
  nothing.
- Drop the plan-phase future tense ("Arrives in plan P2", "land in plan P2–P5", "(as they land)").
- Delete `data-flow.md`'s `## Build status` section, or turn it into a pointer to the plan ledger.
- Add `tests/test_spelling.lua` to `DEPENDENCIES.md`'s `git` evidence cell.
- README: replace the in-development note with what the addon does now. Keep "first release follows
  in-game testing" if that is still true. Update the Version History highlight to name the three
  features. **Run the de-AI pass (`/humanize`) on the README edit before committing**
  (documentation-§1, anti-pattern #77).
- `wow-addon:sync-docs` does most of this. Diff its output against the site list above.

## Info notes (optional)

- **PFE-08.** Optionally write `design spec §6.4` in place of `spec §6.4`. That is pure comment
  edits; not required.
- **PFE-09.** No code. The release command must run from a fresh
  `tests/_kit/run-automated-tests.sh --release 0.1.0` over the tree being tagged.
- **PFE-11.** Optionally add a comment at `modules/Element.lua:15-17` recording that the Blizzard
  cast-bar shield is deliberate. It is the convention players read on every other cast bar, and the
  catalog's white `shield` stays available.

## Ordering constraints

- PFE-03's seam change comes before PFE-04's cast/target trace lines, so the new veto path is not also
  instrumented twice. They touch different files, so this is a preference, not a hard constraint.
- Do PFE-06 (Env) after PFE-02 if a new suite file is added, because the inventory pin needs
  `tests/run.lua` updated in the same change.
- Do PFE-01 **last**, since PFE-02–PFE-07 change `docs/testing.md`, `docs/test-cases.md` and the
  README badge. Regenerate `docs/test-cases.md` and update the `Tests` badge in the same change as
  each new case (testing-§5).
