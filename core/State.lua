local _, NS = ...

-- Session-only runtime state. Nothing here is ever written to SavedVariables; every field resets on
-- /reload.
--   debug     the debug-logging flag (debug-logging-§5), default off
--   inCombat  the player's combat state, driven by the regen events (events-frames-taint-§2)
--   preview   placeholder content on every enabled element (preview-mode): on exactly while the
--             elements are UNLOCKED, which is the addon's only preview switch (modules/Preview.lua).
--             There is no separate test-mode flag: options-ui-§15 exempts an addon whose unlocked
--             view already is its preview from that row.
--   inParty   the last NS.Units.InParty answer, so a roster change republishes only on a flip
NS.State = NS.State or {}
local State = NS.State
State.debug    = State.debug or false
State.inCombat = State.inCombat or false
State.preview  = State.preview or false
State.inParty  = State.inParty or false
