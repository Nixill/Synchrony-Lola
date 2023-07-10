local Entities  = require "system.game.Entities"
local Player    = require "necro.game.character.Player"
local Utilities = require "system.utils.Utilities"

local module = {}

local function entity(arg)
  if type(arg) == "number" then return Entities.getEntityByID(arg)
  else return arg end
end

-- Add a player to an item's holder list. If the item is already marked as
-- held by that player, nothing changes.
--
-- Returns true iff the player was added to the list (false if they were
-- already on it). If any parameters are invalid, nil is returned.
--
-- holder and item may be passed as entity tables or IDs. To pass a player
-- ID as the holder, use the addPID function instead.
function module.add(holder, item)
  item = entity(item)
  holder = entity(holder)

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
  item = entity(item)

  if not (item
      and item.Lola_holders) then
    return nil
  end

  -- Unmark the item as safe, if it was marked as such.
  item.Lola_holders.safe = false

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
  player = entity(player)

  if not (player
      and player.controllable
      and player.controllable.playerID ~= 0) then
    return nil
  end

  return module.checkPID(item, player.controllable.playerID)
end

-- Same as ItemHolders.check(), but the second argument should be a player ID.
function module.checkPID(item, playerID)
  item = entity(item)

  if not (item
      and item.Lola_holders) then
    return nil
  end

  return item.Lola_holders.safe or not not item.Lola_holders.playerIDs[playerID]
end

-- Check whether an item was held by any of the players.
--
-- Returns true if that item was held by any player in the list. Returns
-- false otherwise. nil is returned if the call fails.
--
-- item may be passed as an entity table or an entity ID. playerIDs MUST
-- be passed as a set (not list!) of player IDs ONLY.
function module.checkAllPIDs(item, playerIDs)
  item = entity(item)

  if not (item
      and item.Lola_holders) then
    return nil
  end

  if item.Lola_holders.safe then return true end

  for k in pairs(playerIDs) do
    if item.Lola_holders.playerIDs[k] then
      return true
    end
  end

  return false
end

-- Copy the list of holders from one item to another.
--
-- Returns true if the list was successfully copied. nil is returned if
-- the call fails. false is never returned.
--
-- fromItem and toItem may be passed as entity tables or entity IDs.
function module.copy(fromItem, toItem)
  fromItem = entity(fromItem)
  toItem = entity(toItem)

  if not (fromItem and toItem
      and fromItem.Lola_holders
      and toItem.Lola_holders) then
    return nil
  end

  toItem.Lola_holders.playerIDs = Utilities.fastCopy(fromItem.Lola_holders.playerIDs)

  return true
end

return module
