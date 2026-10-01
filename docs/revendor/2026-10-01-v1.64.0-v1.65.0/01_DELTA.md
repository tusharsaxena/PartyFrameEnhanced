Delta: LibKa0s v1.64.0 -> v1.65.0 (span: v1.64.0 v1.65.0)

# LibKa0s v1.64.0 and v1.65.0: the consolidated span (PartyFrameEnhanced)

Written 2026-10-01 by `GI-PF-RV` (the v1.66.0 re-vendor), as the revendor-libka0s Step 3h back-fill.
The two tags below were carried into `libs/LibKa0s/` and `tests/_kit/` by the 2026-09-30 debug-logging
run (`DL-PF-*`) and the 2026-09-30 LibKa0s debug-gaps run (`DG-PF-01`), and neither run wrote a
`docs/revendor/` bundle. Nothing is decided here in retrospect.

## The listing

```sh
horizon=$(ls -1 docs/revendor | sort | head -1 | cut -c1-10)     # 2026-09-23
# vendored: every tag the provenance line named at a payload commit or a CLAUDE.md roll since the horizon
v1.55.0 v1.56.0 v1.57.0 v1.58.0 v1.60.0 v1.61.0 v1.62.0 v1.63.0 v1.64.0 v1.65.0
# recorded: every tag a docs/revendor/ bundle names
grep -vxF -f recorded.txt vendored.txt
v1.64.0
v1.65.0
```

(The full script is revendor-libka0s Step 3h.)

## The carriers

| Tag | Library commit | Carrier commits here |
|---|---|---|
| v1.64.0 | `1cb69a7` | `9de887e` DL-PF-01 (LibKa0s v1.64.0, kit 33), `7120cd9` DL-PF-03 (final v1.64.0, kit 34) |
| v1.65.0 | `6cb04da` | `485b786` DG-PF-01 (LibKa0s v1.65.0, kit 34) |

At each carrier the payload matched the library at the tag, as `tests/test_vendor_sync.lua` asserted
in the commit's green gate.
