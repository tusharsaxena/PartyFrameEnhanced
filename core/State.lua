local _, NS = ...

-- Session-only runtime state. Nothing here is ever written to SavedVariables; every field resets on
-- /reload.
--   debug     the debug-logging flag (debug-logging-§5), default off
--   inCombat  the player's combat state, driven by the regen events (events-frames-taint-§2)
--   preview   placeholder content on every enabled element (preview-mode), owned by modules/Preview
--   inParty   the last NS.Units.InParty answer, so a roster change republishes only on a flip
--   test      test mode: nil (off), "party" or "standin", owned by modules/TestMode
NS.State = NS.State or {}
local State = NS.State
State.debug    = State.debug or false
State.inCombat = State.inCombat or false
State.preview  = State.preview or false
State.inParty  = State.inParty or false
State.test     = State.test
