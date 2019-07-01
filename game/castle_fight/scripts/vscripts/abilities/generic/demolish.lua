LinkLuaModifier("modifier_demolish", "abilities/generic/demolish.lua", LUA_MODIFIER_MOTION_NONE)

flesh_golem_demolish = class({})
function flesh_golem_demolish:GetIntrinsicModifierName() return "modifier_demolish" end
tribal_blessing_demolish = class({})
function tribal_blessing_demolish:GetIntrinsicModifierName() return "modifier_demolish" end

modifier_demolish = class({})

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

  if attacker == self.caster and IsCustomBuilding(target) then
    local damage = keys.damage
    damage = damage * (self.damage_pct - 100) * 0.01

    ApplyDamage({
      victim = target,
      damage = damage,
      damage_type = DAMAGE_TYPE_PHYSICAL,
      damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
      attacker = self.caster,
      ability = self.ability
    })
  end
end

