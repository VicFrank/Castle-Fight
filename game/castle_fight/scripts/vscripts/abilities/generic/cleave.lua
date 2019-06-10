LinkLuaModifier("modifier_custom_cleave", "abilities/generic/cleave.lua", LUA_MODIFIER_MOTION_NONE)

crusader_cleave = class({})
function crusader_cleave:GetIntrinsicModifierName() return "modifier_custom_cleave" end
murloc_cleave = class({})
function murloc_cleave:GetIntrinsicModifierName() return "modifier_custom_cleave" end
naga_guardian_cleave = class({})
function naga_guardian_cleave:GetIntrinsicModifierName() return "modifier_custom_cleave" end
bear_cleave = class({})
function bear_cleave:GetIntrinsicModifierName() return "modifier_custom_cleave" end

modifier_custom_cleave = class({})

function modifier_custom_cleave:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.cleave_damage = self.ability:GetSpecialValueFor("cleave_damage")
  self.cleave_radius = self.ability:GetSpecialValueFor("cleave_radius")
end

function modifier_custom_cleave:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
  return funcs
end

function modifier_custom_cleave:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target
  local damage = keys.damage

  local particle = "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf"

  if attacker == self.caster then
    DoCleaveAttack(attacker, target, self.ability, damage * self.cleave_damage * 0.01, self.cleave_radius, self.cleave_radius, self.cleave_radius, particle)
  end
end