local CurrentLevel = require "necro.game.level.CurrentLevel"
local Damage       = require "necro.game.system.Damage"
local Entities     = require "system.game.Entities"
local Event        = require "necro.event.Event"
local GameDLC      = require "necro.game.data.resource.GameDLC"
local Inventory    = require "necro.game.item.Inventory"
local ItemPickup   = require "necro.game.item.ItemPickup"
local LowPercent   = require "necro.game.item.LowPercent"
local Object       = require "necro.game.object.Object"

local ItemHolders   = require "Lola.mod.ItemHolders"
local RevealedItems = require "Lola.mod.RevealedItems"

Event.levelLoad.add("heldItemsSafe", { order = "initialItems", sequence = 1 },
  function(ev)
    if CurrentLevel.isLobby() then return end

    for e in Entities.entitiesWithComponents { "controllable", "inventory" } do
      if e.controllable.playerID ~= 0 then
        for _, i in ipairs(Inventory.getItems(e)) do
          ItemHolders.reset(i)
        end
      end
    end
  end
)
