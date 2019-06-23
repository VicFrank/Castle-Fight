keeper_natures_aura = class({})

LinkLuaModifier("modifier_keeper_natures_aura", "abilities/nature/natures_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_keeper_natures_aura_buff", "abilities/nature/natures_aura.lua", LUA_MODIFIER_MOTION_NONE)

function keeper_natures_aura:GetIntrinsicModifierName()
  return "modifier_keeper_natures_aura"
end

modifier_keeper_natures_aura_buff = class({})

function modifier_keeper_natures_aura_buff:IsAura() return true end
function modifier_keeper_natures_aura_buff:GetAuraDuration() return 0.5 end
function modifier_keeper_natures_aura_buff:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_keeper_natures_aura_buff:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_keeper_natures_aura_buff:GetAuraSearchType() return DOTA_UNIT_TARGET_ALL end
function modifier_keeper_natures_aura_buff:GetModifierAura() return "modifier_keeper_natures_aura_buff" end
function modifier_keeper_natures_aura_buff:IsAuraActiveOnDeath() return false end
function modifier_keeper_natures_aura_buff:GetAuraEntityReject(target) return target:IsRealHero() or IsCustomBuilding(target) end

modifier_keeper_natures_aura_buff = class({})

function modifier_keeper_natures_aura_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
  }
  return funcs
end

function modifier_keeper_natures_aura_buff:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor("health_per_second")
end