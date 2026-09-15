# Data flow

The core mechanic as a pipeline. The README's *How it works* is the same pipeline told to a player;
the two must not contradict each other.

## 1. Where the frames are

```
GROUP_ROSTER_UPDATE / PLAYER_ENTERING_WORLD / EDIT_MODE_* / ADDON_LOADED(EllesmereUI)
  + hooksecurefunc on the frame systems' refresh functions + OnShow/OnHide/OnAttributeChanged hooks
        │  (each only sets a flag and schedules)
        ▼
Providers: one coalesced resolve on the next frame, follow-ups at 0.1 s and 0.5 s
        │  pick the provider (Automatic: EllesmereUI if shown, else Blizzard raid-style/classic)
        │  read each visible member frame's unit (displayedUnit → unit → GetAttribute("unit")),
        │  reject secrets, normalize raidN → player/partyN
        ▼
unit → frame map ── changed? ──► LAYOUT message
```

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

Every element runs the same ladder, first failing rung hides: `Perf.suspended` → master enable →
feature enable → preview (show placeholders, stop) → General visibility vs. the combat flag → unit
included and exists → attached: a frame for the unit → the feature's own condition (casting / has a
target / has a pet). The secure target and pet frames express the later rungs as a state driver.

## Build status

Stage 1 of the addon — the lifecycle, the settings seam and the bus that every arrow above uses — is
in the tree. The providers, the anchor engine and the three features land in plan P2–P5.
