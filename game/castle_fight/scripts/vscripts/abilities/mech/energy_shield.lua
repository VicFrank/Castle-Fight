generator_energy_shield = class({})

LinkLuaModifier("modifier_generator_energy_shield", "abilities/mech/energy_shield.lua", LUA_MODIFIER_MOTION_NONE)

function generator_energy_shield:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local initial_stacks = ability:GetSpecialValueFor("initial_stacks")

  local allies = FindAlliesInRadius(caster, FIND_UNITS_EVERYWHERE)

  local potentialTargets = {}
  for _,ally in pairs(allies) do
    if not ally:IsRealHero() and not IsCustomBuilding(ally) and not ally:HasModifier("modifier_generator_energy_shield") then
      table.insert(potentialTargets, ally)
    end
  end

  if #potentialTargets == 0 then return end

  local target = GetRandomTableElement(potentialTargets)

  caster:EmitSound("Hero_Abaddon.AphoticShield.Cast")

  target:AddNewModifier(caster, ability, "modifier_generator_energy_shield", {})

  target:SetModifierStackCount("modifier_generator_energy_shield", caster, initial_stacks)
end

modifier_generator_energy_shield = class({})

function modifier_generator_energy_shield:OnCreated()
  self.armor = self:GetAbility():GetSpecialValueFor("armor")

  if IsServer() then
    self:GetParent():IncreaseMaxHealth(100)
  end

  local shield_size = self:GetParent():GetModelRadius() * 0.7

  self.particle = ParticleManager:CreateParticle("particles/items_fx/immunity_sphere_buff.vpcf", PATTACH_CENTER_FOLLOW, self:GetParent()) 
end

function modifier_generator_energy_shield:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
  return funcs
end

function modifier_generator_energy_shield:GetModifierPhysicalArmorBonus()
  return self.armor
end

function modifier_generator_energy_shield:OnBuildingTarget()
  if not IsServer() then return end

  local parent = self:GetParent()
  local currentStacks = parent:GetModifierStackCount("modifier_generator_energy_shield", parent)

  parent:SetModifierStackCount("modifier_generator_energy_shield", parent, currentStacks - 1)

  if currentStacks <= 1 then
    self:Destroy()
  end

  return true
end

function modifier_generator_energy_shield:OnDestroy()
  if IsServer() then
    self:GetParent():EmitSound("Hero_Abaddon.AphoticShield.Destroy")
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
  end
end