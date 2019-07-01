troll_berserk = class({})
LinkLuaModifier("modifier_troll_berserk", "abilities/orc/berserk.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_troll_berserk_buff", "abilities/orc/berserk.lua", LUA_MODIFIER_MOTION_NONE)

function troll_berserk:GetIntrinsicModifierName()
  return "modifier_troll_berserk"
end

modifier_troll_berserk = class({})

function modifier_troll_berserk:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS
  }
  return funcs
end

function modifier_troll_berserk:OnDeath(params)
  if not IsServer() then return end

  if params.attacker == self:GetParent() then
    local duration = self:GetAbility():GetSpecialValueFor("duration")

    print("On Death")

    self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_troll_berserk_buff", {duration = duration})
  end
end

function modifier_troll_berserk:GetActivityTranslationModifiers()
  return "run"
end


modifier_troll_berserk_buff = class({})

function modifier_troll_berserk_buff:OnCreated()
  self.attack_speed = self:GetAbility():GetSpecialValueFor("attack_speed")
  self.move_speed = self:GetAbility():GetSpecialValueFor("move_speed")
  self.damage_increase = self:GetAbility():GetSpecialValueFor("damage_increase")

  print("OnCreated")
end

function modifier_troll_berserk_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
  }
  return funcs
end

function modifier_troll_berserk_buff:GetModifierAttackSpeedBonus_Constant(keys)
  return self.attack_speed
end

function modifier_troll_berserk_buff:GetModifierMoveSpeedBonus_Constant(keys)
  return self.move_speed
end

function modifier_troll_berserk_buff:GetModifierIncomingDamage_Percentage(keys)
  return self.damage_increase
end

function modifier_troll_berserk_buff:GetEffectName()
  return "particles/units/heroes/hero_troll_warlord/troll_warlord_battletrance_buff.vpcf"
end