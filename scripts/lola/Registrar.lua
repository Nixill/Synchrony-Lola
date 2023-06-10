local Components     = require "necro.game.data.Components"
local CustomEntities = require "necro.game.data.CustomEntities"
local HSVFilter      = require "necro.render.filter.HSVFilter"
local ItemBan        = require "necro.game.item.ItemBan"

Components.register {
  -- Component given to Lola (by default)
  --
  -- The carrier of this component receives any items they reveal when
  -- they use the stairs to leave the floor.
  NixsChars_descentCollectItems = {
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
  NixsChars_forcedLowPercent = {
    Components.field.bool("active", true),
    Components.constant.localizedString("killerName", "Lola's Curse")
  },

  -- This component is given to any entity with storage.
  --
  -- If the entity is attacked or interacted with by a player, that
  -- player's ID is stored here. If the storage is subsequently opened,
  -- any items it contained get marked as revealed by that player.
  NixsChars_interactedBy = {
    Components.field.int("playerID", 0)
  },

  -- This component is given to any item.
  --
  -- If the item is revealed from a crate, chest, or shrine, or the result
  -- of a conjurer or transmog transaction, "player" to the player that
  -- did so.
  --
  -- "player" is reset to 0 if any player picks it up.
  NixsChars_revealedBy = {
    Components.field.int("playerID", 0)
  },

  -- This component is only given to NixsChars_SpellcastPackage.
  --
  -- Causes the effect of a spellcast to be the packaging of items into
  -- crates.
  NixsChars_spellcastPackageItems = {},

  -- This component is only given to NixsChars_SpellcastPackageGreater.
  --
  -- Causes the effect of a spellcast to be the packaging of items into
  -- chests.
  NixsChars_spellcastPackageItemsGreater = {}
}

CustomEntities.extend {
  template = CustomEntities.template.player(0),
  name = "NixsChars_Lola",
  components = {
    NixsChars_descentCollectItems = {},
    NixsChars_forcedLowPercent = {},
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
        "NixsChars_SpellPackage"
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
  name = "NixsChars_Randomizer",
  random = {}
}

CustomEntities.register {
  name = "NixsChars_SpellcastPackage",
  NixsChars_spellcastPackageItems = {},
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
    offsets = { { 1, 0 } }
  },
  spellcastUpgradable = {
    upgradeTypes = {
      greater = "NixsChars_SpellcastPackageGreater"
    }
  },
  spellcastUseFacingDirection = {},
}

CustomEntities.register {
  name = "NixsChars_SpellcastPackageGreater",
  NixsChars_spellcastPackageItemsGreater = {},
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
    offsets = { { 1, 0 } }
  },
  spellcastUseFacingDirection = {},
}

CustomEntities.extend {
  template = CustomEntities.template.item(),
  name = "NixsChars_SpellPackage",
  components = {
    Sync_itemExcludeFromCloneDrop = {},
    friendlyName = {
      name = "Package Spell"
    },
    itemBanInnateSpell = {},
    itemCastOnUse = {
      spell = "NixsChars_SpellcastPackage"
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
