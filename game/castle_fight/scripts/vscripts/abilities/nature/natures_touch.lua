LinkLuaModifier("modifier_dryad_natures_touch", "abilities/nature/natures_touch.lua", LUA_MODIFIER_MOTION_NONE)

dryad_natures_touch = class({})
function dryad_natures_touch:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  target:AddNewModifier(caster, ability, "modifier_dryad_natures_touch", {})
end

modifier_dryad_natures_touch = class({})

function modifier_dryad_natures_touch:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
  return funcs
end

function modifier_dryad_natures_touch:GetModifierHealthBonus(keys)
  return self:GetAbility():GetSpecialValueFor("health")
end

function modifier_dryad_natures_touch:GetModifierStatusResistance(keys)
  return self:GetAbility():GetSpecialValueFor("armor")
end