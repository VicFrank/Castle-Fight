void_walker_corruption_aura = class({})
LinkLuaModifier("modifier_corruption_aura", "abilities/corrupted/corruption_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_corruption_aura_debuff", "abilities/corrupted/corruption_aura.lua", LUA_MODIFIER_MOTION_NONE)

function void_walker_corruption_aura:GetIntrinsicModifierName()
  return "modifier_corruption_aura"
end

modifier_corruption_aura = class({})

function modifier_corruption_aura:OnCreated()
  self.radius = self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_corruption_aura:OnRefresh()
  self.radius = self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_corruption_aura:IsAura()
  return true
end

function modifier_corruption_aura:IsPurgable()
  return false
end

function modifier_corruption_aura:IsAuraActiveOnDeath()
  return false
end

function modifier_corruption_aura:GetAuraRadius()
  if not IsServer() then return end
  local radius = self.radius
  local parent = self:GetParent()
  if parent:GetTeam() == DOTA_TEAM_NEUTRALS or parent:PassivesDisabled() then
    radius = 0
  end
  return radius
end

function modifier_corruption_aura:GetModifierAura()
  return "modifier_corruption_aura_debuff"
end

function modifier_corruption_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_corruption_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero()
end

function modifier_corruption_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_corruption_aura:GetAuraDuration()
  return 0.5
end

modifier_corruption_aura_debuff = class({})

function modifier_corruption_aura_debuff:IsDebuff() return true end
function modifier_corruption_aura_debuff:IsPurgable() return false end

function modifier_corruption_aura_debuff:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  if not self.ability then return end

  self.armor = self.ability:GetSpecialValueFor("armor")
end

function modifier_corruption_aura_debuff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
  return funcs
end

function modifier_corruption_aura_debuff:GetModifierPhysicalArmorBonus(keys)
  return self.armor
end