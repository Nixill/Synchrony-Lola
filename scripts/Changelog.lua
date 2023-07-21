local Menu     = require "necro.menu.Menu"
local Settings = require "necro.config.Settings"

Settings.user.action {
  name = "View Lola changelog",
  desc = "View changelogs for Lola mod",
  id = "changelog",
  order = 0,
  autoRegister = true,
  action = function()
    Menu.open("changeLog", {
      fileNames = { "1.2.0.md", "1.1.x.md" },
      basePath = "mods/Lola/changelogs/",
      index = 1
    })
  end
}