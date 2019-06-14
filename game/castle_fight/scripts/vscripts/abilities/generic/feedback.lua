LinkLuaModifier("modifier_feedback_custom", "abilities/generic/feedback.lua", LUA_MODIFIER_MOTION_NONE)

murloc_feedback = class({})
function murloc_feedback:GetIntrinsicModifierName() return "modifier_feedback_custom" end
elunes_lantern_feedback = class({})
function elunes_lantern_feedback:GetIntrinsicModifierName() return "modifier_feedback_custom" end
faerie_dragon_feedback = class({})
function faerie_dragon_feedback:GetIntrinsicModifierName() return "modifier_feedback_custom" end
assassin_feedback = class({})
function assassin_feedback:GetIntrinsicModifierName() return "modifier_feedback_custom" end

modifier_feedback_custom = class({})

function modifier_feedback_custom:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.mana_burn = self.ability:GetSpecialValueFor("mana_burn")
  self.mana_to_damage = self.ability:GetSpecialValueFor("mana_to_damage")
end

function modifier_feedback_custom:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_feedback_custom:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster then
    -- do mana burn here
  end
end

