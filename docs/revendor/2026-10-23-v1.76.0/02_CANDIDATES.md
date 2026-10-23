# 02 — Candidates (PartyFrameEnhanced)

Sources: `git -C ../LibKa0s log --oneline v1.75.2..v1.76.0`, the LibKa0s `CHANGELOG.md` block v1.76.0
and its *What a consumer owes* list, and the API documents at the tag for the two majors whose minor
moved: `docs/api/Widgets/version-14.1.4.3.2-docs.md` and `docs/api/Sim/version-2.3.5-docs.md`.

The run's item spec lists the candidates and forbids adopting or interviewing here: the run's own
items do the adoptions, and none is planned for PartyFrameEnhanced. Every candidate below is recorded
as not adopted in this run, with no interview and no GitHub issue.

- **Class A (delivered with the copy):** nothing this host reaches. Widgets 14 leaves every existing
  call unchanged (the amber strip is the default kind), and the DebugLog console and copy window draw
  no strip.
- **Class B (needs a host change), not adopted:**
  - `W.TestStrip(parent, { kind = "sim" })` and `strip.kind` (Widgets 14, v1.76.0; the CHANGELOG's
    *Widgets minor 14* block): this addon has no test mode and no simulator, so it draws no strip of
    either kind.
- **Class C (whole module), not adopted:**
  - `LibKa0s-Sim-1.0` auto-run (SimTimeline 3, SimPanel 5, v1.76.0): settled. Ruled out in
    LibKa0s#54 (recorded in `2026-10-22-v1.75.0/02_CANDIDATES.md`): the addon draws on secure unit
    frames, which cannot show made-up units, so a simulator has nothing to drive. v1.76.0 changes how
    a session plays, not that premise.
