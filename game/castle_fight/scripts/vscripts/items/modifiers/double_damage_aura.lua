LinkLuaModifier("modifier_custom_double_damage", "items/modifiers/double_damage_aura.lua", LUA_MODIFIER_MOTION_NONE)

modifier_double_damage_aura = class({})

function modifier_double_damage_aura:GetTexture() return "item_energy_booster" end
function modifier_double_damage_aura:IsAura() return true end
function modifier_double_damage_aura:IsPurgable() return false end
function modifier_double_damage_aura:GetAuraRadius() return 99999 end
function modifier_double_damage_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_double_damage_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_ALL end
function modifier_double_damage_aura:GetAuraDuration() return 0.5 end
function modifier_double_damage_aura:GetModifierAura() return "modifier_custom_double_damage" end

function modifier_double_damage_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero()
end

modifier_custom_double_damage = class({})

function modifier_custom_double_damage:IsPurgable() return false end
function modifier_custom_double_damage:GetTexture() return "item_energy_booster" end

function modifier_custom_double_damage:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
  }
  return funcs
end

function modifier_custom_double_damage:GetModifierBaseDamageOutgoing_Percentage()
  return 100
end

function modifier_custom_double_damage:GetEffectName()
  return "particles/generic_gameplay/rune_doubledamage_owner.vpcf"
end