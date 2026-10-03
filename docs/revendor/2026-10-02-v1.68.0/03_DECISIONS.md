# Decisions (PartyFrameEnhanced, LibKa0s v1.68.0)

No interview. The owner delegated every decision for this plan
(`Ka0sAddonsCommonTasks/docs/2026-10-02-LIBKA0S_TOOLTIP_PLACE/`, item `TP-PF-01`), and the executor
recorded each one as it was taken.

| # | Candidate | Decision | Reason | Issue |
|---|---|---|---|---|
| 1 | `tooltipPlace` / descriptor `place` (WidgetsDragHandle 4) | **declined: not applicable** | This addon builds no drag strip: no `DragHandle` call and no Widgets lookup outside `libs/`. A placement hook for a tooltip the addon never shows has nothing to place. It is not a gap: if the addon ever adds a drag strip, the hook is there to take with it. | none filed |

**Why no issue.** The playbook files a decline as a GitHub issue so a later run can tell a settled
decline from a stale one. This one is settled by what the addon has. It does not build the surface the
hook attaches to, so an issue would be a permanent `will-not-do` on a non-feature. The plan's
instruction for this run is to file only when the reason is a real gap, and this one is not. The
record of the decline is this file.
