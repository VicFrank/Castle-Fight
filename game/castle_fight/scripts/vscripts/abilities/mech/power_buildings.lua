power_buildings = class({})
LinkLuaModifier("modifier_power_buildings_aura", "abilities/mech/power_buildings.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_power_buildings_aura_buff", "abilities/mech/power_buildings.lua", LUA_MODIFIER_MOTION_NONE)

function power_buildings:GetIntrinsicModifierName()
  return "modifier_power_buildings_aura"
end

modifier_power_buildings_aura = class({})

function modifier_power_buildings_aura:IsAura()
  return true
end

function modifier_power_buildings_aura:IsHidden()
  return true
end

function modifier_power_buildings_aura:IsAuraActiveOnDeath()
  return false
end

function modifier_power_buildings_aura:IsPurgable()
  return false
end

function modifier_power_buildings_aura:OnCreated()
  self.radius = self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_power_buildings_aura:GetAuraRadius()
  if not IsServer() then return end
  local parent = self:GetParent()
  if parent:GetTeam() == DOTA_TEAM_NEUTRALS or parent:PassivesDisabled() then
    radius = 0
  end
  return self.radius
end

function modifier_power_buildings_aura:GetModifierAura()
  return "modifier_power_buildings_aura_buff"
end

function modifier_power_buildings_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_power_buildings_aura:GetAuraEntityReject(target)
  return not IsCustomBuilding(target)
end

function modifier_power_buildings_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_power_buildings_aura:GetAuraDuration()
  return 0.5
end

modifier_power_buildings_aura_buff = class({})

function modifier_power_buildings_aura_buff:IsPurgable()
  return false
end

function modifier_power_buildings_aura_buff:GetTexture()
  return "tinker_rearm"
end

function modifier_power_buildings_aura_buff:OnCreated()
  self.armor = self:GetAbility():GetSpecialValueFor("armor")
  self.tower_damage = self:GetAbility():GetSpecialValueFor("tower_damage")
  self.mana_regen = self:GetAbility():GetSpecialValueFor("mana_regen")

  local parent = self:GetParent()
end

function modifier_power_buildings_aura_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
  }
end

function modifier_power_buildings_aura_buff:GetModifierPhysicalArmorBonus()
  return self.armor
end

function modifier_power_buildings_aura_buff:GetModifierBaseDamageOutgoing_Percentage()
  return self.tower_damage
end

function modifier_power_buildings_aura_buff:GetModifierConstantManaRegen()
  return self.mana_regen
end

modifier_power_buildings_creep_buff = class({})

function modifier_power_buildings_creep_buff:IsPurgable()
  return false
end

function modifier_power_buildings_creep_buff:GetTexture()
  return "tinker_rearm"
end

function modifier_power_buildings_creep_buff:OnCreated()
  self.creep_health = self:GetAbility():GetSpecialValueFor("creep_health")
  self.creep_armor = self:GetAbility():GetSpecialValueFor("creep_armor")
  self.creep_damage = self:GetAbility():GetSpecialValueFor("creep_damage")

  if IsServer() then
    self:GetParent():IncreaseMaxHealth(self.creep_health)
  end
end

function modifier_power_buildings_creep_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_power_buildings_creep_buff:GetModifierPhysicalArmorBonus()
  return self.creep_armor
end

function modifier_power_buildings_creep_buff:GetModifierBaseDamageOutgoing_Percentage()
  return self.creep_damage
end
