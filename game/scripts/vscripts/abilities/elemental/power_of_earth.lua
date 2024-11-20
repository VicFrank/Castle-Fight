power_of_earth = class({})

LinkLuaModifier("modifier_power_of_earth", "abilities/elemental/power_of_earth.lua", LUA_MODIFIER_MOTION_NONE)

function power_of_earth:GetIntrinsicModifierName() return "modifier_power_of_earth" end
-----------------------------

modifier_power_of_earth = class({})

function modifier_power_of_earth:IsHidden() return true end

function modifier_power_of_earth:OnCreated()
  self.max_damage = self:GetAbility():GetSpecialValueFor("max_damage")
end

function modifier_power_of_earth:OnRefresh()
  self.max_damage = self:GetAbility():GetSpecialValueFor("max_damage")
end

function modifier_power_of_earth:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_power_of_earth:GetModifierPreAttack_BonusDamage()
  return self.max_damage * self:GetParent():GetHealthPercent() / 100
end
