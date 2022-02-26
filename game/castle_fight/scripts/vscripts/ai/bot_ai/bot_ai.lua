local AbilityData = require("ai/bot_ai/ai_values")
local BuildingData = require("ai/bot_ai/building_values")

if not BotAI then
  BotAI = class({})
end

function BotAI:Init(hero)
  Timers:CreateTimer(1, function()
    hero.abilityList = {}
    for i=0,15 do
      local ability = hero:GetAbilityByIndex(i)
      if ability and ability:GetAbilityName() ~= "ability_capture" then
        table.insert(hero.abilityList, ability)
      end
    end
    for i=0,15 do
      local item = hero:GetItemInSlot(i)
      if item then
        if item:GetAbilityName() == "item_rescue_strike" then
          hero.rescueStrikeAbility = item
        else
          table.insert(hero.abilityList, item)
        end
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
  end)

  Timers:CreateTimer(1, function()
    return BotAI:OnThink(hero)
  end)
end

function BotAI:OnThink(hero)
  if hero:IsNull() or not hero or not hero:IsAlive() then return end
  if hero:IsStunned() then return 0.1 end


  if BotAI:LookingForNextBuilding(hero) then
    BotAI:GetNextBuildingToBuild(hero)
  end

  if BotAI:WaitingToBuild(hero) then
    -- if BotAI:WantsToRescueStrike(hero) then
    --   BotAI:PrepareRescueStrike(hero)
    -- end
    return BotAI:RepairBuildings(hero)
  end

  -- if IsInToolsMode() then return 1 end

  return BotAI:BuildNextBuilding(hero)
end

function BotAI:GetNextBuildingToBuild(hero)
  local currentInterest = GameMode:GetIncome(hero:GetPlayerOwnerID())

  local currentBuildings = BuildingHelper:GetBuildings(hero:GetPlayerOwnerID())

  -- If we can upgrade a building, do so
  for _,building in pairs(currentBuildings) do
    if not building:IsNull() and building:IsAlive() then
      local buildingName = building:GetUnitName()
      local buildingData = BuildingData[buildingName]
      local upgrades = buildingData.upgrades
      if upgrades then
        local nextUpgrade = GetRandomTableElement(upgrades)
        local upgradeAbility = building:FindAbilityByName(nextUpgrade)
        local hasEnoughSpecialResources = BotAI:HasEnoughSpecialResources(hero, upgradeAbility)

        if hasEnoughSpecialResources and not building:IsChanneling() then
          hero.nextUpgrade = {
            building = building,
            ability = upgradeAbility,
          }
          -- print("Next building (upgrade) is: ", upgradeAbility:GetAbilityName())
          return
        end
      end
    end
  end

  local buildings = {}

  for _,ability in pairs(hero.abilityList) do
    local abilityName = ability:GetAbilityName()
    local abilityData = AbilityData[abilityName]

    if abilityData then
      local interestToConsider = abilityData.interestToConsider
      local hasEnoughSpecialResources = BotAI:HasEnoughSpecialResources(hero, ability)

      if currentInterest >= interestToConsider and hasEnoughSpecialResources then
        table.insert(buildings, ability)
      end
    else
      -- print("Data for ability " .. abilityName .. " not found")
    end    
  end

  local nextBuilding = GetRandomTableElement(buildings)
  hero.nextBuilding = nextBuilding
  -- print("Next building is: ", nextBuilding:GetAbilityName())
end

function BotAI:HasEnoughSpecialResources(hero, ability)
  local lumber_cost = tonumber(ability:GetAbilityKeyValues()['LumberCost']) or 0
  local cheese_cost = tonumber(ability:GetAbilityKeyValues()['IsLegendary']) or 0

  return hero:GetLumber() >= lumber_cost and hero:GetCheese() >= cheese_cost
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

    -- DebugDrawCircle(searchLocation, Vector(255,0,0), 50, 100, true, 3)

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
  return not hero.nextBuilding and not hero.nextUpgrade
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

function BotAI:GetBuildingToRepair(hero)
  local allies = FindAlliesInRadius(hero, FIND_UNITS_EVERYWHERE)

  local lowestHealthBuilding
  local minHealthPercent = 100

  for _,ally in pairs(allies) do
    if IsCustomBuilding(ally) then
      local healthPercentage = ally:GetHealthPercent()
      if healthPercentage < minHealthPercent then
        minHealthPercent = healthPercentage
        lowestHealthBuilding = ally
      end
    end
  end

  return lowestHealthBuilding
end

function BotAI:RepairBuildings(hero)
  local building = BotAI:GetBuildingToRepair(hero)

  if hero.currentRepair and hero.currentRepair == building then
    return 0.3
  end

  hero.currentRepair = building

  if building == nil then
    return 0.1
  end

  BuildingHelper:AddRepairToQueue(hero, building, false)

  return 0.3
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

  if hero.nextUpgrade then
    -- upgrade the next building
    local nextUpgrade = hero.nextUpgrade
    local building = nextUpgrade.building
    local ability = nextUpgrade.ability

    if building:IsNull() or ability:IsNull() or not building:IsAlive() then
      hero.nextUpgrade = nil
      return 0.5
    end

    if BotAI:CanBuildBuilding(hero, ability) then
      building:CastAbilityNoTarget(ability, hero:GetPlayerOwnerID())
      hero.nextUpgrade = nil
      -- print("Upgrading " .. ability:GetAbilityName())
      return 0.5
    else
      return 1
    end
  end

  if not hero.nextBuilding and state == "idle" then
    -- If we've finished our building queue, start looking for our next building
    -- print("BotAI: look for next building")
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
    -- print("Couldn't find buildPosition")
  end
  
  return 1
end

function BotAI:PlaceBuilding(hero, ability, position)
  -- DebugDrawCircle(position, Vector(0,255,0), 50, 100, true, 3)

  -- print("Place Building ", position)
  BuildingHelper:OrderBuildingConstruction(hero, ability, position)
end

function BotAI:UseRescueStrike(hero, position)
  local ability = hero.rescueStrikeAbility

  hero:CastAbilityOnPosition(position, ability, -1)
end