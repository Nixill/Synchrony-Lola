local Action         = require "necro.game.system.Action"
local CurrentLevel   = require "necro.game.level.CurrentLevel"
local Damage         = require "necro.game.system.Damage"
local Entities       = require "system.game.Entities"
local Event          = require "necro.event.Event"
local Flyaway        = require "necro.game.system.Flyaway"
local ItemStorage    = require "necro.game.item.ItemStorage"
local LevelExit      = require "necro.game.tile.LevelExit"
local Move           = require "necro.game.system.Move"
local Object         = require "necro.game.object.Object"
local PriceTag       = require "necro.game.item.PriceTag"
local SpellTargeting = require "necro.game.spell.SpellTargeting"

local RevealedItems = require "Lola.mod.RevealedItems"

local LoSettings = require "Lola.Settings"

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

  local miss = true
  local cantAfford = false
  local enemy = false

  -- What's the target tile?
  local x = nil
  local y = nil

  -- Iterate through any items on the tile to see what we can afford.
  for itm in SpellTargeting.targetsWithComponent(ev, "Lola_revealedBy") do
    miss = false

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

      if priceTag then
        if PriceTag.check(ev.caster, priceTag).affordable then
          PriceTag.pay(ev.caster, priceTag)
          PriceTag.remove(itm)
          table.insert(packageContents, itm)
          chestColor = chestColor or getChestColor(itm)
        else
          cantAfford = true
        end
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

  local pType = (greater and (#packageContents > 0) and "Chest" .. (chestColor or "Red")) or "Crate"

  if greater and LoSettings.get("silly.packageEnemies") then
    for ent in SpellTargeting.targetsWithComponent(ev, "enemy") do
      -- Make sure it's on the same tile (or a tile hasn't been set)
      if x then
        if ent.position.x ~= x or ent.position.y ~= y then goto continue end
      else
        x = ent.position.x
        y = ent.position.y
      end

      -- -- Is it a boss or miniboss?
      -- if ent.boss or (ent.stairLocker and ent.stairLocker.level == LevelExit.StairLock.MINIBOSS) then
      --   goto continue
      -- end

      if ent.boss then
        ent.boss.defeated = true
      end

      -- Sanity check, is it a current player?
      if ent.controllable and ent.controllable.playerID ~= 0 then
        goto continue
      end

      table.insert(packageContents, ent)

      ::continue::
    end
  end

  -- Get the target position (if not already set, it's the tile in front
  -- of the player).
  if not x then
    x = ev.tiles[1][1]
    y = ev.tiles[1][2]
  end

  local dx = x - ev.caster.position.x
  local dy = y - ev.caster.position.y
  local dir = Action.move(dx, dy)

  -- Also, let's knockback any knockbackable entities on that tile.
  for target in SpellTargeting.targetsWithComponent(ev, "knockbackable") do
    if target.position.x == x and target.position.y == y then
      Damage.knockback(target, dir, 1, Move.Type.KNOCKBACK, target.knockbackable.beatDelay)
    end
  end

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

  local text
  local sfp = ev.spell.Lola_spellcastFlyawayPackage

  if miss then
    text = sfp.noTargets
  elseif cantAfford then
    text = sfp.cantAfford
  else
    text = sfp.baseText
  end

  Flyaway.create {
    text = text,
    entity = ev.caster
  }
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
