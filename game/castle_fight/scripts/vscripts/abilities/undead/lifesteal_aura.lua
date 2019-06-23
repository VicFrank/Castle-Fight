vampire_lifesteal_aura = class({})
LinkLuaModifier("modifier_vampire_lifesteal_aura", "abilities/undead/lifesteal_aura.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_vampire_lifesteal_aura_buff", "abilities/undead/lifesteal_aura", LUA_MODIFIER_MOTION_NONE )

function vampire_lifesteal_aura:GetIntrinsicModifierName()
  return "modifier_vampire_lifesteal_aura"
end

modifier_vampire_lifesteal_aura = class({})

function modifier_vampire_lifesteal_aura:IsAura()
  return true
end

function modifier_vampire_lifesteal_aura:GetAuraDuration()
  return 0.5
end

function modifier_vampire_lifesteal_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_vampire_lifesteal_aura:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_vampire_lifesteal_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_vampire_lifesteal_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_vampire_lifesteal_aura:GetModifierAura()
  return "modifier_vampire_lifesteal_aura_buff"
end

function modifier_vampire_lifesteal_aura:IsAuraActiveOnDeath()
  return false
end

function modifier_vampire_lifesteal_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero() or target:GetAttackCapability() == DOTA_UNIT_CAP_RANGED_ATTACK
end

modifier_vampire_lifesteal_aura_buff = class({})

function modifier_vampire_lifesteal_aura_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
  return funcs
end

function modifier_vampire_lifesteal_aura_buff:OnAttackLanded(params)
  if not IsServer() then return end
  
  local parent = self:GetParent()
  local target = params.target
  local attacker = params.attacker
  local ability = self:GetAbility()
  local damage = params.damage

  if attacker == parent and not IsCustomBuilding(target) then
    local lifesteal = ability:GetSpecialValueFor("lifesteal")
    attacker:Heal(damage * lifesteal * 0.01, attacker)

    local particleName = "particles/units/heroes/hero_skeletonking/wraith_king_vampiric_aura_lifesteal.vpcf"
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:SetParticleControlEnt(particle, 0, attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", attacker:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", attacker:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)
  end
end

function modifier_vampire_lifesteal_aura_buff:IsDebuff()
    return false
end