# Scope

## What it does

Adds three **elements** for the player and party1–party4, which neither Blizzard's party frames nor
EllesmereUI's show:

- a **cast bar** per party member;
- a **target frame** per party member — what that member is targeting: name, health, class or
  reaction color, raid marker; click to target it;
- a **pet frame** per party member — name and health; click to target the pet.

Each feature either **attaches** its elements to the party frame currently showing each unit
(Blizzard classic, Blizzard raid-style, or EllesmereUI — detected automatically, overridable) or
stacks them in one movable **free-placement** group.

## What it deliberately does not do

- **Raid frames, or anything out of a party.** The addon is party-only by design: solo or in a raid it
  shows nothing (`/pfe test` previews it). Arena frames are a separate feature (#11).
- **Other frame systems** — ElvUI, Cell, Grid2, VuhDo, DandersFrames. The provider interface makes
  each one additive, but none ships in v0.1.0 (#2).
- **Replace or restyle the party frames themselves.** It never hides, reparents, moves or calls into a
  Blizzard or EllesmereUI frame; it only reads their position and unit, and only through
  `hooksecurefunc` / `HookScript`.
- **Auras, power, target-of-target, focus.** The target frame is a compact "who is my party member
  hitting or healing" readout, not a second unit frame.
- **Per-unit styling.** Every element of one feature shares one style; only position differs.
- **Decide anything from a secret value.** "Hide the target frame when the target is me" is not
  offered: comparing a compound unit token is always secret in Midnight, so it cannot be decided in
  Lua.
- **Follow a mid-combat roster reshuffle with the clickable frames.** Secure frames cannot be moved in
  combat; they fade out when their anchor stops matching and come back on `PLAYER_REGEN_ENABLED`.
- **Translate.** English only for now; the locale seam ships.

Why these limits exist, with the evidence, is the design spec:
[superpowers/specs/2026-09-15-party-frame-enhanced-design.md](superpowers/specs/2026-09-15-party-frame-enhanced-design.md).
