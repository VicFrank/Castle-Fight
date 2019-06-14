LinkLuaModifier("modifier_demolish", "abilities/generic/demloish.lua", LUA_MODIFIER_MOTION_NONE)

flesh_golem_demolish = class({})
function flesh_golem_demolish:GetIntrinsicModifierName() return "modifier_pulverize" end

modifier_pulverize = class({})

function modifier_demolish:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.damage_pct = self.ability:GetSpecialValueFor("damage_pct")
end

function modifier_demolish:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_demolish:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster then
    -- do mana burn here
  end
end

