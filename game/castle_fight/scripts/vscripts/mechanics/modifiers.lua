-- Passes a modifier from one unit to another
function CDOTA_Buff:Transfer(unit, caster)
  local ability = self:GetAbility()
  local duration = self:GetDuration()

  -- If the ability was removed (because the modifier was applied by a unit that died later), we apply it via hero
  if not IsValidEntity(ability) then
    local playerID = caster:GetPlayerOwnerID()
    local fakeHero = PlayerResource:GetSelectedHeroEntity(playerID)
    local abilityName = self:GetAbilityName()
    ability = fakeHero:AddAbility(abilityName)
    Timers:CreateTimer(0.03, function()
      local allModifiers = fakeHero:FindAllModifiers()
      for _,modifier in pairs(allModifiers) do
        -- Remove any associated modifiers that were passively added by the ability
        if modifier:GetAbility() == ability then
          UTIL_Remove(modifier)
        end
      end
      UTIL_Remove(ability)
    end)
  end

  if ability then
    ability:SetLevel(ability:GetMaxLevel())
    if ability.ApplyDataDrivenModifier then
      ability:ApplyDataDrivenModifier(caster, unit, self:GetName(), {duration = duration})
    else
      print(unit:GetUnitName(), caster:GetUnitName(), ability:GetAbilityName(), self:GetName(), duration)
      caster:AddNewModifier(unit, ability, self:GetName(), {duration = duration})
    end
    self:Destroy()
    return true
  end
  
  return false
end