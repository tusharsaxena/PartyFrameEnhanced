# Review findings — PartyFrameEnhanced (2026-09-23)

**Verdict: minor issues** — no Critical, no load/taint/secret-value leak; two High functional defects
(profile-switch anchoring, `profile new` overwriting an existing profile) that a normal player reaches.

Reviewed: the whole repo at `314c95e` (branch `feat/2026-09-23-review-audit-remediation`, addon
v1.0.1, TOC `## Interface: 120100`). Standards cross-check against **Ka0s WoW Addon Standard v2.64.0
(2026-09-23)**, fetched verbatim with `curl` from `tusharsaxena/WowAddonStandards@master` (index +
all 27 section files).

## Measurement run

Every run went through `~/.claude/wow-addon/bin/ka0s-bounded` (not on `PATH` in this shell, invoked
by absolute path; no `timeout 900` fallback was needed). All output went to a scratch directory
outside the repo; nothing under the repo was written except this bundle.

| Suite | Result | Command (repo root unless noted) |
|---|---|---|
| luacheck | **pass** — 0 warnings / 0 errors in 71 files | `ka0s-bounded luacheck .` |
| Headless suite | **pass** — 289 passed, 0 failed, 0 skipped, 289 total | `ka0s-bounded lua5.1 tests/run.lua` |
| Test-case inventory | **pass** — fresh `--list` is byte-identical (CR-normalised) to committed `docs/test-cases.md` (289) | `ka0s-bounded lua5.1 tests/run.lua --list > <scratch>/test-cases.md` then `diff` |
| Offline perf | **ran, all assertions held** — 9 scenarios (figures cited in F-007/F-009) | `ka0s-bounded lua5.1 tests/perf.lua` |
| Complexity | **ran** — 8045 NLOC, 1047 functions, avg CCN 2.2, max CCN 14 (`NS.SetByPath` `settings/Schema.lua:198-220`; `NS.ResolveColor` degraded arm `core/CoreSetup.lua:36-45`), 0 warnings, 0 files in the 1000–1500 band | `ka0s-bounded lizard -l lua -x "./libs/*" -x "./tests/_kit/*" . > <scratch>/complexity.txt` |
| `make test` | **skipped** — no root `Makefile` | — |
| Vendor sync | **pass** — `diff -rq libs/LibKa0s ../LibKa0s/LibKa0s` empty; `diff -rq tests/_kit ../LibKa0s/testkit` empty | as shown |
| Cross-addon (4 classes) | **pass, clean** — run over the **eleven** roster repos (the nine in the review brief plus AuraMaster and PartyFrameEnhanced, per `standards/ADDONS.md`), TOC-derived load lists | commands of the brief, `set --` extended to eleven |

Cross-addon detail (measured non-findings, recorded so the next pass can diff):

- **Slash tokens:** 22 roots across 11 addons, `uniq -d` empty; `pfe`/`partyframeenhanced` belong to
  PartyFrameEnhanced alone. Zero raw `SLASH_*` assignments in any loaded file.
- **Vendored minors:** one line for all eleven — `Bus:1 Compat:1 Core:7 DebugLog:12 Env:1 Item:1
  Launcher:1 Lifecycle:1 Media:3 Options:23 Perf:12 Pool:3 Schema:1 Slash:14 Widgets:9`. Differs from
  the 2026-09-07 baseline only because every consumer moved to v1.55.0 together (uniform = latent, not live).
- **Payload bytes:** `diff -rq PartyFrameEnhanced/libs/LibKa0s <each>/libs/LibKa0s` empty for all
  eleven (reference addon: PartyFrameEnhanced). The baseline's two PrettyChat CR stragglers are gone.
- **`## Interface:`:** `120100` ×11, uniform (baseline `120007`; moved uniformly).

Committed artifacts that disagree with today's run:

- `docs/automated-tests/RESULTS.md` / newest bundle `20260918-121606` (sha `e4d7f41`, release 1.0.1)
  records **227** tests, 70 lint files, 7378 NLOC / 942 functions. Today: **289** tests, 71 files,
  8045 NLOC / 1047 functions. Watch list empty in both (max CCN 14 then and now). Stale, not
  non-compliant — regeneration is a release act. The bundle also lists `tests/test_spelling.lua`,
  since retired in favour of the kit's `test_prose` (commit `7eea3d0`).
- `docs/performance.md` scenario table: `castStartStop` **16.6** B/iter (fresh **5.4**),
  `settingsDrag` **596** B/iter (fresh **895.9**). See F-009.

Line-ending observation (not a finding here; the standards audit owns it): `.gitattributes` carries
`* text=auto eol=crlf`, `*.sh text eol=lf` and the binary list; a CR-vs-LF count over all 415 tracked
files (whole tracked set, no exclusions) found **0** stragglers.

In-client checks are deliberately absent here; they are in `03_SMOKE_TESTS.md`.

---

## High

### F-001 — A profile switch or reset leaves elements placed by the OLD profile `[design]`

- **Where:** `modules/Anchor.lua:359` — `ev:RegisterMessage(NS.MSG.PROFILE, function() Anchor.ApplyAll() end)`;
  the feature specs hand Anchor a captured upvalue: `modules/CastBars.lua:372`,
  `modules/TargetFrames.lua:258`, `modules/PetFrames.lua:139` — `config = function() return cfg end,`;
  each feature rebinds that upvalue only in its own PROFILE handler: `modules/CastBars.lua:408`
  `cfg = NS.db.profile.castbar`, `modules/TargetFrames.lua:297` `cfg, gen = NS.db.profile.target, NS.db.profile.general`,
  `modules/PetFrames.lua:178` `cfg, gen = NS.db.profile.pet, NS.db.profile.general`.
- **Problem:** Anchor's PROFILE handler reads each feature's `cfg` through `spec.config()`, and
  whether the feature has rebound it yet depends on dispatch order across bus targets.
  CallbackHandler dispatches with `next()` (`libs/CallbackHandler-1.0/CallbackHandler-1.0.lua:16`
  `local index, method = next(handlers)`), so that order is hash order over target tables, which is
  **undefined**, not TOC order. Nothing re-anchors afterwards: the features' PROFILE handlers
  reskin and repaint but never call `Anchor.Apply`, and Providers' follow-up resolve sends `LAYOUT`
  only when the frame map changed.
- **Impact:** after a profile switch, copy or reset, some features stay pinned where the old
  profile put them (attached versus free, point, offsets, match width) until the next `/reload` or
  roster change. Which features are affected varies from session to session.
- **Reachability:** any player who switches profiles (the Profiles page, `/pfe profile use|copy|new`)
  between profiles whose placement differs, or who changes placement and then uses **Reset all
  settings** or Profiles → Reset. Both are documented, default-install flows.
- **Evidence (scratch reproduction, not committed):** an out-of-repo script loaded the addon through
  `tests/_kit/loader.lua`, set all three features to `free` in profile B, and then switched profiles.
  - `back to Default   pet      anchoredToHolder= true   cfgMode= attached`
  - `switch to B       pet      anchoredToHolder= false  cfgMode= free`
  - `after Reset all settings  target  anchoredToHolder= true  cfgMode= attached`
- **Coverage asleep:** the inventory's `database: a profile switch publishes PROFILE and VISIBILITY`
  (`tests/test_database.lua:38-40`) calls `NS.OnProfileChanged()` directly and never checks
  placement. `anchor: a section stripped of its defaulted point still pins…` sets the stripped keys
  by hand. No case covers a real switch.
- **Wrong comments carrying the defect:** `modules/Anchor.lua:123-124` ("registered before the
  feature modules' (it loads earlier in the TOC), so it runs FIRST") and `tests/test_anchor.lua:181-182`
  make the same claim. Registration order is not dispatch order.
- **Fix direction:** Anchor must never read a feature's cached section during a PROFILE fan-out.
  Point `spec.config` at the live store (`NS.db.profile.<key>`), or have each feature re-apply its
  own anchors after rebinding. Either is compliant with `architecture-§4`: the single sender stays
  unchanged and receivers stay on their own targets.

### F-002 — `/pfe profile new <name>` silently wipes an existing profile of that name `[ux]` (data loss)

- **Where:** `settings/Slash.lua:270-274`. The code is `new = needsName("new", function(db, name) db:SetProfile(name) NS.ResetProfileCounted(db) …`.
- **Problem:** `new` never checks whether `name` already exists. `SetProfile` switches to an existing
  profile, and the reset that follows wipes it. The line then printed, *"Created and switched to new
  profile 'X'"*, is false.
- **Impact:** every setting in the named profile is lost and there is no undo.
- **Reachability:** any player who types the documented verb (`/pfe profile` lists
  `new <name> — Create new profile with defaults`) with a name that already exists, for example
  re-running a command, or case-matching an existing profile.
- **Evidence (scratch reproduction):** `profile new Healer` → `set castbar.width 222` →
  `profile use Default` → `profile new Healer` leaves `castbar.width` = **140** (the default).
- **Severity note:** this meets Critical's floor (data loss) and its ceiling (a documented command).
  It is graded High, not Critical, because it needs the player to name a profile that already
  exists, and the loss is confined to one profile's addon settings. Triage may raise it.
- **Coverage:** none. The inventory has no case for `profile new|use|copy|delete`, and only the
  empty-argument help (`slash: \`profile\` with no argument…`).
- **Fix direction:** refuse `new` on an existing name, with one tagged line pointing at
  `use`/`reset`.

## Medium

### F-003 — The secure-write memo compares against the APPLIED value, so a reverted in-combat change is lost `[design]`

- **Where:** `modules/UnitButtons.lua:65`: `if btn.__clicks == on then return end`. Also
  `modules/UnitButtons.lua:54`: `if btn.__driver == driver then return end`. In both, the memo field
  is set only inside the deferred closure (`:67`, `:56`).
- **Problem:** in combat, `A→B` queues B while the memo still reads A. A later `B→A` then
  early-returns, because the memo still equals A, and leaves B queued. At `PLAYER_REGEN_ENABLED`, B is
  applied.
- **Impact:** `clickToTarget` off→on in combat leaves every target or pet button **unclickable after
  combat** while the setting reads `true`. Nothing re-applies clicks; `OnLeaveCombat` republishes
  VISIBILITY, and that redraws drivers only. The driver half heals at combat end, because
  `refreshAll` recomputes the driver, but it runs one stale secure write first.
- **Reachability:** a player who flips *Click to target* twice in combat through `/pfe set`, or who
  runs `/pfe profile use` in combat between profiles whose `clickToTarget` differs. The settings
  panel is combat-locked by the library, so the CLI is the route.
- **Evidence (scratch reproduction):** after `set target.clickToTarget false` and `… true` in combat,
  then leaving combat, the output was `setting true btn.__clicks false attr *type1 nil`.

### F-004 — Profile sub-verbs mishandle bad names: raw error, false acknowledgment, silent creation `[ux]`

- **Where:** `settings/Slash.lua:265-285`.
- **Problem:**
  - `copy <missing|current>` calls `db:CopyProfile(name)`, which in AceDB-3.0 raises
    (`libs/AceDB-3.0/AceDB-3.0.lua:581-587`: "Cannot copy profile %q as it does not exist." / "Cannot
    have the same source and destination profiles"). The error escapes the slash handler as a Lua
    error.
  - `delete <missing>` passes `silent = true` (`:283`) and prints "Deleted profile 'X'" for a profile
    that never existed.
  - `use <typo>` creates and switches to a brand-new profile. `SetProfile` creates on demand, and the
    reply says "Switched to profile".
- **Impact:** a typo gets a Lua error, a false confirmation, or a stray profile, depending on the verb.
- **Reachability:** any player who mistypes a profile name after a documented sub-verb.
- **Coverage:** none (see F-002). The kit's AceDB fake also hides the `copy` error (F-011).

### F-005 — The stand-down leaves the Edit Mode callback registered and keeps arming timers `[design][perf]`

- **Where:** `modules/Providers.lua:342-343`:
  `pcall(EventRegistry.RegisterCallback, EventRegistry, "EditMode.Exit", burst, Providers)`, registered
  once in `OnEnable`. `Providers:Suspend` (`:348-353`) unregisters AceEvent events only. `burst()`
  (`:61-67`) arms two `C_Timer.After` closures unconditionally, even while `suspended`.
- **Problem:** `EventRegistry:UnregisterCallback` exists, so this is a registration that "has a real
  unregister". slash-commands-§7 requires it to go, and the `hooksecurefunc` carve-out does not
  apply. While disabled, every Edit Mode exit runs `burst()`, which arms two timers that wake up only
  to find `suspended`.
- **Impact:** small in cost (two closures per Edit Mode exit), but it breaks the "not running"
  contract, and nothing can see it: the kit has no `EventRegistry` fake, so `tests/test_disabled.lua`
  cannot count this registration (F-012).
- **Reachability:** any player who disables the addon and then enters and leaves Edit Mode.

### F-006 — Stand-down replaces the buttons' state drivers with `"hide"` instead of unregistering them `[design][perf]`

- **Where:** `modules/UnitButtons.lua:41-60`. `Driver` returns `"hide"` when not `allowed`, and
  `ApplyDriver` re-registers it. `TargetFrames:Suspend`/`PetFrames:Suspend` reach this through
  `refreshAll`. `UnregisterStateDriver` is declared in `.luacheckrc:31` and called nowhere in
  authored code (F-013).
- **Problem:** slash-commands-§7: "Hooks and secure state drivers are stood down where they can be".
  Out of combat they can be (`UnregisterStateDriver` plus `Hide` through `NS.RunSecure`). The
  addon keeps ten registered state drivers while disabled, and the client's state-driver manager
  keeps re-evaluating them.
- **Impact:** a registration survives the stand-down. The client-side cost is small (ten constant
  `hide` conditions), but it is exactly the class of survivor §7 was written to eliminate. The
  stand-down suite does not assert on drivers.
- **Reachability:** every player who disables the addon.

### F-007 — The zero-overhead scenario compares capture-off with capture-on, not with instrumentation absent `[tests][perf]`

- **Where:** `tests/perf.lua:234-240`, including
  `assert_(probeOff.bytesPerIter <= probeOn.bytesPerIter + 1, …)`.
- **Problem:** performance-§9 MUSTs a scenario proving that the hottest bracketed path with capture
  **off** allocates no more than the same path **without** instrumentation. The current assertion
  bounds "off" by "on". A dormant bracket that allocates exactly as much as an armed one passes it,
  and that is the defect the scenario exists to catch. The `probeOverheadOff ≤ 24 B` ceiling
  (`:262`) partly compensates, but it is a ceiling, not the required comparison.
- **Impact:** "a dormant bracket is free" (performance-§2) is only partially verified. Today's
  numbers happen to be fine: off **0.0** B/iter, on **0.5** B/iter, 11/11 API calls.
- **Reachability:** measurement evidence only. The shipped code is correct today (capped at Medium).

### F-008 — No test covers a real profile switch or the profile sub-verbs `[tests]`

- **Where:** `tests/test_database.lua:38-40` (calls `NS.OnProfileChanged()` directly),
  `tests/test_slash.lua:98-99` (`profile` with no argument only).
- **Problem:** F-001, F-002, F-003 (the profile route) and F-004 all sit on paths the inventory
  appears to cover ("profile switch publishes PROFILE…") but never exercises end to end.
- **Impact:** the suite stays green over two High defects.
- **Reachability:** test inventory only (capped at Medium). It is Medium rather than Low because the
  gap hides real, reachable Highs.

### F-011 `[upstream]` — Test kit AceDB fake: missing `CopyProfile`/`DeleteProfile` error contract and outgoing-profile `removeDefaults` `[tests][upstream]`

- **Owner:** LibKa0s — `testkit/mock_record.lua` (vendored here as `tests/_kit/mock_record.lua:241-268`).
- **Problem:** `db.CopyProfile` returns silently when the source is missing or current (`:259`
  `if not src or name == current then return end`), where AceDB-3.0 raises. `db.DeleteProfile`
  likewise returns silently on the current profile, where AceDB raises. `db.SetProfile` never
  strips defaults from the outgoing profile, which is the AceDB behaviour behind the 2026-09-16
  profile-switch crash (`modules/Anchor.lua:119-126`). This breaks the kit's own fidelity rule 5
  ("Model the awkward real behavior", `tests/_kit/mock_base.lua:26`).
- **Impact:** a host's `profile copy <typo>` crash (F-004) and stripped-default reads cannot be
  reproduced headlessly in any consumer.
- **Reachability:** test inventory only, collection-wide (capped at Medium).
- **Remediation:** **not a local edit.** Fix it in the LibKa0s repo's `testkit/`, bump the kit
  revision, then re-vendor the whole `tests/_kit/` folder into this addon and every other consumer,
  each as its own commit.

## Low

### F-009 — `docs/performance.md` figures are stale, and `settingsDrag` has grown ~50% unnoticed `[perf]`

- **Where:** the `docs/performance.md` scenario table (`castStartStop` 16.6 B, `settingsDrag` 596 B);
  `tests/perf.lua:245`/`:258`, whose comments read "castStartStop at 16.6" and
  `castStartStop = 41,   -- 16.6 measured + 24`.
- **Measured today:** `castStartStop` **5.4** B/iter (committed bundle `20260918-121606`: 3.6);
  `settingsDrag` **895.9** B/iter (bundle: 885.9; write-up: 596).
- **Impact:** the write-up no longer describes the code. The drag figure rose, most likely because
  `structureSignature` (`modules/Element.lua:168-176`) gained three marker fields, and it is
  deliberately unasserted.
- **Reachability:** documentation only.

### F-010 — The Slash degradation stub hand-copies the library's refusal format and re-implements its dispatcher `[design]`

- **Where:** `settings/Slash.lua:331`:
  `local DISABLED_LINE = "%s is disabled \226\128\148 enable it with |cFFFFFF00%s|r"`. This copies
  `libs/LibKa0s/Slash.lua:83` (`lib.DISABLED_LINE_FORMAT`). The rest of `OnSlash`/`PrintHelp` at
  `settings/Slash.lua:361-388` is also a copy.
- **Problem:** slash-commands-§1: "The stub **MUST NOT** re-implement the library's rendering … no
  copied `key = value` shape." The drift is pinned by `tests/test_surface_parity.lua:77-111`, so it
  is detected, but it is still a second copy of a collection-wide string.
- **Reachability:** only a library-absent install, which is not a shipping configuration.

### F-012 `[upstream]` — The test kit has no `EventRegistry` fake or recorder `[tests][upstream]`

- **Owner:** LibKa0s — `testkit/mock_base.lua` / `testkit/mock_record.lua`. `EventRegistry` appears
  nowhere under `tests/_kit/`.
- **Problem:** the `EditMode.Exit` branch (`modules/Providers.lua:342-345`) never executes headless,
  and no stand-down suite in the collection can count `EventRegistry` callback registrations (F-005).
- **Remediation:** **not a local edit.** Add an additive, recording `EventRegistry`
  (`RegisterCallback`/`UnregisterCallback`, counted in `__registrations()`) upstream, bump the kit
  revision, then re-vendor `tests/_kit/` whole.
- **Reachability:** test inventory only.

### F-013 — `.luacheckrc` whitelists 12 globals nothing uses, including the deliberately removed `UnitExists` `[lint]`

- **Where:** the `.luacheckrc:14-38` `read_globals`.
- **Census:** `GetTime`, `wipe`, `Mixin`, `UnitExists`, `UnitGUID`, `UnitIsUnit`,
  `UnitIsDeadOrGhost`, `UnitIsConnected`, `C_Secrets`, `RegisterUnitWatch`, `UnregisterUnitWatch`,
  `UnregisterStateDriver` have **0** bare-global uses.
  - Scope: the default scope (`git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'`, tests
    included), with comment lines excluded.
  - The remaining hits are `mocks.X` field accesses in `tests/`.
- **Impact:** a raw `UnitExists(compoundToken)` would lint clean. That is the secret-value hazard
  `core/Compat.lua:205-208` documents removing ("No UnitExists shim, on purpose").
- **Reachability:** developer lint only.

### F-014 — A dead locale key and two near-duplicate pairs `[locale]`

- **Dead key:** `locales/enUS.lua:150`,
  `"/pfe %s does nothing while the addon is off \226\128\148 /pfe enable turns it back on"`, has no
  reader. It is left over from the pre-library refusal. A scan of all 209 keys against the authored
  source, with `\ddd` escapes normalized, found this one unused key and no missing keys.
- **Near-duplicates:** `"All settings reset to defaults"` (`settings/Slash.lua:107`) vs `"… defaults."`
  (`settings/General.lua:200`), and the same split for "Cannot reset settings…".
- **Reachability:** a translator; one wording drift a player can see.

### F-015 — The migration runner migrates only the active profile but stamps the account-wide version `[design]`

- **Where:** `core/Database.lua:41-45`: `step.apply(NS.db.profile)` … `g.schemaVersion = step.to`.
- **Impact:** the first real ladder step would leave every non-active profile unmigrated forever,
  because the global stamp already says done.
- **Reachability:** nobody today, since `SCHEMA_STEPS` is empty (`:34`). It is a trap for the first
  schema change.

### F-016 — Movable named frames are not excluded from the client's layout cache `[design]`

- **Where:** `modules/Anchor.lua:232`/`:257-262` (the `PartyFrameEnhanced_<key>_Holder` frames, which
  are `SetMovable` and `StartMoving`), and `modules/StandIn.lua:152-160`.
- **Problem:** `StartMoving` marks a frame user-placed, and the client then persists the frame's
  position in `layout-local.txt` beside the addon's own stored `position`. After **Reset position**
  the two can disagree.
- **Reachability:** a player who drags a free-placement stack and later resets positions.
  **Unverified in client**; see smoke step S-008 (layout cache). The fix is `SetDontSavePosition(true)`.

### F-017 — Session-long registrations that ignore the per-feature discipline, and debug arguments evaluated with debug off `[perf]`

- **Where:**
  - `modules/TargetFrames.lua:320` (`PLAYER_TARGET_CHANGED`) and `:326`, plus
    `modules/PetFrames.lua:189` (`RAID_TARGET_UPDATE`), are registered at file load for every
    enabled session, including solo and feature-off.
  - `modules/Preview.lua:154` (`PLAYER_REGEN_DISABLED`) stays registered while not previewing.
  - `modules/TargetFrames.lua:205` and `modules/PetFrames.lua:83` call `UnitName(...)` just to build
    an `NS.Debug` argument on every `UNIT_TARGET`/`UNIT_PET`, even with debug off.
- **Impact:** negligible cost, but inconsistent with the `syncEvents` pattern the same files apply
  to unit events.
- **Reachability:** every enabled session; no user-visible effect.

### F-018 — The package ships three PNG screenshots the client cannot load `[packaging]`

- **Where:** `.pkgmeta` ignores `media/logos/*.png` but not `media/screenshots/*.png`. The files
  `partframeenhanced.screenshot.0{1,2,3}.png` are also misspelled ("partframe"). The README links
  CurseForge copies, not these files.
- **Reachability:** every download; dead weight only.
