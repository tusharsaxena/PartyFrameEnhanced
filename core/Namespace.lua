local addonName, NS = ...

-- The addon's single private table (architecture-§1). Nothing is ever written to _G[addonName].
NS.name = addonName
NS.version = "1.0.0"

-- The mandatory cyan chat tag (slash-commands-§4). One constant so every line prints identically.
NS.PREFIX = "|cff00ffff[PFE]|r"
