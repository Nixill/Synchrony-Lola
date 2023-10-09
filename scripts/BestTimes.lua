local Event    = require "necro.event.Event"
local Menu     = require "necro.menu.Menu"
local Settings = require "necro.config.Settings"

------------------
-- Data Storage --
--#region---------

TimesTable = Settings.user.table {
  id = "timesTable",
  visibility = Settings.Visibility.RESTRICTED,
  default = {}
}

--#endregion Data Storage

--------------
-- Settings --
--#region-----

PBGroup = Settings.group {
  name = "Best times (Lola)",
  desc = "View or toggle saving best times",
  id = "pb",
  order = 2
}

SaveTimes = Settings.user.bool {
  name = "Save times (Lola)",
  desc = "Should your best times be tracked by the mod?",
  id = "pb.save",
  order = 0,
  default = true
}

ViewTimes = Settings.user.action {
  name = "View times (Lola)",
  desc = "View your best times in the Lola mod",
  id = "pb.view",
  order = 1,
  action = function()
    Menu.open("Lola_bestTimes")
  end
}

--#endregion Settings

---------------------
-- Best Times Menu --
--#region------------

Event.menu.add("bestTimes", "Lola_bestTimes", function(ev)
  local entries = {}

  local rules = {
    { id = "Default", name = "Default rules" },
    { id = "Classic", name = "Classic rules" },
    { id = "Lute",    name = "Lute mode" }
  }
  local challenges = {
    { id = "",                 name = "" },
    { id = "NoRejects",        name = ", No rejects" },
    { id = "Mystery",          name = ", Mystery mode" },
    { id = "NoRejectsMystery", name = ", No rejects, Mystery mode" }
  }

  for _, c in ipairs(challenges) do
    for _, r in ipairs(rules) do

    end
  end
end)

--#endregion Best Times Menu