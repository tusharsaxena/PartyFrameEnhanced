Delta: LibKa0s v1.112.0 -> v1.113.0

Recorded with the re-vendor commit. Payload taken from the tag, never the sibling tree: `git -C ../LibKa0s archive v1.113.0 LibKa0s testkit tools` (tag commit cded10bb, a local tag, not yet on origin; expected for this run). Run under Ka0sAddonsCommonTasks `docs/2026-11-24-FEEDBACK_BATCH/R2_SMOKE_FEEDBACK.md`, item FB2-PFE-01 (the copy, provenance, icon-declaration and prune mechanics of `/dev-copilot:wow-revendor-libka0s`; the adoption interview and issue filing are skipped by the run's instructions, and the run's decisions D1-D3 pre-decide the audits).

## 3a Base
- `grep -n '[Bb]undles' CLAUDE.md` named v1.112.0 before the roll.
- Tags vendored since the newest bundle (`2026-11-24-v1.112.0`) without a bundle of their own: none.
- Library range: `git -C ../LibKa0s diff --stat v1.112.0 v1.113.0 -- LibKa0s testkit` (two files, no testkit change).

## 3b/3c Per-file minors that moved (old = this addon, new = v1.113.0)
```
Sim.lua                   old: MINOR 4              new: MINOR 5
WidgetsDropdown.lua       old: DROPDOWN_MINOR = 3   new: DROPDOWN_MINOR = 4
```
Kit revision: 60 -> 60 (no testkit change).

## Blockers
- None. This addon consumes neither surface that moved: it runs no sim (no `LibKa0s-Sim-1.0` call outside `tests/`, where the suites read `Sim.Sample`), and it builds no dropdown of its own (its settings dropdowns are the library's `Options` rows). No suite pins `Sim 4` or `WidgetsDropdown 3`.

## 3i Icons
- `LibKa0s icons:` line kept as written. Prune: the undeclared icons and the sound files (no `LibKa0s sounds:` line, so none).
