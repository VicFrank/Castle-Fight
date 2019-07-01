LinkLuaModifier("modifier_custom_cleave", "abilities/generic/cleave.lua", LUA_MODIFIER_MOTION_NONE)

crusader_cleave = class({})
function crusader_cleave:GetIntrinsicModifierName() return "modifier_custom_cleave" end
murloc_cleave = class({})
function murloc_cleave:GetIntrinsicModifierName() return "modifier_custom_cleave" end
naga_guardian_cleave = class({})
function naga_guardian_cleave:GetIntrinsicModifierName() return "modifier_custom_cleave" end
bear_cleave = class({})
function bear_cleave:GetIntrinsicModifierName() return "modifier_custom_cleave" end
polar_bear_cleave = class({})
function polar_bear_cleave:GetIntrinsicModifierName() return "modifier_custom_cleave" end

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

function modifier_custom_cleave:OnAttackLanded(params)
  if not IsServer() then return end

  local attacker = params.attacker
  local target = params.target
  local damage = params.damage

  local particleName = "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf"

  if params.attacker == self.parent and (not self.parent:IsIllusion()) then
    if self:GetParent():PassivesDisabled() then
      return 0
    end

    if target ~= nil and target:GetTeamNumber() ~= self.parent:GetTeamNumber() then
      local cleaveDamage = (self.cleave_damage * params.damage) / 100.0
      DoCleaveAttack(self.parent, target, self.ability, cleaveDamage, self.cleave_radius, self.cleave_radius, self.cleave_radius, particleName)
    end
  end
end