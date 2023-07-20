local Action         = require "necro.game.system.Action"
local Components     = require "necro.game.data.Components"
local CustomEntities = require "necro.game.data.CustomEntities"
local ItemBan        = require "necro.game.item.ItemBan"

local Direction = Action.Direction

Components.register {
  -- Component given to Lola (by default)
  --
  -- The carrier of this component receives any items they reveal when
  -- they use the stairs to leave the floor.
  Lola_descentCollectItems = {
    Components.field.bool("active", true),
    Components.field.entityID("randomizer"),
    Components.field.table("revealedItems", {})
  },

  -- Component given to Lola (by default)
  --
  -- The carrier of this component dies if they:
  -- a. Pick up any items
  -- b. Bump any bumpable shrines
  --
  -- If "active" is false, that death is skipped.
  --
  -- A setting in the options will allow this component to cause an
  -- invalid move instead of a death.
  Lola_forcedLowPercent = {
    Components.field.bool("active", true),
    Components.constant.localizedString("killerName", "Lola's Curse"),
    Components.constant.table("allowedItems", {})
  },

  -- This component is given to any item that can negate low%.
  --
  -- This tracks whoever has held the item on the current floor. Such
  -- player may pick that item back up even if they have forced low%.
  --
  -- The component is reset to the current holder only at the start of
  -- each floor.
  --
  -- If safe is true, all players are treated as holders.
  Lola_holders = {
    Components.field.table("playerIDs", {}),
    Components.field.bool("safe", false)
  },

  -- This component is given to any entity with storage.
  --
  -- If the entity is attacked or interacted with by a player, that
  -- player's ID is stored here. If the storage is subsequently opened,
  -- any items it contained get marked as revealed by that player.
  Lola_interactedBy = {
    Components.field.int("playerID", 0)
  },

  -- This component is given to any item that can negate low%.
  --
  -- If the item is revealed from a crate, chest, or shrine, or the result
  -- of a conjurer or transmog transaction, "player" to the player that
  -- did so.
  --
  -- "player" is reset to 0 if any player picks it up.
  Lola_revealedBy = {
    Components.field.int("playerID", 0)
  },

  -- This component is only given to Lola_SpellcastPackage.
  --
  -- Causes the effect of a spellcast to be the packaging of items into
  -- crates.
  Lola_spellcastPackageItems = {},

  -- This component is only given to Lola_SpellcastPackageGreater.
  --
  -- Causes the effect of a spellcast to be the packaging of items into
  -- chests.
  Lola_spellcastPackageItemsGreater = {},

  -- This component is given to both Lola_SpellcastPackageGreater and
  -- Lola_SpellcastPackage.
  --
  -- Causes the spellcast to create a flyaway which varies based on the
  -- targets of the spell.
  Lola_spellcastFlyawayPackage = {
    Components.constant.localizedString("baseText", ""),
    Components.constant.localizedString("noTargets", ""),
    Components.constant.localizedString("cantAfford", ""),
    Components.constant.localizedString("enemyCrate", ""),
    Components.constant.int("offsetY", 0)
  }
}

CustomEntities.extend {
  template = CustomEntities.template.player(),
  name = "Lola_Lola",
  components = { {
    InGameAchievements_allZonesAchievement = {
      exclude = true
    },
    Lola_descentCollectItems = {},
    Lola_forcedLowPercent = {
      allowedItems = {
        MiscPotion = true
      }
    },
    NixLib_partialDirectionalSpriteChange = {
      frameX = {
        [Direction.UP_LEFT] = 16,
        [Direction.LEFT] = 16,
        [Direction.DOWN_LEFT] = 16
      },
      ignored = {
        [Direction.UP] = true,
        [Direction.DOWN] = true
      }
    },
    bestiary = {
      focusX = 170,
      focusY = 120,
      image = "mods/Lola/gfx/lola_bestiary.png"
    },
    forceNonSilhouetteVision = {
      component = "storage"
    },
    forceObjectVision = {
      component = "storage"
    },
    friendlyName = {
      name = "Lola"
    },
    initialInventory = {
      items = {
        "ShovelBasic"
        -- NOTE: An entitySchemaLoadEntity handler will add (or not add)
        -- Dagger (or Lute), Bombs, and the Package Spell according to
        -- user settings.
      }
    },
    inventoryBannedItems = {
      components = {
        itemGrantContentsVision = ItemBan.Type.FULL
        -- NOTE: An entitySchemaLoadEntity handler will add (or not add)
        -- itemBanInnateSpell = ItemBan.Type.LOCK according to user settings.
      }
    },
    minimapVision = {
      component = "storage"
    },
    playableCharacter = {
      lobbyOrder = -2370
    },
    sprite = {
      texture = "mods/Lola/gfx/lola_armor_body.png"
    },
    textCharacterSelectionMessage = {
      text = "Lola mode!\n"
        .. "Low% rules apply.\n"
        .. "Receive revealed items (from\n"
        .. "chests, crates, etc.) when\n"
        .. "done with the floor!"
    }
  }, {
    sprite = {
      texture = "mods/Lola/gfx/lola_heads.png"
    }
  } }
}

CustomEntities.register {
  name = "Lola_Randomizer",
  random = {}
}

CustomEntities.register {
  name = "Lola_SpellcastPackage",
  Lola_spellcastFlyawayPackage = {
    baseText = "Package",
    noTargets = "Package (empty)",
    cantAfford = "Package (can't afford)"
  },
  Lola_spellcastPackageItems = {},
  friendlyName = {
    name = "Package"
  },
  soundSpellcast = {
    sound = "spellGeneral"
  },
  spellcast = {},
  spellcastTargetTiles = {
    offsets = { { 1, 0 }, { 0, -1 }, { 0, 1 }, { -1, 0 } }
  },
  spellcastUpgradable = {
    upgradeTypes = {
      greater = "Lola_SpellcastPackageGreater"
    }
  },
  spellcastUseFacingDirection = {},
}

CustomEntities.register {
  name = "Lola_SpellcastPackageGreater",
  Lola_spellcastFlyawayPackage = {
    baseText = "Greater Package",
    noTargets = "Greater Package (empty)",
    cantAfford = "Greater Package (can't afford)",
    enemyCrate = "Greater Package (enemy captured)"
  },
  Lola_spellcastPackageItemsGreater = {},
  friendlyName = {
    name = "Greater Package"
  },
  soundSpellcast = {
    sound = "spellGeneral"
  },
  spellcast = {},
  spellcastTargetTiles = {
    offsets = { { 1, 0 }, { 0, -1 }, { 0, 1 }, { -1, 0 } }
  },
  spellcastUseFacingDirection = {},
}

CustomEntities.extend {
  template = CustomEntities.template.item(),
  name = "Lola_SpellPackage",
  components = {
    Sync_itemExcludeFromCloneDrop = {},
    friendlyName = {
      name = "Package Spell"
    },
    itemBanInnateSpell = {},
    itemCastOnUse = {
      spell = "Lola_SpellcastPackage"
    },
    itemHintLabel = {
      text = "Package items into crates"
    },
    itemHUDCooldown = {
      opacity = 0.5
    },
    itemPreservedByPhasingShrine = {},
    itemScreenFlash = {},
    itemSlot = {
      name = "spell"
    },
    spellBloodMagic = {
      damage = 2,
      killerName = "Blood Magic (Package)"
    },
    spellCooldownKills = {
      cooldown = "25"
    },
    spellReusable = {},
    sprite = {
      height = 24,
      mirrorOffsetX = 0,
      texture = "ext/entities/crate.png",
      width = 24
    }
  }
}