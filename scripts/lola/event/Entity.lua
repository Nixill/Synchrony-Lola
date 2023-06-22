local Event = require "necro.event.Event"

Event.entitySchemaLoadEntity.add("addComponents", { order = "overrides" }, function(ev)
  local entity = ev.entity

  if entity.itemNegateLowPercent then
    entity.Lola_revealedBy = {}
  end

  if entity.storage then
    entity.Lola_interactedBy = {}
  end
end)
