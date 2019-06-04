function GameMode:SpawnCastles()
  local leftCastle = BuildingHelper:PlaceBuilding(nil, "castle", GameRules.leftCastlePosition, 2, 2, 0, DOTA_TEAM_GOODGUYS)
  local rightCastle = BuildingHelper:PlaceBuilding(nil, "castle", GameRules.rightCastlePosition, 2, 2, 0, DOTA_TEAM_BADGUYS)
end

function GameMode:SetupHeroes()
  for _,hero in pairs(HeroList:GetAllHeroes()) do
    hero:ModifyGold(STARTING_GOLD - hero:GetGold(), false, 0)
    hero:SetLumber(STARTING_LUMBER)
    hero:AddNewModifier(hero, nil, "income_modifier", {duration=10})
    hero:AddNewModifier(hero, nil, "income_modifier_enemy", {duration=10})
    if not hero:HasItemInInventory("item_rescue_strike") then
      hero:AddItem(CreateItem("item_rescue_strike", hero, hero))
    end
  end
end

function GameMode:InitializeRoundStats()
  GameRules.roundTime = 0
  GameRules.leftIncome = 5
  GameRules.rightIncome = 5
  GameRules.numLeftTreasureBoxes = 0
  GameRules.numRightTreasureBoxes = 0

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

  Timers:CreateTimer("RoundCountdownTimer", {
    endTime = seconds,
    callback = function()
      GameMode:StartRound()
    end
  })
end

--------------------------------------------------------
-- Start Round
--------------------------------------------------------
function GameMode:StartRound()
  print("Starting Round")
  GameMode:InitializeRoundStats()
  GameMode:SpawnCastles()
  GameMode:SetupHeroes()
  GameMode:StartIncomeTimer()
end

--------------------------------------------------------
-- End Round
--------------------------------------------------------
function GameMode:EndRound(losingTeam)
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

  -- Clear the map of all units/structures
  local allUnits = FindAllUnitsInRadius(FIND_UNITS_EVERYWHERE, Vector(0,0,0))

  for _,unit in pairs(allUnits) do
    if not unit:IsHero() then
      unit:ForceKill(false)
    end
  end

  -- Stop the income timer until the next round
  GameMode:StopIncomeTimer()

  -- Prevent heroes from moving until next round starts
  -- Hide them out of world
  -- TODO

  -- Countdown to next round start
  GameMode:CountdownToNextRound(TIME_BETWEEN_ROUNDS)
end