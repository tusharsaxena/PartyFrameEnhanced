local _, NS = ...

-- Session-only runtime state. Nothing here is ever written to SavedVariables; every field resets on
-- /reload.
--   debug     the debug-logging flag (debug-logging-§5), default off
--   inCombat  the player's combat state, driven by the regen events (events-frames-taint-§2)
--   preview   placeholder content on every enabled element (preview-mode), owned by modules/Preview
NS.State = NS.State or {}
local State = NS.State
State.debug    = State.debug or false
State.inCombat = State.inCombat or false
State.preview  = State.preview or false
