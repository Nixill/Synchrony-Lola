local Color         = require "system.utils.Color"
local CurrentLevel  = require "necro.game.level.CurrentLevel"
local Entities      = require "system.game.Entities"
local Event         = require "necro.event.Event"
local Focus         = require "necro.game.character.Focus"
local OutlineFilter = require "necro.render.filter.OutlineFilter"
local Player        = require "necro.game.character.Player"
local PlayerList    = require "necro.client.PlayerList"
local Render        = require "necro.render.Render"
local Utilities     = require "system.utils.Utilities"

local BLUE   = Color.rgb(43, 66, 180)
local GREEN  = Color.rgb(66, 180, 43)
local SILVER = Color.rgb(150, 150, 150)
local YELLOW = Color.rgb(180, 157, 43)

Event.render.add("outlineClaimedItems", { order = "outlines", sequence = 1 },
  function(ev)
    if CurrentLevel.isLobby() then return end

    local focus = Focus.getAll()

    -- Get focused players and their lowPercentAllowedItems
    local pids = {}
    local itms = {}
    local blue = false

    for i, p in ipairs(focus) do
      if p.NixsChars_forcedLowPercent and p.NixsChars_forcedLowPercent.active then
        blue = true

        if p.lowPercent then
          for k in pairs(p.lowPercent.allowedItems) do
            itms[k] = true
          end
        end
      end

      if p.NixsChars_descentCollectItems then
        pids[p.controllable.playerID] = true
      end
    end

    -- Iterate all items
    for item in Entities.entitiesWithComponents { "item" } do
      local color

      if not item.gameObject.tangible
          or not item.visibility.fullyVisible then
        goto continue
      end

      if blue and itms[item.name] then
        color = BLUE -- blue
      elseif item.NixsChars_revealedBy then
        if not (item.itemNegateLowPercent and item.itemNegateLowPercent.active) then
          color = BLUE -- blue
        elseif pids[item.NixsChars_revealedBy.playerID] then
          if item.item.singleChoice == 0 then
            color = GREEN -- green
          else
            color = YELLOW -- yellow
          end
        elseif item.NixsChars_revealedBy.playerID ~= 0
            and Player.getPlayerEntity(item.NixsChars_revealedBy.playerID).NixsChars_descentCollectItems then
          color = SILVER -- silver
        end
      elseif not item.itemCurrency then
        color = BLUE -- blue
      end

      if color ~= nil then
        local visual = OutlineFilter.getEntityVisual(item)
        visual.color = color
        visual.z = visual.z - 1
        Render.getBuffer(Render.Buffer.CUSTOM).draw(visual)
      end

      ::continue::
    end
  end
)
