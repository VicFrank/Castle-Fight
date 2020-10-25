necromancer_carrion_swarm = class({})
LinkLuaModifier("modifier_carrion_swarm", "abilities/undead/carrion_swarm.lua", LUA_MODIFIER_MOTION_NONE)

function necromancer_carrion_swarm:GetIntrinsicModifierName()
  return "modifier_carrion_swarm"
end

function necromancer_carrion_swarm:OnProjectileHit(target, position)
  if target then
    local caster = self:GetCaster()

    local damage = self:GetSpecialValueFor("damage")

    if IsCustomBuilding(target) then return end

    ApplyDamage({
      victim = target,
      damage = damage,
      damage_type = DAMAGE_TYPE_MAGICAL,
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
      attacker = caster,
      ability = self
    })

    target:EmitSound("Hero_DeathProphet.CarrionSwarm.Damage")
  end
end

modifier_carrion_swarm = class({})

function modifier_carrion_swarm:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.chance = self.ability:GetSpecialValueFor("chance")
  self.start_radius = self.ability:GetSpecialValueFor("start_radius")
  self.end_radius = self.ability:GetSpecialValueFor("end_radius")
  self.range = self.ability:GetSpecialValueFor("range")
  self.speed = self.ability:GetSpecialValueFor("speed")
end

function modifier_carrion_swarm:OnRefresh()
  self.chance = self.ability:GetSpecialValueFor("chance")
  self.start_radius = self.ability:GetSpecialValueFor("start_radius")
  self.end_radius = self.ability:GetSpecialValueFor("end_radius")
  self.range = self.ability:GetSpecialValueFor("range")
  self.speed = self.ability:GetSpecialValueFor("speed")
end

function modifier_carrion_swarm:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_carrion_swarm:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster then
    if self.chance >= RandomInt(1, 100) then
      -- Release carrion swarm
      local direction = (target:GetAbsOrigin() - self.caster:GetAbsOrigin()):Normalized()

      ProjectileManager:CreateLinearProjectile({
        Ability = self.ability,
        EffectName = "particles/econ/items/death_prophet/death_prophet_acherontia/death_prophet_acher_swarm.vpcf",
        vSpawnOrigin = self.caster:GetAbsOrigin(),
        fDistance = self.range,
        fStartRadius = self.start_radius,
        fEndRadius = self.end_radius,
        Source = self.caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        bDeleteOnHit = false,
        vVelocity = self.speed * direction,
        bProvidesVision = false,
      })

      self.caster:EmitSound("Hero_DeathProphet.CarrionSwarm")
    end
  end
end