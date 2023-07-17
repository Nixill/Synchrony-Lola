local Event   = require "necro.event.Event"
local ItemBan = require "necro.game.item.ItemBan"

local LoEnum     = require "Lola.Enum"
local LoSettings = require "Lola.Settings"

Event.entitySchemaLoadEntity.add("addComponents", { order = "overrides" }, function(ev)
  local entity = ev.entity

  if entity.itemNegateLowPercent then
    entity.Lola_revealedBy = {}
    entity.Lola_holders = {}
  end

  if entity.storage then
    entity.Lola_interactedBy = {}
  end
end)

Event.entitySchemaLoadNamedEntity.add("settings", { key = "Lola_Lola" }, function(ev)
  local lola = ev.entity

  -- Let's handle the starting inventory first
  local inv = lola.initialInventory.items

  -- Number of starting bombs?
  local bombs = LoSettings.get("gameplay.bombs")

  if bombs == -1 then
    table.insert(inv, "BombInfinity")
  else
    if bombs >= 3 then
      table.insert(inv, "Bomb3")
      bombs = bombs - 3
    end

    while bombs > 0 do
      table.insert(inv, "Bomb")
      bombs = bombs - 1
    end
  end

  -- Package spell?
  local package = LoSettings.get("gameplay.package")

  if package ~= LoEnum.PackageSetting.NONE then
    table.insert(inv, "Lola_SpellPackage")
    if package == LoEnum.PackageSetting.INNATE then
      lola.inventoryBannedItems.components.itemBanInnateSpell = ItemBan.Type.LOCK
    end
  end

  -- Lute mode?
  if LoSettings.get("silly.luteMode") then
    table.insert(inv, "WeaponGoldenLute")
    lola.inventoryBannedItems.components.itemBanWeaponlocked = ItemBan.Type.FULL
    lola.inventoryBannedItems.components.itemBanNoDamage = ItemBan.Type.GENERATION
    lola.inventoryCursedSlots = { slots = { weapon = true } }
  else
    table.insert(inv, "WeaponDagger")
  end

  -- Storage vision?
  if not LoSettings.get("gameplay.storageVision") then
    lola.forceNonSilhouetteVision = false
    lola.forceObjectVision = false
    lola.minimapVision = false
  end
end)