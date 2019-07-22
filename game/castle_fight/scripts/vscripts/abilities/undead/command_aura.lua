skeleton_general_command_aura = class({})
LinkLuaModifier("modifier_command_aura", "abilities/undead/command_aura.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_command_aura_buff", "abilities/undead/command_aura", LUA_MODIFIER_MOTION_NONE )

function skeleton_general_command_aura:GetIntrinsicModifierName()
  return "modifier_command_aura"
end

modifier_command_aura = class({})

function modifier_command_aura:IsAura()
  return true
end

function modifier_command_aura:IsHidden()
  return true
end

function modifier_command_aura:GetAuraDuration()
  return 0.5
end

function modifier_command_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_command_aura:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_command_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_command_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_command_aura:GetModifierAura()
  return "modifier_command_aura_buff"
end

function modifier_command_aura:IsAuraActiveOnDeath()
  return false
end

function modifier_command_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero()
end

function modifier_command_aura:IsHidden()
  return true
end

modifier_command_aura_buff = class({})

function modifier_command_aura_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
  }
  return funcs
end

function modifier_command_aura_buff:GetModifierBaseDamageOutgoing_Percentage()
  return self:GetAbility():GetSpecialValueFor("damage_increase")
end

function modifier_command_aura_buff:IsDebuff()
    return false
end