# 02 — Candidates (PartyFrameEnhanced)

Sources: `git -C ../LibKa0s log --oneline v1.70.0..v1.71.0`, the LibKa0s `CHANGELOG.md` v1.71.0 block
("What a consumer owes"), and at the tag `docs/api/Env/version-2-docs.md`,
`docs/api/Options/version-28.2.34.2.4.8.1.7.4.2-docs.md`, `docs/api/Slash/version-20.2-docs.md`,
`docs/api/Widgets/version-12.1.4.3.2-docs.md` and `docs/api/testkit/version-38-docs.md`.

- **Class A (delivered on the copy):** Env 2's dead-rung removal, OptionsIdList 4's guard, Slash 20.2's
  refusal of non-finite numbers on `/pfe set`, and kit 38's `--list` Totals (applied: `docs/test-cases.md`
  regenerated, badge 454/454). Nothing further for the host to do.
- **Class B (host change), not adopted in this run:**
  - `Kit.secret` and its siblings (kit 38, `testkit/secrets.lua`): a shared secret-value simulator. This
    addon's suites have no local simulator to replace; the library names only WhatGroup as an adopter.
- **Class C (whole module), not adopted in this run:**
  - `lib.LineChart` / `lib.ChartMath` (WidgetsLineChart, arrived v1.69.0, now minor 3): this addon draws
    no chart.
  - `lib.Autocomplete` (WidgetsAutocomplete, arrived v1.70.0, now minor 2): this addon has no search box.

Under the owner's ruling for this run (`OWNER_SCOPE.md` §5), candidates the plan does not already
require are listed here as not adopted, with no interview and no issue.
