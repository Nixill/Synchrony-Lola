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

local RevealedItems = require "NixsChars.mod.RevealedItems"

local function channel(player)
  if GameDLC.isSynchronyLoaded() and player.Sync_possessable then
    player = Entities.getEntityByID(player.Sync_possessable.possessor)
  end

  local ent = player.NixsChars_descentCollectItems.randomizer

  if ent == nil then
    ent = Entities.spawn("NixsChars_Randomizer")
    player.NixsChars_descentCollectItems.randomizer = ent
  end

  return ent
end

Event.objectInteract.add("lolaShrineDeath",
  { order = "lowPercent", filter = "interactableNegateLowPercent", sequence = -1 },
  function(ev)
    if CurrentLevel.isLobby() or ev.suppressed then return end

    local source = ev.interactor
    local target = ev.entity

    if source.NixsChars_forcedLowPercent and source.NixsChars_forcedLowPercent.active then
      Object.die {
        entity = source,
        killer = target,
        killerName = source.NixsChars_forcedLowPercent.killerName,
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

Event.objectInteract.add("lolaChestRevealer",
  { order = "selfDestruct", filter = { "storage", "interactableSelfDestruct" }, sequence = -1 },
  function(ev)
    local source = ev.interactor
    local target = ev.entity

    -- print("Chest interact event")

    if CurrentLevel.isLobby() or ev.suppressed or not source.controllable or source.controllable.playerID == 0 then return end

    target.NixsChars_interactedBy.playerID = source.controllable.playerID

    -- print(target.name .. " interacted by player " .. target.NixsChars_interactedBy.playerID)
  end
)

Event.objectTakeDamage.add("lolaCrateAttacker",
  { order = "armorMinimumDamage", filter = "storage", sequence = -1 },
  function(ev)
    local source = ev.attacker
    local target = ev.victim

    -- print("Damage event")

    if CurrentLevel.isLobby() or ev.suppressed or not source.controllable or source.controllable.playerID == 0 then return end

    target.NixsChars_interactedBy.playerID = source.controllable.playerID

    -- print(target.name .. " interacted by player " .. target.NixsChars_interactedBy.playerID)
  end
)

Event.objectTryCollectItem.add("lolaItemDeath",
  { order = "lowPercent", sequence = -1, filter = "NixsChars_forcedLowPercent" },
  function(ev)
    local source = ev.entity
    local target = ev.item

    if CurrentLevel.isLobby()
        or ev.result ~= ItemPickup.Result.SUCCESS
        or not (source.NixsChars_forcedLowPercent.active
            and target.itemNegateLowPercent
            and target.itemNegateLowPercent.active)
    then return end

    ev.result = ItemPickup.Result.FAILURE
    ev.count = 0

    Object.die {
      entity = source,
      killer = target,
      killerName = source.NixsChars_forcedLowPercent.killerName,
      damageType = Damage.Type.SELF_DESTRUCT
      --     1 BYPASS_ARMOR
      --     2 BYPASS_INVINCIBILITY
      --     4 BYPASS_DEATH_TRIGGERS
      --    64 SELF_DAMAGE
      -- 16384 BYPASS_IMMUNITY
    }
  end
)

Event.objectDeath.add("lolaDoesntCollectOnDeath",
  { order = "dead", filter = "NixsChars_descentCollectItems", sequence = 1 },
  function(ev)
    ev.entity.NixsChars_descentCollectItems.active = false
  end
)

Event.objectDescentEnd.add("lolaDescent",
  { order = "collectItems", filter = "controllable", sequence = 1 },
  function(ev)
    if CurrentLevel.isLobby() then return end

    -- If not stairs, no collecting items.
    if ev.type ~= Descent.Type.STAIRS and ev.entity.NixsChars_descentCollectItems then
      ev.entity.NixsChars_descentCollectItems.active = false
    end

    -- Also, if this is the last one to exit, we should collect items and
    -- check Low%s.
    if ev.exitRequirementMet then
      -- Iterate all controllable entities with
      -- NixsChars_descentCollectItems. Disable any
      -- NixsChars_forcedLowPercent they may have, then collect their
      -- listed items, before re-enabling.
      for e in Entities.entitiesWithComponents { "NixsChars_descentCollectItems", "controllable" } do
        local singleChoices = {}

        if e.NixsChars_descentCollectItems.active then
          local holster = nil

          -- Search for holsters
          -- caching them saves some computations later
          for i, v in ipairs(Inventory.getItems(e)) do
            if v.itemHolster then
              holster = v
            end
          end

          if e.NixsChars_forcedLowPercent then
            e.NixsChars_forcedLowPercent.active = false
          end

          for i, itm in ipairs(RevealedItems.getRevealedItems(e)) do
            -- print(itm.name)
            -- print("Revealed by player #" .. itm.NixsChars_revealedBy.playerID)

            local sc = itm.item.singleChoice
            if sc == 0 then
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
            else
              -- print("Single-choice " .. sc .. " found, adding there!")
              local list = singleChoices[sc] or {}
              table.insert(list, itm)
              singleChoices[sc] = list
            end
          end

          for k, v in Utilities.sortedPairs(singleChoices) do
            -- print("Single-choice:")
            -- print(v)
            local itm = RNG.choice(v, channel(e))

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
          end

          if e.NixsChars_forcedLowPercent then
            e.NixsChars_forcedLowPercent.active = true
          end
        else
          e.NixsChars_descentCollectItems.active = true
        end
      end
    end
  end
)
