# Scope

## What it does

Adds three **elements** for the player and party1–party4, which neither Blizzard's party frames nor
EllesmereUI's show:

- a **cast bar** per party member;
- a **target frame** per party member — what that member is targeting: name, health, class or
  reaction color, raid marker; click to target it;
- a **pet frame** per party member — name, health, raid marker; click to target the pet.

Each feature either **attaches** its elements to the party frame currently showing each unit
(Blizzard classic, Blizzard raid-style, or EllesmereUI — detected automatically, overridable) or
stacks them in one movable **free-placement** group. Every element fades with its party member's
frame when that member is out of range.

## What it deliberately does not do

- **Raid frames, or anything out of a party.** The addon is party-only by design: solo or in a raid it
  shows nothing (`/pfe unlock` previews it). Arena frames are a separate feature (#11).
- **Other frame systems** — ElvUI, Cell, Grid2, VuhDo, DandersFrames. The provider interface makes
  each one additive, but none ships in v1.0.1 (#2).
- **Replace or restyle the party frames themselves.** It never hides, reparents, moves or calls into a
  Blizzard or EllesmereUI frame; it only reads their position and unit, and only through
  `hooksecurefunc` / `HookScript`. The one other read is EllesmereUI's configured party frame size,
  taken read-only from its saved settings (`EllesmereUIDB`) to size the preview stand-in out of a
  party (a recorded `library-stack-§6` deviation in `docs/ARCHITECTURE.md`).
- **Auras, power, target-of-target, focus.** The target frame is a compact "who is my party member
  hitting or healing" readout, not a second unit frame.
- **Its own range check.** The out-of-range fade copies the party frame's (on Blizzard classic,
  which does not fade, it is a fixed ~40-yard check at half opacity). Spell-based ranges and a
  per-feature opacity slider are #13.
- **Per-unit styling.** Every element of one feature shares one style; only position differs.
- **Decide anything from a secret value.** "Hide the target frame when the target is me" is not
  offered: comparing a compound unit token is always secret in Midnight, so it cannot be decided in
  Lua.
- **Follow a mid-combat roster reshuffle with the clickable frames.** Secure frames cannot be moved in
  combat; they fade out when their anchor stops matching and come back on `PLAYER_REGEN_ENABLED`.
- **Translate.** English only for now; the locale seam ships.

Why these limits exist, with the evidence, is the design spec:
[superpowers/specs/2026-09-15-party-frame-enhanced-design.md](superpowers/specs/2026-09-15-party-frame-enhanced-design.md).
