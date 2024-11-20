LinkLuaModifier("modifier_legendary_spell_resist", "abilities/generic/legendary_spell_resistance.lua", LUA_MODIFIER_MOTION_NONE)

legendary_spell_resistance = class({})
function legendary_spell_resistance:GetIntrinsicModifierName() return "modifier_legendary_spell_resist" end

modifier_legendary_spell_resist = class({})

function modifier_legendary_spell_resist:IsHidden() return true end

function modifier_legendary_spell_resist:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_STATUS_RESISTANCE
  }
  return funcs
end

function modifier_legendary_spell_resist:GetModifierMagicalResistanceBonus()
  return self:GetAbility():GetSpecialValueFor("magic_resist")
end

function modifier_legendary_spell_resist:GetModifierStatusResistance()
  return self:GetAbility():GetSpecialValueFor("status_resist")
end