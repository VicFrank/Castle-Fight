LinkLuaModifier("modifier_blademaster_spell_resist", "abilities/elf/spell_resist.lua", LUA_MODIFIER_MOTION_NONE)

blademaster_spell_resist = class({})
function blademaster_spell_resist:GetIntrinsicModifierName() return "modifier_blademaster_spell_resist" end

modifier_blademaster_spell_resist = class({})

function modifier_blademaster_spell_resist:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
  return funcs
end

function modifier_blademaster_spell_resist:GetModifierMagicalResistanceBonus(keys)
  return self:GetAbility():GetSpecialValueFor("magic_resist")
end