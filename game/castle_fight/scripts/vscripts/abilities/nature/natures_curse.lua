ancient_of_wonders_natures_curse = class({})
LinkLuaModifier("modifier_natures_curse_aura", "abilities/nature/natures_curse.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_natures_curse_debuff", "abilities/nature/natures_curse.lua", LUA_MODIFIER_MOTION_NONE)

function ancient_of_wonders_natures_curse:OnSpellStart()
  local duration = self:GetSpecialValueFor("duration")
  self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_natures_curse_aura", {duration = duration})
end

modifier_natures_curse_aura = class({})

function modifier_natures_curse_aura:IsAura()
  return true
end

function modifier_natures_curse_aura:IsPurgable()
  return false
end

function modifier_natures_curse_aura:GetAuraRadius()
  if not IsServer() then return end
  local radius = 99999
  local parent = self:GetParent()
  if parent:GetTeam() == DOTA_TEAM_NEUTRALS or parent:PassivesDisabled() then
    radius = 0
  end
  return radius
end

function modifier_natures_curse_aura:GetModifierAura()
  return "modifier_natures_curse_debuff"
end

function modifier_natures_curse_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_natures_curse_aura:GetAuraEntityReject(target)
  return target:IsRealHero()
end

function modifier_natures_curse_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_natures_curse_aura:GetAuraDuration()
  return 0.5
end

modifier_natures_curse_debuff = class({})

function modifier_natures_curse_debuff:IsPurgable()
  return false
end

function modifier_natures_curse_debuff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MANA_REGEN_PERCENTAGE
  }
  return funcs  
end

function modifier_natures_curse_debuff:GetModifierPercentageManaRegen()
  return self:GetAbility():GetSpecialValueFor("mana_regen")
end