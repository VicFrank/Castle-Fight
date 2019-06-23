-- From Dota Imba
ranger_multi_shot = class({})

LinkLuaModifier("modifier_ranger_split_shot", "abilities/night_elves/multi_shot", LUA_MODIFIER_MOTION_NONE)

function ranger_multi_shot:GetIntrinsicModifierName()
  return "modifier_ranger_split_shot"
end

modifier_ranger_split_shot = class({})

function modifier_ranger_split_shot:OnCreated()
  self.ability = self:GetAbility()

  self.damage_modifier = self.ability:GetSpecialValueFor("damage_modifier")
  self.arrow_count = self.ability:GetSpecialValueFor("arrow_count")
end

function modifier_ranger_split_shot:DeclareFunctions()
  local decFuncs = {
    MODIFIER_EVENT_ON_ATTACK,
  }

  return decFuncs
end

function modifier_ranger_split_shot:OnAttack(keys)
  if not IsServer() then return end
  
  -- "Secondary arrows are not released upon attacking allies."
  -- The "not keys.no_attack_cooldown" clause seems to make sure the function doesn't trigger on PerformAttacks with that false tag so this thing doesn't crash
  if keys.attacker == self:GetParent() and keys.target and 
    keys.target:GetTeamNumber() ~= self:GetParent():GetTeamNumber() and 
    not keys.no_attack_cooldown and not self:GetParent():PassivesDisabled() and 
    self:GetAbility():IsTrained() then

    local enemies = FindUnitsInRadius(
      self:GetParent():GetTeamNumber(), 
      self:GetParent():GetAbsOrigin(), 
      nil, 
      self:GetParent():GetAttackRangeBuffer() + 100, 
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
      FIND_ANY_ORDER, false)
    
    local target_number = 0
        
    for _, enemy in ipairs(enemies) do
      if enemy ~= keys.target then        
        self:GetParent():PerformAttack(enemy, false, false, true, false, true, false, false)
        
        target_number = target_number + 1
        
        if target_number >= self.arrow_count then
          break
        end
      end
    end
  end
end