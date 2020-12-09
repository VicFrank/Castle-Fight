gale = class({})

LinkLuaModifier("modifier_gale", "abilities/elemental/gale.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gale_debuff", "abilities/elemental/gale.lua", LUA_MODIFIER_MOTION_NONE)

function gale:GetIntrinsicModifierName() return "modifier_gale" end

modifier_gale = class({})

function modifier_gale:IsAura() return true end
function modifier_gale:IsHidden() return true end
function modifier_gale:IsDebuff() return false end
function modifier_gale:IsPurgable() return false end
function modifier_gale:GetAuraDuration() return 0.5 end
function modifier_gale:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end
function modifier_gale:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function modifier_gale:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_gale:GetAuraSearchType() return DOTA_UNIT_TARGET_ALL end
function modifier_gale:GetModifierAura() return "modifier_gale_debuff" end
function modifier_gale:IsAuraActiveOnDeath() return false end
function modifier_gale:GetAuraEntityReject(target)
  return target:IsRealHero() or (not target:IsFlyingUnit())
end

modifier_gale_debuff = class({})

function modifier_gale_debuff:IsHidden() return false end
function modifier_gale_debuff:IsDebuff() return true end
function modifier_gale_debuff:IsPurgable() return false end

function modifier_gale_debuff:OnCreated()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.slow_percent = self.ability:GetSpecialValueFor("slow_percent")
end

function modifier_gale_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
  }
end

function modifier_gale_debuff:GetModifierMoveSpeedBonus_Percentage()
  return -self.slow_percent
end

function modifier_gale_debuff:GetModifierAttackSpeedBonus_Constant()
  return -self.slow_percent
end

function modifier_gale_debuff:GetEffectName()
  return "particles/units/heroes/hero_omniknight/omniknight_degen_aura_debuff.vpcf"
end

function modifier_gale_debuff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
