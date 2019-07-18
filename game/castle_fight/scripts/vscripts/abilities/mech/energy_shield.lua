energy_shield = class({})

LinkLuaModifier("modifier_energy_shield", "abilities/mech/energy_shield.lua", LUA_MODIFIER_MOTION_NONE)

function energy_shield()
  local caster = self:GetCaster()
  local ability = self

  local initial_stacks = ability:GetSpecialValueFor("initial_stacks")

  local allies = FindOrganicAlliesInRadius(caster, FIND_UNITS_EVERYWHERE)

  local potentialTargets = {}
  for _,ally in pairs(allies) do
    if not ally:IsRealHero() and not ally:HasModifier("modifier_energy_shield") then
      table.insert(potentialTargets, ally)
    end
  end

  if #potentialTargets == 0 then return end

  local target = GetRandomTableElement(potentialTargets)

  target:AddNewModifier(caster, ability, "modifier_energy_shield", {})

  target:SetModifierStackCount("modifier_energy_shield", caster, initial_stacks)
end

modifier_energy_shield = class({})

function modifier_energy_shield:OnCreated()
  self.armor = self:GetAbility():GetSpecialValueFor("armor")
end

function modifier_energy_shield:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
  return funcs
end

function modifier_energy_shield:GetModifierPhysicalArmorBonus()
  return self.armor
end