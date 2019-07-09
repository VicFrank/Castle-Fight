local AbilityData = require("ai/bot_ai/ai_values")

if not BotAI then
  BotAI = class({})
end

function BotAI:Init(hero)
  Timers:CreateTimer(1, function()

    hero.abilityList = {}
    for i=0,15 do
      local ability = hero:GetAbilityByIndex(i)
      if ability then
        table.insert(hero.abilityList, ability)
      end
    end
    for i=0,15 do
      local item = hero:GetItemInSlot(i)
      if item and not item:GetAbilityName() == "item_rescue_strike" then
        table.insert(hero.abilityList, item)
      end
    end

    hero.buildingSize = BuildingHelper:GetConstructionSize("barracks")

    if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
      hero.baseMinBounds = GameRules.leftBaseMinBounds
      hero.baseMaxBounds = GameRules.leftBaseMaxBounds
    else
      hero.baseMinBounds = GameRules.rightBaseMinBounds
      hero.baseMaxBounds = GameRules.rightBaseMaxBounds
    end

    if hero:GetAbsOrigin().y < 0 then
      hero.sideToBuild = "SOUTH"
    else
      hero.sideToBuild = "NORTH"
    end

    return BotAI:OnThink(hero)
  end)
end

function BotAI:OnThink(hero)
  if hero:IsNull() or not hero or not hero:IsAlive() then return end
  if hero:IsStunned() then return 0.1 end

  if BotAI:LookingForNextBuilding(hero) then
    hero.nextBuilding = BotAI:GetNextBuildingToBuild(hero)
    print("Next building is: ", hero.nextBuilding:GetAbilityName())
  end

  if BotAI:WaitingToBuild(hero) then
    return BotAI:RepairBuildings(hero)
  end

  return BotAI:BuildNextBuilding(hero)
end

function BotAI:GetNextBuildingToBuild(hero)
  local currentInterest = GameMode:GetIncome(hero:GetPlayerOwnerID())

  local buildings = {}

  for _,ability in pairs(hero.abilityList) do
    local abilityName = ability:GetAbilityName()
    local abilityData = AbilityData[abilityName]
    local lumber_cost = tonumber(ability:GetAbilityKeyValues()['LumberCost']) or 0
    local cheese_cost = tonumber(ability:GetAbilityKeyValues()['IsLegendary']) or 0
    local gold_cost = tonumber(ability:GetAbilityKeyValues()['GoldCost']) or 0

    local interestToConsider = abilityData.interestToConsider

    if currentInterest >= interestToConsider and hero:GetLumber() >= lumber_cost and
      hero:GetCheese() >= cheese_cost then
      table.insert(buildings, ability)
    end
  end

  return GetRandomTableElement(buildings)
end

function BotAI:GetPlaceToBuild(hero)
  local searchStart
  local searchDirectionX
  local searchDirectionY

  local searchInterval = 200

  if hero.sideToBuild == "SOUTH" then    
    if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
      -- Bottom Left West Base
      searchStart = hero.baseMinBounds
      searchDirectionX = 1
      searchDirectionY = 1
    else
      -- Bottom Right East Base
      searchStart = Vector(hero.baseMaxBounds.x, hero.baseMinBounds.y, 0)
      searchDirectionX = -1
      searchDirectionY = 1
    end
  else    
    if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
      -- Top left West Base
      searchStart = Vector(hero.baseMinBounds.x, hero.baseMaxBounds.y, 0)
      searchDirectionX = 1
      searchDirectionY = -1
    else
      -- Top Right East Base
      searchStart = hero.baseMaxBounds
      searchDirectionX = -1
      searchDirectionY = -1
    end
  end

  local searchLocation = GetGroundPosition(searchStart, hero)

  for i=1,100 do
    local isValidBuildLocation = BotAI:CanBuildAtPosition(hero, searchLocation)
    if isValidBuildLocation then
      return searchLocation
    end

    DebugDrawCircle(searchLocation, Vector(255,0,0), 50, 100, true, 3)

    searchLocation = searchLocation + Vector(0, searchDirectionY * searchInterval, 0)

    -- If you cross the center while searching, reset the y, and move the x
    if hero.sideToBuild == "SOUTH" then
      if searchLocation.y > 0 then
        searchLocation.y = searchStart.y
        searchLocation = searchLocation + Vector(searchDirectionX * searchInterval, 0, 0)
      end
    elseif hero.sideToBuild == "NORTH" then
      if searchLocation.y < 0 then
        searchLocation.y = searchStart.y
        searchLocation = searchLocation + Vector(searchDirectionX * searchInterval, 0, 0)
      end
    end
  end

  return nil
end

function BotAI:CanBuildBuilding(hero, ability)
  -- local gold_cost = ability:GetGoldCost(1) 
  local gold_cost = tonumber(ability:GetAbilityKeyValues()['GoldCost']) or 0
  local lumber_cost = tonumber(ability:GetAbilityKeyValues()['LumberCost']) or 0
  local cheese_cost = tonumber(ability:GetAbilityKeyValues()['IsLegendary']) or 0
  local playerID = hero:GetPlayerID()

  if hero:GetCustomGold() < gold_cost or hero:GetLumber() < lumber_cost or
    hero:GetCheese() < cheese_cost then
      return false
  end

  return true
end

function BotAI:LookingForNextBuilding(hero)
  return not hero.nextBuilding
end

function BotAI:WaitingToBuild(hero)
  if not hero.nextBuilding then
    return false
  end

  local playerID = hero:GetPlayerOwnerID()

  if not BotAI:CanBuildBuilding(hero, hero.nextBuilding) then
    return true
  end

  return false
end

-- TODO: Repair buildings while we're waiting to build
function BotAI:RepairBuildings(hero)
  return 0.1
end

function BotAI:CanBuildAtPosition(hero, position)
  if position == nil then return false end
  BuildingHelper:SnapToGrid(hero.buildingSize, position)
  local canFindPath = GridNav:CanFindPath(hero:GetAbsOrigin(), position)
  local isValidPosition = BuildingHelper:ValidPosition(hero.buildingSize, position, hero, {})
  return canFindPath and isValidPosition
end

function BotAI:BuildNextBuilding(hero)
  local state = hero.state

  if not hero.nextBuilding and state == "idle" then
    -- If we've finished our building queue, start looking for our next building
    print("BotAI: look for next building")
    return 0.5
  end

  local hasValidBuildPosition = hero.buildPosition and BotAI:CanBuildAtPosition(hero, hero.buildPosition)
  if not hasValidBuildPosition then
    -- Find new build position
    hero.buildPosition = BotAI:GetPlaceToBuild(hero)
  end

  if hero.buildPosition then
    BotAI:PlaceBuilding(hero, hero.nextBuilding, hero.buildPosition)
    hero.nextBuilding = nil
  else
    print("Couldn't find buildPosition")
  end
  
  return 1
end

function BotAI:PlaceBuilding(hero, ability, position)
  DebugDrawCircle(position, Vector(0,255,0), 50, 100, true, 3)

  print("Place Building ", position)
  BuildingHelper:OrderBuildingConstruction(hero, ability, position)
end
