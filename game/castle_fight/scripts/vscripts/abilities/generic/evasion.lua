LinkLuaModifier("modifier_custom_evasion", "abilities/generic/evasion.lua", LUA_MODIFIER_MOTION_NONE)

defender_evasion = class({})
function defender_evasion:GetIntrinsicModifierName() return "modifier_custom_evasion" end

modifier_custom_evasion = class({})

function modifier_custom_evasion:OnCreated()
  self.evasion = self.ability:GetSpecialValueFor("evasion")
end

function modifier_custom_evasion:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_EVASION_CONSTANT
  }
  return funcs
end

function modifier_custom_evasion:GetModifierEvasion_Constant()
  return self.evasion
end