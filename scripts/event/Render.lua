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

local ItemHolders = require "Lola.mod.ItemHolders"

local BLUE   = Color.rgb(43, 66, 180)
local GREEN  = Color.rgb(66, 180, 43)
local SILVER = Color.rgb(150, 150, 150)
local YELLOW = Color.rgb(180, 157, 43)

Event.render.add("outlineClaimedItems", { order = "outlines", sequence = 1 },
  function(ev)
    if CurrentLevel.isLobby() then return end

    local focus = Focus.getAll()
    local focusPIDs = {}

    -- Get focused players and their lowPercentAllowedItems
    local pids = {}
    local itms = {}
    local blue = false

    -- Iterate all focused players
    for i, p in ipairs(focus) do
      -- If that player is forced to be low% then...
      if p.Lola_forcedLowPercent and p.Lola_forcedLowPercent.active then
        -- ... we can use blue rendering later. (This doesn't apply if no
        -- focused player is forced low%.)
        blue = true

        -- Also iterate their allowed items, so that we know *which* items
        -- to render blue.
        -- First, the "low% allowed items" (items which don't negate low%
        -- on being picked up)
        if p.lowPercent then
          for k in pairs(p.lowPercent.allowedItems) do
            itms[k] = true
          end
        end

        -- And second, the "forcedlow% allowed items" (items which do
        -- negate low% on being picked up, but for balance reasons, are
        -- still allowed).
        for k in pairs(p.Lola_forcedLowPercent.allowedItems) do
          itms[k] = true
        end
      end

      if p.Lola_descentCollectItems then
        pids[p.controllable.playerID] = true
      end
    end

    -- Iterate all items
    for item in Entities.entitiesWithComponents { "item" } do
      local color

      -- Only outline items that are actually on the floor and revealed.
      if not item.gameObject.tangible
          or not item.visibility.fullyVisible
          or (item.itemSlot and item.itemSlot.name == "follower") then
        goto continue
      end

      if blue and itms[item.name] then
        color = BLUE
      elseif ItemHolders.checkAllPIDs(item, pids) then
        color = BLUE
      elseif item.Lola_revealedBy then
        if not (item.itemNegateLowPercent and item.itemNegateLowPercent.active) then
          color = BLUE
        elseif pids[item.Lola_revealedBy.playerID] then
          if item.item.singleChoice == 0 then
            color = GREEN
          else
            color = YELLOW
          end
        elseif item.Lola_revealedBy.playerID ~= 0
            and Player.getPlayerEntity(item.Lola_revealedBy.playerID).Lola_descentCollectItems then
          color = SILVER
        end
      elseif not item.itemCurrency then
        color = BLUE
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
