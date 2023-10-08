local Event  = require "necro.event.Event"
local FileIO = require "system.game.FileIO"
local JSON   = require "system.utils.serial.JSON"

Event.settingsPresetSave.add("addVersionNumbers", { order = "editor", sequence = 10 }, function(ev)
  local modVer = JSON.decode(FileIO.readFileToString("mods/Lola/mod.json")).version
  ev.settings.mod.Lola._version = modVer
end)