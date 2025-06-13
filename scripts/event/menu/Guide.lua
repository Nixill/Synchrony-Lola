local Entities     = require "system.game.Entities"
local Event        = require "necro.event.Event"
local Menu         = require "necro.menu.Menu"
local PlayerList   = require "necro.client.PlayerList"
local Settings     = require "necro.config.Settings"
local SettingsMenu = require "necro.menu.settings.SettingsMenu"
local TextFormat   = require "necro.config.i18n.TextFormat"
local UI           = require "necro.render.UI"

local LolaRender = require "Lola.event.Render"

ShowInPauseMenu = Settings.user.bool {
  name = "Show guide in pause menu",
  desc = "Whether or not the \"Guide to Lola\" should be shown in the pause menu.",
  order = 4,
  id = "showGuideInPauseMenu",
  default = true,
  setter = Menu.updateAll
}

ShowNow = Settings.user.action {
  name = "Show guide",
  desc = "Show the Guide to Lola now",
  order = 3,
  id = "showGuideNow",
  action = function()
    Menu.open("Lola_guide", {
      source = "settings"
    })
  end
}

local function localPlayerIsLola()
  local localChar = PlayerList.getCharacter(PlayerList.getLocalPlayerID())
  if localChar then return localChar.name == "Lola_Lola" end

  if (#Entities.getEntitiesByType("Lola_Lola") >= 1) then return true end
end

Event.menu.override("pause", 1, function(func, ev)
  -- Run regular menu event first
  func(ev)

  if ShowInPauseMenu and localPlayerIsLola() then
    table.insert(ev.menu.entries, 2, {
      id = "Lola_help",
      label = "Guide to Lola",
      action = function()
        Menu.open("Lola_guide", {
          source = "pause"
        })
      end
    })
  end
end)

local function coloredParticle(color)
  return TextFormat.color("E3", color)
  -- return TextFormat.icon(PaletteSwapFilter.replaceSingleColor("mods/Lola/gfx/white_particle.png", 0xffffffff, color), 6)
end

Event.menu.add("guide", "Lola_guide", function(ev)
  local menu = {}
  menu.label = "Lola guide"

  local entries = {
    {
      label = "Items in " ..
        coloredParticle(LolaRender.safeItemColor()) ..
        " this color are safe. Lola can directly pick up items outlined in this color ONLY.",
      font = UI.Font.SMALL,
      height = 6,
      color = 0xffffffff
      -- action = function() end
    },
    {
      label = "Items in " ..
        coloredParticle(LolaRender.dangerItemColor()) ..
        " this color are unsafe. Try Packaging them and reopening the Package!",
      font = UI.Font.SMALL,
      height = 6,
      color = 0xffffffff
    },
    {
      label = "Items in " ..
        coloredParticle(LolaRender.claimedItemColor()) ..
        " this color are claimed. Lola will receive them upon going down the stairs (but not from a trapdoor!).",
      font = UI.Font.SMALL,
      height = 6,
      color = 0xffffffff
    },
    {
      label = "Items in " ..
        coloredParticle(LolaRender.chanceItemColor()) ..
        " this color are claimed, but Lola will only receive one of them. If you Package one, the others will disappear.",
      font = UI.Font.SMALL,
      height = 6,
      color = 0xffffffff
    },
    {
      label = "Shrines in " ..
        coloredParticle(LolaRender.dangerShrineColor()) ..
        " this color are unsafe and unusable, but not umbombable...",
      font = UI.Font.SMALL,
      height = 6,
      color = 0xffffffff
    },
    {
      label = "If you're in multiplayer, " ..
        coloredParticle(LolaRender.otherClaimedItemColor()) ..
        " this color means another player has claimed the item.",
      font = UI.Font.SMALL,
      height = 6,
      color = 0xffffffff
    },
    {
      label = "",
      font = UI.Font.SMALL,
      height = 6
    },
    {
      label = "Change these colors...",
      action = function()
        if (ev.arg.source == "settings") then
          Menu.close()
        end
        SettingsMenu.open({
          layer = Settings.Layer.USER,
          prefix = "mod.Lola.colors"
        })
      end
    },
    {
      label = "",
      font = UI.Font.SMALL,
      height = 6
    },
    {
      label = "Misc tips:",
      font = UI.Font.SMALL,
      height = 6
    },
    {
      label = "- Items will be received in the order they were unpackaged. Later items override earlier items.",
      font = UI.Font.SMALL,
      height = 6
    },
    {
      label =
      "- Containers broken by environmental damage will reward the last player that interacted with the container.",
      font = UI.Font.SMALL,
      height = 6
    },
    {
      label = "",
      font = UI.Font.SMALL,
      height = 6
    },
    SettingsMenu.createEntry("mod.Lola.showGuideInPauseMenu"),
    {
      label = "Back",
      action = Menu.close
    }
  }

  menu.entries = entries
  ev.menu = menu
end)