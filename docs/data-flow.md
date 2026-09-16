# Data flow

The core mechanic as a pipeline. The README's *How it works* is the same pipeline told to a player;
the two must not contradict each other.

## 0. Whether the addon is awake

`NS.Units.InParty()`: `IsInGroup() and not IsInRaid()`. Out of a party the provider map is empty, no
unit event is registered, and every element is hidden unless preview is on. `GROUP_ROSTER_UPDATE`
republishes VISIBILITY when the answer flips, and each feature re-syncs its events from it.

## 1. Where the frames are

```
GROUP_ROSTER_UPDATE / PLAYER_ENTERING_WORLD / EDIT_MODE_* / ADDON_LOADED(EllesmereUI)
  + hooksecurefunc on the frame systems' refresh functions + OnShow/OnHide/OnAttributeChanged hooks
        │  (each only sets a flag and schedules)
        ▼
Providers: one coalesced resolve on the next frame, follow-ups at 0.1 s and 0.5 s
        │  pick the provider (Automatic: EllesmereUI if shown, else Blizzard raid-style/classic)
        │  read each visible member frame's unit (displayedUnit → unit → GetAttribute("unit")),
        │  reject secrets; only player/party1–4 map (a raidN token maps to nothing)
        ▼
unit → frame map ── changed? ──► LAYOUT message
```

Preview out of a party adds one source: the stand-in fills party1 when no real frame does
(`Providers.SetStandIn`, resolved at once rather than next frame).

## 2. Where each element goes

```
LAYOUT / CONFIG(section) / PROFILE
        ▼
Anchor, per feature:
  attached → SetPoint(element, point, FrameFor(unit), relativePoint, x, y)   (skipped if the key is unchanged)
  free     → stack the five elements from the feature's saved position (growth, spacing)
  secure element in combat → fade to 0 and mark dirty; PLAYER_REGEN_ENABLED re-anchors
```

## 3. What each element shows

```
Cast bar      UNIT_SPELLCAST_* (RegisterUnitEvent per unit)
                → UnitCastingInfo / UnitChannelInfo (name, texture, notInterruptible)
                → duration object → StatusBar:SetTimerDuration   (never Lua arithmetic on a secret)
                → stop / interrupted / failed from the event, not from the clock
Target frame  UNIT_TARGET (per owner) → name, class/reaction color, marker
              health ticker (0.2 s, only while a target frame is shown) → SetMinMaxValues/SetValue
Pet frame     UNIT_PET (owner) + UNIT_HEALTH / UNIT_MAXHEALTH / UNIT_NAME_UPDATE (per pet token)
```

## 4. Whether it is shown

Every element runs the same ladder, first failing rung hides: `NS.IsStoodDown()` — the one latch,
held for a perf run or for the player's own *Enable* switch — → master enable →
feature enable → preview (show placeholders, stop) → in a party (`NS.Units.InParty`) → General
visibility vs. the combat flag → unit
included and exists → attached: a frame for the unit → the feature's own condition (casting / has a
target / has a pet). The secure target and pet frames express the later rungs as a state driver.

## Where each stage lives

Stage 1 is `modules/Providers.lua`, stage 2 `modules/Anchor.lua`, stage 3 `modules/CastBars.lua`,
`modules/TargetFrames.lua` and `modules/PetFrames.lua` (the last two over `modules/UnitButtons.lua`),
and stage 4 is each feature's `shouldShow` / state driver over `modules/Element.lua`'s shared rungs.
Preview mode (`modules/Preview.lua`, on exactly while UNLOCKED — its only switch, options-ui-§15) is rung 3 of stage 4.
