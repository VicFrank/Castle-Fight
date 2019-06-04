function GameMode:OnScriptReload()
  print("Script Reload")

  -- SpawnTestBuildings()
  -- SpawnRandomBuilding()
  -- KillEverything()
  -- GameMode:StartRound()
  -- GameMode:EndRound()
  GiveLumberToAllPlayers(2000)
  -- KillAllUnits()
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