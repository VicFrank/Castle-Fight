ice_queen_crystal_aura = class({})

LinkLuaModifier("modifier_ice_queen_crystal_aura", "abilities/north/crystal_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ice_queen_crystal_aura_buff", "abilities/north/crystal_aura.lua", LUA_MODIFIER_MOTION_NONE)

function ice_queen_crystal_aura:GetIntrinsicModifierName()
  return "modifier_ice_queen_crystal_aura"
end

modifier_ice_queen_crystal_aura = class({})

function modifier_ice_queen_crystal_aura:IsAura()
  return true
end

function modifier_ice_queen_crystal_aura:GetAuraDuration()
  return 0.5
end

function modifier_ice_queen_crystal_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_ice_queen_crystal_aura:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_ice_queen_crystal_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_ice_queen_crystal_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_ice_queen_crystal_aura:GetModifierAura()
  return "modifier_ice_queen_crystal_aura_buff"
end

function modifier_ice_queen_crystal_aura:IsAuraActiveOnDeath()
  return false
end

function modifier_ice_queen_crystal_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero()
end

modifier_ice_queen_crystal_aura_buff = class({})

function modifier_ice_queen_crystal_aura_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
  }
  return funcs
end

function modifier_ice_queen_crystal_aura_buff:OnCreated()
  if self:GetAbility() then
    self.mana_regen = self:GetAbility():GetSpecialValueFor("mana_per_second")
  else
    self.mana_regen = 0.5
  end
end

function modifier_ice_queen_crystal_aura_buff:GetModifierConstantManaRegen()
  return self.mana_regen
end