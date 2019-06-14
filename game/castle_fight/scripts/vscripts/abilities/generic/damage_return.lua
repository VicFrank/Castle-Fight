LinkLuaModifier("modifier_damage_return", "abilities/generic/damage_return.lua", LUA_MODIFIER_MOTION_NONE)

dragon_turtle_damage_return = class({})
function dragon_turtle_damage_return:GetIntrinsicModifierName() return "modifier_damage_return" end

modifier_damage_return = class({})

function modifier_damage_return:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.damage_return = self.ability:GetSpecialValueFor("damage_return")
end

function modifier_damage_return:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_damage_return:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster then
    -- do mana burn here
  end
end

