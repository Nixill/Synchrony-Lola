local Entities  = require "system.game.Entities"
local Player    = require "necro.game.character.Player"
local Utilities = require "system.utils.Utilities"

local module = {}

-- Add a player to an item's holder list. If the item is already marked as
-- held by that player, nothing changes.
--
-- Returns true iff the player was added to the list (false if they were
-- already on it). If any parameters are invalid, nil is returned.
--
-- holder and item may be passed as entity tables or IDs. To pass a player
-- ID as the holder, use the addPID function instead.
function module.add(holder, item)
  if type(item) == "number" then item = Entities.getEntityByID(item) end
  if type(holder) == "number" then holder = Entities.getEntityByID(holder) end

  if not (item and holder
      and item.Lola_holders
      and holder.controllable
      and holder.controllable.playerID ~= 0) then
    return nil
  end

  local holders = item.Lola_holders.playerIDs
  local playerID = holder.controllable.playerID

  if holders[playerID] then
    -- Already marked as held?
    return false
  else
    holders[playerID] = true
    return true
  end
end

-- Same as ItemHolders.add, except the first argument should be a player ID.
function module.addPID(playerPID, item)
  return module.add(Player.getPlayerEntity(playerPID), item)
end

-- Mark an item as only held by its current holder. Removes all holders if
-- the item is not currently held by anyone.
--
-- Returns the previous list of holders. nil is returned if the call fails.
--
-- item may be passed as an entity table or ID.
function module.reset(item)
  if type(item) == "number" then item = Entities.getEntityByID(item) end

  if not (item
      and item.Lola_holders) then
    return nil
  end

  -- Get the old list of holders. We'll return it.
  local oldHolders = Utilities.deepCopy(item.Lola_holders.playerIDs)

  -- Prepare a new list.
  local holders = {}

  -- Is the item currently being held?
  if item.item.holder ~= 0 then
    local holderNow = Entities.getEntityByID(item.item.holder)

    -- Is it being held by a player?
    if holderNow.controllable then
      -- Mark that player as holding the item
      holders[holderNow.controllable.playerID] = true
    end
  end

  -- Put the list into the component
  item.Lola_holders.playerIDs = holders

  -- And return the old list
  return oldHolders
end

-- Check whether an item was held by a specific player.
--
-- Returns true if that item was held by that player. Returns false
-- otherwise. nil is returned if the call fails.
--
-- item and player may be passed as entity tables or entity IDs. To use a
-- player ID, use checkPID.
function module.check(item, player)
  if type(player) == "number" then player = Entities.getEntityByID(player) end

  if not (player
      and player.controllable
      and player.controllable.playerID ~= 0) then
    return nil
  end

  return module.checkPID(item, player.controllable.playerID)
end

-- Same as ItemHolders.check(), but the second argument should be a player ID.
function module.checkPID(item, playerID)
  if type(item) == "number" then item = Entities.getEntityByID(item) end

  if not (item
      and item.Lola_holders) then
    return nil
  end

  return not not item.Lola_holders.playerIDs[playerID]
end

return module
