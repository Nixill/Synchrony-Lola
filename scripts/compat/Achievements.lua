local Event              = require "necro.event.Event"
local LeaderboardContext = require "necro.client.leaderboard.LeaderboardContext"

local RuleCheck = require "Lola.mod.RuleCheck"
local ShownItems = require "Lola.mod.ShownItems"

local hasIGA, IGA = pcall(require, "InGameAchievements.api")

if not hasIGA then
  return
end

-----------------------------
-- ACHIEVEMENT DEFINITIONS --
--#region--------------------

local defaultRulesAch = IGA.register {
  id = "InGameAchievements_AUTOGENALLZONES_Lola_Lola", -- For backwards compatibility with existing unlocks
  version = 1,
  friendlyName = "Lola the Lucky",
  desc = "Clear a solo Lola all zones run with Default Rules!",
  descShort = "Solo Lola Default Rules clear!",
  icon = "mods/Lola/gfx/achievement_default_rules.png",
  sortOrder = IGA.sortOrder.ALL_ZONES
}

local classicRulesAch = IGA.register {
  id = "Lola_ClassicRulesClear",
  version = 1,
  friendlyName = "Lola the Persistent",
  desc = "Clear a solo Lola all zones run with Classic Rules!\n" ..
    "(Pause > Customize > Custom rules > Mod options > Lola > Use a preset > Classic Rules)",
  descShort = "Solo Lola Classic Rules clear!",
  icon = "mods/Lola/gfx/achievement_classic_rules.png",
  sortOrder = IGA.sortOrder.ALL_ZONES_SPECIAL
}

local noRejectsAch = IGA.register {
  id = "Lola_NoRejectsClear",
  version = 1,
  friendlyName = "Lola the Adaptible",
  desc = "Clear a solo Lola run using either preset ruleset, without rejecting items!\n" ..
    "(Do not destroy or repackage claimed items, or skip collection with trapdoors.)",
  descShort = "Lola Clear without rejecting items!",
  icon = "mods/Lola/gfx/achievement_adaptible.png",
  sortOrder = IGA.sortOrder.ALL_ZONES_SPECIAL
}

--#endregion ACHIEVEMENT DEFINITIONS

---------------
-- FUNCTIONS --
--#region------

local function check(rules, rule, value, nillable)
  local val = rules["mod.Lola." .. rule]
  if rules["mod.Lola." .. rule] == value then
    return true
  elseif nillable and rules["mod.Lola." .. rule] == nil then
    return true
  end
  return false
end

--#endregion FUNCTIONS

--------------------
-- EVENT HANDLERS --
--#region-----------

Event.runComplete.add("unlockLolaAchievement", { order = "leaderboardSubmission", sequence = 1 }, function(ev)
  local followedRules = RuleCheck.getFollowedRules()

  if followedRules.Default then
    defaultRulesAch.unlock()
  end

  if followedRules.Classic then
    classicRulesAch.unlock()
  end

  if (followedRules.Default or followedRules.Classic) and followedRules.NoRejects then
    noRejectsAch.unlock()
  end
end)

--#endregion EVENT HANDLERS

-- defaultRulesAch.revoke()
-- classicRulesAch.revoke()
-- noRejectsAch.revoke()