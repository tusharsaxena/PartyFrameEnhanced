# Decisions: LibKa0s v1.54.2 -> v1.55.0

Step 6 of `revendor-libka0s`. **There was no interview.** The owner delegated the decision (the
suite sweep's CP-6) under fixed rules, and each decision below is that rule applied, written as it
landed:

1. **Adopt** each delta the design spec prescribes for this repo: one major per commit, the
   characterization test written and green before the code changes, the degraded (library-absent)
   case the spec requires, and the surface-source map updated where the spec says. The host's seam
   names stay, so call sites do not move.
2. **Decline as "not now"** (`state:triaged`) where the spec says the repo MAY defer, or where the
   adoption cannot land green without changing behavior a test pins or a player would see, after one
   honest attempt. **Decline as "never"** (`state:will-not-do`) only for a structural misfit the spec
   or the repo's own docs record.
3. Order: fixes a live defect, then closes a recorded gap, then new capability; smallest blast radius
   first.

A behavior change the spec itself prescribes and names (the Schema API document's *Adoption notes*,
the Bus document's *While down*) is part of the adoption, re-pinned in the adoption commit. Rule 2's
trigger is an **unplanned** change: one the spec does not name.

Declines are filed as public GitHub issues in this repo.

## Order

| # | Candidate | Class | Why this position |
|---|---|---|---|
| 1 | C1 `LibKa0s-Bus-1.0` | fixes a live defect | the hand-written record's `order` list grows on every re-register (`core/Bus.lua:62-66`) |
| 2 | C2 `LibKa0s-Compat-1.0` | closes a recorded gap | smallest blast radius (4 lines) |
| 3 | C3 `LibKa0s-Schema-1.0` | closes a recorded gap | largest blast radius |

## C1. `LibKa0s-Bus-1.0`: adopt

- **Rule:** 1. The spec prescribes it (`bus.md:549-560`) and names this repo the reference design.
  The spec gives no deferral clause for a record-half adopter.
- **Outcome:** adopted in `8a46028`. The two semantics that move (a registration made while down
  goes live at the stand-up; a stand-up is refused while the latch reads down) are the ones the Bus
  document names under *While down* and *The descriptor*, so they were re-pinned rather than treated
  as a decline trigger.

## C2. `LibKa0s-Compat-1.0`: adopt

- **Rule:** 1. The spec prescribes `IsSecret` only (`compat.md:537-540`); every other `NS.Compat`
  member is recorded as single-consumer and stays (`compat.md:280`).
- **Outcome:** adopted in `d64703f`.

## C3. `LibKa0s-Schema-1.0`: adopt (full adopter), one honest attempt

- **Rule:** 1. The spec prescribes a full adoption (`schema.md:507-518`). The MAY-defer clause
  (`schema.md` section 14, V-3) covers the partial adopters AuraMaster and MultiMeters only, not this
  repo.
- **Attempt:** made once and green on every existing suite and every new characterization case,
  with `tests/perf.lua` `resolveUnchanged` at 0.0 bytes/iter. It still changed behavior a player
  would see, and the spec does not name the change. On a load without LibKa0s the Master controls
  composer is hollow (`settings/OptionsSetup.lua:124`), so `enabled` and `locked` have no row. The
  Schema document's stub refuses a row-less path (`LibKa0s/docs/api/Schema/version-1-docs.md:308`).
  Under the attempt, `/pfe disable`, `/pfe enable` and `/pfe lock` stopped writing, against
  `settings/Slash.lua:147-150` and slash-commands-section-1. A new pin,
  `tests/test_schema.lua:209`, is green on the host seam and went red under the attempt
  (`expected false, got true`). No in-standard fix exists here: options-ui-section-1 bars
  hand-writing the composed rows back, architecture-section-5 bars a second write path, and a stub
  that stores row-less paths deviates from the prescribed stub shape.
- **Decision:** rule 2, **not now**. The code was rolled back to the Compat commit boundary. The
  characterization cases stayed as their own commit, `3720782`, because they are green host tests
  and hold the blocker's evidence. Filed as
  [#14](https://github.com/tusharsaxena/PartyFrameEnhanced/issues/14), `state:triaged`,
  `severity:medium` (a deferred duplication).
- **[upstream] finding:** the spec's JC-2 grep (`schema.md:255-261`) and the Schema document's stub
  cover only the live build. They leave open what a runtime-completing stub does with a path whose
  row a hollow composer did not emit. Every adopter whose host verbs write a composed Master
  controls row shares this.
