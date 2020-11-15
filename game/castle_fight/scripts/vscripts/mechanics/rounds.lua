function GameMode:SpawnCastles()
  GameRules.leftCastle = BuildingHelper:PlaceBuilding(nil, "castle", GameRules.leftCastlePosition, 2, 2, 0, DOTA_TEAM_GOODGUYS)
  GameRules.rightCastle = BuildingHelper:PlaceBuilding(nil, "castle", GameRules.rightCastlePosition, 2, 2, 0, DOTA_TEAM_BADGUYS)
end

function GameMode:SetupHeroes()
  for _,hero in pairs(HeroList:GetAllHeroes()) do
    if hero:IsAlive() then
      -- hero:ModifyGold(STARTING_GOLD - hero:GetGold(), false, 0)
      hero:SetCustomGold(STARTING_GOLD)
      hero:SetLumber(STARTING_LUMBER)
      hero:SetCheese(STARTING_CHEESE)
      hero:AddNewModifier(hero, nil, "income_modifier", {duration=10})
      hero:RemoveModifierByName("modifier_stunned_custom")
      if not hero:HasItemInInventory("item_rescue_strike") then
        hero:AddItem(CreateItem("item_rescue_strike", hero, hero))
      end
    end
  end
end

function GameMode:SetupShops()
  GameMode:SetupShopForTeam(DOTA_TEAM_GOODGUYS)
  GameMode:SetupShopForTeam(DOTA_TEAM_BADGUYS)
end

function GameMode:InitializeRoundStats()
  GameRules.roundStartTime = GameRules:GetGameTime()
  GameRules.numPlayersBuilt = 0

  GameRules.unitsKilled = {}
  GameRules.buildingsBuilt = {}
  GameRules.numUnitsTrained = {}
  GameRules.rescueStrikeDamage = {}
  GameRules.rescueStrikeKills = {}

  for _,playerID in pairs(GameRules.playerIDs) do
    GameRules.unitsKilled[playerID] = 0
    GameRules.buildingsBuilt[playerID] = 0
    GameRules.numUnitsTrained[playerID] = 0
    GameRules.rescueStrikeDamage[playerID] = 0
    GameRules.rescueStrikeKills[playerID] = 0
    GameRules.buildOrders[playerID] = {}
  end

  GameMode:ResetIncome()
end

function GameMode:StartIncomeTimer()
  Timers:CreateTimer("IncomeTimer", {
    endTime = INCOME_TICK_RATE,
    callback = function()
      GameMode:PayIncome()
      return INCOME_TICK_RATE
    end
  })
end

function GameMode:StopIncomeTimer()
  Timers:RemoveTimer("IncomeTimer")
end

function GameMode:RandomHero(playerID)
  local heroes = {
    human = "npc_dota_hero_kunkka",
    naga = "npc_dota_hero_slark",
    nature = "npc_dota_hero_treant",
    night_elves = "npc_dota_hero_vengefulspirit",
    undead = "npc_dota_hero_abaddon",
    orc = "npc_dota_hero_juggernaut",
    north = "npc_dota_hero_tusk",
    elves = "npc_dota_hero_invoker",
    chaos = "npc_dota_hero_chaos_knight",
    corrupted = "npc_dota_hero_grimstroke",
    mech = "npc_dota_hero_tinker",
  }

  local botHeroes = {
    "npc_dota_hero_kunkka",
  }

  local heroesAvailable = CustomNetTables:GetTableValue("heroes_available", tostring(playerID))
  local heroesToPickFrom = {}

  for _,availableHero in pairs(heroesAvailable.heroes) do
    table.insert(heroesToPickFrom, heroes[availableHero])
  end

  -- Randomly select a hero from the pool
  local hero = GetRandomTableElement(heroesToPickFrom)

  if PlayerResource:IsFakeClient(playerID) then
    hero = GetRandomTableElement(botHeroes)
  end

  PlayerResource:ReplaceHeroWith(playerID, hero, 0, 0)
end

function GameMode:StartRoundTimer()
  GameRules.roundSeconds = 0
  GameRules.RoundTimer = Timers:CreateTimer(function()
    CustomGameEventManager:Send_ServerToAllClients("round_timer",
      {time = ConvertTimeToTable(GameRules.roundSeconds)})

    GameRules.roundSeconds = GameRules.roundSeconds + 1

    return 1
  end)
end

function GameMode:StartHeroSelection()
  print("StartHeroSelection()")

  GameMode:SetAvailableHeroes()

  GameRules.InHeroSelection = true
  CustomNetTables:SetTableValue("hero_select", "status", {ongoing = true})

  CustomGameEventManager:Send_ServerToAllClients("round_timer",
    {time = ConvertTimeToTable(0)})

  GameRules.needToPick = 0
  for _,hero in pairs(HeroList:GetAllHeroes()) do
    if hero:IsAlive() then
      hero.hasPicked = false
      local dummy = PlayerResource:ReplaceHeroWith(hero:GetPlayerOwnerID(), "npc_dota_hero_wisp", 0, 0)
      if dummy then
        dummy:AddNewModifier(dummy, nil, "modifier_hide_hero", {})
      end
    end
  end

  GameRules.needToPick = TableCount(GameRules.playerIDs)

  -- Have the bots pick automatically
  for _,hero in pairs(HeroList:GetAllHeroes()) do
    local playerID = hero:GetPlayerOwnerID()

    if PlayerResource:IsFakeClient(playerID) then
      OnRaceSelected(0, {PlayerID = playerID, hero = "npc_dota_hero_kunkka"})
    end
  end

  local timeToStart = HERO_SELECT_TIME
  -- Reset the timer if it's already going
  Timers:RemoveTimer(GameRules.HeroSelectionTimer)

  GameRules.HeroSelectionTimer = Timers:CreateTimer(function()
    CustomGameEventManager:Send_ServerToAllClients("countdown",
      {seconds = timeToStart})

    if timeToStart == 0 then
      --Hero Selection is over
      GameMode:EndHeroSelection()
    end

    timeToStart = timeToStart - 1

    return 1
  end)
end


function GameMode:SetAvailableHeroes()
  local heroes = {
    "human",
    "naga",
    "nature",
    "night_elves",
    "undead",
    "orc",
    "north",
    "elves",
    "chaos",
    "corrupted",
    "mech",
  }
  
  local availableHeroes = {}
  
  local draftMode = tonumber(CustomNetTables:GetTableValue("settings", "draft_mode")["draftMode"])
  
  for _,playerID in pairs(GameRules.playerIDs) do
    if draftMode == 1 then -- All pick
      availableHeroes = heroes
    elseif draftMode == 2 then -- Single draft
      availableHeroes = GetRandomTableElements(heroes, 3)
    elseif draftMode == 3 then -- All random
      availableHeroes = GetRandomTableElements(heroes, 1)
    end
  
    CustomNetTables:SetTableValue("heroes_available", tostring(playerID), {
      heroes = availableHeroes,
    })
  end  
  
  CustomGameEventManager:Send_ServerToAllClients("available_heroes", {})
end

function GameMode:EndHeroSelection()
  Timers:RemoveTimer(GameRules.HeroSelectionTimer)

  GameRules.InHeroSelection = false
  CustomNetTables:SetTableValue("hero_select", "status", {ongoing = false})
  -- Force players who haven't picked to random a hero
  for _,hero in pairs(HeroList:GetAllHeroes()) do
    if hero:IsAlive() and not hero.hasPicked then
      GameMode:RandomHero(hero:GetPlayerOwnerID())
    end
  end

  -- Wait for loading, then start the next round
  GameMode:WaitToLoad()
end

function GameMode:WaitToLoad()
  CustomGameEventManager:Send_ServerToAllClients("loading_started", {})

  Timers:RemoveTimer(GameRules.LoadingTimer)

  local announcerLine = RandomInt(1, 2)
  EmitAnnouncerSound("announcer_ann_custom_round_begin_0" .. announcerLine)

  GameRules.LoadingTimer = Timers:CreateTimer(1, function()
    if GameRules.numToCache == 0 then
      -- Start the next round after we've finished precaching everything
      GameMode:StartRound()
      return
    end
    return 1
  end)
end

-- Kills all units and structures, including both castles. Does not kill heroes.
function GameMode:KillAllUnitsAndBuildings()
  local numSweeps = 5
  -- Kill everything multiple times, to make sure we get revivers
  Timers:CreateTimer(function()
    if numSweeps <= 0 then return end
    for _,unit in pairs(FindAllUnits()) do
      if not unit:IsHero() then
        unit:ForceKill(false)
      end
    end

    numSweeps = numSweeps - 1

    return 1/30
  end)
end

function GameMode:PlayEndRoundAnimations(winningTeam)
  for _,unit in pairs(FindAllUnits()) do
    if unit:GetTeam() == winningTeam then
      unit:StartGesture(ACT_DOTA_VICTORY)
    else
      unit:StartGesture(ACT_DOTA_DEFEAT)
    end
    unit:AddNewModifier(unit, nil, "modifier_end_round", {})
  end
end

--------------------------------------------------------
-- Constantly checking game status
--------------------------------------------------------
function GameMode:CheckLeavers()
  -- Don't check for leavers in cheat mode
  if GameRules:IsCheatMode() then return end
  if TableCount(GameRules.playerIDs) < 3 then return end
  -- if all players on a team have been disconnected for 10 seconds
  -- automatically end the round, and the game
  Timers:CreateTimer(function()
    local goodConnected, badConnected = GameMode:CheckFullTeamDisconnect()
    local bothTeamsConnected = goodConnected and badConnected
    if not bothTeamsConnected and not GameRules.CheckingForLeavers then
      GameRules.CheckingForLeavers = true
      Timers:CreateTimer(10, function()
        GameRules.CheckingForLeavers = false
        local goodConnected, badConnected = GameMode:CheckFullTeamDisconnect()
        if not goodConnected and not badConnected then
          GameMode:EndRound(DOTA_TEAM_NEUTRALS)
          GameMode:EndGame(DOTA_TEAM_NEUTRALS)
        elseif not goodConnected then
          GameMode:EndRound(DOTA_TEAM_GOODGUYS)
          GameMode:EndGame(DOTA_TEAM_BADGUYS)
        elseif not badConnected then
          GameMode:EndRound(DOTA_TEAM_BADGUYS)
          GameMode:EndGame(DOTA_TEAM_GOODGUYS)
        end
      end)
    end
    return 1
  end)
end

function GameMode:CheckFullTeamDisconnect()
  local radiantConnected = false
  local direConnected = false
  for _,playerID in pairs(GameRules.playerIDs) do
    if PlayerResource:IsFakeClient(playerID) then
      -- If there is a bot player, always return that both teams are connected
      return true, true
    end

    local team = PlayerResource:GetTeam(playerID)
    local connected = PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED

    if connected then
      if team == DOTA_TEAM_GOODGUYS then
        radiantConnected = true
      elseif team == DOTA_TEAM_BADGUYS then
        direConnected = true
      end
    end
  end

  return radiantConnected, direConnected
end

function GameMode:DetectAFK()
  if GameRules:IsCheatMode() then return end
  if GameRules:IsInToolsMode() then return end

  Timers:CreateTimer(function()
    if not GameRules.roundInProgress then return 1 end

    for playerID, lastOrderTime in pairs(GameRules.PlayerOrderTime) do
      local timeSinceLastOrder = GameRules:GetGameTime() - lastOrderTime

      local connected = PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED
      local isBot = PlayerResource:IsFakeClient(playerID)

      if connected and not isBot and timeSinceLastOrder > AFK_DETECTION_TIME then
        print("player" .. playerID .. " is afk for " .. timeSinceLastOrder .. " seconds")
        CustomGameEventManager:Send_ServerToPlayer(player, "kick_afk", {})
      end
    end

    return 1
  end)
  
end

function GameMode:RefreshOrderTimes()
  -- Act as though each player just issued an order
  for _,playerID in pairs(GameRules.playerIDs) do
    GameRules.PlayerOrderTime[playerID] = GameRules:GetGameTime()
  end
end

--------------------------------------------------------
-- Start Round
--------------------------------------------------------
function GameMode:StartRound()
  -- Wait for precaching to finish before starting the round
  Timers:CreateTimer(function()
    if GameRules.numToCache > 0 then
      print("Loading...")
      return 1
    end

    print("Starting Round")
    ClearDrawSettings()
    ClearGGVote(DOTA_TEAM_GOODGUYS)
    ClearGGVote(DOTA_TEAM_BADGUYS)
    GameMode:StartDrawVoteCountdown(DRAW_VOTE_DELAY)

    GameMode:InitializeRoundStats()
    GameMode:SpawnCastles()
    GameMode:SetupHeroes()
    GameMode:SetupShops()
    GameMode:StartIncomeTimer()
    GameMode:StartRoundTimer()
    GameMode:RefreshOrderTimes()

    Notifications:TopToAll({text="Round " .. GameRules.roundCount .. " started!", duration=3.0})

    EmitGlobalSound("GameStart.RadiantAncient")

    CustomGameEventManager:Send_ServerToAllClients("round_started",
      {round = GameRules.roundCount})

    GameRules.roundInProgress = true
  end)
end

--------------------------------------------------------
-- End Round
--------------------------------------------------------
function GameMode:EndRound(losingTeam)
  if not GameRules.roundInProgress then return end
  GameRules.roundInProgress = false

  ClearDrawSettings()

  -- Clear timers
  Timers:RemoveTimer(GameRules.GGTimerWest)
  Timers:RemoveTimer(GameRules.GGTimerEast)

  -- Record the winner
  local winningTeam
  local losingCastlePosition
  if losingTeam == DOTA_TEAM_BADGUYS then
    winningTeam = DOTA_TEAM_GOODGUYS
    GameRules.leftRoundsWon = GameRules.leftRoundsWon + 1
    losingCastlePosition = GameRules.rightCastlePosition
  elseif losingTeam == DOTA_TEAM_GOODGUYS then
    winningTeam = DOTA_TEAM_BADGUYS
    GameRules.rightRoundsWon = GameRules.rightRoundsWon + 1
    losingCastlePosition = GameRules.leftCastlePosition
  else
    -- game ended in a draw
    winningTeam = DOTA_TEAM_NEUTRALS
    losingCastlePosition = Vector(0,0,0)
  end

  -- Reveal the map
  AddFOWViewer(DOTA_TEAM_BADGUYS, Vector(0,0,0), 9999, POST_ROUND_TIME, false)
  AddFOWViewer(DOTA_TEAM_BADGUYS, GameRules.rightCastlePosition, 9999, POST_ROUND_TIME, false)
  AddFOWViewer(DOTA_TEAM_BADGUYS, GameRules.leftCastlePosition, 9999, POST_ROUND_TIME, false)
  AddFOWViewer(DOTA_TEAM_GOODGUYS, Vector(0,0,0), 9999, POST_ROUND_TIME, false)
  AddFOWViewer(DOTA_TEAM_GOODGUYS, GameRules.rightCastlePosition, 9999, POST_ROUND_TIME, false)
  AddFOWViewer(DOTA_TEAM_GOODGUYS, GameRules.leftCastlePosition, 9999, POST_ROUND_TIME, false)

  -- Record the round stats for stat tracking
  local playerStats = {}

  for _,playerID in pairs(GameRules.playerIDs) do
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    local playerRoundData = {
      playerID = playerID,
      race = heroToRace(hero:GetUnitName()),
      team = hero:GetTeam(),
      unitsKilled = GameRules.unitsKilled[playerID],
      unitsSpawned = GameRules.numUnitsTrained[playerID],
      abandoned = hero:HasOwnerAbandoned(),
      income = math.floor(GameMode:GetIncomeForPlayer(playerID)),
      buildOrder = GameRules.buildOrders[playerID],
    }

    table.insert(playerStats, playerRoundData)

    -- While we're at it, reduce their resources to 0
    SetLumber(playerID, 0)
    SetCheese(playerID, 0)
    SetCustomGold(playerID, 0)
  end

  local roundData = {
    roundNumber = GameRules.roundCount,
    duration = roundDuration,
    winner = winningTeam,
    playerStats = playerStats,
  }

  table.insert(GameRules.GameData.rounds, roundData)

  -- update the client for the end round scoreboard
  CustomNetTables:SetTableValue("round_score", "score", {
    left_score = GameRules.leftRoundsWon,
    right_score = GameRules.rightRoundsWon,
  })

  local maxUnitsKilled = GetTableMax(GameRules.unitsKilled)
  local maxBuildingsBuilt = GetTableMax(GameRules.buildingsBuilt)
  local maxUnitsTrained = GetTableMax(GameRules.numUnitsTrained)
  local maxRescueStrikeDamage = GetTableMax(GameRules.rescueStrikeDamage)
  local maxIncome = 0

  for _,playerID in pairs(GameRules.playerIDs) do
    maxIncome = math.max(maxIncome, GameMode:GetIncomeForPlayer(playerID))
  end

  for _,playerID in pairs(GameRules.playerIDs) do
    CustomNetTables:SetTableValue("round_score", tostring(playerID), {
      unitsKilled = GameRules.unitsKilled[playerID],
      buildingsBuilt = GameRules.buildingsBuilt[playerID],
      numUnitsTrained = GameRules.numUnitsTrained[playerID],
      rescueStrikeDamage = GameRules.rescueStrikeDamage[playerID],
      rescueStrikeKills = GameRules.rescueStrikeKills[playerID],
      income = GameMode:GetIncomeForPlayer(playerID),

      maxUnitsKilled = GameRules.unitsKilled[playerID] == maxUnitsKilled,
      maxBuildingsBuilt = GameRules.buildingsBuilt[playerID] == maxBuildingsBuilt,
      maxUnitsTrained = GameRules.numUnitsTrained[playerID] == maxUnitsTrained,
      maxRescueStrikeDamage = GameRules.rescueStrikeDamage[playerID] == maxRescueStrikeDamage,
      maxIncome = GameMode:GetIncomeForPlayer(playerID) == maxIncome,

    })
  end

  -- Send round info to the clients
  local roundDuration = math.floor(GameRules:GetGameTime() - GameRules.roundStartTime)
  GameRules.roundCount = GameRules.roundCount + 1

  CustomGameEventManager:Send_ServerToAllClients("round_ended", {
    winningTeam = winningTeam,
    losingTeam = losingTeam,
    leftPoints = GameRules.leftRoundsWon,
    rightPoints = GameRules.rightRoundsWon,

    roundNumber = GameRules.roundCount,
    roundDuration = roundDuration,

    losingCastlePosition = losingCastlePosition,
  })

  -- Stop the income timer until the next round
  GameMode:StopIncomeTimer()

  -- Celebrate the end of the round
  GameMode:PlayEndRoundAnimations(winningTeam)

  -- Wait to start the next round
  Timers:RemoveTimer(GameRules.RoundTimer)
  Timers:RemoveTimer(GameRules.PostRoundTimer)

  local pointsToWin = tonumber(CustomNetTables:GetTableValue("settings", "num_rounds")["numRounds"])

  GameRules.PostRoundTimer = Timers:CreateTimer(POST_ROUND_TIME, function()
    if GameRules.leftRoundsWon >= pointsToWin or GameRules.rightRoundsWon >= pointsToWin then
      GameMode:EndGame(winningTeam)
    else
      -- Go into the next round preparation phase
      GameMode:KillAllUnitsAndBuildings()
      GameMode:StartHeroSelection()
    end
  end)
end

function GameMode:EndGame(winningTeam)
  if GameRules.GameEnded then return end

  CustomGameEventManager:Send_ServerToAllClients("game_ended", {})

  GameRules.GameEnded = true

  if winningTeam == DOTA_TEAM_GOODGUYS then
    Notifications:TopToAll({text="Western Forces Victory!", duration=30})
  elseif winningTeam == DOTA_TEAM_BADGUYS then
    Notifications:TopToAll({text="Eastern Forces Victory!", duration=30})
  end

  -- Send the game's stats to the server
  GameRules.GameData.winner = winningTeam

  SendGameStatsToServer()

  GameRules:SetGameWinner(winningTeam)
end
