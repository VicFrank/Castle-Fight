LinkLuaModifier("modifier_iron_golem_spell_resistance", "abilities/mech/spell_resistance.lua", LUA_MODIFIER_MOTION_NONE)

iron_golem_spell_resistance = class({})
function iron_golem_spell_resistance:GetIntrinsicModifierName() return "modifier_iron_golem_spell_resistance" end

modifier_iron_golem_spell_resistance = class({})

function modifier_iron_golem_spell_resistance:IsHidden() return true end

function modifier_iron_golem_spell_resistance:OnCreated()
  self.magic_resistance = self:GetAbility():GetSpecialValueFor("magic_resistance")
  self.status_resistance = self:GetAbility():GetSpecialValueFor("status_resistance")
end

function modifier_iron_golem_spell_resistance:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_STATUS_RESISTANCE
  }
  return funcs
end

function modifier_iron_golem_spell_resistance:GetModifierMagicalResistanceBonus(keys)
  return self.magic_resistance
end
function modifier_iron_golem_spell_resistance:GetModifierStatusResistance(keys)
  return self.status_resistance
end