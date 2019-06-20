LinkLuaModifier("modifier_avenging_spirit_spell_reduction", "abilities/night_elves/spell_reduction.lua", LUA_MODIFIER_MOTION_NONE)

avenging_spirit_spell_reduction = class({})
function avenging_spirit_spell_reduction:GetIntrinsicModifierName() return "modifier_avenging_spirit_spell_reduction" end

modifier_avenging_spirit_spell_reduction = class({})

function modifier_avenging_spirit_spell_reduction:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_STATUS_RESISTANCE,
  }
  return funcs
end

function modifier_avenging_spirit_spell_reduction:GetModifierStatusResistance(keys)
  return self:GetAbility():GetSpecialValueFor("resistance")
end