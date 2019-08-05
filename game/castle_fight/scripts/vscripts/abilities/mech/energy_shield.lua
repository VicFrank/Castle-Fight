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

  local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/abaddon_aphotic_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
  local common_vector = Vector(shield_size, 0, shield_size)
  ParticleManager:SetParticleControl(particle, 1, common_vector)
  ParticleManager:SetParticleControl(particle, 2, common_vector)
  ParticleManager:SetParticleControl(particle, 4, common_vector)
  ParticleManager:SetParticleControl(particle, 5, Vector(shield_size, 0, 0))

  -- Proper Particle attachment courtesy of BMD. Only PATTACH_POINT_FOLLOW will give the proper shield position
  ParticleManager:SetParticleControlEnt(particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, attach_hitloc, self:GetParent():GetAbsOrigin(), true)
  self:AddParticle(particle, false, false, -1, false, false)
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
  end
end