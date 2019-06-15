LinkLuaModifier("modifier_winged_serpent_bouncing_attack", "abilities/naga/bouncing_attack.lua", LUA_MODIFIER_MOTION_NONE)

winged_serpent_bouncing_attack = class({})
function winged_serpent_bouncing_attack:GetIntrinsicModifierName() return "modifier_winged_serpent_bouncing_attack" end

function winged_serpent_bouncing_attack:BounceAttack(target, damage, bounces, source)
  local caster = self:GetCaster()
  local hSource = source or caster
  local extraData = {damage = damage, bounces = bounces}
  self:FireTrackingProjectile(
    caster:GetRangedProjectileName(),
    target,
    caster:GetProjectileSpeed(),
    {extraData = extraData, source = hSource, origin = hSource:GetAbsOrigin()})
end

function winged_serpent_bouncing_attack:OnProjectileHit_ExtraData(target, position, extraData)
  if not IsServer() then return end

  if target then
    local caster = self:GetCaster()
    
    local damage = tonumber(extraData.damage)
    local bounces = tonumber(extraData.bounces) or 0

    local damageTable = {
      victim = target,
      damage = damage,
      damage_type = DAMAGE_TYPE_PHYSICAL,
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
      attacker = caster,
      ability = self
    }

    ApplyDamage(damageTable)
    
    if bounces > 0 then
      local radius = self.range
      local reduction = (100 - self.damage_reduction_percent) / 100
      local enemies = FindEnemiesInRadius(caster, radius, target:GetAbsOrigin())

      for _,enemy in pairs(enemies) do
        if enemy ~= target then
          self:BounceAttack(enemy, damage * reduction, bounces - 1, target)
          break
        end
      end
    end
  end
end


modifier_winged_serpent_bouncing_attack = class({})

function modifier_winged_serpent_bouncing_attack:OnCreated()
  self.range = self.ability:GetSpecialValueFor("range")
  self.bounces = self.ability:GetSpecialValueFor("bounces")
  self.damage_reduction_percent = self.ability:GetSpecialValueFor("damage_reduction_percent")
end

function modifier_winged_serpent_bouncing_attack:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_winged_serpent_bouncing_attack:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster then
    local enemy = FindEnemyUnitsInRadius()
    local damage = attacker:GetAttackDamage()
    self:GetAbility():BounceAttack(enemy, damage, self.bounces, target)
  end
end