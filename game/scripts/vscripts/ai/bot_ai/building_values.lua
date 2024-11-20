-- Info that can be derived:
--   Building Cost
--   Has upgrade ability
-- Info we need to give
--   Damage/Armor type
--   
local building_data = {
  barracks = {
    damageType = "",
    armorType = "",
    upgrades = {
      "upgrade_stronghold",
    },
  },
  stronghold = {
    damageType = "",
    armorType = "",
  },
  sniper_nest = {
    damageType = "",
    armorType = "",
    canHitFlying = true,
    upgrades = {
      "upgrade_gunners_hall",
      "upgrade_marksmens_encampment",
    },
  },
  gunners_hall = {
    damageType = "",
    armorType = "",
  },
  marksmens_encampment = {
    damageType = "",
    armorType = "",
    canHitFlying = true,
  },
  weapon_lab = {
    damageType = "",
    armorType = "",
  },
  gryphon_rock = {
    damageType = "",
    armorType = "",
    canHitFlying = true,
    trainsFlying = true,
  },
  chapel = {
    damageType = "",
    armorType = "",
upgrades = {
      "upgrade_church",
    },
  },
  church = {
    damageType = "",
    armorType = "",
  },
  hjordhejmen = {
    damageType = "",
    armorType = "",
  },
  treasure_box = {
  },
  gjallarhorn = {
  },
  artillery = {
  },
  watch_tower = {
  },
  heroic_shrine = {
  },
}

return building_data