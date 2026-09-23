# 03 — Evidence

Every citation below was re-read at `314c95e` before it was written, and the cited text is quoted
beside it. Every count gives its command and its scope. Commands ran from the repo root. Runs that
could be long went through `~/.claude/wow-addon/bin/ka0s-bounded`, called by full path because
`ka0s-bounded` is not on `PATH` in this shell.

**Default census scope** (`layout-§1`'s denominator): `git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'`,
which is **71 files, 11,230 lines**. `tests/` is included. `libs/` and `tests/_kit/` are excluded as
vendored. No generated data is tracked. A different scope is named where one is used.

## 0. Standard resolution

```
curl -fsSL $RAW/AUDIT.md                 -> 990 lines
curl -fsSL $RAW/standards/STANDARDS.md   -> 242 lines, "# Ka0s WoW Addon Standard (v2.64.0, 2026-09-23)"
curl -fsSL $RAW/standards/ADDONS.md      -> 79 lines
27 section files, discovered from the Sections list, 6027 lines in total; no fetch failed
```

## 1. Lint and tests

```
$ ~/.claude/wow-addon/bin/ka0s-bounded luacheck .        (exit 0)
Total: 0 warnings / 0 errors in 71 files
$ ~/.claude/wow-addon/bin/ka0s-bounded lua tests/run.lua (exit 0)
289 passed, 0 failed, 0 skipped, 289 total
```

Lint scope, `.luacheckrc:8`: `exclude_files = { "libs/", "docs/audits/", "docs/reviews/", "_dev/", "tests/_kit/" }`.
This is the `lint` template's list. `docs/revendor/` holds no Lua. The harness global appears only in
`files["tests/"]` (`.luacheckrc:48-53`). There is no top-level `ignore`; the narrowed `212/self`
stanzas each name their file (`:59-78`).

## 2. Vendored Ka0s library (`library-stack-§7`, anti-patterns #45/#48)

The provenance tag was read first:

```
$ grep -n 'Bundles \[LibKa0s\]' CLAUDE.md README.md
CLAUDE.md:38:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.55.0 (MIT).
```

The sibling `../LibKa0s` is at HEAD `46ccaa6`, while the tag `v1.55.0` is `bb161b7`. The diff ran
against the **tag**, extracted with `git -C ../LibKa0s archive v1.55.0 LibKa0s testkit`:

```
$ diff -r <v1.55.0>/LibKa0s libs/LibKa0s   -> exit 0, 0 lines
$ diff -r <v1.55.0>/testkit tests/_kit     -> exit 0, 0 lines
files: tag 146, libs/LibKa0s on disk 146, git ls-files libs/LibKa0s 146
```

`tests/_kit/framework.lua:20`: `Kit.VERSION = 25`.

## 3. README and CLAUDE.md checks

```
$ grep -nE '^## (Libraries|Bundled libraries|Libraries and credits|Credits and libraries|Credits and bundled libraries)' README.md   -> (none)
$ grep -n 'WoW_Addon_Standard' README.md
6:![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)     <- bare, compliant
$ grep -nE '!\[[^]]*\]\(media/logos|<img' README.md                               -> (none)
```

- `CLAUDE.md:33`: `- **`docs/superpowers/plans/`** — the v0.1.0 build plan; its status ledger is the resume point.` (PFE-01)

## 4. Disabled state (`slash-commands-§7`)

Registration census (scope: default, `tests/` included; the addon's own hits are listed first):

```
$ git ls-files '*.lua' ':!libs' ':!tests/_kit' | xargs grep -nE 'Register(Unit)?Event|RegisterMessage|RegisterBucketEvent'
core/PartyFrameEnhanced.lua:116:    regenWatch:RegisterEvent("PLAYER_REGEN_ENABLED")
core/PartyFrameEnhanced.lua:140:    for event, method in pairs(LIFECYCLE_EVENTS) do self:RegisterEvent(event, method) end
modules/Anchor.lua:358-360     ev:RegisterMessage(LAYOUT / PROFILE / CONFIG)
modules/CastBars.lua:336:                for i = 1, #EVENTS do el:RegisterUnitEvent(EVENTS[i], unit) end
modules/CastBars.lua:395,406,414,419   ev:RegisterMessage(CONFIG / PROFILE / VISIBILITY / LAYOUT)
modules/PetFrames.lua:103-107  btn:RegisterUnitEvent(UNIT_PET / UNIT_NAME_UPDATE / UNIT_HEALTH / UNIT_MAXHEALTH)
modules/PetFrames.lua:169,177,182,186  ev:RegisterMessage(...);  :189 ev:RegisterEvent("RAID_TARGET_UPDATE", ...)
modules/Preview.lua:81  ev:RegisterEvent("GROUP_ROSTER_UPDATE", applyStandIn);  :154 PLAYER_REGEN_DISABLED;  :161,:170 RegisterMessage
modules/Providers.lua:330-334  ev:RegisterEvent(GROUP_ROSTER_UPDATE / PLAYER_ENTERING_WORLD / EDIT_MODE_LAYOUTS_UPDATED / PLAYER_REGEN_ENABLED / ADDON_LOADED)
modules/Providers.lua:362,365  ev:RegisterMessage(CONFIG / PROFILE)
modules/RangeFade.lua:168  ev:RegisterEvent("UNIT_IN_RANGE_UPDATE", onRange);  :215-218 RegisterMessage x4
modules/TargetFrames.lua:214  btn:RegisterUnitEvent("UNIT_TARGET", unit);  :288,296,301,305 RegisterMessage;  :320,:326 RegisterEvent
(tests/*.lua hits are the suites' own targets and are not addon registrations)
```

Undo census (scope: default, minus `tests/`):

```
core/PartyFrameEnhanced.lua:112/120  regenWatch UnregisterAllEvents;  :152 addon:UnregisterEvent per lifecycle event
modules/CastBars.lua:137 SetScript("OnUpdate", nil);  :343 el:UnregisterAllEvents()
modules/PetFrames.lua:101 btn:UnregisterAllEvents();  modules/TargetFrames.lua:161 CancelTimer, :218 UnregisterAllEvents
modules/Providers.lua:352 ev:UnregisterAllEvents();  modules/RangeFade.lua:170,190;  modules/Preview.lua:83
+ every NS.NewBusTarget() target taken down by NS.BusStandDown() (core/Bus.lua:78, LibKa0s-Bus-1.0's record)
```

Other kinds of registration (scope: default, minus `tests/`):

```
$ git ls-files '*.lua' ':!libs' ':!tests' | xargs grep -nE 'C_Timer|ScheduleTimer|ScheduleRepeatingTimer|NewTicker|OnUpdate|HookScript|hooksecurefunc|RegisterCallback'
core/Database.lua:14-16        NS.db.RegisterCallback(OnProfileChanged/Copied/Reset)        <- survives by rule (setup)
modules/Providers.lua:56,65,66 C_Timer.After(...)
modules/Providers.lua:78-80    frame:HookScript(OnShow/OnHide/OnAttributeChanged)           <- one-way; body gates on `suspended` (:54)
modules/Providers.lua:86       hooksecurefunc(owner, method, Providers.Request)            <- one-way; gated
modules/Providers.lua:343      pcall(EventRegistry.RegisterCallback, EventRegistry, "EditMode.Exit", burst, Providers)   <- PFE-12
modules/RangeFade.lua:106,108  hooksecurefunc(SetAlpha / SetAlphaFromBoolean)             <- one-way; gated by active()
modules/TargetFrames.lua:166   ScheduleRepeatingTimer; :252-253 HookScript                  <- ticker cancelled on Suspend (:157-169)
```

**PFE-12.** `modules/Providers.lua:342-343`:
`if EventRegistry and type(EventRegistry.RegisterCallback) == "function" then` /
`pcall(EventRegistry.RegisterCallback, EventRegistry, "EditMode.Exit", burst, Providers)`.
`Providers:Suspend` at `:348-353` is `suspended = true` … `ev:UnregisterAllEvents()`, with nothing for
the callback. `burst()` at `:61-67` does `Providers.Request()` (which returns early while suspended,
`:54`), then `burstGen = burstGen + 1`, then two `C_Timer.After(...)` calls at `:65` and `:66`.
`Providers:Resume` (`:355-359`) does not re-register the callback, which is consistent with it never
having been removed.

**PFE-12a.** `grep -n 'EventRegistry' tests/_kit/mock_base.lua tests/wow_mock.lua` returns nothing. The
guard at `:342` is false in the harness, so the callback is never registered there, and
`tests/test_disabled.lua:95-97` (`assertEqual(#after, 0, …)`) cannot see it.

**PFE-12b.** `docs/ARCHITECTURE.md:165`: `**Every registration in this table except the last comes off while the addon is stood down**`.
The table (`:151-163`) has no `EditMode.Exit` row.

**PFE-13.** `modules/RangeFade.lua:55`: `f = CreateFrame("Frame", "PartyFrameEnhanced_Fade_" .. unit, UIParent)`,
and `:11`: `-- The fade frames are plain, never moved, never hidden, …`. `modules/Anchor.lua:232`:
`local holder = CreateFrame("Frame", "PartyFrameEnhanced_" .. spec.key .. "_Holder", UIParent)`.
No `:Hide()` for either appears on any path. `tests/_kit/mock_base.lua:121`:
`local f = { __shown = false, __scripts = {} }`, so a mock frame starts hidden, while a client frame
starts shown.

The stand-down is not a draw gate, and here is the evidence. `core/PartyFrameEnhanced.lua:151-160`
(`NS.StandDown`) unregisters, suspends, publishes, and takes down the bus. `core/LifecycleSetup.lua:90-92`
routes `enabled` into the latch. `tests/test_disabled.lua` asserts on `mocks.__registrations()`
(`:35-40`, `:95-97`).

The launcher while disabled: `settings/Slash.lua:136`:
`if NS.GetSetting("enabled") ~= true then return print(cli:DisabledLine()) end`, pinned by
`tests/test_disabled.lua:279-289`.

**PFE-17.** `modules/Preview.lua:40`:
`local REFUSED_DISABLED  = "|cff808080" .. L["cannot unlock \226\128\148 the addon is disabled"] .. "|r"`.
`:110`: `elseif NS.GetSetting("enabled") ~= true then why = REFUSED_DISABLED`. `:114`: `NS.Print(why)`.
It is reached through `settings/General.lua:115-117`:
`row.validate = function(v) return not NS.AcceptLock or NS.AcceptLock(v) end`.

## 5. Event registration isolation (`events-frames-taint-§1`) — PFE-14

```
core/PartyFrameEnhanced.lua:140:  for event, method in pairs(LIFECYCLE_EVENTS) do self:RegisterEvent(event, method) end
modules/CastBars.lua:336:         for i = 1, #EVENTS do el:RegisterUnitEvent(EVENTS[i], unit) end
$ git ls-files '*.lua' ':!libs' ':!tests' | xargs grep -n 'IsEventValid'      -> (none)
```

No `pcall` wraps any `RegisterEvent` or `RegisterUnitEvent` in the addon's own code. The only
`pcall`ed registration is `EventRegistry.RegisterCallback` (`modules/Providers.lua:343`), and it
records nothing. The Bus record replays through `pcall` on stand-up and names rejects
(`core/Bus.lua:82-87`), but that covers the replay, not the first registration.

## 6. The deviation register (`audit-review-history`) — PFE-10

`docs/ARCHITECTURE.md:352` begins: `` | `events-frames-taint-§1` | `UNIT_SPELLCAST_*`, `UNIT_TARGET` and the pet unit events are registered with `RegisterUnitEvent` on each element's own frame, not through AceEvent | … | 2026-09-15 | AceEvent or LibKa0s gains a unit-filtered registration | ``

- Rule change: the v2.63.0 changelog (`STANDARDS.md:100`), item (5): *"Three repos deviated
  (AbsorbTracker, KickCD, LootHistory), PartyFrameEnhanced's row turned out not to be a violation at
  all"*.
- Trigger: `grep -rln 'RegisterUnitEvent' libs/` matches only `libs/LibKa0s/Lifecycle.lua`, at a
  comment (`:83`). Nothing offers a unit-filtered registration, so the trigger has not fired.
- Evidence ids: the row cites none.

Issue store:

```
$ gh issue list --state all --limit 200 --json number,title,state,labels,url
14 issues, #1-#14, all with state: + severity: labels, no [status] title prefixes
#1 CLOSED state:will-not-do "Support raid frames" (scope, docs/scope.md:20-21)
#2-#12, #14 OPEN state:triaged;  #13 OPEN state:untriaged
$ ls docs/pending    -> No such file or directory
```

## 7. Line endings (`line-endings`)

`.gitattributes` is itself checked out CRLF, so the `$`-anchored greps were run over `tr -d '\r'`:

```
(a) present
(b) 26:* text=auto eol=crlf
(c) 36:*.sh text eol=lf   37:*.py text eol=lf
(d) 20 lines ending ' binary'
body: tr -d '\r' < .gitattributes | head -84 | diff - <canonical client-bound body, line-endings.md:166-249>   -> BODY-IDENTICAL; tail after 84 = 0 lines
(e) AUDIT.md's pipeline, verbatim (scope: all 415 tracked files, nothing excluded)  -> 0
```

`tests/_kit/test_eol.lua` is wired (`tests/run.lua:86`) and green.

## 8. Packaging (`packaging`) — PFE-21

Run under `bash`, because zsh does not word-split `$entries`:

```
(a) (nothing printed)
(b) UNACCOUNTED — .git            <- .git needs no row by rule
(c) FALSE CLAIM — .claude ignored, no such directory
    FALSE CLAIM — .superpowers ignored, no such directory
```

`.pkgmeta:12`: `  - .claude          # dev-only: agent tooling; never loaded by the client`.
`.pkgmeta:13`: `  - .superpowers     # dev-only: agent tooling; never loaded by the client`.
`ls -a` of the root shows neither directory.

## 9. Complexity (`performance-§10`, `automated-tests`) — PFE-09

```
$ ~/.claude/wow-addon/bin/ka0s-bounded lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .   (exit 0)
No thresholds exceeded (cyclomatic_complexity > 15 or length > 1000 or nloc > 1000000 or parameter_count > 100)
Total nloc 8045  Avg.NLOC 6.3  AvgCCN 2.2  Avg.token 47.2  Fun Cnt 1047  Warning cnt 0
top CCN: 14 NS.SetByPath@198-220@./settings/Schema.lua;  14 NS.ResolveColor@36-45@./core/CoreSetup.lua;  12 ellesmereConfiguredSize@292-302@./modules/Providers.lua
```

The latest bundle's `complexity.txt` (`docs/automated-tests/20260918-121606/`) reads
`Total nloc 7378 … Fun Cnt 942  Warning cnt 0`. Its `manifest.json` reads
`"git": { "sha": "e4d7f41f…", "dirty": false }` and `"release": "1.0.1"`.
`git rev-list --count e4d7f41..HEAD` returns `32`. The `RESULTS.md` watch list is "None." and has no
`Accepted` entries (`grep -c Accepted` returns 0). The top two CCN 14 functions are dense guarding and
defaulting: the seam's validate/bulk/debug/row branches, and the degraded resolver's `or`-defaults.
Neither is tangled control flow.

## 10. Mechanical greps (all compliant unless noted)

```
bus literals at call sites   grep -rnE '(Send|Register)Message\("Ka0s_' … | grep -v libs,_kit     -> (none)
bus wire strings             core/Bus.lua:93-96 "Ka0s_PartyFrameEnhanced_{LayoutChanged,ConfigChanged,VisibilityChanged,ProfileChanged}"  PascalCase
close button                 core/CoreSetup.lua:87 return lib.MakeCloseButton(parent, onClick, addonName)   (the one wrapper; no callers)
settings window in combat    grep -rnE 'SettingsPanel|HideUIPanel|ToggleGameMenu|OpenToCategory' … minus libs,_kit   -> (none in addon code)
SetMovable sweep             modules/Anchor.lua:257, modules/StandIn.lua:153       (positionable -> Test mode governed by the Lock-frame exemption)
reorder arrows               grep ScrollUp-Up|ScrollDown-Up settings/            -> (none)
disabledIf                   11 hits in settings/, none on a color row
compat shims                 grep -cE '^\s*function\s+[A-Za-z_][A-Za-z0-9_]*\.' core/Compat.lua   -> 14   (docs/ARCHITECTURE.md:324 says "15", PFE-01)
TOC addon lines              tr -d '\r' < PartyFrameEnhanced.toc | grep -vE '^(#|$)' | grep -vc '^libs'   -> 38
IconTexture file             media/logos/partyframeenhanced.logo.128.tga: type=2 w=128 h=128 bpp=32
re-vendor bundles            store horizon 2026-09-23; in-scope re-vendor commit e331135 (2026-09-23 14:53 +0530) vendors v1.55.0;
                             recorded: docs/revendor/2026-09-23-v1.55.0 -> v1.55.0. Unrecorded: none.
retired notation             grep -rEn '§[0-9]+\.[0-9]' . --exclude-dir={libs,_kit,audits,reviews,automated-tests,revendor,.git} | wc -l   -> 18
                             (every hit cites the addon's design spec; none cites the standard)
citation range check         271 filename-§N citations in the tracked non-frozen .lua/.md/config set; 0 out of range, 0 malformed
                             (a first pass flagged 11 "malformed", but each was a valid citation followed by a colon, e.g. `options-ui-§1:`)
```

Note on the re-vendor check: AUDIT.md's `git log --since="$horizon"` passes a bare date, and git reads a
bare date with the **current time of day**. Run at 20:00 it skipped `e331135`, committed at 14:53 the
same day. The result above comes from reading the commit directly. This is a playbook quirk worth
fixing upstream (`--since="$horizon 00:00"`). It is not a finding against the addon.

## 11. Per-finding citations (re-read, quoted)

| ID | Citation | Text at the line |
|---|---|---|
| PFE-15 | `modules/Providers.lua:292-293` | `local function ellesmereConfiguredSize()` / `local db = EllesmereUIDB` |
| PFE-15a | `docs/scope.md:24-26` | `It never hides, reparents, moves or calls into a / Blizzard or EllesmereUI frame; it only reads their position and unit, and only through / hooksecurefunc / HookScript.` |
| PFE-15a | `docs/ARCHITECTURE.md:248-249` | `…change detection is hooksecurefunc and HookScript only.` |
| PFE-16 | `PartyFrameEnhanced.toc:57-59` | `# LOAD-BEARING: publishes NS.Perf before any module takes …` / `core\LifecycleSetup.lua` / `core\PerfSetup.lua` |
| PFE-16 | `core/PerfSetup.lua:56` | `lifecycle = NS.lifecycle,` |
| PFE-16 | `libs/LibKa0s/Perf.lua:342` | `required(d, "lifecycle", "table")` |
| PFE-16 | `core/LifecycleSetup.lua:13` | `-- LOAD-BEARING POSITION: core/PerfSetup.lua REQUIRES descriptor.lifecycle and loads immediately` |
| PFE-16 | `tests/test_loadorder.lua` | cases at `:41,:48,:55,:65,:79,:92`; none names LifecycleSetup |
| PFE-18 | `locales/enUS.lua:31` | `"General", "Position", "Placement", …` |
| PFE-18 | `locales/enUS.lua:150` | `"/pfe %s does nothing while the addon is off \226\128\148 /pfe enable turns it back on",` |
| PFE-18 | method | load `enUS.lua` in Lua 5.1, list 209 keys, search for each key as a Lua string literal in `git ls-files '*.lua' ':!libs' ':!tests' ':!locales'`; 2 have no reader |
| PFE-05 | `modules/Providers.lua:96,119,138` | `label = "EllesmereUI"`, `label = "Blizzard (raid-style)"`, `label = "Blizzard (classic)"` |
| PFE-05 | `settings/Slash.lua:196` | `print(L["Frame system: %s"]:format(NS.Providers.ActiveLabel() or L["none found"]))` |
| PFE-05 | `core/DebugLogSetup.lua:40` / `:54` | `NS.Print("debug logging " .. …)` / `label   = "Debug console",` |
| PFE-19 | `modules/Preview.lua:161` / `:170` | `ev:RegisterMessage(NS.MSG.CONFIG, …)` / `ev:RegisterMessage(NS.MSG.PROFILE, …)` |
| PFE-19 | `docs/ARCHITECTURE.md:107` / `:109` | CONFIG and PROFILE rows; neither *Consumers* cell names Preview |
| PFE-01 | `docs/ARCHITECTURE.md:5-6` | `and the build's progress is the ledger in / [superpowers/plans/2026-09-15-party-frame-enhanced-v0.1.0.md]` |
| PFE-01 | `docs/module-map.md:17` | `` `core/State.lua` \| session state: `debug`, `inCombat`, `preview`, `inParty`, `test` `` (the file has no `test`: `core/State.lua:14-17`) |
| PFE-01 | `docs/compat-layer.md:16`, `:22` | blank lines inside the table; rows `:17-21`, `:23-27` follow with no header |
| PFE-01 | `docs/compat-layer.md:4` | `Feature modules call NS.Compat.X, never the raw` |
| PFE-01 | `modules/CastBars.lua:216` | `if not UnitCastingInfo(el.unit) and not UnitChannelInfo(el.unit) then` |
| PFE-01 | `docs/ARCHITECTURE.md:140` | `…The ruling narrows the *slash* surface and a mouse click is not a slash command…` |
| PFE-01 | `defaults/Profile.lua:4` | `-- Feature sections (castbar, target, pet) are added by the phase that builds each feature.` |
| PFE-20 | bootstrap census | `for f in $(git ls-files 'core/*.lua' 'defaults/*.lua' 'settings/*.lua' 'locales/*.lua' 'modules/*.lua')` → first `local …, NS = ...` line: 28 at line 1, 10 later (listed in 02) |
| PFE-20a | header census | `head -5 "$f" \| grep -F -- "-- $f"`: 35 with a header, 3 without (`core/Constants.lua`, `core/Namespace.lua`, `core/State.lua`) |
| PFE-22 | `core/Database.lua:43` | `step.apply(NS.db.profile)` (the stamp is `g.schemaVersion`, `:40,:45`) |
| PFE-23 | `settings/Slash.lua:327` / `:331` | `SlashLib = { FormatRow = function(cmd, desc) return cmd .. " \226\128\148 " .. desc end }` / `local DISABLED_LINE = "%s is disabled \226\128\148 enable it with |cFFFFFF00%s|r"` |
| PFE-24 | `core/Constants.lua:17` | `C.LOGO_PATH = "Interface\\AddOns\\PartyFrameEnhanced\\media\\logos\\partyframeenhanced.logo.tga"` |

## 12. Compliance evidence for the shared subsystems (descriptors, not library source)

| Module | Descriptor / lookup | Degraded arm |
|---|---|---|
| Core | `core/CoreSetup.lua:15` `LibStub("LibKa0s-Core-1.0", true)`; `:91` `lib:New({ prefix = … })` | `:17-69` |
| DebugLog | `core/DebugLogSetup.lua:11`; `:65-97` (`name`, `addonName`, `title`, `font`, `slash`, `isEnabled`/`setEnabled`) | `:13-63` |
| Perf | `core/PerfSetup.lua:10`; `:25-75` (buckets, `lifecycle = NS.lifecycle`, no `decorate`) | `:11-23` |
| Lifecycle | `core/LifecycleSetup.lua:17-25` | `:26-76` (hold set modeled) |
| Options | `settings/OptionsSetup.lua:267-330`, `:400` `lib:New(descriptor)` | `:342-391` (load-completing) |
| Slash | `settings/Slash.lua:16`, `:393-424` | `:325-391` |
| Bus | `core/Bus.lua:40`, `:72` `Bus:New({ name = addonName, isDown = … })` | `:42-65` (untracked-target stub) |
| Compat | `core/Compat.lua:13`, `:20` | `:20-23` (guard arm) |
| Media | `core/MediaSetup.lua:16`, `:34` `Media.RegisterLSM(addonName)` | `:22,:28` answer nil |
| Env | `core/EnvSetup.lua:10` | `:15-21` |
| Launcher | `core/LauncherSetup.lua:36-76` | none, reason at `:27-34` |

Stub parity for Core, DebugLog, Bus, Options and Slash is `tests/test_surface_parity.lua:11-77`. Perf is
`tests/test_perfsetup.lua:44,66`. Env is `tests/test_envsetup.lua` (degraded case).
