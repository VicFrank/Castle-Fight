LinkLuaModifier("modifier_bear_feral_rage", "abilities/nature/feral_rage.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bear_feral_rage_buff", "abilities/nature/feral_rage.lua", LUA_MODIFIER_MOTION_NONE)

bear_feral_rage = class({})
function bear_feral_rage:GetIntrinsicModifierName() return "modifier_bear_feral_rage" end

modifier_bear_feral_rage = class({})

function modifier_bear_feral_rage:IsHidden() return true end

function modifier_bear_feral_rage:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()
end

function modifier_bear_feral_rage:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_bear_feral_rage:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster and not IsCustomBuilding(target) then
    if self.ability:GetSpecialValueFor("chance") >= RandomInt(1, 100) then
      attacker:AddNewModifier(attacker, self.ability, "modifier_bear_feral_rage_buff", {duration = self.ability:GetSpecialValueFor("duration")})
    end
  end
end

modifier_bear_feral_rage_buff = class({})

function modifier_bear_feral_rage_buff:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.attack_speed = self.ability:GetSpecialValueFor("attack_speed")
  self.damage_increase = self.ability:GetSpecialValueFor("damage_increase")
end

function modifier_bear_feral_rage_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
  }
  return funcs
end

function modifier_bear_feral_rage_buff:GetModifierBaseDamageOutgoing_Percentage()
return self.damage_increase
end

function modifier_bear_feral_rage_buff:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed
end