LinkLuaModifier("modifier_shaman_buff", "abilities/orc/shaman_buff.lua", LUA_MODIFIER_MOTION_NONE)

shaman_buff = class({})

function shaman_buff:IsPurgable()
  return false
end

function shaman_buff:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  local duration = ability:GetSpecialValueFor("duration")

  target:AddNewModifier(caster, ability, "modifier_shaman_buff", {duration = duration})
end

modifier_shaman_buff = class({})

function modifier_shaman_buff:IsPurgable()
  return true
end

function modifier_shaman_buff:OnCreated()
  if not self:GetAbility() then return end
  self.armor = self:GetAbility():GetSpecialValueFor("armor")
  self.damage_increase = self:GetAbility():GetSpecialValueFor("damage_increase")
  self.health_per_second = self:GetAbility():GetSpecialValueFor("health_per_second")
end

function modifier_shaman_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
  }
  return funcs
end

function modifier_shaman_buff:GetModifierConstantHealthRegen(keys)
  return self.health_per_second
end

function modifier_shaman_buff:GetModifierBaseDamageOutgoing_Percentage(keys)
  return self.damage_increase
end

function modifier_shaman_buff:GetModifierPhysicalArmorBonus(keys)
  return self.armor
end

function modifier_shaman_buff:GetEffectName()
  return "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodrage.vpcf"
end

function modifier_shaman_buff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_shaman_buff:PlayEffects()
  -- Get Resources
  local particle_cast = "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodbath.vpcf"

  -- Create Particle
  local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
  ParticleManager:ReleaseParticleIndex( effect_cast )
end