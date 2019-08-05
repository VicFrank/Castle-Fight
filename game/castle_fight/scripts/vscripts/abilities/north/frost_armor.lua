ice_troll_frost_armor = class({})

LinkLuaModifier("modifier_ice_troll_frost_armor", "abilities/north/frost_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ice_troll_frost_armor_debuff", "abilities/north/frost_armor.lua", LUA_MODIFIER_MOTION_NONE)

function ice_troll_frost_armor:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  local armor_duration = self:GetSpecialValueFor("armor_duration")

  target:AddNewModifier(caster, ability, "modifier_ice_troll_frost_armor", {duration = armor_duration})

  caster:EmitSound("Hero_Lich.FrostArmor")
end

modifier_ice_troll_frost_armor = class({})

function modifier_ice_troll_frost_armor:OnCreated()
  self.parent = self:GetParent()

  self.armor = self:GetAbility():GetSpecialValueFor("armor")
  self.debuff_duration = self:GetAbility():GetSpecialValueFor("debuff_duration")

  local particleName = "particles/units/heroes/hero_lich/lich_frost_armor.vpcf"

  self.particle_frost_armor_fx = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, self.parent)
  ParticleManager:SetParticleControl(self.particle_frost_armor_fx, 0, self.parent:GetAbsOrigin())
  ParticleManager:SetParticleControl(self.particle_frost_armor_fx, 1, Vector(1,1,1))
  self:AddParticle(self.particle_frost_armor_fx, false, false, -1, false, false)
end

function modifier_ice_troll_frost_armor:IsPurgable()
  return true
end

function modifier_ice_troll_frost_armor:DeclareFunctions()
  local decFuncs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }

  return decFuncs
end

function modifier_ice_troll_frost_armor:GetModifierPhysicalArmorBonus()
  return self.armor
end

function modifier_ice_troll_frost_armor:OnAttackLanded(keys)
  local attacker = keys.attacker
  local target = keys.target

  if target == self.parent and target:GetTeamNumber() ~= attacker:GetTeamNumber() then
    attacker:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_ice_troll_frost_armor_debuff", {duration = self.debuff_duration})
  end
end

function modifier_ice_troll_frost_armor:GetStatusEffectName()
  return "particles/status_fx/status_effect_frost_armor.vpcf"
end


modifier_ice_troll_frost_armor_debuff = class({})

function modifier_ice_troll_frost_armor_debuff:OnCreated()
  if not self:GetAbility() then return end
  self.move_slow = -self:GetAbility():GetSpecialValueFor("move_slow")
  self.attack_slow = -self:GetAbility():GetSpecialValueFor("attack_slow")
end

function modifier_ice_troll_frost_armor_debuff:IsDebuff()
  return true
end

function modifier_ice_troll_frost_armor_debuff:IsPurgable()
  return true
end

function modifier_ice_troll_frost_armor_debuff:GetTexture()
  return "ogre_magi_frost_armor"
end

function modifier_ice_troll_frost_armor_debuff:DeclareFunctions()
  local decFuns =
    {
      MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
      MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
  return decFuns
end

function modifier_ice_troll_frost_armor_debuff:GetModifierMoveSpeedBonus_Percentage()
  return self.move_slow
end

function modifier_ice_troll_frost_armor_debuff:GetModifierAttackSpeedBonus_Constant()
  return self.attack_slow
end

function modifier_ice_troll_frost_armor_debuff:GetEffectName()
  return "particles/status_fx/status_effect_frost.vpcf"
end