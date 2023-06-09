local Event = require "necro.event.Event"

local RevealedItems = require "NixsChars.mod.RevealedItems"

local transactionBy = nil

Event.shopkeeperTransaction.add("setTransaction",
  { order = "spawnItem", sequence = -1, filter = "transactionSpawnItem" },
  function(ev)
    transactionBy = ev.client
  end
)

Event.shopkeeperTransaction.add("clearTransaction",
  { order = "spawnItem", sequence = 1, filter = "transactionSpawnItem" },
  function(ev)
    transactionBy = nil
  end
)

Event.objectSpawn.add("transactionItems", { order = "overrides", filter = "NixsChars_revealedBy" },
  function(ev)
    if transactionBy then
      RevealedItems.mark(transactionBy, ev.entity)
    end
  end
)
