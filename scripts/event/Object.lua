local CurrentLevel = require "necro.game.level.CurrentLevel"
local Damage       = require "necro.game.system.Damage"
local Descent      = require "necro.game.character.Descent"
local Entities     = require "system.game.Entities"
local Event        = require "necro.event.Event"
local GameDLC      = require "necro.game.data.resource.GameDLC"
local Inventory    = require "necro.game.item.Inventory"
local ItemPickup   = require "necro.game.item.ItemPickup"
local LowPercent   = require "necro.game.item.LowPercent"
local Object       = require "necro.game.object.Object"
local RNG          = require "necro.game.system.RNG"
local Utilities    = require "system.utils.Utilities"

local ItemHolders   = require "Lola.mod.ItemHolders"
local RevealedItems = require "Lola.mod.RevealedItems"

local function channel(player)
  if GameDLC.isSynchronyLoaded() and player.Sync_possessable then
    player = Entities.getEntityByID(player.Sync_possessable.possessor)
  end

  local ent = player.Lola_descentCollectItems.randomizer

  if ent == nil then
    ent = Entities.spawn("Lola_Randomizer")
    player.Lola_descentCollectItems.randomizer = ent
  end

  return ent
end

--#region objectInteract{interactableNegateLowPercent} → shrineDeath
Event.objectInteract.add("shrineDeath",
  { order = "lowPercent", filter = "interactableNegateLowPercent", sequence = -1 },
  function(ev)
    if CurrentLevel.isLobby() or ev.suppressed then return end

    local source = ev.interactor
    local target = ev.entity

    if source.Lola_forcedLowPercent and source.Lola_forcedLowPercent.active then
      Object.die {
        entity = source,
        killer = target,
        killerName = source.Lola_forcedLowPercent.killerName,
        damageType = Damage.Type.SELF_DESTRUCT
        --     1 BYPASS_ARMOR
        --     2 BYPASS_INVINCIBILITY
        --     4 BYPASS_DEATH_TRIGGERS
        --    64 SELF_DAMAGE
        -- 16384 BYPASS_IMMUNITY
      }

      ev.suppressed = true
    end
  end
)
--#endregion

--#region objectInteract{storage,interactableSelfDestruct} → chestRevealer
Event.objectInteract.add("chestRevealer",
  { order = "selfDestruct", filter = { "storage", "interactableSelfDestruct" }, sequence = -1 },
  function(ev)
    local source = ev.interactor
    local target = ev.entity

    -- print("Chest interact event")

    if CurrentLevel.isLobby() or ev.suppressed or not source.controllable or source.controllable.playerID == 0 then return end

    target.Lola_interactedBy.playerID = source.controllable.playerID

    -- print(target.name .. " interacted by player " .. target.Lola_interactedBy.playerID)
  end
)
--#endregion

--#region objectTakeDamge{storage} → crateAttacker
Event.objectTakeDamage.add("crateAttacker",
  { order = "armorMinimumDamage", filter = "storage", sequence = -1 },
  function(ev)
    local source = ev.attacker
    local target = ev.victim

    -- print("Damage event")

    if CurrentLevel.isLobby() or ev.suppressed or not source.controllable or source.controllable.playerID == 0 then return end

    target.Lola_interactedBy.playerID = source.controllable.playerID

    -- print(target.name .. " interacted by player " .. target.Lola_interactedBy.playerID)
  end
)
--#endregion

--#region objectTryCollectItem{Lola_forcedLowPercent} → itemDeath
Event.objectTryCollectItem.add("itemDeath",
  { order = "lowPercent", sequence = -1, filter = "Lola_forcedLowPercent" },
  function(ev)
    local source = ev.entity
    local target = ev.item

    -- The player should NOT die if:
    -- 1. We're in the lobby
    if CurrentLevel.isLobby()
        -- 2. The item pickup isn't successful
        or ev.result ~= ItemPickup.Result.SUCCESS
        -- 3. The player doesn't have forced low% active
        or not source.Lola_forcedLowPercent.active
        -- 4. The target item doesn't negate low%
        or not (target.itemNegateLowPercent
            and target.itemNegateLowPercent.active)
        -- 5. The player doesn't have a low% component
        or not source.lowPercent
        -- 6. The player's low% component explicitly allows the item
        or source.lowPercent.allowedItems[target.name]
        -- 7. The player's forced low% component explicitly allows the item
        or source.Lola_forcedLowPercent.allowedItems[target.name]
        -- 8. The player has held the item
        or ItemHolders.check(target, source)
    then return end

    ev.result = ItemPickup.Result.FAILURE
    ev.count = 0

    Object.die {
      entity = source,
      killer = target,
      killerName = source.Lola_forcedLowPercent.killerName,
      damageType = Damage.Type.SELF_DESTRUCT
      --     1 BYPASS_ARMOR
      --     2 BYPASS_INVINCIBILITY
      --     4 BYPASS_DEATH_TRIGGERS
      --    64 SELF_DAMAGE
      -- 16384 BYPASS_IMMUNITY
    }
  end
)
--#endregion

--#region objectDeath{Lola_descentCollectItems} → dontCollectOnDeath
Event.objectDeath.add("dontCollectOnDeath",
  { order = "dead", filter = "Lola_descentCollectItems", sequence = 1 },
  function(ev)
    ev.entity.Lola_descentCollectItems.active = false
  end
)
--#endregion

local function collectItems()
  -- Iterate all controllable entities with Lola_descentCollectItems.
  -- Disable any Lola_forcedLowPercent they may have, then collect
  -- their listed items, before re-enabling.
  for e in Entities.entitiesWithComponents { "Lola_descentCollectItems", "controllable" } do
    if e.Lola_descentCollectItems.active then
      local singleChoices = {}

      local holster = nil

      -- Search for single-choice groups first
      for i, itm in ipairs(RevealedItems.getRevealedItems(e)) do
        local sc = itm.item.singleChoice

        if sc == 0 then
          local list = singleChoices[sc] or {}
          table.insert(list, itm)
          singleChoices[sc] = list
        end
      end

      -- And for each group, pick an item to give.
      for k, v in Utilities.sortedPairs(singleChoices) do
        -- print("Single-choice:")
        -- print(v)
        local itm = RNG.choice(v, channel(e))

        for i, v2 in ipairs(v) do
          singleChoices[v2.id] = false
        end

        singleChoices[itm.id] = true
      end

      -- Search for holsters
      -- caching them saves some computations later
      for i, v in ipairs(Inventory.getItems(e)) do
        if v.itemHolster then
          holster = v
        end
      end

      if e.Lola_forcedLowPercent then
        e.Lola_forcedLowPercent.active = false
      end

      for i, itm in ipairs(RevealedItems.getRevealedItems(e)) do
        -- print(itm.name)
        -- print("Revealed by player #" .. itm.Lola_revealedBy.playerID)

        if itm.item.singleChoice == 0 or singleChoices[itm.id] then
          if itm.itemSlot then
            -- print("Holster swap initiated")
            local slot = itm.itemSlot.name
            if not Inventory.hasSlotCapacity(e, slot, 1)
                and holster
                and holster.itemHolster.slot == slot then
              Inventory.swapWithHolster(e, holster)
            end
          end

          Inventory.add(itm, e)
          LowPercent.negate(e, itm)
          -- print("Item added!")
        end
      end

      if e.Lola_forcedLowPercent then
        e.Lola_forcedLowPercent.active = true
      end
    else
      e.Lola_descentCollectItems.active = true
    end
  end
end

--#region objectDescentEnd{controllable} → descent
Event.objectDescentEnd.add("descent",
  { order = "collectItems", filter = "controllable", sequence = 1 },
  function(ev)
    if CurrentLevel.isLobby() then return end

    -- If not stairs, no collecting items.
    if ev.type ~= Descent.Type.STAIRS and ev.entity.Lola_descentCollectItems then
      ev.entity.Lola_descentCollectItems.active = false
    end

    -- Also, if this is the last one to exit, we should collect items and
    -- check Low%s.
    if ev.exitRequirementMet then
      collectItems()
    end
  end
)
--#endregion

--#region objectDeath{controllable} → deathCollectItems
Event.objectDeath.add("deathCollectItems", { order = "descent", filter = "controllable", sequence = 1 },
  function(ev)
    -- print(ev.entity.name .. " died.")
    -- print("Is exit requirement met? " .. tostring(Descent.isExitRequirementLogicallyMet()))
    if Descent.isExitRequirementLogicallyMet() then
      collectItems()
    end
  end
)
--#endregion
