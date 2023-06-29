local CurrentLevel   = require "necro.game.level.CurrentLevel"
local Entities       = require "system.game.Entities"
local Event          = require "necro.event.Event"
local ItemStorage    = require "necro.game.item.ItemStorage"
local Object         = require "necro.game.object.Object"
local PriceTag       = require "necro.game.item.PriceTag"
local SpellTargeting = require "necro.game.spell.SpellTargeting"

local RevealedItems = require "Lola.mod.RevealedItems"

local function getChestColor(itm)
  if itm.itemPoolRedChest then return "Red"
  elseif itm.itemPoolBlackChest then return "Black"
  elseif itm.itemPoolPurpleChest then return "Purple"
  end
end

local function packageItems(ev, greater)
  if CurrentLevel.isLobby() then return end

  local package = nil
  local packageContents = {}
  local chestColor = nil

  -- What's the target tile?
  local x = nil
  local y = nil

  -- Iterate through any items on the tile to see what we can afford.
  for itm in SpellTargeting.targetsWithComponent(ev, "Lola_revealedBy") do
    -- Make sure it's on the same tile (or a tile hasn't been set)
    if x then
      if itm.position.x ~= x or itm.position.y ~= y then goto continue end
    else
      x = itm.position.x
      y = itm.position.y
    end

    -- Is there a price tag?
    if itm.sale and itm.sale.priceTag ~= 0 then
      local priceTag = Entities.getEntityByID(itm.sale.priceTag)

      if priceTag and PriceTag.check(ev.caster, priceTag).affordable then
        PriceTag.pay(ev.caster, priceTag)
        PriceTag.remove(itm)
        table.insert(packageContents, itm)
        chestColor = chestColor or getChestColor(itm)
      end
    else
      table.insert(packageContents, itm)
      chestColor = chestColor or getChestColor(itm)
    end

    -- Is it single choice?
    if itm.item and itm.item.singleChoice ~= 0 then
      -- Find other single choice items and despawn them
      for other in Entities.entitiesWithComponents { "item" } do
        if other.item.singleChoice == itm.item.singleChoice and other.id ~= itm.id then
          Object.delete(other)
        end
      end
    end

    ::continue::
  end

  local pType = (greater and "Chest" .. (chestColor or "Red")) or "Crate"

  if #packageContents > 0 then
    package = Object.spawn(pType, x, y)
    ItemStorage.clear(package)
    for i, itm in ipairs(packageContents) do
      ItemStorage.store(itm, package)
      RevealedItems.unmark(itm)
    end
    -- print(itm.name .. "#" .. itm.id)
  else
    local tile = ev.tiles[1]
    package = Object.spawn("Crate", tile[1], tile[2])
    ItemStorage.clear(package)
  end
end

Event.spellcast.add("crateItem",
  { order = "convertItems", filter = "Lola_spellcastPackageItems", sequence = 1 },
  function(ev)
    -- print("Lesser Package")
    packageItems(ev, false)
  end
)

Event.spellcast.add("chestItem",
  { order = "convertItems", filter = "Lola_spellcastPackageItemsGreater", sequence = 2 },
  function(ev)
    -- print("Greater Package")
    packageItems(ev, true)
  end
)
