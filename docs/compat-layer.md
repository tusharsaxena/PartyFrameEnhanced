# Compat layer

`core/Compat.lua` owns every version-variant or optional client API this addon calls, and the
secret-value guards around them (compat, spec §7). Feature modules call `NS.Compat.X`, never the raw
API. Every global is read at **call time**: 12.0 and 12.1 differ in which members exist, and a
headless run has none of them. Shims LibKa0s supplies (metadata, media, the stringifier) are the
library's and are not documented here.

| Shim | Wraps | Answers | Why it exists |
|---|---|---|---|
| `IsSecret(v)` | `issecretvalue` | `true` only for a value the client marks secret | 12.0 global; older builds and the harness lack it |
| `IsAddOnLoaded(name)` | `C_AddOns.IsAddOnLoaded`, then `IsAddOnLoaded` | boolean | the presence guard for optional integrations (library-stack-§6) |
| `FrameVisible(frame)` | `frame:IsVisible()` | `true` for a secret answer (fail open), `false` for nil or a raise | other addons' secure frames can answer secrets |
| `FrameUnit(frame)` | `displayedUnit` → `unit` → `unitToken` → `GetAttribute("unit")` | the unit token, or nil for none or a secret | three frame systems store the unit three ways; the secret check runs before any comparison |
| `UseRaidStyleParty()` | `EditModeManagerFrame:UseRaidStylePartyFrames()`, then CVar `useCompactPartyFrames` | boolean | 12.x stores the layout choice per Edit Mode layout |

| `CastInfo(unit, hint)` | `UnitCastingInfo`, then `UnitChannelInfo` | kind, name, texture, notInterruptible (the last three possibly secret), or nil | one place that knows the two returns' positions; empower decided by `isEmpowered` only when plain |
| `CastDuration(unit, kind)` | `UnitCastingDuration` / `UnitChannelDuration` / `UnitEmpoweredChannelDuration` | the duration object, or nil | 12.0 API; opaque, passed only to C methods |
| `ApplyTimer(bar, duration, kind)` | `StatusBar:SetTimerDuration` + `Enum.StatusBarTimerDirection` | true when the engine animates the bar | casts fill, channels drain; false sends the caller to the manual fill |
| `BoolValue(flag, a, b)` | `C_CurveUtil.EvaluateColorValueFromBoolean` | `a` or `b` (possibly secret) | picks a value by a secret boolean without an `if` |
| `AlphaFromBool(region, flag, a, b)` | `Region:SetAlphaFromBoolean` | — | the one alpha setter that takes a secret boolean |

| `HealthPercent(token)` | `UnitHealthPercent(token, true, CurveConstants.ScaleTo100)` | 0–100, possibly secret, or nil | the client scales it, so no Lua arithmetic; rendered only through `SetFormattedText` |
| `ClassToken(token)` | `UnitClass`'s second return | the class token, or nil when secret or absent | a secret token must never index `RAID_CLASS_COLORS`; the localized name is never used (localization-§4) |
| `IsPlayer(token)` | `UnitIsPlayer` | `true` / `false` / **nil = unknown** | compound tokens' player-ness can be secret |
| `Reaction(token)` | `UnitReaction(token, "player")` | 1–8, or nil when secret | the reaction palette is indexed only by a plain number |
| `RaidMarker(texture, token)` | `GetRaidTargetIndex` + `SetRaidTargetIconTexture` | shows or hides the texture | the index may be secret; only its presence is tested |

Why each secret rule exists: [midnight-quirks.md](midnight-quirks.md).

Tests: `tests/test_compat.lua` drives each shim through a mock `issecretvalue` that marks one sentinel
secret.
