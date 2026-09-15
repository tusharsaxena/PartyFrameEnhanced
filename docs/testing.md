# Testing

How to verify Ka0s Party Frame Enhanced. The two automated gates must be green **before every
commit** and before tagging a release; the in-game smoke tests run before a release, after bumping
`## Interface:`, and after refreshing vendored libraries. Conforms to the standard's `testing`
section.

What to install is [`../DEPENDENCIES.md`](../DEPENDENCIES.md); this page is how to verify.

## The green gate (every commit)

| Check | Command | Expected |
|---|---|---|
| Unit tests | `lua tests/run.lua` | every suite green (non-zero exit on any failure) |
| Lint | `luacheck .` | `0 warnings / 0 errors` |
| Syntax-check one file | `luac5.1 -p <path/to/file.lua>` | no output |
| In-game smoke tests | manual | [smoke-tests.md](./smoke-tests.md) |

`.luacheckrc` carries **no top-level `ignore`**. Nine `files[...]` stanzas each name one file and one
code (`212/self`) for receivers a calling convention forces on a body that does not read them —
`core/PartyFrameEnhanced.lua` (AceAddon/AceEvent handlers), `core/Database.lua` (`NS:InitDB`,
`NS:RunMigrations`), `settings/Slash.lua` (the degraded `SlashLib:New` and the `Sl:` methods), and the
six modules whose lifecycle hooks are colon methods (`modules/Providers.lua`, `CastBars.lua`,
`TargetFrames.lua`, `PetFrames.lua`, `Preview.lua`, `TestMode.lua`). The reason for each sits above it in
`.luacheckrc`.

## What the suite covers

The harness is the vendored LibKa0s testkit under `tests/_kit/` (never edited here). `tests/run.lua`
holds only this addon's load list — the library half derived from `libs/LibKa0s/LibKa0s.xml`, the
addon half from `PartyFrameEnhanced.toc` — the lifecycle kick (`NS:InitDB()`, then
`NS.addon:OnEnable()`, which enables every module and registers the settings panel) and the suite list.
`tests/wow_mock.lua` is a thin extender over the kit's base mock.

The suites test what is **this addon's**: each setup file's descriptor and degradation stub, the
schema and its write seam, the slash table, the lifecycle and the secure-write queue, the providers,
the anchor engine, the three features, preview mode, perf-bucket coverage and the spelling gate. The
library's own internals are tested in the LibKa0s repo and not again here (testing-§8).

`tests/test_spelling.lua` is the US-English prose gate (localization-§5): it copies the standard's
published `BRITISH` and `ALLOWED` lists **whole** and scans every authored `.lua`, `.md` and `.toc`
the repo tracks, skipping only `libs/`, `tests/_kit/` and the frozen evidence bundles. A British form
the lists miss is added upstream in the standard first, never locally.

The **degraded path** is proven by a real load with the library absent — `tests/degraded_env.lua`
loads the whole TOC without `libs/LibKa0s` — never by hand-stubbing the member under test.

## Automated test records — the consolidated run

All four out-of-game suites go through one vendored runner, and every recorded run lands in
[`automated-tests/`](./automated-tests/):

```sh
tests/_kit/run-automated-tests.sh                                          # all four, writes a bundle
tests/_kit/run-automated-tests.sh --suite lint --suite tests --no-bundle   # the green gate; writes nothing
tests/_kit/run-automated-tests.sh --release 0.1.0                          # the release run
```

There are **two checkpoints**, and a suite's answer differs between them:

| Suite | Command | Run + commit | Release tag |
|---|---|---|---|
| `lint` | `luacheck .` | **gates** | **gates** |
| `tests` | `lua tests/run.lua` | **gates** | **gates** |
| `perf` | `lua tests/perf.lua` | no — recorded | **gates** — `pass` required |
| `complexity` | `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` | no — recorded | **gates** — `pass`, zero functions above CCN 15 |

**`perf` and `complexity` never fail a run and never block a commit** (`performance-§9`,
`performance-§10`): a threshold that fails a run teaches everyone to reach for `--no-verify`. They
contribute `amber`, a signal rather than a stop. **A missing tool is a skip recorded with its
reason**, never a pass.

**At the tag, all four gate** (`automated-tests-§3`, *The release gate*): the release run's
`manifest.json` must show all four suites at `pass` and `suites.complexity.warnings` at `0`.
`/wow-addon:bump-version` evaluates that — the runner's exit code is unchanged — and a `skip` there is
**NOT EVALUATED**, never passed.

`lua tests/perf.lua` is documented in [performance.md](./performance.md).

## Verifying the vendored LibKa0s copies

`tests/test_vendor_sync.lua` asks the authoritative question inside the suite: are `libs/LibKa0s/`
and `tests/_kit/` exactly what LibKa0s published at the tag [`../CLAUDE.md`](../CLAUDE.md) names? It
reads that blob out of the sibling `../LibKa0s` checkout with `git`, strips CR from the working-tree
side only, and **skips** with the reason when the sibling is absent. It also checks that
`tests/_kit/run-automated-tests.sh` is recorded `100755` in the index. The by-eye version:

```sh
tag=$(grep -oE 'Bundles \[LibKa0s\]\([^)]*\) v[0-9]+\.[0-9]+\.[0-9]+' CLAUDE.md | grep -oE 'v[0-9.]+$')
rm -rf "/tmp/libka0s-$tag" && mkdir -p "/tmp/libka0s-$tag"
git -C ../LibKa0s archive "$tag" LibKa0s testkit | tar -x -C "/tmp/libka0s-$tag"
diff -r --strip-trailing-cr "/tmp/libka0s-$tag/LibKa0s" libs/LibKa0s   # MUST be empty
diff -r --strip-trailing-cr "/tmp/libka0s-$tag/testkit" tests/_kit     # MUST be empty
```

Never re-vendor from the sibling's working tree: another branch may be checked out there. Vendor from
the tag with `git archive`, and move the provenance line in the same commit as the bytes.

## Current status

The **authoritative** case list and count is the generated [test-cases.md](./test-cases.md)
(testing-§5). This page quotes no number, so there is nothing here to drift.

## The test-case inventory and the badge

`docs/test-cases.md` is **generated, never hand-edited**:

```sh
lua tests/run.lua --list > docs/test-cases.md
diff <(lua tests/run.lua --list) docs/test-cases.md   # no output == in sync
```

Whenever the suite changes — a case added, removed or renamed, or the pass count moves — regenerate
the inventory **and** update the README `Tests` badge (`Tests-X%2FY_passing-green`) **in the same
change**. There is no CI and no dynamic badge.
