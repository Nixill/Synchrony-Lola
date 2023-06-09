local Event = require "necro.event.Event"

Event.entitySchemaLoadEntity.add("lolaAddComponents", { order = "overrides" }, function(ev)
  local entity = ev.entity

  if entity.itemNegateLowPercent then
    entity.NixsChars_revealedBy = {}
  end

  if entity.storage then
    entity.NixsChars_interactedBy = {}
  end
end)
