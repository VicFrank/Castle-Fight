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
    MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
  }
  return funcs
end

function modifier_damage_reduction:GetModifierPhysical_ConstantBlock()
  if not IsServer() then return end

  if self.reduction_chance > RandomInt(1,100) then
    return self.damage_reduced
  end
end

