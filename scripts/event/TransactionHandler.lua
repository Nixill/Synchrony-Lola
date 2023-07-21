local Event = require "necro.event.Event"

local RevealedItems = require "Lola.mod.RevealedItems"

local LoSettings = require "Lola.Settings"
local LoAchievements = require "Lola.Achievements"

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

Event.objectSpawn.add("transactionItems", { order = "overrides", filter = "Lola_revealedBy" },
  function(ev)
    if transactionBy and LoSettings.get("gameplay.transaction") then
      RevealedItems.mark(transactionBy, ev.entity)
      LoAchievements.trackItem(ev.entity.id)
    end
  end
)