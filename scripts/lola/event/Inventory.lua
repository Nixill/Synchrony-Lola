local Event = require "necro.event.Event"

local RevealedItems = require "NixsChars.mod.RevealedItems"

Event.inventoryAddItem.add("lolaUntrack", { order = "unmap", sequence = 1 },
  function(ev)
    if ev.item.NixsItems_revealedBy then
      ev.item.NixsItems_revealedBy = 0
    end
  end
)

Event.itemConsume.add("lolaGlassShard", { order = "convert", sequence = 1 },
  function(ev)
    local drop = ev.droppedItem
    if drop and drop.itemNegateLowPercent then
      drop.itemNegateLowPercent.active = false
    end
  end
)

Event.storageDetach.add("lolaItemTracker", { order = "item", sequence = 1 },
  function(ev)
    local container = ev.container
    local entity = ev.entity

    -- print("Storage detach event")

    if ev.suppressed or (not entity.itemNegateLowPercent) or container.NixsChars_interactedBy.playerID == 0 then return end

    RevealedItems.markPID(container.NixsChars_interactedBy.playerID, entity)

    -- print(entity.name .. " revealed by player " .. container.NixsChars_interactedBy.playerID)
  end
)
