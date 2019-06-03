-- Basic functionality cribbed from DotaCraft
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
      
  GameMode:OnConstructionCompleted(building, ability)
  
  -- Remove old building entity
  caster:RemoveSelf()

  local newRelativeHP = math.max(building:GetMaxHealth() * currentHealthPercentage, 1)
  building:SetHealth(newRelativeHP)

end

function RefundUpgradePrice(keys)
  local caster = keys.caster
  local ability = keys.ability
  
  local abilityPrice = ability:GetGoldCost()
  local playerID = caster:GetPlayerOwnerID()

  PlayerResource:ModifyGold(playerID, abilityPrice, true, DOTA_ModifyGold_SellItem)
end