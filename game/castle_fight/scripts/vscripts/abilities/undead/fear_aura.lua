banshee_fear_aura = class({})
LinkLuaModifier("modifier_fear_aura", "abilities/undead/fear_aura.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_fear_aura_buff", "abilities/undead/fear_aura", LUA_MODIFIER_MOTION_NONE )

function banshee_fear_aura:GetIntrinsicModifierName()
  return "modifier_fear_aura"
end

modifier_fear_aura = class({})

function modifier_fear_aura:IsAura()
  return true
end

function modifier_fear_aura:IsHidden()
  return true
end

function modifier_fear_aura:GetAuraDuration()
  return 0.5
end

function modifier_fear_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_fear_aura:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_fear_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_fear_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_fear_aura:GetModifierAura()
  return "modifier_fear_aura_buff"
end

function modifier_fear_aura:IsAuraActiveOnDeath()
  return false
end

function modifier_fear_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero()
end

function modifier_fear_aura:IsHidden()
  return true
end

modifier_fear_aura_buff = class({})

function modifier_fear_aura_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
  }
  return funcs
end

function modifier_fear_aura_buff:OnCreated()
  self.damage_decrease = -self:GetAbility():GetSpecialValueFor("damage_decrease")
end

function modifier_fear_aura_buff:GetModifierBaseDamageOutgoing_Percentage()
  return self.damage_decrease
end

function modifier_fear_aura_buff:IsDebuff()
    return true
end