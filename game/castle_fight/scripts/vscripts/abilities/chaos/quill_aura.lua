LinkLuaModifier("modifier_quill_aura", "abilities/chaos/quill_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_quill_aura_buff", "abilities/chaos/quill_aura.lua", LUA_MODIFIER_MOTION_NONE)

quill_demon_quill_aura = class({})
function quill_demon_quill_aura:GetIntrinsicModifierName() return "modifier_quill_aura" end

modifier_quill_aura = class({})

function modifier_quill_aura:IsAura()
  return true
end

function modifier_quill_aura:GetAuraDuration()
  return 0.5
end

function modifier_quill_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_quill_aura:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_quill_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_quill_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_quill_aura:GetModifierAura()
  return "modifier_quill_aura_buff"
end

function modifier_quill_aura:IsAuraActiveOnDeath()
  return false
end

function modifier_quill_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero()
end

modifier_quill_aura_buff = class({})

function modifier_quill_aura_buff:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.damage_return = self.ability:GetSpecialValueFor("damage_return")
end

function modifier_quill_aura_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_quill_aura_buff:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target
  local damage = keys.damage

  if self.parent == target and attacker:GetAttackCapability() == DOTA_UNIT_CAP_MELEE_ATTACK then
    local particleName = "particles/units/heroes/hero_centaur/centaur_return.vpcf"
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, self.parent)
    ParticleManager:SetParticleControlEnt(particle, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", attacker:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)

    local damageTable = {
      victim = attacker,
      attacker = self.parent,
      damage = damage * self.damage_return * 0.01,
      damage_type = DAMAGE_TYPE_PHYSICAL,
      damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_REFLECTION,
      ability = self.ability
    }

    ApplyDamage(damageTable)
  end
end