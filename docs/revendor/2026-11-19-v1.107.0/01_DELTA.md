Delta: LibKa0s v1.106.0 -> v1.107.0

Recorded for the re-vendor commit. Payload taken from the tag, never the sibling tree: `git -C ../LibKa0s archive v1.107.0 LibKa0s testkit tools` (tag 427e108, a local annotated tag, not yet on origin: `git -C ../LibKa0s ls-remote --tags origin v1.107.0` prints nothing, which this run expects). Run under the adoption feedback run (Ka0sAddonsCommonTasks `docs/2026-11-19-ADOPTION_FEEDBACK/`), item AF-RV-PFE: the copy, provenance, icon-declaration and prune half of `/dev-copilot:wow-revendor-libka0s`. The adoption interview is skipped by that run's design; its adoption items are its own manifest's, and none is this addon's.

## Step 0 pre-flight
For this addon: newest single-tag bundle `docs/revendor/2026-11-16-v1.105.0`, base v1.94.0, vendored-before v1.94.0@1c3f374: `ok`. No base correction is owed.

## 3a Base
- `grep -n '[Bb]undles' CLAUDE.md` -> `42:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.106.0 (MIT).` before the roll.
- `git log -1 --format=%H -- libs/LibKa0s tests/_kit` = dbae93d (Re-vendor LibKa0s v1.106.0); its CLAUDE.md names v1.106.0. They agree.
- Payload before the copy equalled the library at v1.106.0: `diff -rq` of a v1.106.0 extract against `libs/LibKa0s` printed only the undeclared icons and the pruned `media/sounds/callout`, and against `tests/_kit` printed nothing (payload-matches).
- Range: `git -C ../LibKa0s log --oneline v1.106.0..v1.107.0` is 6 commits (AF-LK-01, AF-LK-02, AF-DR-LK, AF-LK-03 x3); `git diff --stat v1.106.0 v1.107.0 -- LibKa0s testkit` moves two files.

## 3b/3c Per-file minors that moved (old = this addon, new = v1.107.0)
From the loop over the tag's `LibKa0s.xml`:
```
WidgetsDragHandle.lua     old: DRAG_MINOR = 14     new: DRAG_MINOR = 15
WidgetsDragHandleTip.lua  old: DRAGTIP_MINOR = 1   new: DRAGTIP_MINOR = 2
```
Every other file matches v1.106.0; claimed and actual minors agree, so there is no cross-major skew.

## 3d Diffs
After the copy and before the prune, both diffs (content and bytes) of both payloads were empty. After the prune the only difference is the undeclared icons and the sounds (`Only in <extract>/...`), and `tests/test_vendor_sync.lua` is green. No `Only in libs/LibKa0s` line: nothing removed upstream.

## 3e Consumption map
Unchanged from `../2026-11-16-v1.105.0/01_DELTA.md`. `grep -rnE 'DragHandle|tooltipPlace' . --include='*.lua'` outside `libs/` and `tests/_kit/` finds nothing: this addon builds no drag strip. Its unlock overlay is its own (`modules/Anchor.lua`), not a `Widgets.DragHandle`. The only strip in its payload is the library's own, inside `Callout.lua`, and this addon does not consume Callout.

## 3f Kit revision
`grep -n 'Kit.VERSION'`: addon 57, tag 57. The kit is byte-identical; both payloads still move together.

## 3g Contract delta
Majors that moved: Widgets (DragHandle 15, DragHandleTip 2), which this addon looks up, but not for `DragHandle`. The v1.107.0 *What a consumer owes* list (`CHANGELOG.md`, the v1.107.0 block): a strip's settings mark on by default (`spec.settings = false` opts out), close only with `onClose`, a strip `tooltipPlace` ignored, the `settings` icon declared by a strip host. None reaches a host with no strip. `grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit` finds no host attach site.

### Blockers
None.

## 3h Span
`vendored.txt` minus `recorded.txt` names v1.106.0 (vendored by dbae93d, no bundle). A one-tag span bundle, `docs/revendor/2026-11-19-v1.106.0-v1.106.0/`, is written beside this one.

## 3i Icon declaration
`grep -n 'LibKa0s icons:' CLAUDE.md` -> line 43, directly under the provenance line: `chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high.` Kept as written: `settings` is already declared, which is what a strip host now owes, and this addon has no strip. No `LibKa0s sounds:` line: no line means none. Hand lists have drifted before (KickCD `tests/test_mediasetup.lua:28`, WhatGroup `tests/test_mediasetup.lua:19`); the owner's in-client smoke is the backstop.

Prune: `lua <extract>/tools/prune-icons.lua .` ended `sounds none (no LibKa0s sounds: line); kept 0 file(s), removed 362` across icons and sounds (the same 362 paths the whole-folder copy brought back as at v1.105.0). `libs/LibKa0s/media/icons/` holds 13 entries after it.

## 3j Tests that assume the whole icon folder
`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'`: `tests/test_optionssetup.lua:295-296` opens `info.tga`, a declared name. No whole-catalog loop.

## Dead stub mirrors
`grep -rn '__releaseChrome' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit`: none.
