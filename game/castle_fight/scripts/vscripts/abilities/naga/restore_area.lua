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
  return self.parent:IsUnderConstruction() and target:IsRealHero()
end

function modifier_restore_area_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_restore_area_aura:GetAuraDuration()
  return 0.5
end

modifier_restore_area = class({})

function modifier_restore_area:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.unit_regen = self.ability:GetSpecialValueFor("unit_regen")
  self.building_regen = self.ability:GetSpecialValueFor("building_regen")
end

function modifier_restore_area:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_restore_area:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
  }
  return funcs
end

function modifier_restore_area:GetModifierConstantHealthRegen()
  if IsCustomBuilding(self.parent) then
    return self.building_regen
  else
    return self.unit_regen
  end
end