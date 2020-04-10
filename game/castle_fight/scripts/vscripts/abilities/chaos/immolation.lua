LinkLuaModifier("modifier_infernal_immolation", "abilities/chaos/immolation.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_infernal_immolation_debuff", "abilities/chaos/immolation.lua", LUA_MODIFIER_MOTION_NONE)

infernal_immolation = class({})
function infernal_immolation:GetIntrinsicModifierName() return "modifier_infernal_immolation" end

modifier_infernal_immolation = class({})

function modifier_infernal_immolation:IsAura()
  return true
end

function modifier_infernal_immolation:GetAuraDuration()
  return 0.5
end

function modifier_infernal_immolation:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_infernal_immolation:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_infernal_immolation:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_infernal_immolation:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_infernal_immolation:GetModifierAura()
  return "modifier_infernal_immolation_debuff"
end

function modifier_infernal_immolation:IsAuraActiveOnDeath()
  return false
end

function modifier_infernal_immolation:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero()
end

function modifier_infernal_immolation:IsHidden()
  return true
end

modifier_infernal_immolation_debuff = class({})
function modifier_infernal_immolation_debuff:OnCreated(table)
  self.dps = self:GetAbility():GetSpecialValueFor("dps")
  if IsServer() then self:StartIntervalThink(1) end
end

function modifier_infernal_immolation_debuff:OnIntervalThink()
  ApplyDamage({
    victim = self:GetParent(),
    damage = self.dps,
    damage_type = DAMAGE_TYPE_MAGICAL,
    attacker = self:GetCaster(),
    ability = self:GetAbility()
  })
end

function modifier_infernal_immolation_debuff:GetEffectName()
  return "particles/units/heroes/hero_phoenix/phoenix_sunray_debuff.vpcf"
end

function modifier_infernal_immolation_debuff:IsDebuff()
  return true
end