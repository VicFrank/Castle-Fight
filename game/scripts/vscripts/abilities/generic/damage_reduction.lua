LinkLuaModifier("modifier_damage_reduction", "abilities/generic/damage_reduction.lua", LUA_MODIFIER_MOTION_NONE)

lobster_damage_reduction = class({})
function lobster_damage_reduction:GetIntrinsicModifierName() return "modifier_damage_reduction" end
tank_armor = class({})
function tank_armor:GetIntrinsicModifierName() return "modifier_damage_reduction" end

modifier_damage_reduction = class({})

function modifier_damage_reduction:IsHidden() return true end

function modifier_damage_reduction:OnCreated()
  self.ability = self:GetAbility()
end

function modifier_damage_reduction:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
  }
  return funcs
end

function modifier_damage_reduction:GetModifierPhysical_ConstantBlock()
  if not IsServer() then return end

  if self.ability:GetSpecialValueFor("reduction_chance") >= RandomInt(1,100) then
    return self.ability:GetSpecialValueFor("damage_reduced")
  end
end

