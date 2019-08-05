LinkLuaModifier("modifier_shredder_attack", "abilities/mech/shredder_attack.lua", LUA_MODIFIER_MOTION_NONE)

goblin_shredder_attack = class({})
function goblin_shredder_attack:GetIntrinsicModifierName() return "modifier_shredder_attack" end

modifier_shredder_attack = class({})

function modifier_shredder_attack:IsHidden() return true end

function modifier_shredder_attack:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.radius = self.ability:GetSpecialValueFor("radius")
end

function modifier_shredder_attack:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_shredder_attack:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster then
    local damage = keys.damage
    local center = attacker:GetAbsOrigin() + (attacker:GetForwardVector() * (self.radius / 2))

    local enemies = FindEnemiesInRadius(attacker, self.radius, center)

    for _,enemy in pairs(enemies) do
      if enemy ~= target and not enemy:HasFlyMovementCapability() then
        ApplyDamage({
          victim = enemy,
          damage = damage,
          damage_type = DAMAGE_TYPE_PHYSICAL,
          attacker = attacker,
          ability = self.ability
        })
      end
    end
  end
end

