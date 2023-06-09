local CurrentLevel = require "necro.game.level.CurrentLevel"
local Damage       = require "necro.game.system.Damage"
local Descent      = require "necro.game.character.Descent"
local Entities     = require "system.game.Entities"
local Event        = require "necro.event.Event"
local GameDLC      = require "necro.game.data.resource.GameDLC"
local Inventory    = require "necro.game.item.Inventory"
local ItemPickup   = require "necro.game.item.ItemPickup"
local Object       = require "necro.game.object.Object"

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

    print("Chest interact event")

    if CurrentLevel.isLobby() or ev.suppressed or not source.controllable or source.controllable.playerID == 0 then return end

    target.NixsChars_interactedBy.playerID = source.controllable.playerID

    print(target.name .. " interacted by player " .. target.NixsChars_interactedBy.playerID)
  end
)

Event.objectTakeDamage.add("lolaCrateAttacker",
  { order = "armorMinimumDamage", filter = "storage", sequence = -1 },
  function(ev)
    local source = ev.attacker
    local target = ev.victim

    print("Damage event")

    if CurrentLevel.isLobby() or ev.suppressed or not source.controllable or source.controllable.playerID == 0 then return end

    target.NixsChars_interactedBy.playerID = source.controllable.playerID

    print(target.name .. " interacted by player " .. target.NixsChars_interactedBy.playerID)
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

Event.objectDescentEnd.add("lolaPitfall",
  { order = "collectItems", filter = "NixsChars_descentCollectItems", sequence = 1 },
  function(ev)
    if ev.type ~= Descent.Type.STAIRS then
      ev.entity.NixsChars_descentCollectItems.active = false
    end
  end
)

Event.storageDetach.add("lolaItemTracker", { order = "item", sequence = 1 },
  function(ev)
    local container = ev.container
    local entity = ev.entity

    print("Storage detach event")

    if ev.suppressed or (not entity.itemNegateLowPercent) or container.NixsChars_interactedBy.playerID == 0 then return end

    entity.NixsChars_revealedBy.playerID = container.NixsChars_interactedBy.playerID

    print(entity.name .. " revealed by player " .. container.NixsChars_interactedBy.playerID)
  end
)
