local CurrentLevel = require "necro.game.level.CurrentLevel"
local Damage       = require "necro.game.system.Damage"
local Entities     = require "system.game.Entities"
local Event        = require "necro.event.Event"
local GameDLC      = require "necro.game.data.resource.GameDLC"
local Inventory    = require "necro.game.item.Inventory"
local ItemPickup   = require "necro.game.item.ItemPickup"
local LowPercent   = require "necro.game.item.LowPercent"
local Object       = require "necro.game.object.Object"

Event.levelComplete.add("lolaCollectItems", { order = "collectItems", sequence = 1 },
  function(ev)
    if CurrentLevel.isLobby() then return end

    local descentCollectors = {}
    local holsters = {}

    -- Log all controllable entities with NixsChars_descentCollectItems
    -- (and disable any NixsChars_forcedLowPercent they may have)
    print("Log descent collectors")
    for e in Entities.entitiesWithComponents { "NixsChars_descentCollectItems", "controllable" } do
      print(e.name .. "#" .. e.id .. " (player " .. e.controllable.playerID .. ")")
      if e.NixsChars_descentCollectItems.active then
        descentCollectors[e.controllable.playerID] = e

        -- Search for holsters
        -- caching them saves some computations later
        for i, v in ipairs(Inventory.getItems(e)) do
          if v.itemHolster then
            holsters[e.controllable.playerID] = v
          end
        end

        if e.NixsChars_forcedLowPercent then
          print("Disabling forced low%")
          e.NixsChars_forcedLowPercent.active = false
        end
      else
        print("(Collection disabled, resuming)")
        e.NixsChars_descentCollectItems.active = true
      end
    end

    -- Pick up all revealed items
    print("Pick up revealed items")
    for e in Entities.entitiesWithComponents { "NixsChars_revealedBy" } do
      if e.gameObject.tangible then
        local pNum = e.NixsChars_revealedBy.playerID

        print(e.name .. "#" .. e.id .. " (revealed by player " .. pNum .. ")")
        local player = descentCollectors[pNum]

        if player then
          print("Player " .. pNum .. " is " .. player.name .. "#" .. player.id)

          -- Holster check!
          if e.itemSlot then
            local slot = e.itemSlot.name
            local holster = holsters[pNum]
            if not Inventory.hasSlotCapacity(player, slot, 1)
                and holster
                and holster.itemHolster.slot == slot then
              Inventory.swapWithHolster(player, holster)
            end
          end

          Inventory.add(e, player)
          LowPercent.negate(player, e)
        else
          print("Player " .. pNum .. " not found (or collection disabled)")
        end
      end
    end

    -- Re-enable any NixsChars_forcedLowPercent
    print("Re-enable forced low%")
    for e in Entities.entitiesWithComponents { "NixsChars_descentCollectItems", "controllable",
      "NixsChars_forcedLowPercent" } do

      e.NixsChars_forcedLowPercent.active = true
    end
  end
)

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
