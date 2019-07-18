if GameMode == nil then
  _G.GameMode = class({})
end

require('libraries/timers')
require('libraries/notifications')
require('libraries/selection')
require("libraries/buildinghelper")
require("libraries/animations")

require("mechanics/units")
require("mechanics/attacks")
require("mechanics/resources")
require("mechanics/rounds")
require("mechanics/income")
require("mechanics/corpses")
require("mechanics/modifiers")
require("mechanics/settings")

require("tables/precache_tables")
require("tables/item_tables")
require("tables/ability_costs")
require("tables/ai_modifier_table")

require("items/custom_shop")

require("ai/bot_ai/bot_ai")

require('repair')
require("order_filters")
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
  PrecacheResource("particle", "particles/abilities/generic/quad_damage/rune_quaddamage_owner.vpcf", context) -- quad damage
  PrecacheResource("particle", "particles/econ/generic/generic_timer/generic_timer.vpcf", context)

  -- Precache the heroes

  -- Shop Items
  PrecacheItemByNameSync("item_blast_staff", context)
  PrecacheItemByNameSync("orb_of_lightning", context)
  PrecacheItemByNameSync("scroll_of_stone", context)
  PrecacheItemByNameSync("building_self_destruct", context)
  
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
      Tutorial:AddBot("npc_dota_hero_wisp", "", "", false)
      Tutorial:AddBot("npc_dota_hero_wisp", "", "", false)
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

  -- Adding Many Players
  if GetMapName() == "castle_fight" then
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 4)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 4)
  elseif GetMapName() == "single_lane" then
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 2)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 2)
  end
  
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
  ListenToGameEvent('player_chat', Dynamic_Wrap(GameMode, 'OnPlayerChat'), self)

  -- Custom Event Hooks
  CustomGameEventManager:RegisterListener('on_race_selected', OnRaceSelected)
  CustomGameEventManager:RegisterListener('attempt_purchase', OnAttemptPurchase)
  CustomGameEventManager:RegisterListener('add_ai', OnAddAI)
  CustomGameEventManager:RegisterListener('draw_vote', OnVoteDraw)

  -- Filters
  mode:SetDamageFilter(Dynamic_Wrap(GameMode, "FilterDamage"), self)
  mode:SetExecuteOrderFilter(Dynamic_Wrap(GameMode, "OrderFilter"), self)

  -- Lua Modifiers
  LinkLuaModifier("modifier_disable_turning", "libraries/modifiers/modifier_disable_turning", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_under_construction", "libraries/modifiers/modifier_under_construction", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("income_modifier", "abilities/generic/income_modifier", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_hide_hero", "abilities/modifiers/modifier_hide_hero", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_stunned_custom", "abilities/modifiers/modifier_stunned_custom", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_end_round", "abilities/modifiers/modifier_end_round", LUA_MODIFIER_MOTION_NONE)

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
  GameRules.roundCount = 1
  GameRules.roundInProgress = false
  GameRules.InHeroSelection = false
  GameRules.roundStartTime = 0
  GameRules.needToPick = 0
  GameRules.playerIDs = {}
  GameRules.numToCache = 0
  GameRules.numUnits = 0
  GameRules.precached = {}
  GameRules.income = {}
  GameRules.numBoxes = {}
  GameRules.lumber = {}
  GameRules.gold = {}
  GameRules.cheese = {}
  GameRules.drawVotes = {}

  GameRules.HeroSelectionTimer = ""
  GameRules.LoadingTimer = ""
  GameRules.PostRoundTimer = ""
  GameRules.DrawTimer = ""
  GameRules.RoundTimer = ""

  -- Modifier Applier
  GameRules.Applier = CreateItem("item_apply_modifiers", nil, nil)

  GameRules.Damage = LoadKeyValues("scripts/kv/damage_table.kv")

  SetUpCustomItemCosts()
  SetupCustomAblityCosts()
  CheckHeroPositions()
end

function SetUpCustomItemCosts()
  for _,item_names in pairs(g_Race_Items) do
    for _,itemname in ipairs(item_names) do
      local item = CreateItem(itemname, nil, nil)

      local goldCost = tonumber(item:GetAbilityKeyValues()['GoldCost']) or 0
      local lumberCost = tonumber(item:GetAbilityKeyValues()['LumberCost']) or 0
      local isLegendary = item:GetAbilityKeyValues()['IsLegendary'] ~= nil

      CustomNetTables:SetTableValue("ability_costs", itemname, {
        lumberCost = lumberCost,
        isLegendary = isLegendary,
        goldCost = goldCost
      })

      item:RemoveSelf()
    end
  end
end

function SetupCustomAblityCosts()
  local dummy = CreateUnitByName("dummy_unit", Vector(0,0,0), false, nil, nil, 0)
  for _,abilityname in ipairs(g_Custom_Ability_Costs) do
    local ability = dummy:AddAbility(abilityname)

    local goldCost = tonumber(ability:GetAbilityKeyValues()['GoldCost']) or 0
    local lumberCost = tonumber(ability:GetAbilityKeyValues()['LumberCost']) or 0
    local isLegendary = ability:GetAbilityKeyValues()['IsLegendary'] ~= nil

    CustomNetTables:SetTableValue("ability_costs", abilityname, {
      goldCost = goldCost,
      lumberCost = lumberCost,
      isLegendary = isLegendary
    })

    dummy:RemoveAbility(abilityname)
  end
  dummy:RemoveSelf()
end

function CheckHeroPositions()
  -- Make sure heroes can't go to the other base
  Timers:CreateTimer(function()
    for _,hero in pairs(HeroList:GetAllHeroes()) do
      if hero:IsAlive() then
        if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
          if hero:GetAbsOrigin().x > GameRules.leftBaseMaxBounds.x then
            FindClearSpaceForUnit(hero, GameRules.leftCastlePosition, true)
          end
        elseif hero:GetTeam() == DOTA_TEAM_BADGUYS then
          if hero:GetAbsOrigin().x < GameRules.rightBaseMinBounds.x then
            FindClearSpaceForUnit(hero, GameRules.rightCastlePosition, true)
          end
        end
      end
    end

    return 1
  end)
end