LinkLuaModifier("modifier_damage_return", "abilities/generic/damage_return.lua", LUA_MODIFIER_MOTION_NONE)

dragon_turtle_damage_return = class({})
function dragon_turtle_damage_return:GetIntrinsicModifierName() return "modifier_damage_return" end
treant_thorns = class({})
function treant_thorns:GetIntrinsicModifierName() return "modifier_damage_return" end

modifier_damage_return = class({})

function modifier_damage_return:IsHidden() return true end

function modifier_damage_return:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.damage_return = self.ability:GetSpecialValueFor("damage_return")
end

function modifier_damage_return:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_damage_return:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target
  local damage = keys.damage

  if self.parent == target then
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

