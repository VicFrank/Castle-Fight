LinkLuaModifier("modifier_naga_purge", "abilities/naga/purge.lua", LUA_MODIFIER_MOTION_NONE)

naga_siren_purge = class({})

function naga_siren_purge:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  local duration = ability:GetSpecialValueFor("duration")

  caster:EmitSound("DOTA_Item.DiffusalBlade.Activate")

  target:Purge(true, false, false, false, false)
  target:AddNewModifier(caster, ability, "modifier_naga_purge", {duration = duration})

  target:EmitSound("DOTA_Item.DiffusalBlade.Target")

  ParticleManager:CreateParticle("particles/generic_gameplay/generic_purge.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
end

modifier_naga_purge = class({})

function modifier_naga_purge:IsDebuff() return true end

function modifier_naga_purge:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.slow_percent = self.ability:GetSpecialValueFor("slow_percent")
end

function modifier_naga_purge:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
  }
  return funcs
end

function modifier_naga_purge:GetModifierMoveSpeedBonus_Percentage()
  return -self.slow_percent
end