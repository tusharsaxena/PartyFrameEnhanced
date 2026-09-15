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
| `UnitIsUnit(a, b)` | `C_Secrets.CanCompareUnitTokens`, then `UnitIsUnit` | `true` / `false` / **nil = unknown** | 12.1 refuses to compare secret identities, and the answer itself can be secret |
| `UseRaidStyleParty()` | `EditModeManagerFrame:UseRaidStylePartyFrames()`, then CVar `useCompactPartyFrames` | boolean | 12.x stores the layout choice per Edit Mode layout |

Arriving with the features: the cast-duration and timer shims (P3), and the health-percent and
raid-marker shims (P4). Each is added here in the change that adds it.

Tests: `tests/test_compat.lua` drives each shim through a mock `issecretvalue` that marks one sentinel
secret.
