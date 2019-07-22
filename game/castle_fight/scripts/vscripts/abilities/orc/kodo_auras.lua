kodo_melee_damage_aura = class({})
kodo_armor_aura = class({})
LinkLuaModifier("modifier_kodo_melee_damage_aura", "abilities/orc/kodo_auras.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_kodo_melee_damage_aura_buff", "abilities/orc/kodo_auras", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_kodo_armor_aura", "abilities/orc/kodo_auras.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_kodo_armor_aura_buff", "abilities/orc/kodo_auras", LUA_MODIFIER_MOTION_NONE )

function kodo_melee_damage_aura:GetIntrinsicModifierName()
  return "modifier_kodo_melee_damage_aura"
end
function kodo_armor_aura:GetIntrinsicModifierName()
  return "modifier_kodo_armor_aura"
end

modifier_kodo_melee_damage_aura = class({})

function modifier_kodo_melee_damage_aura:IsAura()
  return true
end

function modifier_kodo_melee_damage_aura:GetAuraDuration()
  return 0.5
end

function modifier_kodo_melee_damage_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_kodo_melee_damage_aura:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_kodo_melee_damage_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_kodo_melee_damage_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_kodo_melee_damage_aura:GetModifierAura()
  return "modifier_kodo_melee_damage_aura_buff"
end

function modifier_kodo_melee_damage_aura:IsAuraActiveOnDeath()
  return false
end

function modifier_kodo_melee_damage_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero() or target:GetAttackCapability() == DOTA_UNIT_CAP_RANGED_ATTACK
end

modifier_kodo_melee_damage_aura_buff = class({})

function modifier_kodo_melee_damage_aura_buff:IsDebuff() return false end

function modifier_kodo_melee_damage_aura_buff:OnCreated()
  self.damage = self:GetAbility():GetSpecialValueFor("damage")
end

function modifier_kodo_melee_damage_aura_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
  }
  return funcs
end

function modifier_kodo_melee_damage_aura_buff:GetModifierBaseDamageOutgoing_Percentage()
  return self.damage
end

modifier_kodo_armor_aura = class({})

function modifier_kodo_armor_aura:IsAura()
  return true
end

function modifier_kodo_armor_aura:GetAuraDuration()
  return 0.5
end

function modifier_kodo_armor_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_kodo_armor_aura:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_kodo_armor_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_kodo_armor_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_kodo_armor_aura:GetModifierAura()
  return "modifier_kodo_armor_aura_buff"
end

function modifier_kodo_armor_aura:IsAuraActiveOnDeath()
  return false
end

function modifier_kodo_armor_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero()
end

modifier_kodo_armor_aura_buff = class({})

function modifier_kodo_armor_aura_buff:IsDebuff()
  return false
end

function modifier_kodo_armor_aura_buff:OnCreated()
  if not self:GetAbility() then return end
  self.armor = self:GetAbility():GetSpecialValueFor("armor")
end

function modifier_kodo_armor_aura_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
  return funcs
end

function modifier_kodo_armor_aura_buff:GetModifierPhysicalArmorBonus()
  return self.armor
end