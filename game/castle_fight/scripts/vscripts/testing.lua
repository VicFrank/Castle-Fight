function GameMode:OnScriptReload()
  print("Script Reload")

  -- SpawnTestBuildings()
  -- SpawnRandomBuilding()
  -- KillEverything()
  -- GameMode:StartRound()
  -- GameMode:EndRound()
  -- GiveLumberToAllPlayers(2000)
  KillAllUnits()
  -- KillAllBuildings()
end

function SpawnTestBuildings()
  -- Only call this on the first script_reload
  if GameRules.SpawnTestBuildings then
    -- return
  else
    GameRules.SpawnTestBuilding = true
  end

  local humanBuildings = {
    "barracks",
    "stronghold",
    "sniper_nest",
    "gunners_hall",
    "marksmens_encampment",
    "weapon_lab",
    "gryphon_rock",
    "chapel",
    "church",
    "hjordhejmen",
    "gjallarhorn",
    "artillery",
    "watch_tower",
    "heroic_shrine",
  }

  for _,building in pairs(humanBuildings) do
    local randomPosition = RandomPositionBetweenBounds(GameRules.rightBaseMinBounds, GameRules.rightBaseMaxBounds)

    BuildingHelper:PlaceBuilding(nil, building, randomPosition, 2, 2, 0, DOTA_TEAM_BADGUYS)
  end

end

function SpawnRandomBuilding()
  local humanBuildings = {
    "barracks",
    "stronghold",
    "sniper_nest",
    "gunners_hall",
    "marksmens_encampment",
    "weapon_lab",
    "gryphon_rock",
    "chapel",
    "church",
    "hjordhejmen",
    "gjallarhorn",
    "artillery",
    "watch_tower",
    "heroic_shrine",
  }

  local building = GetRandomTableElement(humanBuildings)
  local randomPosition = RandomPositionBetweenBounds(GameRules.rightBaseMinBounds, GameRules.rightBaseMaxBounds)

  BuildingHelper:PlaceBuilding(nil, building, randomPosition, 2, 2, 0, DOTA_TEAM_BADGUYS)
end

function KillAllUnits()
  local units = FindAllUnitsInRadius(FIND_UNITS_EVERYWHERE, Vector(0,0,0))

  for _,unit in pairs(units) do
    if not IsCustomBuilding(unit) and not unit:IsHero() then
      unit:ForceKill(false)
    end
  end
end

function KillAllBuildings()
  local units = FindAllUnitsInRadius(FIND_UNITS_EVERYWHERE, Vector(0,0,0))

  for _,unit in pairs(units) do
    if IsCustomBuilding(unit) and unit:GetUnitName() ~= "castle" then
      unit:ForceKill(false)
    end
  end
end

function KillEverything()
  local allUnits = FindAllUnitsInRadius(FIND_UNITS_EVERYWHERE, Vector(0,0,0))

  for _,unit in pairs(allUnits) do
    if not unit:IsHero() then
      unit:ForceKill(false)
    end
  end
end

function GiveLumberToAllPlayers(value)
  for _,hero in pairs(HeroList:GetAllHeroes()) do
    hero:GiveLumber(value)
  end
end

function GameMode:GreedIsGood(playerID, value)
  for _,hero in pairs(HeroList:GetAllHeroes()) do
    hero:GiveLumber(value)
    hero:ModifyGold(value, false, 0)
  end
end

function GameMode:LumberCheat(playerID, value)
  PlayerResource:GetSelectedHeroEntity(playerID):GiveLumber(value)
end

    
CHEAT_CODES = {
  ["lumber"] = function(...) GameMode:LumberCheat(...) end,                -- "Gives you X lumber"
  ["greedisgood"] = function(...) GameMode:GreedIsGood(...) end,           -- "Gives you X gold and lumber" 
  ["unitsaredead"] = function(...) KillAllUnits() end,                     -- "Kills all units"    
  ["reset"] = function(...) KillEverything() end,                          -- "Kills all units and buildings"    
  ["nextround"] = function(...) GameMode:StartRound(...) end,              -- "Calls start round"      
  ["endround"] = function(...) GameMode:EndRound(...) end,                 -- "Calls end round"
}

function GameMode:OnPlayerChat(keys)
  local text = keys.text
  local userID = keys.userid
  local playerID = self.vUserIds[userID] and self.vUserIds[userID]:GetPlayerID()
  if not playerID then return end

  -- Cheats are only available in the tools
  if not IsInToolsMode() then return end

  -- Handle '-command'
  if StringStartsWith(text, "-") then
      text = string.sub(text, 2, string.len(text))
  end

  local input = split(text)
  local command = input[1]
  if CHEAT_CODES[command] then
    CHEAT_CODES[command](playerID, input[2])
  end
end