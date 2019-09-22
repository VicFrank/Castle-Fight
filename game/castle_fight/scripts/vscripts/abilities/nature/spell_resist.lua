LinkLuaModifier("modifier_dryad_spell_resist", "abilities/nature/spell_resist.lua", LUA_MODIFIER_MOTION_NONE)

dryad_spell_resist = class({})
function dryad_spell_resist:GetIntrinsicModifierName() return "modifier_dryad_spell_resist" end

modifier_dryad_spell_resist = class({})

function modifier_dryad_spell_resist:IsHidden() return true end

function modifier_dryad_spell_resist:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_STATUS_RESISTANCE,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
  }
  return funcs
end

function modifier_dryad_spell_resist:GetModifierStatusResistance(keys)
  return self:GetAbility():GetSpecialValueFor("status_resist")
end

function modifier_dryad_spell_resist:GetModifierStatusResistance(keys)
  return self:GetAbility():GetSpecialValueFor("GetModifierMagicalResistanceBonus")
end