gaze_of_corruption = class({})
LinkLuaModifier("modifier_gaze_of_corruption_aura", "abilities/corrupted/gaze_of_corruption.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gaze_of_corruption_debuff", "abilities/corrupted/gaze_of_corruption.lua", LUA_MODIFIER_MOTION_NONE)

function gaze_of_corruption:GetIntrinsicModifierName()
  return "modifier_gaze_of_corruption_aura"
end

modifier_gaze_of_corruption_aura = class({})

function modifier_gaze_of_corruption_aura:IsAura()
  return true
end

function modifier_gaze_of_corruption_aura:IsPurgable()
  return false
end

function modifier_gaze_of_corruption_aura:IsAuraActiveOnDeath()
  return false
end

function modifier_gaze_of_corruption_aura:GetAuraRadius()
  if not IsServer() then return end
  local radius = 99999
  local parent = self:GetParent()
  if parent:GetTeam() == DOTA_TEAM_NEUTRALS or parent:PassivesDisabled() then
    radius = 0
  end
  return radius
end

function modifier_gaze_of_corruption_aura:GetModifierAura()
  return "modifier_gaze_of_corruption_debuff"
end

function modifier_gaze_of_corruption_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_gaze_of_corruption_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero()
end

function modifier_gaze_of_corruption_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_gaze_of_corruption_aura:GetAuraDuration()
  return 0.5
end

modifier_gaze_of_corruption_debuff = class({})

function modifier_gaze_of_corruption_debuff:IsDebuff() return true end

function modifier_gaze_of_corruption_debuff:IsPurgable()
  return false
end

function modifier_gaze_of_corruption_debuff:OnCreated()
  self.armor = self:GetAbility():GetSpecialValueFor("armor")
end

function modifier_gaze_of_corruption_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

function modifier_gaze_of_corruption_debuff:GetModifierPhysicalArmorBonus()
  return self.armor
end

function modifier_gaze_of_corruption_debuff:GetTexture()
  return "medusa_stone_gaze"
end