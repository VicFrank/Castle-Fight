if GameMode == nil then
  _G.GameMode = class({})
end

require('libraries/timers')
require('libraries/notifications')
require('libraries/selection')
require("libraries/buildinghelper")

require("mechanics/units")
require("mechanics/attacks")
require("mechanics/lumber")
require("mechanics/rounds")
require("mechanics/income")
require("mechanics/corpses")

require("tables/precache_tables")
require("tables/item_tables")

require('repair')
require("damage")
require("testing")
require("events")
require("constants")
require("utility_functions")

function Precache( context )
  --[[
  PrecacheResource( "model", "*.vmdl", context )
  PrecacheModel should generally used over PrecacheResource for individual models
  PrecacheModel("models/heroes/viper/viper.vmdl", context)

  PrecacheResource( "soundfile", "*.vsndevts", context )
  PrecacheResource( "particle", "*.vpcf", context )
  PrecacheResource( "particle_folder", "particles/folder", context )

  Entire items can be precached by name
  Abilities can also be precached in this way despite the name
  PrecacheItemByNameSync("item_rune_heal", context)

  Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
  Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
  PrecacheUnitByNameSync("npc_dota_hero_ancient_apparition", context)
  ]]

  PrecacheResource("particle_folder", "particles/buildinghelper", context)

  -- General Precaches
  PrecacheUnitByNameSync("treasure_box", context)
  PrecacheUnitByNameSync("castle", context)
  PrecacheUnitByNameSync("dotacraft_corpse", context)
  PrecacheResource("particle", "particles/dire_fx/fire_barracks.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_magnataur/magnus_dust_hit.vpcf", context) -- splash attack

  -- Human Precaches
  -- for _,unitname in ipairs(g_Human_Precache) do
  --   PrecacheUnitByNameSync(unitname, context)
  -- end
end

-- Create the game mode when we activate
function Activate()
  GameRules.GameMode = GameMode()
  GameRules.GameMode:InitGameMode()
  GameMode.Initialized = true

  if IsInToolsMode() then
    Timers:CreateTimer(2, function()
      Tutorial:AddBot("npc_dota_hero_kunkka", "", "", false)
    end)
  end
end

-- Make it so we have code that will run on every script reload
if GameMode.Initialized then
  GameMode:OnScriptReload()
end

function GameMode:InitGameMode()
  GameMode = self
  print("Castle Fight has loaded.")

  -- LimitPathingSearchDepth(0.5)

  GameRules:SetCustomGameAllowMusicAtGameStart(false)
  GameRules:SetCustomGameAllowBattleMusic(false)
  GameRules:SetCustomGameAllowHeroPickMusic(false)
  GameRules:EnableCustomGameSetupAutoLaunch(true)
  GameRules:SetSameHeroSelectionEnabled(false)
  GameRules:SetHideKillMessageHeaders(true)
  GameRules:SetUseUniversalShopMode(false)
  GameRules:SetHeroRespawnEnabled(false)
  GameRules:SetSafeToLeave(true)
  GameRules:SetCustomGameSetupAutoLaunchDelay(30)
  GameRules:SetCustomGameEndDelay(0)
  GameRules:SetHeroSelectionTime(0)
  GameRules:SetPreGameTime(0)
  GameRules:SetStrategyTime(0)
  GameRules:SetShowcaseTime(0)
  GameRules:SetGoldTickTime(0)
  GameRules:SetStartingGold(0)
  GameRules:SetGoldPerTick(0)

  GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 4)
  GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 4)

  -- -- Set game mode rules
  mode = GameRules:GetGameModeEntity()        
  mode:DisableHudFlip(true)
  mode:SetBuybackEnabled(false)
  mode:SetFogOfWarDisabled(false)
  mode:SetLoseGoldOnDeath(false)
  mode:SetAnnouncerDisabled(true)
  mode:SetDeathOverlayDisabled(true)
  mode:SetDaynightCycleDisabled(true)
  mode:SetWeatherEffectsDisabled(true)
  mode:SetUnseenFogOfWarEnabled(false)
  mode:SetRemoveIllusionsOnDeath(true)
  mode:SetStashPurchasingDisabled(true)
  mode:SetTopBarTeamValuesVisible(false)
  mode:SetTopBarTeamValuesOverride(true)
  mode:SetRecommendedItemsDisabled(true)
  mode:SetSelectionGoldPenaltyEnabled(false)
  mode:SetKillingSpreeAnnouncerDisabled(true)
  mode:SetCustomGameForceHero("npc_dota_hero_slark")

  -- Event Hooks
  ListenToGameEvent('entity_killed', Dynamic_Wrap(GameMode, 'OnEntityKilled'), self)
  ListenToGameEvent('player_connect_full', Dynamic_Wrap(GameMode, 'OnConnectFull'), self)
  -- ListenToGameEvent('player_connect', Dynamic_Wrap(GameMode, 'PlayerConnect'), self)
  ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
  ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameMode, 'OnGameRulesStateChange'), self)
  -- ListenToGameEvent('entity_hurt', Dynamic_Wrap(GameMode, 'OnEntityHurt'), self)
  ListenToGameEvent('player_chat', Dynamic_Wrap(GameMode, 'OnPlayerChat'), self)

  -- Custom Event Hooks
  CustomGameEventManager:RegisterListener('on_race_selected', OnRaceSelected)

  -- Filters
  mode:SetDamageFilter(Dynamic_Wrap(GameMode, "FilterDamage"), self)

  -- Lua Modifiers
  LinkLuaModifier("modifier_disable_turning", "libraries/modifiers/modifier_disable_turning", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("income_modifier", "abilities/generic/income_modifier", LUA_MODIFIER_MOTION_NONE)

  self.vUserIds = {}
  
  -- Setup Global Values
  GameRules.leftCastlePosition = Entities:FindByName(nil, "left_ancient_position"):GetAbsOrigin()
  GameRules.rightCastlePosition = Entities:FindByName(nil, "right_ancient_position"):GetAbsOrigin()
  GameRules.leftBaseMinBounds = Entities:FindByName(nil, "left_base_min_bounds"):GetAbsOrigin()
  GameRules.leftBaseMaxBounds = Entities:FindByName(nil, "left_base_max_bounds"):GetAbsOrigin()
  GameRules.rightBaseMinBounds = Entities:FindByName(nil, "right_base_min_bounds"):GetAbsOrigin()
  GameRules.rightBaseMaxBounds = Entities:FindByName(nil, "right_base_max_bounds"):GetAbsOrigin()

  GameRules.leftRoundsWon = 0
  GameRules.rightRoundsWon = 0
  GameRules.roundCount = 0
  GameRules.roundInProgress = false
  GameRules.playerIDs = {}
  GameRules.numToCache = 0
  GameRules.precached = {}

  -- Modifier Applier
  GameRules.Applier = CreateItem("item_apply_modifiers", nil, nil)

  GameRules.Damage = LoadKeyValues("scripts/kv/damage_table.kv")

  SetUpCustomItemCosts()
end

function SetUpCustomItemCosts()
  local item_names = {
    "item_build_gjallarhorn",
    "item_build_artillery",
    "item_build_watch_tower",
    "item_build_heroic_shrine",
    "item_build_treasure_box",
  }

  for _,itemname in ipairs(item_names) do
    local item = CreateItem(itemname, nil, nil)

    local goldCost = item:GetCost()
    local lumberCost = tonumber(item:GetAbilityKeyValues()['LumberCost']) or 0
    local isLegendary = item:GetAbilityKeyValues()['IsLegendary'] ~= nil

    CustomNetTables:SetTableValue("item_costs", itemname, {
      goldCost = goldCost,
      lumberCost = lumberCost,
      isLegendary = isLegendary
    })

    item:RemoveSelf()
  end
end