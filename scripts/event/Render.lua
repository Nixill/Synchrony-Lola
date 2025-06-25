local Color         = require "system.utils.Color"
local CurrentLevel  = require "necro.game.level.CurrentLevel"
local Entities      = require "system.game.Entities"
local Event         = require "necro.event.Event"
local Focus         = require "necro.game.character.Focus"
local OutlineFilter = require "necro.render.filter.OutlineFilter"
local Player        = require "necro.game.character.Player"
local PlayerList    = require "necro.client.PlayerList"
local Render        = require "necro.render.Render"
local Settings      = require "necro.config.Settings"
local Utilities     = require "system.utils.Utilities"

local ItemHolders = require "Lola.mod.ItemHolders"

local NELoaded, NecroEdit = pcall(require, "NecroEdit.NecroEdit")

local module = {}

ColorGroup = Settings.user.group {
  name = "Outline colors",
  desc = "Modify color outlines for Lola",
  order = 0,
  id = "colors"
}

SafeItemColor = Settings.user.color {
  name = "Safe items",
  desc = "Items Lola can safely pick up",
  default = Color.rgba(43, 66, 180, 255),
  order = 0,
  id = "colors.safe"
}

function module.safeItemColor() return SafeItemColor end

ClaimedItemColor = Settings.user.color {
  name = "Claimed items",
  desc = "Items Lola has claimed",
  default = Color.rgba(66, 180, 43, 255),
  order = 1,
  id = "colors.claimed"
}

function module.claimedItemColor() return ClaimedItemColor end

OtherClaimedItemColor = Settings.user.color {
  name = "Other players' claimed items",
  desc = "Items another Lola has claimed",
  default = Color.rgba(150, 150, 150, 255),
  order = 2,
  id = "colors.other"
}

function module.otherClaimedItemColor() return OtherClaimedItemColor end

ChanceItemColor = Settings.user.color {
  name = "Chance items",
  desc = "Items Lola has claimed (when only one of a group)",
  default = Color.rgba(180, 157, 43, 255),
  order = 3,
  id = "colors.chance"
}

function module.chanceItemColor() return ChanceItemColor end

DangerItemColor = Settings.user.color {
  name = "Dangerous items",
  desc = "Unclaimed items that will kill Lola upon contact",
  default = Color.rgba(180, 43, 66, 255),
  order = 4,
  id = "colors.danger"
}

function module.dangerItemColor() return DangerItemColor end

DangerShrineColor = Settings.user.color {
  name = "Dangerous shrines",
  desc = "Shrines that will kill Lola upon contact",
  default = Color.rgba(180, 43, 66, 255),
  order = 5,
  id = "colors.dangerShrine"
}

function module.dangerShrineColor() return DangerShrineColor end

Event.render.add("outlineClaimedItems", { order = "outlines", sequence = 1 },
  function(ev)
    if CurrentLevel.isLobby() or (NELoaded and NecroEdit.isActive()) then return end

    local focus = Focus.getAll()
    local focusPIDs = {}

    -- Get focused players and their lowPercentAllowedItems
    local pids = {}
    local itms = {}
    local redBlue = false

    -- Iterate all focused players
    for i, p in ipairs(focus) do
      -- If that player is forced to be low% then...
      if p.Lola_forcedLowPercent and p.Lola_forcedLowPercent.active then
        -- ... we can use blue rendering later. (This doesn't apply if no
        -- focused player is forced low%.)
        redBlue = true

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

      if redBlue and itms[item.name] then
        color = SafeItemColor
      elseif redBlue and ItemHolders.checkAllPIDs(item, pids) then
        color = SafeItemColor
      elseif item.Lola_revealedBy then
        if not (item.itemNegateLowPercent and item.itemNegateLowPercent.active) then
          color = SafeItemColor
        elseif pids[item.Lola_revealedBy.playerID] then
          if item.item.singleChoice == 0 then
            color = ClaimedItemColor
          else
            color = ChanceItemColor
          end
        elseif item.Lola_revealedBy.playerID ~= 0
          and Player.getPlayerEntity(item.Lola_revealedBy.playerID).Lola_descentCollectItems then
          color = OtherClaimedItemColor
        elseif redBlue then
          color = DangerItemColor
        end
      elseif not item.itemCurrency then
        color = SafeItemColor
      end

      if color ~= nil then
        local visual = OutlineFilter.getEntityVisual(item)
        visual.color = color
        visual.z = visual.z - 1
        Render.getBuffer(Render.Buffer.CUSTOM).draw(visual)
      end

      ::continue::
    end

    for shrine in Entities.entitiesWithComponents { "interactableNegateLowPercent" } do
      local color

      -- Only outline shrines that are actually on the floor and revealed.
      if not shrine.gameObject.tangible
        or not shrine.visibility.fullyVisible then
        goto continue2
      end

      if redBlue then
        color = DangerShrineColor
      end

      if color ~= nil then
        local visual = OutlineFilter.getEntityVisual(shrine)
        visual.color = color
        visual.z = visual.z - 1
        Render.getBuffer(Render.Buffer.CUSTOM).draw(visual)
      end

      ::continue2::
    end
  end
)

return module