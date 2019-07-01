bear_slumber = class({})

LinkLuaModifier("modifier_bear_slumber", "abilities/nature/slumber.lua", LUA_MODIFIER_MOTION_NONE)

function bear_slumber:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local duration = ability:GetSpecialValueFor("duration")

  caster:AddNewModifier(caster, ability, "modifier_bear_slumber", {duration = duration})
end

modifier_bear_slumber = class({})

function modifier_bear_slumber:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
  return funcs
end

function modifier_bear_slumber:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor("health_regen")
end

function modifier_bear_slumber:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if target == self:GetParent() then
    local damage = keys.damage
    damage = damage * 2

    ApplyDamage({
      victim = target,
      damage = damage,
      damage_type = DAMAGE_TYPE_PHYSICAL,
      attacker = attacker,
      ability = self:GetAbility()
    })

    self:GetParent():RemoveModifierByName("modifier_bear_slumber")
  end
end

function modifier_bear_slumber:CheckState()
  return { 
    [MODIFIER_STATE_STUNNED] = true,
  }
end

function modifier_bear_slumber:GetEffectName()
  return "particles/generic_gameplay/generic_sleep.vpcf"
end

function modifier_bear_slumber:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_bear_slumber:GetStatusEffectName()
  return "particles/status_fx/status_effect_nightmare.vpcf"
end
