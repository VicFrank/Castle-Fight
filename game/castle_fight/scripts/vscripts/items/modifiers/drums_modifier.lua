LinkLuaModifier("modifier_drums_buff", "items/modifiers/drums_modifier.lua", LUA_MODIFIER_MOTION_NONE)

modifier_drums_aura = class({})

function modifier_drums_aura:GetTexture() return "item_spirit_vessel" end
function modifier_drums_aura:IsAura() return true end
function modifier_drums_aura:IsPurgable() return false end
function modifier_drums_aura:GetAuraRadius() return 99999 end
function modifier_drums_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_drums_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_ALL end
function modifier_drums_aura:GetAuraDuration() return 0.5 end
function modifier_drums_aura:GetModifierAura() return "modifier_drums_buff" end

function modifier_drums_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero()
end

modifier_drums_buff = class({})

function modifier_drums_buff:GetTexture() return "item_spirit_vessel" end
function modifier_drums_buff:IsPurgable() return false end

function modifier_drums_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
  }
  return funcs
end

function modifier_drums_buff:GetModifierBaseDamageOutgoing_Percentage()
  return 33
end