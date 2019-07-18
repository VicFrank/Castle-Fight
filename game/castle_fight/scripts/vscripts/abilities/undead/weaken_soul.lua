weaken_soul = class({})
LinkLuaModifier("modifier_weaken_soul_aura", "abilities/undead/weaken_soul.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_weaken_soul_debuff", "abilities/undead/weaken_soul.lua", LUA_MODIFIER_MOTION_NONE)

function weaken_soul:GetIntrinsicModifierName()
  return "modifier_weaken_soul_aura"
end

modifier_weaken_soul_aura = class({})

function modifier_weaken_soul_aura:OnCreated()
  self.range = self:GetAbility():GetSpecialValueFor("range")
end

function modifier_weaken_soul_aura:IsAura()
  return true
end

function modifier_weaken_soul_aura:IsPurgable()
  return false
end

function modifier_weaken_soul_aura:IsAuraActiveOnDeath()
  return false
end

function modifier_weaken_soul_aura:GetAuraRadius()
  if not IsServer() then return end
  local radius = self.range
  local parent = self:GetParent()
  if parent:GetTeam() == DOTA_TEAM_NEUTRALS or parent:PassivesDisabled() then
    radius = 0
  end
  return radius
end

function modifier_weaken_soul_aura:GetModifierAura()
  return "modifier_weaken_soul_debuff"
end

function modifier_weaken_soul_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_weaken_soul_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero() or target:IsMechanical()
end

function modifier_weaken_soul_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_weaken_soul_aura:GetAuraDuration()
  return 0.5
end

modifier_weaken_soul_debuff = class({})

function modifier_weaken_soul_debuff:IsDebuff() return true end

function modifier_weaken_soul_debuff:IsPurgable()
  return false
end

function modifier_weaken_soul_debuff:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.armor_reduction = self.ability:GetSpecialValueFor("armor_reduction")
end

function modifier_weaken_soul_debuff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
  return funcs
end

function modifier_weaken_soul_debuff:GetModifierPhysicalArmorBonus(keys)
  return -self.armor_reduction
end