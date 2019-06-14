LinkLuaModifier("modifier_damage_reduction", "abilities/generic/damage_reduction.lua", LUA_MODIFIER_MOTION_NONE)

lobster_damage_reduction = class({})
function lobster_damage_reduction:GetIntrinsicModifierName() return "modifier_damage_reduction" end

modifier_damage_reduction = class({})

function modifier_damage_reduction:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.damage_reduced = self.ability:GetSpecialValueFor("damage_reduced")
  self.reduction_chance = self.ability:GetSpecialValueFor("reduction_chance")
end

function modifier_damage_reduction:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_damage_reduction:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster then
    -- do mana burn here
  end
end

