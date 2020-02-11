function GameMode:OnGameRulesStateChange()
  local nNewState = GameRules:State_Get()
  if nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
    print( "[PRE_GAME] in Progress" )
  elseif nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    GameMode:OnGameInProgress()
  end
end

function GameMode:OnGameInProgress()
  local numPlayers = TableCount(GameRules.playerIDs)

  --Wait for all the heroes to load in
  Timers:CreateTimer(function()
    if TableCount(HeroList:GetAllHeroes()) >= numPlayers then
      -- Record the game settings for stat tracking purposes
      local roundsToWin = tonumber(CustomNetTables:GetTableValue("settings", "num_rounds")["numRounds"])
      local botsEnabled = CustomNetTables:GetTableValue("settings", "bots_enabled")["botsEnabled"]
      local cheatsEnabled = GameRules:IsCheatMode()
      GameRules.GameData.settings = {
        roundsToWin = roundsToWin,
        allowBots = botsEnabled,
        cheatsEnabled = cheatsEnabled,
      }

      CustomNetTables:SetTableValue("round_score", "score", {
        left_score = GameRules.leftRoundsWon,
        right_score = GameRules.rightRoundsWon,
      })

      GameMode:StartHeroSelection()
      GameMode:CheckLeavers()
      GameMode:DetectAFK()
      return
    end

    print("Waiting for heroes")
    return .3
  end)
end

function GameMode:OnNPCSpawned(keys)
  local npc = EntIndexToHScript(keys.entindex)

  -- Ignore specific units
  local unitName = npc:GetUnitName()
  if unitName == "npc_dota_thinker" then return end
  if unitName == "npc_dota_units_base" then return end
  if unitName == "dotacraft_corpse" then return end
  if unitName == "" then return end

  Timers:CreateTimer(.1, function()
    if not npc:IsNull() and not IsCustomBuilding(npc) and npc.IsUnderConstruction == nil and not npc.BHDUMMY then
      GameRules.numUnits = GameRules.numUnits + 1
      CustomGameEventManager:Send_ServerToAllClients("num_units_changed",
        {numUnits = GameRules.numUnits})
    end
  end)

  -- Level all of the unit's abilities to max
  if npc:IsHero() then
    npc:SetAbilityPoints(0)
  end

  for i=0,16 do
    local ability = npc:GetAbilityByIndex(i)
    if ability then
      local level = math.min(ability:GetMaxLevel(), npc:GetLevel())
      ability:SetLevel(level)
    end
  end

  if npc:IsRealHero() and npc.bFirstSpawned == nil then
    npc.bFirstSpawned = true
    GameMode:OnHeroInGame(npc)
  end

  -- handle unique material sets and animations
  if npc:GetUnitName() == "frost_wyrm" then
    npc:SetMaterialGroup("3")
  elseif npc:GetUnitName() == "azure_drake" then
    npc:SetMaterialGroup("2")
  elseif npc:GetUnitName() == "red_dragon" then
    npc:SetMaterialGroup("1")
  elseif npc:GetUnitName() == "energy_tower" then
    npc:SetMaterialGroup("dire_level6")
    StartAnimation(npc, {duration=-1, activity=ACT_DOTA_CONSTANT_LAYER, rate=0.8, translate="level6"})
  end

  Units:Init(npc)
end

function GameMode:OnHeroInGame(hero)
  print("Hero Spawned")

  if hero:GetUnitName() ~= "npc_dota_hero_wisp" then
    hero.hasPicked = true
  end

  -- Add bots to the playerids list
  local playerID = hero:GetPlayerOwnerID()
  if not TableContainsValue(GameRules.playerIDs, playerID) then
    print("Didn't find playerID, ", playerID, " inserting")
    table.insert(GameRules.playerIDs, playerID)
  end

  if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:IsFakeClient(playerID)
    and hero:GetUnitName() ~= "npc_dota_hero_wisp" then
    print("Bot Hero Spawned")
    BotAI:Init(hero)
  end

  PlayerResource:SetDefaultSelectionEntity(playerID, hero)
  GameRules.heroList[playerID] = hero

  -- Move the camera to the hero
  PlayerResource:SetCameraTarget(playerID, hero)
  Timers:CreateTimer(.5, function()
    PlayerResource:SetCameraTarget(playerID, nil)
  end)

  -- Initialize custom resource values
  SetLumber(playerID, 0)
  SetCheese(playerID, 0)
  SetCustomGold(playerID, 0)

  -- Get rid of the tp scroll
  Timers:CreateTimer(.03, function()
    for i=0,16 do
      local item = hero:GetItemInSlot(i)
      if item ~= nil then
        item:RemoveSelf()
      end
    end

    local unitName = hero:GetUnitName()
    local items = g_Race_Items[unitName]
    if items then
      for _,itemname in ipairs(items) do
        hero:AddItem(CreateItem(itemname, hero, hero))
      end
    end

    hero:AddItem(CreateItem("item_build_treasure_box", hero, hero))

    -- Stun the hero until the round starts
    hero:AddNewModifier(hero, nil, "modifier_stunned_custom", {})

    -- Place the hero at a random spawn location
    local spawnPositions
    if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
      spawnPositions = Entities:FindAllByClassname("info_player_start_goodguys")
    else
      spawnPositions = Entities:FindAllByClassname("info_player_start_badguys")
    end

    local spawnPosition = GetRandomTableElement(spawnPositions):GetAbsOrigin()
    hero:SetAbsOrigin(spawnPosition)

    -- Only precache if the game has actually started
    -- This is so we don't needlessly precache the heroes the bots random
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    -- Precache this race
      if not GameRules.precached[unitName] and g_Precache_Tables[unitName] then
        for _,unit in ipairs(g_Precache_Tables[unitName]) do
          GameRules.numToCache = GameRules.numToCache + 1

          PrecacheUnitByNameAsync(unit, function(unit)
            GameRules.numToCache = GameRules.numToCache - 1
            print(GameRules.numToCache)
           end)
        end

        GameRules.precached[unitName] = true
      end
    end
  end) 
end

function GameMode:OnEntityKilled(keys)
  local killed = EntIndexToHScript(keys.entindex_killed)
  local killer = nil

  if keys.entindex_attacker ~= nil then
    killer = EntIndexToHScript( keys.entindex_attacker )
  end

  if not IsCustomBuilding(killed) and not killed.BHDUMMY then
    GameRules.numUnits = GameRules.numUnits - 1
    CustomGameEventManager:Send_ServerToAllClients("num_units_changed",
      {numUnits = GameRules.numUnits})
  end

  if killed:GetUnitName() == "castle" then
    if GameRules.roundInProgress then
      GameMode:EndRound(killed:GetTeam())
      killed:EmitSound("Radiant.ancient.Destruction")
    end
    return
  end

  local bounty = killed:GetGoldBounty()
  if killer and bounty and not DeepTableCompare(killer == killed, true) then
    -- when you use forcekill, it's the same as the unit killing itself
    local killerPlayerID = killer.playerID or killer:GetPlayerOwnerID()
    if killerPlayerID and killerPlayerID >= 0 then
      -- Tax the bounty
      bounty = bounty * GameMode:GetTaxRateForPlayer(killerPlayerID)

      local player = PlayerResource:GetPlayer(killerPlayerID)

      -- Don't show the message if it's going to show it anyway
      if not (killer:GetPlayerOwnerID() and killer:GetPlayerOwnerID() >= 0) and player then
        SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, killed, bounty, player)
      end
      -- PlayerResource:ModifyGold(killerPlayerID, bounty, false, DOTA_ModifyGold_CreepKill)
      ModifyCustomGold(killerPlayerID, bounty)

      GameRules.unitsKilled[killerPlayerID] = GameRules.unitsKilled[killerPlayerID] + 1
    else
      -- print(killer:GetUnitName() .. " doesn't have a .playerID")
    end
  end

  if IsCustomBuilding(killed) and not killed:IsUnderConstruction() then
    local killedPlayerID = killed:GetPlayerOwnerID()

    -- Lose the income value that this building was generating
    local lostIncome = killed.incomeValue
    GameMode:ModifyIncome(killedPlayerID, -lostIncome)

    if killed:GetUnitName() == "item_build_treasure_box" then
      GameMode:ModifyNumBoxes(killedPlayerID, -1)
    end

    -- Refund Cheese when a legendary building dies
    if killed:IsLegendary() then
      ModifyCheese(killedPlayerID, 1)
    end
  end

  Corpses:CreateFromUnit(killed)
end

function GameMode:OnConnectFull(keys)
  local entIndex = keys.index+1
  -- The Player entity of the joining user
  local ply = EntIndexToHScript(entIndex)
  -- The Player ID of the joining player
  local playerID = ply:GetPlayerID()
  local userID = keys.userid

  if playerID < 0 then return end

  self.vUserIds = self.vUserIds or {}
  self.vUserIds[userID] = ply
  print(playerID .. " connected")

  -- SetLumber(playerID, 0)
  -- SetCheese(playerID, 0)
  -- SetCustomGold(playerID, 0)

  if not TableContainsValue(GameRules.playerIDs, playerID) then
    -- insert player data for stat tracking
    local playerData = {
      playerID = playerID,
      steamID = tostring(PlayerResource:GetSteamID(playerID)),
      username = PlayerResource:GetPlayerName(playerID),
    }
    table.insert(GameRules.GameData.playerInfo, playerData)

    -- insert playerID to list of playerIDs
    table.insert(GameRules.playerIDs, playerID)

    -- Insert into list of actions
    GameRules.PlayerOrderTime[playerID] = GameRules:GetGameTime()

    -- initialize settings vote values
    GameRules.numRoundsVotes[playerID] = 2
    GameRules.allowBotsVote[playerID] = false
  end
end

function GameMode:OnPlayerReconnect(keys)
  print("OnPlayerReconnect")
  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local playerHero = player:GetAssignedHero()
  
  -- Reconnecting counts as an action
  GameRules.PlayerOrderTime[playerID] = GameRules:GetGameTime()
end

function GameMode:OnConstructionCompleted(building, ability, isUpgrade, previousIncomeValue)
  local buildingType = building:GetBuildingType()
  local hero = building:GetOwner()
  local playerID = building:GetPlayerOwnerID()
  -- local goldCost = ability:GetGoldCost(ability:GetLevel())
  local gold_cost = tonumber(ability:GetAbilityKeyValues()['GoldCost']) or 0

  -- If this building produced units, give the player lumber
  if buildingType == "UnitTrainer" or buildingType == "SiegeTrainer" then
    SendOverheadEventMessage(hero, OVERHEAD_ALERT_HEAL, building, gold_cost, nil)
    hero:GiveLumber(gold_cost)
  end

  -- If the unit is a treasure box, increase the income for the team
  if building:GetUnitName() == "treasure_box" then
    GameMode:ModifyNumBoxes(playerID, 1)
  end

  -- Give the player a reward for being the nth player to build a building
  -- reward is 20, 15, 10, 5
  if GameRules.buildingsBuilt[playerID] == 0 then
    local numBuilt = GameRules.numPlayersBuilt
    local reward = 20 - numBuilt * 5

    if reward > 0 then
      local rewardMessage = "You received <font color='#FFBF00'>" .. reward .. "</font> gold for being the <font color='#00C400'>" .. 
        numBuilt + 1 .. getNumberSuffix(numBuilt + 1) .. "</font> player to build a building."
      Notifications:Top(playerID, {text=rewardMessage, duration=8.0})

      -- hero:ModifyGold(reward, false, DOTA_ModifyGold_Unspecified)
      hero:ModifyCustomGold(reward)
    end

    GameRules.numPlayersBuilt = numBuilt + 1
  end

  GameRules.buildingsBuilt[playerID] = GameRules.buildingsBuilt[playerID] + 1

  local increase = GameMode:GetIncomeIncreaseForBuilding(building, gold_cost)

  -- Track how much income this building is generating
  if isUpgrade then
    building.incomeValue = previousIncomeValue + increase
  else
    building.incomeValue = increase
  end

  GameMode:ModifyIncome(playerID, building.incomeValue)

  -- Add to build order for stat tracking
  local buildTime = math.floor(GameRules:GetGameTime() - GameRules.roundStartTime)
  table.insert(GameRules.buildOrders[playerID], {
    building = building:GetUnitName(),
    buildTime = buildTime,
  })
end

function OnRaceSelected(eventSourceIndex, args)
  local playerID = args.PlayerID
  local heroName = args.hero

  if not GameRules.InHeroSelection then return end

  if heroName == "random" then
    GameMode:RandomHero(playerID)
  else
    PlayerResource:ReplaceHeroWith(playerID, heroName, 0, 0)
  end

  GameRules.needToPick = GameRules.needToPick - 1

  print(GameRules.needToPick .. " players still need to pick")

  if GameRules.needToPick <= 0 then
    GameMode:EndHeroSelection()
  end
end