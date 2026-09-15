local _, NS = ...
NS.Constants = NS.Constants or {}
local C = NS.Constants

-- Fallback media — used when LibSharedMedia is absent or a stored key no longer resolves, so an
-- element always has a real texture, border and font.
C.FALLBACK_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
C.FALLBACK_BORDER  = "Interface\\Tooltips\\UI-Tooltip-Border"
C.FALLBACK_FONT    = "Fonts\\FRIZQT__.TTF"

-- The debug console's monospace face, from LibKa0s (debug-logging-§2). The last rung is the literal
-- above, never _G.STANDARD_TEXT_FONT: a fallback that can itself be nil is not a fallback.
C.FONT_MONO = NS.MediaFont and NS.MediaFont("JetBrains Mono") or C.FALLBACK_FONT
C.FONT_MONO_NAME = "JetBrains Mono"

-- Landing-page logo (options-ui-§5): a .tga, because the client cannot load .png.
C.LOGO_PATH = "Interface\\AddOns\\PartyFrameEnhanced\\media\\logos\\partyframeenhanced.logo.tga"

-- The nine SetPoint anchors, in the order the anchor dropdowns list them.
C.POINTS = {
    "TOPLEFT", "TOP", "TOPRIGHT",
    "LEFT", "CENTER", "RIGHT",
    "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}
