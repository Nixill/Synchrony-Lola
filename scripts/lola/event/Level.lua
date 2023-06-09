local CurrentLevel = require "necro.game.level.CurrentLevel"
local Damage       = require "necro.game.system.Damage"
local Entities     = require "system.game.Entities"
local Event        = require "necro.event.Event"
local GameDLC      = require "necro.game.data.resource.GameDLC"
local Inventory    = require "necro.game.item.Inventory"
local ItemPickup   = require "necro.game.item.ItemPickup"
local LowPercent   = require "necro.game.item.LowPercent"
local Object       = require "necro.game.object.Object"

local RevealedItems = require "NixsChars.mod.RevealedItems"

Event.levelLoad.add("lolaHeldItemsSafe", { order = "initialItems", sequence = 1 },
  function(ev)
    if CurrentLevel.isLobby() then return end

    for e in Entities.entitiesWithComponents { "controllable", "inventory" } do
      if e.controllable.playerID ~= 0 then
        for _, i in ipairs(Inventory.getItems(e)) do
          if i.itemNegateLowPercent then
            i.itemNegateLowPercent.active = false
          end
        end
      end
    end
  end
)
