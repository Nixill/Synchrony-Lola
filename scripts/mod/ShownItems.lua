local Snapshot = require "necro.game.system.Snapshot"

---------------
-- SNAPSHOTS --
--#region------

ShownItems = Snapshot.runVariable({})

--#endregion SNAPSHOTS

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

function mdl.hasUncollectedItems()
  for k, v in pairs(ShownItems) do
    if v == false then
      return true
    end
  end

  return false
end

return mdl

---#endregion MODULE