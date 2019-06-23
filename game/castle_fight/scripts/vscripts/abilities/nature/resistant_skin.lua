LinkLuaModifier("modifier_mountain_giant_resistant_skin", "abilities/nature/resistant_skin.lua", LUA_MODIFIER_MOTION_NONE)

mountain_giant_resistant_skin = class({})
function mountain_giant_resistant_skin:GetIntrinsicModifierName() return "modifier_mountain_giant_resistant_skin" end

mountain_giant_resistant_skin = class({})

function mountain_giant_resistant_skin:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_STATUS_RESISTANCE,
    MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK
  }
  return funcs
end

function mountain_giant_resistant_skin:GetModifierStatusResistance(keys)
  return self:GetAbility():GetSpecialValueFor("status_resistance")
end

function mountain_giant_resistant_skin:GetModifierPhysical_ConstantBlock(keys)
  return keys.damage * self:GetAbility():GetSpecialValueFor("damage_reduction") * 0.01
end