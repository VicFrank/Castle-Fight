control_enemy = class({})

LinkLuaModifier("modifier_control_enemy_fx", "abilities/naga/control_enemy.lua", LUA_MODIFIER_MOTION_NONE)

function control_enemy:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local particleName = "particles/units/heroes/hero_chen/chen_holy_persuasion_a.vpcf"

  local filter = function(target) return not target:IsLegendary() end
  local target = GetRandomVisibleEnemyWithFilter(caster:GetTeam(), filter)

  if not target then return end

  caster:EmitSound("Hero_Chen.HolyPersuasionCast")

  for _,modifier in pairs(target:FindAllModifiers()) do
    if modifier.OnBuildingTarget and modifier:OnBuildingTarget() then
      return
    end
  end

  -- swap target for new unit under our control
  local hero = caster:GetOwner()
  local playerID = hero:GetPlayerOwnerID()

  local position = target:GetAbsOrigin()
  local relative_health = target:GetHealthPercent() * 0.01
  local fv = target:GetForwardVector()
  local unitName = target:GetUnitName()
  local playerID = hero:GetPlayerOwnerID()
  local team = hero:GetTeam()
  local new_unit = CreateLaneUnit(unitName, position, team, playerID)
  new_unit:SetHealth(new_unit:GetMaxHealth() * relative_health)
  new_unit:SetMana(target:GetMana())
  new_unit:SetForwardVector(fv)
  FindClearSpaceForUnit(new_unit, position, true)

  target:CustomRemoveSelf()

  new_unit:EmitSound("Hero_Chen.HolyPersuasionEnemy")

  local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, new_unit)
  ParticleManager:SetParticleControl(particle, 1, new_unit:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle)

  new_unit:AddNewModifier(caster, ability, "modifier_control_enemy_fx", {duration = -1})
end

----------------------------------------------------------------------------------------------------

modifier_control_enemy_fx = class ({})

function modifier_control_enemy_fx:OnCreated(table)
  self.isOvertakeEffect = true

  local modifiers = self:GetParent():FindAllModifiers()
  for _,modifier in pairs(modifiers) do
    if modifier.isOvertakeEffect and modifier ~= self then
      UTIL_Remove(modifier)
    end
  end
end

function modifier_control_enemy_fx:DeclareFunctions()
  return {}
end

function modifier_control_enemy_fx:IsHidden()
  return true
end

function modifier_control_enemy_fx:IsDebuff()
  return false
end

function modifier_control_enemy_fx:IsPurgable()
  return false
end

function modifier_control_enemy_fx:GetStatusEffectName()
  return "particles/status_fx/status_effect_morphling_morph_target.vpcf"
end

function modifier_control_enemy_fx:RemoveOnDeath()
  return false
end

function modifier_control_enemy_fx:StatusEffectPriority()
  return FX_PRIORITY_CONTROLLED
end