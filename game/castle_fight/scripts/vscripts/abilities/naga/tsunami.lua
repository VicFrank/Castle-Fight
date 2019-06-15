tsunami = class({})

function tsunami:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local particleName = "particles/units/heroes/hero_tidehunter/tidehunter_gush_upgrade.vpcf"

  local speed = ability:GetSpecialValueFor("speed")
  local aoe = ability:GetSpecialValueFor("aoe")

  local target = GetRandomVisibleEnemy(caster:GetTeam())
  if not target then return end

  caster:EmitSound("Ability.GushCast")

  local direction = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
  -- local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()

  local linear_projectile = {
    Ability = ability,
    EffectName = "particles/units/heroes/hero_tidehunter/tidehunter_gush_upgrade.vpcf", -- Might not do anything
    vSpawnOrigin = caster:GetAbsOrigin(),
    fDistance = 9999,
    fStartRadius = aoe,
    fEndRadius = aoe,
    Source = caster,
    bHasFrontalCone = false,
    bReplaceExisting = false,
    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
    iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    fExpireTime = GameRules:GetGameTime() + 10.0,
    bDeleteOnHit = false,
    vVelocity = speed,
    bProvidesVision = false,
  }
    
  self.projectile = ProjectileManager:CreateLinearProjectile(linear_projectile)
end

function tsunami:OnProjectileHit(target, location)
  if not IsServer() then return end

  local damage = self:GetSpecialValueFor("damage")

  target:EmitSound("Ability.GushImpact")

  local damageTable = {
    victim = target,
    damage = damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    damage_flags = DOTA_DAMAGE_FLAG_NONE,
    attacker = self:GetCaster(),
    ability = self
  }

  ApplyDamage(damageTable)
end