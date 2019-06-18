vampire_attack = class({})
LinkLuaModifier("modifier_vampire_attack", "abilities/undead/vampire_attack.lua", LUA_MODIFIER_MOTION_NONE )

function vampire_attack:GetIntrinsicModifierName()
  return "modifier_vampire_attack"
end

modifier_vampire_attack = class({})

function modifier_vampire_attack:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
  return funcs
end

function modifier_vampire_attack:OnAttackLanded(params)
  if not IsServer() then return end
  
  local parent = self:GetParent()
  local target = params.target
  local attacker = params.attacker
  local ability = self:GetAbility()
  local damage = params.damage

  if attacker == parent then
    local lifesteal = ability:GetSpecialValueFor("lifesteal")
    -- attacker:Heal(damage * lifesteal * 0.01, attacker)

    local particleName = "particles/units/heroes/hero_skeletonking/wraith_king_vampiric_aura_lifesteal.vpcf"
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:SetParticleControlEnt(particle, 0, attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", attacker:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", attacker:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)
  end
end

function modifier_vampire_attack:IsDebuff()
  return false
end