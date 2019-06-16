function ResourceCheck(keys)
  local caster = keys.caster
  local ability = keys.ability
  local playerID = caster:GetPlayerOwnerID()
  local hero = caster:GetOwner()

  local lumber_cost = tonumber(ability:GetAbilityKeyValues()['LumberCost']) or 0
  local cheese_cost = tonumber(ability:GetAbilityKeyValues()['IsLegendary']) or 0

  -- If not enough resources to upgrade, stop
  if hero:GetLumber() < lumber_cost then
    SendErrorMessage(playerID, "#error_not_enough_lumber")
    ability:EndChannel(true)
    Timers:CreateTimer(.03, function()
      ability:EndChannel(true)
    end)
    ability.refund = false
    return false
  end

  -- If not enough resources to upgrade, stop
  if hero:GetCheese() < cheese_cost then
    SendErrorMessage(playerID, "#error_not_enough_cheese")
    ability:EndChannel(true)
    Timers:CreateTimer(.03, function()
      ability:EndChannel(true)
    end)
    ability.refund = false
    return false
  end

  hero:ModifyLumber(-lumber_cost)
  hero:ModifyCheese(-cheese_cost)
  ability.refund = true
end

function UpgradeBuilding(keys)
  local caster = keys.caster
  local ability = keys.ability
  local new_unit = keys.UnitName
  local playerID = caster:GetPlayerOwnerID()
  local currentHealthPercentage = caster:GetHealthPercent() * 0.01

  -- Keep the gridnav blockers, hull radius and orientation
  local blockers = caster.blockers
  local hull_radius = caster:GetHullRadius()
  local angle = caster:GetAngles()

  -- New building
  local building = BuildingHelper:UpgradeBuilding(caster, new_unit)
  building:SetHullRadius(hull_radius)

  -- If the building to ugprade is selected, change the selection to the new one
  if PlayerResource:IsUnitSelected(playerID, caster) then
      PlayerResource:AddToSelection(playerID, building)
  end
      
  GameMode:OnConstructionCompleted(building, ability, true, caster.incomeValue)
  
  -- Remove old building entity
  caster:RemoveSelf()

  local newRelativeHP = math.max(building:GetMaxHealth() * currentHealthPercentage, 1)
  building:SetHealth(newRelativeHP)

end

function RefundUpgradePrice(keys)
  local caster = keys.caster
  local ability = keys.ability
  
  local abilityPrice = ability:GetGoldCost(ability:GetLevel())
  local lumber_cost = tonumber(ability:GetAbilityKeyValues()['LumberCost']) or 0
  local cheese_cost = tonumber(ability:GetAbilityKeyValues()['IsLegendary']) or 0
    
  local playerID = caster:GetPlayerOwnerID()

  local hero = caster:GetOwner()

  PlayerResource:ModifyGold(playerID, abilityPrice, false, DOTA_ModifyGold_SellItem)
  
  if ability.refund then
    hero:ModifyLumber(lumber_cost)
    hero:ModifyCheese(cheese_cost)
  end
end