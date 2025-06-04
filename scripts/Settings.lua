local Menu            = require "necro.menu.Menu"
local Settings        = require "necro.config.Settings"
local SettingsStorage = require "necro.config.SettingsStorage"
local SinglePlayer    = require "necro.client.SinglePlayer"

local LoEnum = require "Lola.Enum"

local Text = require "Lola.i18n.Text"

-------------
-- ACTIONS --
--#region----

local function setPreset(values)
  local keys = SettingsStorage.listKeys("mod.Lola", Settings.Layer.REMOTE_OVERRIDE)
  for i, v in ipairs(keys) do
    if values[v] ~= nil then
      SettingsStorage.set(v, values[v], Settings.Layer.REMOTE_PENDING)
    else
      SettingsStorage.set(v, nil, Settings.Layer.REMOTE_PENDING)
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

----------------
-- CONDITIONS --
--#region-------

local function notSingleplayer()
  return not SinglePlayer.isActive()
end

--#endregion CONDITIONS

--------------
-- SETTINGS --
--#region-----

Settings.shared.group {
  name = "Use a preset",
  id = "preset",
  desc = "Select a rules preset to use.",
  order = 0,
  autoRegister = true
}

--#region Presets

Settings.shared.action {
  name = "Default Rules",
  id = "preset.default",
  desc = "Lola's default rules",
  order = 0,
  action = function()
    setPreset {}
    Menu.close()
  end,
  autoRegister = true
}

Settings.shared.action {
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
      ["mod.Lola.multiplayer.death"] = true,
      ["mod.Lola.silly.packageEnemies"] = false
    }
    Menu.close()
  end,
  autoRegister = true
}

--#endregion Presets

Settings.shared.action {
  name = "---",
  id = "blank1",
  order = 1,
  action = true,
  enableIf = false,
  autoRegister = true
}

Settings.shared.group {
  name = "Gameplay settings",
  id = "gameplay",
  order = 2,
  autoRegister = true
}

--#region Gameplay

Settings.entitySchema.enum {
  name = "Package spell",
  id = "gameplay.package",
  order = 1,
  enum = LoEnum.PackageSetting,
  default = LoEnum.PackageSetting.INNATE,
  autoRegister = true
}

Settings.entitySchema.number {
  name = "Starting bombs",
  id = "gameplay.bombs",
  order = 2,
  minimum = -1,
  maximum = 5,
  default = 1,
  format = infiniteFormatter(-1),
  autoRegister = true
}

Settings.entitySchema.bool {
  name = "Chest vision",
  desc = "Whether or not Lola can see containers (such as chests, crates, shrines) at all times",
  id = "gameplay.storageVision",
  order = 3,
  default = true,
  autoRegister = true
}

Settings.shared.bool {
  name = "Allow picking up glass shards",
  desc = "Can Lola pick up the shards of glass weapons and shovels that she was previously holding?",
  id = "gameplay.glass",
  order = 4,
  default = true,
  autoRegister = true
}

Settings.shared.bool {
  name = "Receive shrine rewards",
  desc = "Does Lola get rewards from shrines that can be indirectly activated (such as Sacrifice)?",
  id = "gameplay.shrine",
  order = 5,
  default = true,
  autoRegister = true
}

Settings.shared.bool {
  name = "Receive tile purchases",
  desc = "Does Lola receive items purchased from the tiles in Conjurer/Transmogrifier rooms?",
  id = "gameplay.transaction",
  order = 6,
  default = true,
  autoRegister = true
}

Settings.shared.bool {
  name = "Bounce on attempted violation",
  desc = "Does Lola bounce harmlessly off attempted item pickups or shrine usages?",
  id = "gameplay.bounce",
  order = 7,
  default = false,
  autoRegister = true
}

Settings.shared.bool {
  name = "Automatically claim package interactions",
  desc = "When Lola creates a package, should it automatically be marked as interacted?",
  id = "gameplay.autoInteract",
  order = 8,
  default = true,
  autoRegister = true
}

--#endregion Gameplay (section)

Settings.group {
  name = "Multiplayer settings",
  desc = "Settings that only affect the multiplayer game.",
  id = "multiplayer",
  order = 3,
  enableIf = notSingleplayer,
  autoRegister = true
}

--#region Multiplayer (section)

Settings.shared.bool {
  name = "Death unclaims items",
  desc = "In multiplayer, should a dead Lola skip collecting items at the end of the floor?",
  id = "multiplayer.death",
  order = 1,
  enableIf = notSingleplayer,
  default = false,
  autoRegister = true
}

--#endregion Multiplayer (section)

-- Settings.shared.action {
--   name = "",
--   order = 9,
--   id = "blank2",
--   visibility = Settings.Visibility.ADVANCED,
--   action = function() end,
--   enableIf = false
-- }

Settings.shared.group {
  name = "Silly settings",
  order = 4,
  id = "silly",
  autoRegister = true
}

--#region Silly

Settings.shared.bool {
  name = "Greater Package enemies",
  order = 1,
  id = "silly.packageEnemies",
  desc = "Enemies can be captured by Greater Package",
  default = true,
  autoRegister = true
}

Settings.entitySchema.bool {
  name = "Lute mode",
  order = 2,
  id = "silly.luteMode",
  desc = "Play with the Golden Lute as your weapon!",
  autoRegister = true
}

--#endregion Silly

--#endregion SETTINGS

return {
  get = function(node, ...)
    return SettingsStorage.get("mod.Lola." .. node, ...)
  end
}