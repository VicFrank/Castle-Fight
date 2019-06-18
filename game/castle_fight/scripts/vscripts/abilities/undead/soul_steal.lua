turret_of_souls_soul_steal = class({})
LinkLuaModifier("modifier_soul_steal", "abilities/undead/soul_steal.lua", LUA_MODIFIER_MOTION_NONE)

function turret_of_souls_soul_steal:GetIntrinsicModifierName()
  return "modifier_soul_steal"
end

modifier_soul_steal = class({})

function modifier_soul_steal:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.chance = self.ability:GetSpecialValueFor("chance")
end

function modifier_soul_steal:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_soul_steal:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster then
    if self.chance >= RandomInt(1,100) then
      -- Instantly kill the target
      target:Kill(self.ability, self.parent)
    end
  end
end