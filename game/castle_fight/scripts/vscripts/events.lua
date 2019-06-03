function GameMode:OnGameRulesStateChange()
  local nNewState = GameRules:State_Get()
  if nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
    print( "[PRE_GAME] in Progress" )
  elseif nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    GameMode:OnGameInProgress()
  end
end

function GameMode:OnGameInProgress()
  GameMode:StartRound()
end

function GameMode:OnNPCSpawned(keys)
  local npc = EntIndexToHScript(keys.entindex)

  -- Ignore specific units
  local unitName = npc:GetUnitName()
  if unitName == "npc_dota_hero_treant" then return end
  if unitName == "npc_dota_thinker" then return end
  if unitName == "npc_dota_units_base" then return end
  if unitName == "" then return end

  -- Level all of the unit's abilities to max
  if npc:IsHero() then
    npc:SetAbilityPoints(0)
  end

  for i=0,16 do
    local ability = npc:GetAbilityByIndex(i)
    if ability then ability:SetLevel(ability:GetMaxLevel()) end
  end

  if npc:IsRealHero() and npc.bFirstSpawned == nil then
      npc.bFirstSpawned = true
      GameMode:OnHeroInGame(npc)
  end

  Units:Init(npc)
end

function GameMode:OnHeroInGame(hero)
  print("Hero Spawned")

  -- Get rid of the tp scroll
  Timers:CreateTimer(.03, function()
    for i=0,15 do
      local item = hero:GetItemInSlot(i)
      if item ~= nil and item:GetAbilityName() == "item_tpscroll" then
        item:RemoveSelf()
      end
    end

    hero:AddItem(CreateItem("item_build_gjallarhorn", hero, hero))
    hero:AddItem(CreateItem("item_build_artillery", hero, hero))
    hero:AddItem(CreateItem("item_build_watch_tower", hero, hero))
    hero:AddItem(CreateItem("item_build_heroic_shrine", hero, hero))
    hero:AddItem(CreateItem("item_build_treasure_box", hero, hero))
    hero:AddItem(CreateItem("item_rescue_strike", hero, hero))
  end)  
end

function GameMode:OnEntityKilled(keys)
  local killed = EntIndexToHScript(keys.entindex_killed)
  local killer = nil

  if keys.entindex_attacker ~= nil then
    killer = EntIndexToHScript( keys.entindex_attacker )
  end

  if killed:GetUnitName() == "castle" then
    GameMode:EndRound(killed:GetTeam())
  end

  local bounty = killed:GetGoldBounty()
  if killer and bounty then
    local player = killer:GetPlayerOwner()
    local playerID = killer:GetPlayerOwnerID()
    SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, killed, bounty, nil)
    PlayerResource:ModifyGold(playerID, bounty, true, DOTA_ModifyGold_CreepKill)
  end

  if building:GetUnitName == "item_build_treasure_box" then
    if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
      GameRules.numLeftTreasureBoxes = GameRules.numLeftTreasureBoxes - 1
    else
      GameRules.numRightTreasureBoxes = GameRules.numRightTreasureBoxes - 1
    end
  end
end

function GameMode:OnConnectFull(keys)
  local entIndex = keys.index+1
    -- The Player entity of the joining user
    local ply = EntIndexToHScript(entIndex)

    -- The Player ID of the joining player
    local playerID = ply:GetPlayerID()

    table.insert(GameRules.playerIDs, playerID)
end

function GameMode:OnPlayerReconnect(keys)
  print("OnPlayerReconnect")
  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local playerHero = player:GetAssignedHero()
  
  -- Update the ui to reflect the player's current state
end

function GameMode:OnConstructionCompleted(building, ability)
  local buildingType = building:GetBuildingType()
  local hero = building:GetOwner()
  local playerID = building:GetPlayerOwnerID()
  local goldCost = ability:GetGoldCost(ability:GetLevel())

  -- If this building produced units, give the player lumber
  if buildingType == "UnitTrainer" or buildingType == "SiegeTrainer" then
    SendOverheadEventMessage(hero, OVERHEAD_ALERT_HEAL, building, goldCost, nil)
    hero:GiveLumber(goldCost)
  end

  -- If the unit is a treasure box, increase the income for the team
  if building:GetUnitName == "item_build_treasure_box" then
    if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
      GameRules.numLeftTreasureBoxes = GameRules.numLeftTreasureBoxes + 1
    else
      GameRules.numRightTreasureBoxes = GameRules.numRightTreasureBoxes + 1
    end
  end

  table.insert(GameRules.buildingsBuilt[playerID], building)

  GameMode:IncreaseIncomeByBuilding(building, goldCost)
end