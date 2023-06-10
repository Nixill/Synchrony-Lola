local Color         = require "system.utils.Color"
local Entities      = require "system.game.Entities"
local Event         = require "necro.event.Event"
local OutlineFilter = require "necro.render.filter.OutlineFilter"
local PlayerList    = require "necro.client.PlayerList"
local Render        = require "necro.render.Render"

Event.render.add("outlineClaimedItems", { order = "outlines", sequence = 1 },
  function(ev)
    local pid = PlayerList.getLocalPlayerID()
    for item in Entities.entitiesWithComponents { "NixsChars_revealedBy" } do
      if item.NixsChars_revealedBy.playerID == pid then
        local visual = OutlineFilter.getEntityVisual(item)
        visual.color = Color.rgb(66, 180, 43)
        visual.z = visual.z - 1
        Render.getBuffer(Render.Buffer.CUSTOM).draw(visual)
      end
    end
  end
)
