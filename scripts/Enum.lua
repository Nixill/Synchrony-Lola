local Enum = require "system.utils.Enum"

local module = {}

module.PackageSetting = Enum.sequence {
  NONE = Enum.entry(0, { name = "None", desc = "Package Spell does not exist." }), -- Classic Rules
  REPLACEABLE = Enum.entry(1, { name = "Replaceable", desc = "Lola starts with Package Spell and can lose it." }),
  INNATE = Enum.entry(2, { name = "Innate", desc = "Lola starts with Package Spell and it is locked." }) -- Default Rules
}

return module