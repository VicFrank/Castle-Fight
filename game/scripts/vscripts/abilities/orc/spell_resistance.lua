LinkLuaModifier("modifier_kodo_spell_resistance", "abilities/orc/spell_resistance.lua", LUA_MODIFIER_MOTION_NONE)

kodo_spell_resistance = class({})
function kodo_spell_resistance:GetIntrinsicModifierName() return "modifier_kodo_spell_resistance" end

modifier_kodo_spell_resistance = class({})

function modifier_kodo_spell_resistance:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
  return funcs
end

function modifier_kodo_spell_resistance:GetModifierMagicalResistanceBonus(keys)
  return self:GetAbility():GetSpecialValueFor("magic_resistance")
end