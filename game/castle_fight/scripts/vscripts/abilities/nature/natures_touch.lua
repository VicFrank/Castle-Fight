LinkLuaModifier("modifier_dryad_natures_touch", "abilities/nature/natures_touch.lua", LUA_MODIFIER_MOTION_NONE)

dryad_natures_touch = class({})
function dryad_natures_touch:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  target:AddNewModifier(caster, ability, "modifier_dryad_natures_touch", {})
end

modifier_dryad_natures_touch = class({})

function modifier_dryad_natures_touch:OnCreated()
  self.health_bonus = self:GetAbility():GetSpecialValueFor("health")
  self.armor = self:GetAbility():GetSpecialValueFor("armor")
end

function modifier_dryad_natures_touch:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
  return funcs
end

function modifier_dryad_natures_touch:GetModifierExtraHealthBonus(keys)
  return self.health_bonus
end

function modifier_dryad_natures_touch:GetModifierPhysicalArmorBonus(keys)
  return self.armor
end