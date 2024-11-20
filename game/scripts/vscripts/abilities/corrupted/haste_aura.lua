felhound_haste_aura = class({})
LinkLuaModifier("modifier_haste_aura", "abilities/corrupted/haste_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_haste_aura_buff", "abilities/corrupted/haste_aura.lua", LUA_MODIFIER_MOTION_NONE)

function felhound_haste_aura:GetIntrinsicModifierName()
  return "modifier_haste_aura"
end

modifier_haste_aura = class({})

function modifier_haste_aura:OnCreated()
  self.radius = self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_haste_aura:IsAura()
  return true
end

function modifier_haste_aura:IsPurgable()
  return false
end

function modifier_haste_aura:IsAuraActiveOnDeath()
  return false
end

function modifier_haste_aura:GetAuraRadius()
  return self.radius
end

function modifier_haste_aura:GetModifierAura()
  return "modifier_haste_aura_buff"
end

function modifier_haste_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_haste_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero()
end

function modifier_haste_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_haste_aura:GetAuraDuration()
  return 0.5
end

modifier_haste_aura_buff = class({})

function modifier_haste_aura_buff:IsDebuff() return false end
function modifier_haste_aura_buff:IsPurgable() return false end

function modifier_haste_aura_buff:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  if not self.ability then return end

  self.attack_speed = self.ability:GetSpecialValueFor("attack_speed")
end

function modifier_haste_aura_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
  return funcs
end

function modifier_haste_aura_buff:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed
end