local Event = require "necro.event.Event"

local RevealedItems = require "Lola.mod.RevealedItems"
local ShownItems    = require "Lola.mod.ShownItems"

local LoSettings = require "Lola.Settings"

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

Event.shopkeeperTransaction.add("setPawnbrokerTransaction",
  { order = "payPrice", sequence = -1, filter = "transactionSellItem" },
  function(ev)
    transactionBy = ev.client
  end
)

Event.shopkeeperTransaction.add("clearPawnbrokerTransaction",
  { order = "payPrice", sequence = 2, filter = "transactionSellItem" },
  function(ev)
    transactionBy = nil
  end
)

Event.objectSpawn.add("transactionItems", { order = "overrides", filter = "Lola_revealedBy" },
  function(ev)
    if transactionBy and LoSettings.get("gameplay.transaction") then
      RevealedItems.mark(transactionBy, ev.entity)
      ShownItems.trackItem(ev.entity.id)
    end
  end
)