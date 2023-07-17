local Event = require "necro.event.Event"

if pcall(require, "NecroEdit.NecroEdit") then
  Event.NecroEdit_spawn.add("spawnSafe",
    { filter = "Lola_holders", order = "attributes", sequence = 1 },
    function(ev)
      ev.entity.Lola_holders.safe = true
    end
  )
end