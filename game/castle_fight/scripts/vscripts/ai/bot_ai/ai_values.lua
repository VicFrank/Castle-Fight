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
  },
  stronghold = {
    damageType = "",
    armorType = "",
  },
  sniper_nest = {
    damageType = "",
    armorType = "",
    canHitFlying = true,
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
  "weapon_lab" = {
    damageType = "",
    armorType = "",
  },
  "gryphon_rock" = {
    damageType = "",
    armorType = "",
    canHitFlying = true,
    trainsFlying = true,
  },
  "chapel" = {
    damageType = "",
    armorType = "",
  },
  "church" = {
    damageType = "",
    armorType = "",
  },
}

local ability_data = {
  build_barracks = {
    interestToConsider = 5,
  },
  build_sniper_nest = {
    interestToConsider = 5,
  },
  build_weapon_lab = {
    interestToConsider = 5,
  },
  build_gryphon_rock = {
    interestToConsider = 5,
  },
  build_chapel = {
    interestToConsider = 15,
  },
  build_hjordhejmen = {
    interestToConsider = 15,
  },
  item_build_treasure_box = {
    interestToConsider = 25,
  },
  item_build_gjallarhorn = {
    interestToConsider = 30,
  },
  item_build_artillery = {
    interestToConsider = 100,
  },
  item_build_watch_tower = {
    interestToConsider = 20,
  },
  item_build_heroic_shrine = {
    interestToConsider = 60,
  },

  -- Upgrades
  upgrade_stronghold = {

  },
  upgrade_gunners_hall = {

  },
  upgrade_marksmens_encampment = {

  },
  upgrade_church = {

  },
}

return ability_data