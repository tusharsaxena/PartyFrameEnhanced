Delta: LibKa0s v1.69.0 -> v1.70.0 (span: v1.69.0 v1.70.0)

# LibKa0s v1.69.0 and v1.70.0: the consolidated span (PartyFrameEnhanced)

Written 2026-10-07 by `RV-PF` (the v1.71.0 re-vendor of the 2026-10-07 review and standards audit
remediation), as the revendor-libka0s Step 3h back-fill. The 2026-10-07 standards audit found these two
tags vendored with no `docs/revendor/` bundle (`PFE-A-02`, the audit's PFE-26). Both were carried by
plain `chore:` re-vendor commits that bypassed `/dev-copilot:wow-revendor-libka0s`, so neither wrote a
bundle or synced the docs that restate the vendored version (`PFE-A-11`, repaired in `RV-PF`'s commit).
Nothing is decided here in retrospect.

## Base

The provenance line at the time was **v1.68.1**: `git show 547ac68^:CLAUDE.md` reads
`Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.68.1 (MIT).`, matching the newest
recorded bundle, `2026-10-04-v1.68.1` (`02b8254`, DC-REV-01, kit 36).

## The listing

```sh
horizon=$(ls -1 docs/revendor | sort | head -1 | cut -c1-10)     # 2026-09-23
# vendored: every tag the provenance line named at a payload commit or a CLAUDE.md roll since the horizon
v1.55.0 v1.56.0 v1.57.0 v1.58.0 v1.60.0 v1.61.0 v1.62.0 v1.63.0 v1.64.0 v1.65.0 v1.66.0 v1.67.0 v1.68.0 v1.68.1 v1.69.0 v1.70.0
# recorded: every tag a docs/revendor/ bundle names
grep -vxF -f recorded.txt vendored.txt
v1.69.0
v1.70.0
```

(The full script is revendor-libka0s Step 3h; the same listing is in
`docs/audits/2026-10-07/03_EVIDENCE.md`.)

## The carriers

| Tag | Library tag / commit | Carrier commit here | Non-payload files it touched |
|---|---|---|---|
| v1.69.0 | `aeea542` / `5949f4c` | `547ac68` 2026-10-06 `chore: re-vendor LibKa0s v1.69.0 (kit 37; adds the line chart widget)` | `CLAUDE.md` (provenance), `docs/testing.md:93` (kit 36 -> 37) |
| v1.70.0 | `26f441a` / `162a7fd` | `735a111` 2026-10-07 `chore: re-vendor LibKa0s v1.70.0` | `CLAUDE.md` (provenance) |

At each carrier the payload matched the library at the tag: `git archive <carrier> libs/LibKa0s
tests/_kit` against `git -C ../LibKa0s archive <tag> LibKa0s testkit`, `diff -rq` empty on both
payloads, re-checked on 2026-10-07 for this bundle.

## Per-file minors (LibStub), v1.68.1 -> v1.70.0

| File | v1.68.1 | v1.69.0 | v1.70.0 |
|---|---|---|---|
| `WidgetsLineChart.lua` (new, secondary of `LibKa0s-Widgets-1.0`) | absent | 1 | 2 (`opts.pxPerPoint`) |
| `WidgetsAutocomplete.lua` (new, secondary of `LibKa0s-Widgets-1.0`) | absent | absent | 1 |
| every other file (32) | — | unchanged | unchanged |

`LibKa0s.xml` gained one `<Script>` row per new file (+1 line at each tag); the payload went from 32 to
34 files, fifteen majors throughout. `Widgets.lua` stayed at minor 12, so the Widgets key moved 12.1.4
-> 12.1.4.1 -> 12.1.4.2.1. No `NEEDS_*` floor rose and no member was removed. This addon's TOC loads
the payload through `libs\LibKa0s\LibKa0s.xml` and `tests/run.lua` reads the same XML, so neither new
file owed a host row.

## Test kit

Revision 36 -> **37** at v1.69.0 (new `testkit/mock_lines.lua`: recording `Line` regions from
`CreateLine`, loaded by `mock_base.lua`; `README.md` and `framework.lua` follow). v1.70.0 left the kit
bytes unchanged at revision 37. No case was added or renamed in this addon's run, so
`docs/test-cases.md` and the README badge (454/455 under revision 37's counting) did not move.

## Consumption

Neither new file is consumed: this addon looks up twelve majors (Bus, Compat, Core, DebugLog, Env,
Launcher, Lifecycle, Media, Perf, Options, Schema, Slash) and draws no chart and hangs no autocomplete
list. `LibKa0s-Widgets-1.0` reaches it only through DebugLog's own console. No consumed major moved a
minor across the span, so no contract change applied.
