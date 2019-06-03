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

  -- Human Precaches
  PrecacheUnitByNameSync("barracks", context)
  PrecacheUnitByNameSync("stronghold", context)
  PrecacheUnitByNameSync("footman", context)
  PrecacheUnitByNameSync("defender", context)

  PrecacheUnitByNameSync("sniper_nest", context)
  PrecacheUnitByNameSync("gunners_hall", context)
  PrecacheUnitByNameSync("marksmens_encampment", context)
  PrecacheUnitByNameSync("sniper", context)
  PrecacheUnitByNameSync("heavy_gunner", context)
  PrecacheUnitByNameSync("marksman", context)

  PrecacheUnitByNameSync("weapon_lab", context)
  PrecacheUnitByNameSync("mortar", context)

  PrecacheUnitByNameSync("gryphon_rock", context)
  PrecacheUnitByNameSync("gryphon_rider", context)  

  PrecacheUnitByNameSync("chapel", context)
  PrecacheUnitByNameSync("church", context)
  PrecacheUnitByNameSync("crusader", context)
  PrecacheUnitByNameSync("paladin", context)

  PrecacheUnitByNameSync("hjordhejmen", context)
  PrecacheUnitByNameSync("warlock", context)

  PrecacheUnitByNameSync("gjallarhorn", context)
  PrecacheUnitByNameSync("artillery", context)
  PrecacheUnitByNameSync("watch_tower", context)
  PrecacheUnitByNameSync("heroic_shrine", context)  
end

-- Create the game mode when we activate
function Activate()
  GameRules.GameMode = GameMode()
  GameRules.GameMode:InitGameMode()
  GameMode.Initialized = true

  if IsInToolsMode() then
    Timers:CreateTimer(2, function()
      Tutorial:AddBot("npc_dota_hero_wisp", "", "", false)
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

  LimitPathingSearchDepth(0.5)

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
  mode:SetCustomGameForceHero("npc_dota_hero_wisp")

  -- Event Hooks
  ListenToGameEvent('entity_killed', Dynamic_Wrap(GameMode, 'OnEntityKilled'), self)
  ListenToGameEvent('player_connect_full', Dynamic_Wrap(GameMode, 'OnConnectFull'), self)
  -- ListenToGameEvent('player_connect', Dynamic_Wrap(GameMode, 'PlayerConnect'), self)
  ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
  ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameMode, 'OnGameRulesStateChange'), self)
  -- ListenToGameEvent('entity_hurt', Dynamic_Wrap(GameMode, 'OnEntityHurt'), self)
  -- ListenToGameEvent('player_chat', Dynamic_Wrap(GameMode, 'OnPlayerChat'), self)

  -- Filters
  mode:SetModifyExperienceFilter(Dynamic_Wrap(GameMode, "FilterExperience"), self)
  mode:SetDamageFilter(Dynamic_Wrap(GameMode, "FilterDamage"), self)

  -- Lua Modifiers
  LinkLuaModifier("modifier_disable_turning", "libraries/modifiers/modifier_disable_turning", LUA_MODIFIER_MOTION_NONE)

  -- Setup Global Values
  GameRules.leftCastlePosition = Entities:FindByName(nil, "left_ancient_position"):GetAbsOrigin()
  GameRules.rightCastlePosition = Entities:FindByName(nil, "right_ancient_position"):GetAbsOrigin()
  GameRules.leftBaseMinBounds = Entities:FindByName(nil, "left_base_min_bounds"):GetAbsOrigin()
  GameRules.leftBaseMaxBounds = Entities:FindByName(nil, "left_base_max_bounds"):GetAbsOrigin()
  GameRules.rightBaseMinBounds = Entities:FindByName(nil, "right_base_min_bounds"):GetAbsOrigin()
  GameRules.rightBaseMaxBounds = Entities:FindByName(nil, "right_base_max_bounds"):GetAbsOrigin()

  GameRules.leftRoundsWon = 0
  GameRules.rightRoundsWon = 0

  GameRules.playerIDs = {}

  -- Modifier Applier
  GameRules.Applier = CreateItem("item_apply_modifiers", nil, nil)

  GameRules.Damage = LoadKeyValues("scripts/kv/damage_table.kv")
end

function GameMode:FilterExperience(filterTable)
  return false
end