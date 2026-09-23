# Execution plan: LibKa0s v1.55.0 adoption

Step 7 of `revendor-libka0s`, written before any code moved. One commit per candidate. Each commit
is gated on `ka0s-bounded lua tests/run.lua` and `ka0s-bounded luacheck .` (0/0). A candidate whose
suites go red is rolled back to its own commit boundary and does not block the next one.

## 1. `LibKa0s-Bus-1.0`

**Files:** `core/Bus.lua`, `tests/test_bus.lua`, `tests/test_surface_parity.lua`, `tests/run.lua`,
`docs/ARCHITECTURE.md`.

**Characterization, written and green on the hand-written record first** (`tests/test_bus.lua`):

- a stand-down takes a receiver's events AND messages down (the kit's `__events` recorder is empty,
  a sent message reaches no handler), and a stand-up puts both back (the event is recorded again,
  the message reaches its handler exactly once);
- a stand-up replays the record as it is NOW: a message unregistered while down stays unregistered;
- a method-name handler survives the round trip and is called as `t[method](t, message, ...)`.

Every probe empties itself afterwards (Bus API document, Known limitation 3).

**The change:** `Bus:New{ name = addonName, isDown = NS.IsStoodDown at call time }` and the three
delegates under the same names; `NS.MSG = Bus.Catalog(addonName, {...})`; `StandUp`'s `rejected`
list logged through `NS.Debug`; the untracked-target stub (Bus API document, *Worked example*) when
the major is absent. The publisher `NS.bus` stays host code.

**Assertions that prove the change** (added with it):

- re-registering a key after forgetting it does not grow the record: the entry count `BusStandDown`
  answers moves by exactly one for one new key, however often it was toggled (red on the hand-written
  record, which answers nothing and appended every time);
- a registration made while the addon is stood down is recorded and not live until the stand-up
  (through the write seam: `enabled = false`, register, `enabled = true`);
- `NS.MSG` is strict: an undeclared key raises;
- degraded: `Kit.assertSurfaceParity(stub, "LibKa0s-Bus-1.0")`; the stub's targets deliver a message;
  its `StandDown` answers 0 and leaves the registration live (the stated limitation); `NS.MSG` holds
  the same four names.

**Runner:** `["LibKa0s-Bus-1.0"] = mocks.LibStub("LibKa0s-Bus-1.0", true)` in the surface-source map.

**Docs:** `docs/ARCHITECTURE.md` Message Bus names the major; Known Limitations gains the degraded
build's untracked receivers.

## 2. `LibKa0s-Compat-1.0`

**Files:** `core/Compat.lua`, `tests/test_compat.lua`, `tests/run.lua`, `docs/ARCHITECTURE.md`.

**Characterization first:** `Compat.IsSecret` answers exactly `true` for the fixture's secret and
exactly `false` for a plain value, nil, and with `issecretvalue` absent (return arity 1, type
boolean); `FrameVisible`/`FrameUnit` keep answering through it.

**The change:** `Compat.IsSecret = CompatLib and CompatLib.IsSecret or <guard stub>`, the stub the
one-rung body with the duplication comment naming the Compat API document's *Degradation*.

**Assertions:** the degraded load's `IsSecret` answers what the library answers under the same
`issecretvalue` fixture; `Kit.assertSurfaceParity(NS.Compat, "LibKa0s-Compat-1.0", notWired)` with
the eight members this repo does not wire.

**Runner:** `["LibKa0s-Compat-1.0"]` row in the surface-source map.

## 3. `LibKa0s-Schema-1.0` (full adopter, one honest attempt)

**Files:** `settings/Schema.lua`, `settings/General.lua`, `settings/OptionsSetup.lua`,
`settings/Slash.lua`, `tests/test_schema.lua`, `tests/test_surface_parity.lua`, `tests/run.lua`,
`docs/ARCHITECTURE.md`, `docs/schema.md`.

**Characterization first** (`tests/test_schema.lua`, green on the host seam):

- a write runs store, `[Set]` line, `onChange`, CONFIG publish, in that order, once each;
- a `validate` refusal stores nothing, calls nothing and publishes nothing;
- the Minimap button row reads and writes `db.global.minimap.hide` inverted, a page's *Defaults*
  sweep leaves it alone, and `/pfe reset global.minimap.hide` resets it;
- a bulk sweep emits one `[Set] <act> <scope>: N rows` line counting only rows that moved;
- the counted profile reset excludes the global row;
- `GetSetting` falls back to `defaults.profile` before the db opens.

**The change:** the spec's delta (`schema.md:507-518`) with the host's public names bound to
instance members, and a runtime-completing stub (Schema API document, *The degradation stub*).

**Behavior deltas pinned in the commit** (Schema API document, *Adoption notes*): unknown path
refused; a table value is copied into the store; the `"%s refused"` line is gone; `SetByPath`
answers `false, err` on refusal.

**Perf:** `ka0s-bounded lua tests/perf.lua` keeps `resolveUnchanged` at 0 bytes/iter.

**Decline trigger:** a red the spec does not name, after one attempt. Then the candidate is rolled
back to the Compat commit and filed as `state:triaged`.
