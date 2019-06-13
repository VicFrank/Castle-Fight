function GameMode:SpawnCastles()
  local leftCastle = BuildingHelper:PlaceBuilding(nil, "castle", GameRules.leftCastlePosition, 2, 2, 0, DOTA_TEAM_GOODGUYS)
  local rightCastle = BuildingHelper:PlaceBuilding(nil, "castle", GameRules.rightCastlePosition, 2, 2, 0, DOTA_TEAM_BADGUYS)
end

function GameMode:SetupHeroes()
  for _,hero in pairs(HeroList:GetAllHeroes()) do
    hero:ModifyGold(STARTING_GOLD - hero:GetGold(), false, 0)
    hero:SetLumber(STARTING_LUMBER)
    hero:SetCheese(STARTING_CHEESE)
    hero:AddNewModifier(hero, nil, "income_modifier", {duration=10})
    if not hero:HasItemInInventory("item_rescue_strike") then
      hero:AddItem(CreateItem("item_rescue_strike", hero, hero))
    end
  end
end

function GameMode:InitializeRoundStats()
  GameRules.roundCount = GameRules.roundCount + 1

  GameRules.roundTime = 0
  GameRules.numPlayersBuilt = 0

  GameRules.unitsKilled = {}
  GameRules.buildingsBuilt = {}
  GameRules.numUnitsTrained = {}
  GameRules.rescueStrikeDamage = {}
  GameRules.rescueStrikeKills = {}

  for _,playerID in pairs(GameRules.playerIDs) do
    GameRules.unitsKilled[playerID] = {}
    GameRules.buildingsBuilt[playerID] = {}
    GameRules.numUnitsTrained[playerID] = {}
    GameRules.rescueStrikeDamage[playerID] = {}
    GameRules.rescueStrikeKills[playerID] = {}
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

function GameMode:CountdownToNextRound(seconds)
  CustomGameEventManager:Send_ServerToAllClients("start_countdown_timer",
    {seconds = seconds})

  if seconds >= 3 then
    Notifications:TopToAll({text="Get ready for round " .. GameRules.roundCount + 1, duration=3.0})
  end

  Timers:CreateTimer("RoundCountdownTimer", {
    endTime = seconds,
    callback = function()
      GameMode:StartRound()
    end
  })
end

-- Kills all units and structures, including both castles. Does not kill heroes.
function GameMode:KillAllUnitsAndBuildings()
  local allUnits = FindAllUnitsInRadius(FIND_UNITS_EVERYWHERE, Vector(0,0,0))

  for _,unit in pairs(allUnits) do
    if not unit:IsHero() then
      unit:ForceKill(false)
    end
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
    -- Clear the map again, just in case
    GameMode:KillAllUnitsAndBuildings()
    GameMode:InitializeRoundStats()
    GameMode:SpawnCastles()
    GameMode:SetupHeroes()
    GameMode:StartIncomeTimer()

    Notifications:TopToAll({text="Round " .. GameRules.roundCount .. " started!", duration=3.0})

    GameRules.roundInProgress = true
  end)
end

--------------------------------------------------------
-- End Round
--------------------------------------------------------
function GameMode:EndRound(losingTeam)
  GameRules.roundInProgress = false

  local winningTeam  
  if losingTeam == DOTA_TEAM_BADGUYS then
    winningTeam = DOTA_TEAM_GOODGUYS
    GameRules.leftRoundsWon = GameRules.leftRoundsWon + 1
  else
    winningTeam = DOTA_TEAM_BADGUYS
    GameRules.rightRoundsWon = GameRules.rightRoundsWon + 1
  end

  -- Send round info to the clients
  local roundDuration = 0
  local highestIncome = 0
  local mostUnitsKilled = 0
  local mostUnitSpawningBuildings = 0
  local mostSpecialBuildings = 0
  local mostUnitsTrained = 0
  local highestRescueStrikeDamage = 0
  local numKilledFromHighestRescueStrike = 0

  CustomGameEventManager:Send_ServerToAllClients("round_ended", {
    winningTeam = winningTeam,
    losingTeam = losingTeam,
    leftPoints = GameRules.leftRoundsWon,
    rightPoints = GameRules.rightRoundsWon,

    roundNumber = GameRules.roundNumber,

    roundDuration = roundDuration,

    highestIncome = highestIncome,
    mostUnitsKilled = mostUnitsKilled,
    mostUnitSpawningBuildings = mostUnitSpawningBuildings,
    mostSpecialBuildings = mostSpecialBuildings,
    mostUnitsTrained = mostUnitsTrained,
    highestRescueStrikeDamage = highestRescueStrikeDamage,
    numKilledFromHighestRescueStrike = numKilledFromHighestRescueStrike,
  })

  -- Stop the income timer until the next round
  GameMode:StopIncomeTimer()

  -- Clear the map
  GameMode:KillAllUnitsAndBuildings()

  -- Prevent heroes from moving until next round starts
  -- Hide them out of world
  -- TODO

  -- Countdown to next round start
  GameMode:CountdownToNextRound(TIME_BETWEEN_ROUNDS)
end