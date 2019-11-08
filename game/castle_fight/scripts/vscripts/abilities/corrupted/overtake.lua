LinkLuaModifier("modifier_overtake", "abilities/corrupted/overtake.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_overtake_fx", "abilities/corrupted/overtake.lua", LUA_MODIFIER_MOTION_NONE)

incubus_overtake = class({})
function incubus_overtake:GetIntrinsicModifierName() return "modifier_overtake" end

modifier_overtake = class({})

function modifier_overtake:IsHidden() return true end

function modifier_overtake:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.chance = self.ability:GetSpecialValueFor("chance")
end

function modifier_overtake:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_overtake:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster and not IsCustomBuilding(target) and not target:IsLegendary() then
    if self.chance >= RandomInt(1, 100) then
      local position = target:GetAbsOrigin()
      local relative_health = target:GetHealthPercent() * 0.01
      if relative_health == 0 then return end
      local fv = target:GetForwardVector()
      local unitName = target:GetUnitName()
      local playerID = self.parent.playerID
      local team = self.parent:GetTeam()
      local new_unit = CreateLaneUnit(unitName, position, team, playerID)
      new_unit:SetHealth(new_unit:GetMaxHealth() * relative_health)
      new_unit:SetMana(target:GetMana())
      new_unit:SetForwardVector(fv)
      FindClearSpaceForUnit(new_unit, position, true)

      target:CustomRemoveSelf()

      local particleName = "particles/econ/items/terrorblade/terrorblade_back_ti8/terrorblade_sunder_ti8.vpcf"
      local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, new_unit)
      ParticleManager:SetParticleControl(particle, 1, new_unit:GetAbsOrigin())
      ParticleManager:ReleaseParticleIndex(particle)
      if RandomInt(0, 1) == 0 then
        new_unit:EmitSound("Hero_Terrorblade.Sunder.Cast")
      else
        new_unit:EmitSound("Hero_Terrorblade.Sunder.Target")
      end
      new_unit:AddNewModifier(self.caster, self.ability, "modifier_overtake_fx", {duration = -1})
    end
  end
end

----------------------------------------------------------------------------------------------------

modifier_overtake_fx = class ({})

function modifier_overtake_fx:OnCreated(table)
  self.isOvertakeEffect = true

  local modifiers = self:GetParent():FindAllModifiers()
  for _,modifier in pairs(modifiers) do
    if modifier.isOvertakeEffect and modifier ~= self then
      UTIL_Remove(modifier)
    end
  end
end

function modifier_overtake_fx:DeclareFunctions()
  return {}
end

function modifier_overtake_fx:IsHidden()
  return true
end

function modifier_overtake_fx:IsDebuff()
  return false
end

function modifier_overtake_fx:IsPurgable()
  return false
end

function modifier_overtake_fx:GetStatusEffectName()
  return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_overtake_fx:RemoveOnDeath()
  return false
end

function modifier_overtake_fx:StatusEffectPriority()
  return FX_PRIORITY_CONTROLLED
end