local DropdownMenu       = require "necro.menu.generic.DropdownMenu"
local Event              = require "necro.event.Event"
local FileIO             = require "system.game.FileIO"
local JSON               = require "system.utils.serial.JSON"
local LeaderboardContext = require "necro.client.leaderboard.LeaderboardContext"
local Menu               = require "necro.menu.Menu"
local Replay             = require "necro.client.replay.Replay"
local Settings           = require "necro.config.Settings"
local Timer              = require "system.utils.Timer"

local RuleCheck = require "Lola.mod.RuleCheck"

local MOD_VERSION = JSON.decode(FileIO.readFileToString(("mods/%s/mod.json"):format(script.loader:match("[^.]+"))))
  .version

------------
-- Format --
--#region---

--[[
  A small explanation for the format of the TimesTable:
  {
    -- "Normal", "NoRejects", "Mystery", or "NoRejectsMystery"
    Normal = {
      -- "Default", "Classic", or "Lute"
      Default = {
        -- The in-game time.
        Time = 666.66,
        -- When (in real-life time) this was achieved.
        When = "2024-01-01 00:00:00", -- This is the format "%Y-%m-%d %H:%M:%S"
        -- The final coin score in the run.
        Score = 6666,
        -- The replay file, if I can get it.
        ReplayFile = "",
        -- The mod version.
        Version = "1.3.0"
      }
    }
  }
]]

--#endregion Format

------------------
-- Data Storage --
--#region---------

TimesTable = Settings.user.table {
  id = "timesTable",
  visibility = Settings.Visibility.RESTRICTED,
  default = {
    Normal = {},
    NoRejects = {},
    Mystery = {},
    NoRejectsMystery = {}
  }
}

TimesTableNoBeat = Settings.user.table {
  id = "timesTableNoBeat",
  visibility = Settings.Visibility.RESTRICTED,
  default = {
    Normal = {},
    NoRejects = {},
    Mystery = {},
    NoRejectsMystery = {}
  }
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
    Menu.open("Lola_bestTimes", {})
  end
}

ViewTimesNB = Settings.user.action {
  name = "View no-beat times (Lola)",
  desc = "View your best times with No Beat Mode in the Lola mod",
  id = "pb.viewNoBeat",
  order = 2,
  action = function()
    Menu.open("Lola_bestTimes", { noBeat = true })
  end
}

--#endregion Settings

----------------
-- Formatters --
--#region-------

local function TimeFormat(value)
  local negative = value < 0 and "-" or ""
  value = math.abs(value)

  local seconds = value % 60
  local secStr = ("%02.2f"):format(seconds)

  local minutes = math.floor(value / 60) % 60
  local minStr = ("%02i"):format(minutes) .. ":"

  local hours = math.floor(value / 3600)
  local hrStr = hours > 0 and (hours .. ":") or ""

  return hrStr .. minStr .. secStr
end

--#endregion formatters

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
    { id = "Normal",           name = "" },
    { id = "NoRejects",        name = ", No rejects" },
    { id = "Mystery",          name = ", Mystery mode" },
    { id = "NoRejectsMystery", name = ", No rejects, Mystery mode" }
  }

  local timetable = ev.arg.noBeat and TimesTableNoBeat or TimesTable

  for _, c in ipairs(challenges) do
    if timetable[c.id] then -- just in case, shouldn't ever be nil
      for _, r in ipairs(rules) do
        local label = r.name .. c.name .. ": "

        if timetable[c.id][r.id] then
          label = label .. TimeFormat(timetable[c.id][r.id].Time)
        else
          label = label .. "-"
        end

        local entry = {
          id = r.id .. c.id,
          label = label,
          enableIf = not not timetable[c.id][r.id],
          action = function()
            Menu.open("Lola_pbDetails", {
              challenge = c,
              ruleset = r,
              info = timetable[c.id][r.id],
              noBeat = ev.arg.noBeat
            })
          end
        }

        table.insert(entries, entry)
      end
    end
  end

  table.insert(entries, {
    id = "BlankSpace",
    height = 0
  })

  table.insert(entries, {
    id = "Back",
    label = "Back",
    action = Menu.close
  })

  ev.menu = {
    label = "Lola Best Times" .. (ev.arg.noBeat and " (No beat)" or ""),
    entries = entries
  }
end)

--#endregion Best Times Menu

--------------------
-- PB Detail Menu --
--#region-----------

Event.menu.add("pbDetails", "Lola_pbDetails", function(ev)
  local entries = {
    {
      id = "entry.timestamp",
      label = "Achieved: " .. ev.arg.info.When,
      enableIf = false,
      action = function() end
    },
    {
      id = "entry.time",
      label = "Clear time: " .. TimeFormat(ev.arg.info.Time),
      enableIf = false,
      action = function() end
    },
    {
      id = "entry.score",
      label = "Clear score: " .. ev.arg.info.Score,
      enableIf = false,
      action = function() end
    },
    {
      id = "entry.version",
      label = "Mod version: " .. ev.arg.info.Version,
      enableIf = false,
      action = function() end
    },
    {
      height = 0
    },
    {
      id = "entry.delete",
      label = "Delete",
      action = function()
        DropdownMenu.open {
          entries = {
            { label = "Cancel" },
            {
              label = "Confirm delete",
              action = function()
                Menu.close()
                if ev.arg.noBeat then
                  TimesTableNoBeat[ev.arg.challenge.id][ev.arg.ruleset.id] = nil
                else
                  TimesTable[ev.arg.challenge.id][ev.arg.ruleset.id] = nil
                end
                Menu.update()
              end
            }
          }
        }
      end
    },
    {
      id = "entry.goback",
      label = "Back",
      action = Menu.close
    }
  }

  ev.menu = {
    entries = entries,
    label = ev.arg.ruleset.name .. ev.arg.challenge.name .. (ev.arg.noBeat and " (No beat)" or "")
  }
end)

--#endregion PB Detail Menu

-------------------------
-- Run completed event --
--#region----------------

local function trySaveScore(ruleset, challenge, noBeat)
  local timetable = noBeat and TimesTableNoBeat or TimesTable
  local challengeBoard = timetable[challenge]
  if not challengeBoard then
    timetable[challenge] = {}
    challengeBoard = timetable[challenge]
  end

  local prevEntry = challengeBoard[ruleset]

  local ctx = LeaderboardContext.getFinalRunContext().completion
  local newEntryWhen = Timer.dateTime("*t")

  local when =
    newEntryWhen.year .. "-"
    .. (newEntryWhen.month < 10 and "0" or "") .. newEntryWhen.month .. "-"
    .. (newEntryWhen.day < 10 and "0" or "") .. newEntryWhen.day .. " "
    .. (newEntryWhen.hour < 10 and "0" or "") .. newEntryWhen.hour .. ":"
    .. (newEntryWhen.min < 10 and "0" or "") .. newEntryWhen.min .. ":"
    .. (newEntryWhen.sec < 10 and "0" or "") .. newEntryWhen.sec

  local newEntry = {
    Time = ctx.duration,
    Score = ctx.score,
    When = when,
    Version = MOD_VERSION,
    ReplayFile = Replay.getCurrentSavedReplayFile()
  }

  if not (prevEntry and prevEntry.Time < newEntry.Time) then
    challengeBoard[ruleset] = newEntry
  end
end

Event.runComplete.add("unlockLolaAchievement", { order = "leaderboardSubmission", sequence = 1 }, function(ev)
  if not SaveTimes then return end

  local followedRules = RuleCheck.getFollowedRules()
  local noBeat = followedRules.NoBeat

  if followedRules.Any then
    local ruleset = followedRules.Default and "Default" or followedRules.Classic and "Classic" or "Lute"

    if followedRules.Mystery then
      trySaveScore(ruleset, "Mystery", noBeat)

      if followedRules.NoRejects then
        trySaveScore(ruleset, "NoRejectsMystery", noBeat)
      end
    end

    if followedRules.NoRejects then
      trySaveScore(ruleset, "NoRejects", noBeat)
    end

    trySaveScore(ruleset, "Normal", noBeat)
  end
end)

--#endregion Run Completed