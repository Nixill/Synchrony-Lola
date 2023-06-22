local Components     = require "necro.game.data.Components"
local CustomEntities = require "necro.game.data.CustomEntities"
local HSVFilter      = require "necro.render.filter.HSVFilter"
local ItemBan        = require "necro.game.item.ItemBan"

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
  -- A setting in the options allows this component to cause an invalid
  -- move instead of a death.
  Lola_forcedLowPercent = {
    Components.field.bool("active", true),
    Components.constant.localizedString("killerName", "Lola's Curse")
  },

  -- This component is given to any entity with storage.
  --
  -- If the entity is attacked or interacted with by a player, that
  -- player's ID is stored here. If the storage is subsequently opened,
  -- any items it contained get marked as revealed by that player.
  Lola_interactedBy = {
    Components.field.int("playerID", 0)
  },

  -- This component is given to any item.
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
  Lola_spellcastPackageItemsGreater = {}
}

CustomEntities.extend {
  template = CustomEntities.template.player(0),
  name = "Lola_Lola",
  components = {
    Lola_descentCollectItems = {},
    Lola_forcedLowPercent = {},
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
        "ShovelBasic",
        "WeaponDagger",
        "Bomb",
        "Lola_SpellPackage"
      }
    },
    inventoryBannedItems = {
      components = {
        itemBanInnateSpell = ItemBan.Type.LOCK,
        itemGrantContentsVision = ItemBan.Type.FULL
      }
    },
    minimapVision = {
      component = "storage"
    },
    playableCharacter = {
      lobbyOrder = -2370
    },
    playerXMLMapping = false,
    sprite = {
      texture = HSVFilter.getPath("ext/entities/char2_armor_body.png",
        30 / 360, 0, 0)
    },
    subtitled = false,
    textCharacterSelectionMessage = {
      text = "Lola mode!\n"
          .. "Low% rules apply.\n"
          .. "Receive revealed items (from\n"
          .. "chests, crates, etc.) when\n"
          .. "done with the floor!"
    },
    traitStoryBosses = false,
    voiceConfused = false,
    voiceDeath = false,
    voiceDescend = false,
    voiceDig = false,
    voiceGrabbed = false,
    voiceGreeting = false,
    voiceHeal = false,
    voiceHit = false,
    voiceHotTileStep = false,
    voiceMeleeAttack = false,
    voiceNotice = false,
    voiceRangedAttack = false,
    voiceShrink = false,
    voiceSlideStart = false,
    voiceSpellCasterPrefix = false,
    voiceSquish = false,
    voiceStairsUnlock = false,
    voiceTeleport = false,
    voiceUnshrink = false,
    voiceWind = false
  }
}

CustomEntities.register {
  name = "Lola_Randomizer",
  random = {}
}

CustomEntities.register {
  name = "Lola_SpellcastPackage",
  Lola_spellcastPackageItems = {},
  friendlyName = {
    name = "Package"
  },
  soundSpellcast = {
    sound = "spellGeneral"
  },
  spellcast = {},
  spellcastFlyaway = {
    offsetY = 0,
    text = "Package"
  },
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
  Lola_spellcastPackageItemsGreater = {},
  friendlyName = {
    name = "Greater Package"
  },
  soundSpellcast = {
    sound = "spellGeneral"
  },
  spellcast = {},
  spellcastFlyaway = {
    offsetY = 0,
    text = "Greater Package"
  },
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
