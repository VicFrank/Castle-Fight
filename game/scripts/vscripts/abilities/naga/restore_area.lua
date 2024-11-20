LinkLuaModifier("modifier_restore_area_aura", "abilities/naga/restore_area.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_restore_area", "abilities/naga/restore_area.lua", LUA_MODIFIER_MOTION_NONE)

restore_area = class({})
function restore_area:GetIntrinsicModifierName() return "modifier_restore_area_aura" end

modifier_restore_area_aura = class({})

function modifier_restore_area_aura:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.radius = self.ability:GetSpecialValueFor("radius")

  if not IsServer() then return end

  -- Doesn't work properly if spawned immediately
  Timers:CreateTimer(1/30,function()
    self.particle = ParticleManager:CreateParticle("particles/radiant_fx2/good_ancient001_ambient.vpcf", PATTACH_WORLDORIGIN, self.caster)
    ParticleManager:SetParticleControl(self.particle, 0, self.parent:GetAbsOrigin() + Vector(0,0,10))
  end)
end

function modifier_restore_area_aura:OnDestroy()
  if not IsServer() then return end
  ParticleManager:DestroyParticle(self.particle, false)
  ParticleManager:ReleaseParticleIndex(self.particle)
end

function modifier_restore_area_aura:IsAura()
  return true
end

function modifier_restore_area_aura:IsAuraActiveOnDeath()
  return false
end

function modifier_restore_area_aura:IsPurgable()
  return false
end

function modifier_restore_area_aura:GetAuraRadius()
  return self.radius
end

function modifier_restore_area_aura:GetModifierAura()
  return "modifier_restore_area"
end

function modifier_restore_area_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_restore_area_aura:GetAuraEntityReject(target)
  if not IsServer() then return end
  return self.parent:IsUnderConstruction() or target:IsRealHero()
end

function modifier_restore_area_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_restore_area_aura:GetAuraDuration()
  return 0.5
end

----------------------------------------------------------------------------------------------------

modifier_restore_area = class({})

function modifier_restore_area:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.unit_regen = self.ability:GetSpecialValueFor("unit_regen")
  self.building_regen = self.ability:GetSpecialValueFor("building_regen")

  if self.parent:HasModifier("modifier_building") then
    self.regen = self.building_regen
  else
    self.regen = self.unit_regen
  end
end

function modifier_restore_area:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
  }
  return funcs
end

function modifier_restore_area:GetModifierConstantHealthRegen()
  return self.regen
end