LinkLuaModifier("modifier_rune_of_repair_buff", "items/modifiers/rune_of_repair_modifier.lua", LUA_MODIFIER_MOTION_NONE)

modifier_rune_of_repair_aura = class({})

function modifier_rune_of_repair_aura:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.radius = 900
end

function modifier_rune_of_repair_aura:GetTexture() return "item_holy_locket" end

function modifier_rune_of_repair_aura:IsAura()
  return true
end

function modifier_rune_of_repair_aura:IsPurgable()
  return false
end

function modifier_rune_of_repair_aura:GetAuraRadius()
  return self.radius
end

function modifier_rune_of_repair_aura:GetModifierAura()
  return "modifier_rune_of_repair_buff"
end

function modifier_rune_of_repair_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_rune_of_repair_aura:GetAuraEntityReject(target)
  return target:IsRealHero()
end

function modifier_rune_of_repair_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_rune_of_repair_aura:GetAuraDuration()
  return 0.5
end

function modifier_rune_of_repair_aura:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_rune_of_repair_buff = class({})

function modifier_rune_of_repair_buff:GetTexture() return "item_holy_locket" end

function modifier_rune_of_repair_buff:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.building_regen = 3
end

function modifier_rune_of_repair_buff:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_rune_of_repair_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
  }
  return funcs
end

function modifier_rune_of_repair_buff:GetModifierConstantHealthRegen()
  return self.building_regen
end