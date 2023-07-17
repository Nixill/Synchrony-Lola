local Menu            = require "necro.menu.Menu"
local SettingsStorage = require "necro.config.SettingsStorage"

local PowerSettings = require "PowerSettings.PowerSettings"

local LoEnum = require "Lola.Enum"

local Text = require "Lola.i18n.Text"

PowerSettings.autoRegister()
PowerSettings.saveVersionNumber()

-------------
-- ACTIONS --
--#region----

local function setPreset(values)
  local keys = SettingsStorage.listKeys("mod.Lola", PowerSettings.Layer.REMOTE_OVERRIDE)
  for i, v in ipairs(keys) do
    if values[v] ~= nil then
      SettingsStorage.set(v, values[v], PowerSettings.Layer.REMOTE_PENDING)
    else
      SettingsStorage.set(v, nil, PowerSettings.Layer.REMOTE_PENDING)
    end
  end
end

--#endregion ACTIONS

----------------
-- FORMATTERS --
--#region-------

local function infiniteFormatter(inf)
  return function(value)
    if value == inf then
      return Text.Infinite
    else
      return tostring(value)
    end
  end
end

--#endregion FORMATTERS

--------------
-- SETTINGS --
--#region-----

PowerSettings.shared.group {
  name = "Use a preset",
  id = "preset",
  desc = "Select a rules preset to use.",
  order = 0
}

--#region Presets

PowerSettings.shared.action {
  name = "Default Rules",
  id = "preset.default",
  desc = "Lola's default rules",
  order = 0,
  action = function()
    setPreset {}
    Menu.close()
  end
}

PowerSettings.shared.action {
  name = "Classic Rules",
  id = "preset.classic",
  desc = "Classic rules: Nix's first clear",
  order = 1,
  action = function()
    setPreset {
      ["mod.Lola.gameplay.package"] = LoEnum.PackageSetting.NONE,
      ["mod.Lola.gameplay.bombs"] = 3,
      ["mod.Lola.gameplay.storageVision"] = false,
      ["mod.Lola.gameplay.glass"] = false,
      ["mod.Lola.gameplay.shrine"] = false,
      ["mod.Lola.gameplay.transaction"] = false,
      ["mod.Lola.silly.packageEnemies"] = false
    }
    Menu.close()
  end
}

--#endregion Presets

PowerSettings.shared.label {
  name = "",
  id = "blank1",
  order = 1
}

PowerSettings.shared.group {
  name = "Gameplay settings",
  id = "gameplay",
  order = 2
}

--#region Gameplay

PowerSettings.entitySchema.enum {
  name = "Package spell",
  id = "gameplay.package",
  order = 1,
  enum = LoEnum.PackageSetting,
  default = LoEnum.PackageSetting.INNATE
}

PowerSettings.entitySchema.number {
  name = "Starting bombs",
  id = "gameplay.bombs",
  order = 2,
  minimum = -1,
  maximum = 5,
  default = 1,
  format = infiniteFormatter(-1)
}

PowerSettings.entitySchema.bool {
  name = "Chest vision",
  desc = "Whether or not Lola can see containers (such as chests, crates, shrines) at all times",
  id = "gameplay.storageVision",
  order = 3,
  default = true
}

PowerSettings.shared.bool {
  name = "Allow picking up glass shards",
  desc = "Can Lola pick up the shards of glass weapons and shovels that she was previously holding?",
  id = "gameplay.glass",
  order = 4,
  default = true
}

PowerSettings.shared.bool {
  name = "Receive shrine rewards",
  desc = "Does Lola get rewards from shrines that can be indirectly activated (such as Sacrifice)?",
  id = "gameplay.shrine",
  order = 5,
  default = true
}

PowerSettings.shared.bool {
  name = "Receive tile purchases",
  desc = "Does Lola receive items purchased from the tiles in Conjurer/Transmogrifier rooms?",
  id = "gameplay.transaction",
  order = 6,
  default = true
}

--#endregion Gameplay (section)

-- PowerSettings.shared.label {
--   name = "",
--   order = 9,
--   id = "blank2",
--   visibility = PowerSettings.Visibility.ADVANCED
-- }

PowerSettings.shared.group {
  name = "Silly settings",
  order = 3,
  id = "silly"
}

--#region Silly

PowerSettings.shared.bool {
  name = "Greater Package enemies",
  order = 1,
  id = "silly.packageEnemies",
  desc = "Enemies can be captured by Greater Package",
  default = true
}

PowerSettings.entitySchema.bool {
  name = "Lute mode",
  order = 2,
  id = "silly.luteMode",
  desc = "Play with the Golden Lute as your weapon!"
}

--#endregion Silly

--#endregion SETTINGS

return {
  get = function(node, ...)
    return SettingsStorage.get("mod.Lola." .. node, ...)
  end
}