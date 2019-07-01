banshee_astral_chains = class({})
LinkLuaModifier("modifier_astral_chains_debuff", "abilities/undead/astral_chains.lua", LUA_MODIFIER_MOTION_NONE)

function banshee_astral_chains:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  local duration = ability:GetSpecialValueFor("duration")

  caster:EmitSound("Hero_Lich.IceAge")

  target:AddNewModifier(caster, ability, "modifier_astral_chains_debuff", {duration = duration})
end


modifier_astral_chains_debuff = class({})

function modifier_astral_chains_debuff:IsDebuff() return true end

function modifier_astral_chains_debuff:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.move_slow = self.ability:GetSpecialValueFor("move_slow")
  self.attack_slow = self.ability:GetSpecialValueFor("attack_slow")
end

function modifier_astral_chains_debuff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
  }
  return funcs
end

function modifier_astral_chains_debuff:GetModifierMoveSpeedBonus_Percentage()
  return -self.move_slow
end

function modifier_astral_chains_debuff:GetModifierAttackSpeedBonus_Constant()
  return -self.attack_slow;
end

function modifier_astral_chains_debuff:GetEffectName()
  return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end

function modifier_astral_chains_debuff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end