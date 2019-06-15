call_to_arms = class({})
LinkLuaModifier("modifier_call_to_arms_aura", "abilities/human/call_to_arms.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_call_to_arms_aura_buff", "abilities/human/call_to_arms.lua", LUA_MODIFIER_MOTION_NONE)

function call_to_arms:GetIntrinsicModifierName()
  return "modifier_call_to_arms_aura"
end

modifier_call_to_arms_aura = class({})

function modifier_call_to_arms_aura:IsAura()
  return true
end

function modifier_call_to_arms_aura:IsHidden()
  return false
end

function modifier_call_to_arms_aura:IsPurgable()
  return false
end

function modifier_call_to_arms_aura:GetAuraRadius()
  return 99999
end

function modifier_call_to_arms_aura:GetModifierAura()
  return "modifier_call_to_arms_aura_buff"
end

function modifier_call_to_arms_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_call_to_arms_aura:GetAuraEntityReject(target)
  return not IsCustomBuilding(target) or not (target:GetBuildingType() == "UnitTrainer" or target:GetBuildingType() == "SiegeTrainer")
end

function modifier_call_to_arms_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_call_to_arms_aura:GetAuraDuration()
  return 0.5
end

modifier_call_to_arms_aura_buff = class({})

function modifier_call_to_arms_aura_buff:IsPurgable()
  return false
end

function modifier_call_to_arms_aura_buff:GetTexture()
  return "chen_holy_persuasion"
end