fan_of_spikes = class({})

function fan_of_spikes:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorPosition()

  caster:EmitSound("Hero_NyxAssassin.Impale")

  local speed = ability:GetSpecialValueFor("speed")

  local particleName = "particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale.vpcf"

  local projectile = {
    Ability = self,
    EffectName = particleName,
    vSpawnOrigin = caster:GetAbsOrigin(),
    fDistance = self:GetSpecialValueFor("length"),
    fStartRadius = 125,
    fEndRadius = 400,
    Source = caster,
    bHasFrontalCone = false,
    bReplaceExisting = false,
    iUnitTargetTeam = self:GetAbilityTargetTeam(),              
    iUnitTargetType = self:GetAbilityTargetType(),              
    bDeleteOnHit = false,
    vVelocity = (((target - caster:GetAbsOrigin()) * Vector(1, 1, 0)):Normalized()) * speed,
    bProvidesVision = false,              
  }

  ProjectileManager:CreateLinearProjectile(projectile)
end

function fan_of_spikes:OnProjectileHit(target, location)
  if not IsServer() then return end
  if not target then return end
  if IsCustomBuilding(target) or target:IsRealHero() or target:HasFlyMovementCapability() then return end

  local caster = self:GetCaster()
  local ability = self

  local duration = ability:GetSpecialValueFor("duration")
  local damage = ability:GetSpecialValueFor("damage")

  target:AddNewModifier(caster, ability, "modifier_stunned", {duration = duration})
  ApplyDamage({
    victim = target,
    damage = damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    attacker = caster,
    ability = ability
  })
end