local Enum = require "system.utils.Enum"

local module = {}

-- I'll use this at some point. Probably. Maybe.
module.SettingsPreset = Enum.sequence {
  CUSTOM = Enum.entry(0, {
    name = "Custom rules",
    rules = {}
  }),
  CLASSIC = Enum.entry(1, {
    name = "Classic rules",
    rules = {}
  }),
  DEFAULT = Enum.entry(2, {
    name = "Default rules",
    rules = {}
  })
}

module.PackageSetting = Enum.sequence {
  NONE = Enum.entry(0, { name = "None", desc = "Package Spell does not exist." }), -- Classic Rules
  REPLACEABLE = Enum.entry(1, { name = "Replaceable", desc = "Lola starts with Package Spell and can lose it." }),
  INNATE = Enum.entry(2, { name = "Innate", desc = "Lola starts with Package Spell and it is locked." }) -- Default Rules
}

return module
