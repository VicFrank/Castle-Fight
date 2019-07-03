if not BotAI then
  BotAI = class({})
end

function BotAI:Init(hero)
  Timers:CreateTimer(1, function()

    return BotAI:OnThink(hero)
  end)
end

function BotAI:OnThink(hero)
  if hero:IsStunned() then return 0.1 end

  -- place a building at our location
  local ability = hero:GetAbilityByIndex(1)

  if BotAI:CanBuildBuilding(hero, ability) then
    BotAI:PlaceBuilding(hero, ability, hero:GetAbsOrigin())
  end

  return 0.1
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

function BotAI:PlaceBuilding(hero, ability, position)
  BuildingHelper:OrderBuildingConstruction(hero, ability, position)

end