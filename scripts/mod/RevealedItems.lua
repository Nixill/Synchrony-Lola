local Entities  = require "system.game.Entities"
local GameDLC   = require "necro.game.data.resource.GameDLC"
local Player    = require "necro.game.character.Player"
local Utilities = require "system.utils.Utilities"

local module = {}

-- Mark an item as revealed by a specific player. If an item is already
-- marked as revealed by another, it will be removed from their list and
-- their player ID returned. Otherwise, 0 will be returned. nil is
-- returned if the call fails.
--
-- If already marked by the player passed into the argument, will move the
-- item to the end of the list.
--
-- revealer or item may be passed as entity tables or IDs. To pass a
-- player ID as the revealer, use the markPID function instead.
function module.mark(revealer, item)
  if type(revealer) == "number" then revealer = Entities.getEntityByID(revealer) end
  if type(item) == "number" then item = Entities.getEntityByID(item) end

  if not (revealer and item
      and item.NixsChars_revealedBy
      and revealer.controllable
      and revealer.controllable.playerID ~= 0) then
    return nil
  end

  -- Get the current revealer, if any.
  local out = module.unmark(item)

  -- Make sure we have that player's topmost entity
  if GameDLC.isSynchronyLoaded() then
    while revealer.Sync_possessable and revealer.Sync_possessable.possessor ~= 0 do
      revealer = Entities.getEntityByID(revealer.Sync_possessable.possessor)
    end
  end

  -- Mark item as revealed by player
  item.NixsChars_revealedBy.playerID = revealer.controllable.playerID

  -- If player tracks revealed items, add item to player's revealed list
  if revealer.NixsChars_descentCollectItems then
    table.insert(revealer.NixsChars_descentCollectItems.revealedItems, item.id)
  end

  return out
end

-- Same as module.mark, except the first argument should be a player ID.
function module.markPID(revealerPID, item)
  return module.mark(Player.getPlayerEntity(revealerPID), item)
end

-- Mark an item as unrevealed. If it's revealed by a player, it is also
-- removed from that player's list (if they have one). Returns the player
-- ID that it had been marked as revealed by, or 0 if there is no such
-- player. nil is returned if the call fails.
--
-- item may be passed as an entity table or ID.
function module.unmark(item)
  if type(item) == "number" then item = Entities.getEntityByID(item) end

  if not (item
      and item.NixsChars_revealedBy) then
    return nil
  end

  -- Get the current revealer.
  local pid = item.NixsChars_revealedBy.playerID

  if pid ~= 0 then
    item.NixsChars_revealedBy.playerID = 0

    local player = Player.getPlayerEntity(pid)

    if player and player.NixsChars_descentCollectItems then
      local pos = nil
      for i, v in ipairs(player.NixsChars_descentCollectItems.revealedItems) do
        if v == item.id then
          pos = i
          break
        end
      end

      if pos then
        table.remove(player.NixsChars_descentCollectItems.revealedItems, pos)
      end
    end
  end

  return pid
end

-- Return a table of all items a player has marked as revealed. This
-- returns the item entity tables, not just the IDs.
--
-- player may be passed as an entity table or ID.
function module.getRevealedItems(player)
  if type(player) == "number" then player = Entities.getEntityByID(player) end

  if not (player
      and player.NixsChars_descentCollectItems) then
    return nil
  end

  return Utilities.map(player.NixsChars_descentCollectItems.revealedItems, Entities.getEntityByID)
end

function module.getRevealedItemsPID(playerID)
  return module.getRevealedItems(Player.getPlayerEntity(playerID))
end

return module
