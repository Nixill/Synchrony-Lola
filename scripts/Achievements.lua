local Event              = require "necro.event.Event"
local Fallback           = require "system.utils.Fallback"
local LeaderboardContext = require "necro.client.leaderboard.LeaderboardContext"
local Snapshot           = require "necro.game.system.Snapshot"
local Utilities          = require "system.utils.Utilities"

local hasIGA, IGA = pcall(require, "InGameAchievements.api")

if not hasIGA then
  return Fallback.create()
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

---------------
-- SNAPSHOTS --
--#region------

ShownItems = Snapshot.runVariable({})

--#endregion SNAPSHOTS

--------------------
-- EVENT HANDLERS --
--#region-----------

Event.runComplete.add("unlockLolaAchievement", { order = "leaderboardSubmission", sequence = 1 }, function(ev)
  local ctx = LeaderboardContext.getFinalRunContext()

  if
    not ctx.completion.victory -- Only wins count
    or #ctx.characters > 1 or ctx.characters[1] ~= "Lola_Lola" -- Only solo Lola runs count
    or #ctx.customRules > 1 -- Runs don't count if rules change midway
    or ctx.gameMode ~= "AllZones" -- Only All Zones runs count
    or ctx.maximumPlayers > 1 -- Only singleplayer runs count
    or #ctx.mods > 1 -- Runs don't count if mods change midway
  then
    return
  end

  local rules = ctx.customRules[1]

  if
    rules["gameplay.modifiers.dancepad"] -- Dance Pad mode doesn't count
    or rules["gameplay.modifiers.phasing"] -- Phasing mode doesn't count
    or rules["gameplay.modifiers.rhythm"] == "NO_BEAT" -- No beat mode doesn't count
  then
    return
  end

  -- We may be eligible for an achievement.
  local defaultRulesMet = (
    check(rules, "gameplay.package", "INNATE", true)
    and check(rules, "gameplay.bombs", 1, true)
    and check(rules, "gameplay.storageVision", true, true)
    and check(rules, "gameplay.glass", true, true)
    and check(rules, "gameplay.shrine", true, true)
    and check(rules, "gameplay.transaction", true, true)
    -- multiplayer.death is ignored; this achievement may be earned with
    -- either value. (That setting has no effect on singleplayer runs,
    -- which are a prerequisite for achievements anyway.)
    -- silly.packageEnemies is ignored; this achievement may be earned
    -- with either value.
    and check(rules, "silly.luteMode", false, true)
  )

  if defaultRulesMet then
    defaultRulesAch.unlock()
  end

  local classicRulesMet = (
    check(rules, "gameplay.package", "NONE")
    and check(rules, "gameplay.bombs", 3)
    and check(rules, "gameplay.storageVision", false)
    and check(rules, "gameplay.glass", false)
    and check(rules, "gameplay.shrine", false)
    and check(rules, "gameplay.transaction", false)
    -- multiplayer.death is ignored; this achievement may be earned with
    -- either value. (That setting has no effect on singleplayer runs,
    -- which are a prerequisite for achievements anyway.)
    and check(rules, "silly.packageEnemies", false)
    and check(rules, "silly.luteMode", false, true)
  )

  if classicRulesMet then
    classicRulesAch.unlock()
  end

  if defaultRulesMet or classicRulesMet then
    for k, v in pairs(ShownItems) do
      if v == false then
        goto noRejectsFail
      end
    end

    noRejectsAch.unlock()
  end

  ::noRejectsFail::
end)

--#endregion EVENT HANDLERS

-- defaultRulesAch.revoke()
-- classicRulesAch.revoke()
-- noRejectsAch.revoke()

------------
-- MODULE --
--#region---

local mdl = {}

function mdl.trackItem(id)
  ShownItems[id] = false
end

function mdl.collectItem(id)
  ShownItems[id] = true
end

function mdl.untrackItem(id)
  ShownItems[id] = nil
end

return mdl

---#endregion MODULE