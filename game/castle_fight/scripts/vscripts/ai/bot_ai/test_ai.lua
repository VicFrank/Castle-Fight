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
      if item then
        table.insert(hero.abilityList, item)
      end
    end

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
  if hero:IsStunned() then return 0.1 end

  if BotAI:LookingForNextBuilding(hero) then
    BotAI:GetNextBuildingToBuild(hero)
  end

  if BotAI:WaitingToBuild(hero) then
    return BotAI:RepairBuildings(hero)
  end


  -- place a building at our location
  -- local ability = GetNextBuildingToBuild(hero)

  -- if BotAI:CanBuildBuilding(hero, ability) then
  --   BotAI:PlaceBuilding(hero, ability, hero:GetAbsOrigin())
  -- end

  return 0.1
end

function BotAI:GetNextBuildingToBuild(hero)
  local currentInterest = GameMode:GetIncome(hero:GetPlayerOwnerID())

  local buildings = {}

  for _,ability in pairs(hero.abilityList) do
    local abilityName = ability:GetAbilityName()
    local abilityData = AbilityData[abilityName]
    local lumber_cost = tonumber(ability:GetAbilityKeyValues()['LumberCost']) or 0
    local cheese_cost = tonumber(ability:GetAbilityKeyValues()['IsLegendary']) or 0

    local interestToConsider = abilityData.interestToConsider

    if currentInterest >= interestToConsider and hero:GetLumber() >= lumber_cost and
      hero:GetCheese > cheese_cost then
      table.insert(buildings)
    end
  end

  local nextBuilding = GetRandomTableElement(buildings)

  hero.nextBuilding = nextBuilding
  hero.nextBuildingCost = nextBuilding:GetGoldCost(1)
end

function BotAI:GetPlaceToBuild(hero)
  local searchStart
  local searchDirectionX
  local searchDirectionY

  if hero.sideToBuild = "SOUTH" then    
    if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
      -- Bottom Left West Base
      searchStart = hero.baseMinBounds
      searchDirectionX = 1
      searchDirectionY = 1
    else
      -- Bottom Right East Base
      searchStart = Vector(hero.baseMaxBounds.x, baseMinBounds.y, 0)
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

  local searchLocation = searchStart

  for i=1,100 do
    if GridNav:CanFindPath(hero:GetAbsOrigin(), searchLocation) then
      return searchLocation
    end

    searchLocation = searchLocation + Vector(0, searchDirectionY * 50, 0)
  end
end

function BotAI:CanBuildBuilding(hero, ability)
  local gold_cost = ability:GetGoldCost(1) 
  local lumber_cost = tonumber(ability:GetAbilityKeyValues()['LumberCost']) or 0
  local cheese_cost = tonumber(ability:GetAbilityKeyValues()['IsLegendary']) or 0
  local playerID = hero:GetPlayerID()

  if PlayerResource:GetGold(playerID) < gold_cost or hero:GetLumber() < lumber_cost or
    hero:GetCheese() < cheese_cost then
      return false
  end

  return true
end

function BotAI:LookingForNextBuilding(hero)
  if hero.nextBuilding == nil or hero.nextBuildingCost == nil then
    return true
  end
end

function BotAI:WaitingToBuild(hero)
  local playerID = hero:GetPlayerOwnerID()

  if PlayerResource:GetGold(playerID) < hero.nextBuildingCost then
    return true
  end
end

-- TODO: Repair buildings while we're waiting to build
function BotAI:RepairBuildings(hero)
  return 0.1
end

function BotAI:PlaceBuilding(hero, ability, position)
  BuildingHelper:OrderBuildingConstruction(hero, ability, position)

end
