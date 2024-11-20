LinkLuaModifier("modifier_bassline_buff", "items/modifiers/bassline_modifier.lua", LUA_MODIFIER_MOTION_NONE)

modifier_bassline_aura = class({})

function modifier_bassline_aura:GetTexture() return "item_ancient_janggo" end
function modifier_bassline_aura:IsAura() return true end
function modifier_bassline_aura:IsPurgable() return false end
function modifier_bassline_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_bassline_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_ALL end
function modifier_bassline_aura:GetAuraDuration() return 0.5 end
function modifier_bassline_aura:GetModifierAura() return "modifier_bassline_buff" end

function modifier_bassline_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero()
end

function modifier_bassline_aura:OnCreated()
  if not IsServer() then return end
  self.creationTime = GameRules:GetGameTime()
end

function modifier_bassline_aura:GetAuraRadius()
  if not IsServer() then return end

  local time = GameRules:GetGameTime() - self.creationTime
  local radius = 99999
  local expansionTime = 3

  if time < expansionTime then
    multiplier = time / expansionTime

    return radius * multiplier
  end

  return radius
end

modifier_bassline_buff = class({})

function modifier_bassline_buff:GetTexture() return "item_ancient_janggo" end
function modifier_bassline_buff:IsPurgable() return false end

function modifier_bassline_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
  }
  return funcs
end

function modifier_bassline_buff:GetModifierMoveSpeedBonus_Percentage()
  return 15
end

function modifier_bassline_buff:GetModifierAttackSpeedBonus_Constant()
  return 30
end