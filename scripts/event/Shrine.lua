local Event   = require "necro.event.Event"
local GameDLC = require "necro.game.data.resource.GameDLC"

local RevealedItems = require "Lola.mod.RevealedItems"

local LoSettings = require "Lola.Settings"

local shrineBy = nil

Event.shrine.override("sacrifice", 1, function(func, ev)
  shrineBy = ev.interactor
  func(ev)
  shrineBy = nil
end)

Event.shrine.override("pain", 1, function(func, ev)
  shrineBy = ev.interactor
  func(ev)
  shrineBy = nil
end)

if GameDLC.isSynchronyLoaded then
  Event.shrine.override("Sync_feast", 1, function(func, ev)
    shrineBy = ev.interactor
    func(ev)
    shrineBy = nil
  end)

  Event.shrine.override("Sync_fire", 1, function(func, ev)
    shrineBy = ev.interactor
    func(ev)
    shrineBy = nil
  end)
end

Event.objectSpawn.add("shrineDetected", { order = "overrides", filter = "Lola_revealedBy" }, function(ev)
  if shrineBy and LoSettings.get("gameplay.shrine") then
    RevealedItems.mark(shrineBy, ev.entity)
  end
end)