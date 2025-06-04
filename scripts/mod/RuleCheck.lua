local Event              = require "necro.event.Event"
local LeaderboardContext = require "necro.client.leaderboard.LeaderboardContext"

local ShownItems = require "Lola.mod.ShownItems"

local mod = {}

local function check(rules, rule, value, nillable)
  local val = rules["mod.Lola." .. rule]
  if rules["mod.Lola." .. rule] == value then
    return true
  elseif nillable and rules["mod.Lola." .. rule] == nil then
    return true
  end
  return false
end

-- Returns which rules were followed for the purposes of PBs and
-- achievements. The format is as follows. An empty table can be returned
-- if no rules were followed.
-- {
--   Any = true, -- if any of Default, Classic, or Lute are true.
--   Default = true, -- if the Default Rules were followed.
--   Classic = true, -- if the Classic Rules were followed.
--   Lute = true, -- if the Lute Mode Rules were followed.
--   NoRejects = true, -- if no items were rejected during the run.
--   Mystery = true, -- if Mystery Mode was enabled during the run.
--   NoBeat = true -- if No Beat Mode was enabled during the run.
--     -- Achievements may be earned with or without No Beat Mode, but
--     -- times are tracked separately.
-- }
function mod.getFollowedRules()
  print("Rule check!")
  print("Leaderboard context follows:")
  local ctx = LeaderboardContext.getFinalRunContext()
  local out = {}
  print(ctx)

  if
    not ctx.completion.victory -- Only wins count
    or #ctx.characters > 1 or ctx.characters[1] ~= "Lola_Lola" -- Only solo Lola runs count
    or #ctx.customRules > 1 -- Runs don't count if rules change midway
    or (ctx.gameMode ~= "AllZones" and ctx.gameMode ~= "WeeklyChallenge") -- Only All Zones or Weekly Challenge runs count
    or ctx.maximumPlayers > 1 -- Only singleplayer runs count
    or #ctx.mods > 1 -- Runs don't count if mods change midway
  then
    return {}
  end

  local rules = ctx.customRules[1]

  if
    rules["gameplay.modifiers.dancepad"] -- Dance Pad mode doesn't count
    or rules["gameplay.modifiers.phasing"] -- Phasing mode doesn't count
  then
    return {}
  end

  out.Default = (
    check(rules, "gameplay.package", "INNATE", true)
    and check(rules, "gameplay.bombs", 1, true)
    and check(rules, "gameplay.storageVision", true, true)
    and check(rules, "gameplay.glass", true, true)
    and check(rules, "gameplay.shrine", true, true)
    and check(rules, "gameplay.transaction", true, true)
    -- gameplay.bounce is ignored; this achievement may be earned with
    -- either value, for leniency purposes.
    and check(rules, "gameplay.autoInteract", true, true)
    -- multiplayer.death is ignored; this achievement may be earned with
    -- either value. (That setting has no effect on singleplayer runs,
    -- which are a prerequisite for achievements anyway.)
    -- silly.packageEnemies is ignored; this achievement may be earned
    -- with either value.
    and check(rules, "silly.luteMode", false, true)
  )

  out.Classic = (
    check(rules, "gameplay.package", "NONE")
    and check(rules, "gameplay.bombs", 3)
    and check(rules, "gameplay.storageVision", false)
    and check(rules, "gameplay.glass", false)
    and check(rules, "gameplay.shrine", false)
    and check(rules, "gameplay.transaction", false)
    and check(rules, "gameplay.bounce", false, true)
    -- gameplay.autoInteract is ignored; this achievement may be earned
    -- with either value. (That setting has no effect when Package Spell
    -- does not exist.)
    -- multiplayer.death is ignored; this achievement may be earned with
    -- either value. (That setting has no effect on singleplayer runs,
    -- which are a prerequisite for achievements anyway.)
    -- silly.packageEnemies is ignored; this achievement may be earned
    -- with either value. (That setting has no effect when Package Spell
    -- does not exist.)
    and check(rules, "silly.luteMode", false, true)
  )

  out.Lute = (
    check(rules, "gameplay.package", "INNATE", true)
    and check(rules, "gameplay.bombs", 1, true)
    and check(rules, "gameplay.storageVision", true, true)
    and check(rules, "gameplay.glass", true, true)
    and check(rules, "gameplay.shrine", true, true)
    and check(rules, "gameplay.transaction", true, true)
    -- gameplay.bounce is ignored; this achievement may be earned with
    -- either value, for leniency purposes.
    and check(rules, "gameplay.autoInteract", false)
    -- multiplayer.death is ignored; this achievement may be earned with
    -- either value. (That setting has no effect on singleplayer runs,
    -- which are a prerequisite for achievements anyway.)
    -- silly.packageEnemies is ignored; this achievement may be earned
    -- with either value.
    and check(rules, "silly.luteMode", true, false)
  )

  out.NoRejects = not ShownItems.hasUncollectedItems()
  out.Mystery = rules["gameplay.modifiers.mystery"]

  out.Any = (
    out.Default
    or out.Classic
    or out.Lute
  )

  out.NoBeat = rules["gameplay.modifiers.rhythm"] == "NO_BEAT"

  print(out)

  return out
end

return mod