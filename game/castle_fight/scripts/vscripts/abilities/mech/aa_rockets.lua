LinkLuaModifier("modifier_aa_rockets", "abilities/mech/aa_rockets.lua", LUA_MODIFIER_MOTION_NONE)

rocket_tank_aa_rockets = class({})

function rocket_tank_aa_rockets:GetIntrinsicModifierName()
  return "modifier_aa_rockets"
end

function rocket_tank_aa_rockets:OnProjectileHit(target, position)
  local damage = self:GetSpecialValueFor("damage")

  target:EmitSoundParams("Hero_Tinker.Heat-Seeking_Missile.Impact", 0, 0.25, 0)

  ApplyDamage({
    victim = target,
    damage = damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    attacker = self:GetCaster(),
    ability = self
  })
end

modifier_aa_rockets = class({})

function modifier_aa_rockets:IsHidden() return true end

function modifier_aa_rockets:OnCreated()
  self.radius = self:GetAbility():GetSpecialValueFor("radius")

  self:StartIntervalThink(1.5)
end

function modifier_aa_rockets:OnIntervalThink()
  if not IsServer() then return end
  if not self:GetParent():IsAlive() then return end

  local enemies = FindEnemiesInRadius(self:GetParent(), self.radius)

  local flyingEnemies = {}

  for _,enemy in pairs(enemies) do
    if enemy:HasFlyMovementCapability() then
      table.insert(flyingEnemies, enemy)
    end
  end

  if #flyingEnemies == 0 then return end

  local target = GetRandomTableElement(flyingEnemies)

  self:GetParent():EmitSound("Hero_Tinker.Heat-Seeking_Missile")

  local projectile =
  {
    Target = target,
    Source = self:GetParent(),
    Ability = self:GetAbility(),
    EffectName = "particles/units/heroes/hero_tinker/tinker_missile.vpcf",
    bDodgeable = true,
    bProvidesVision = false,
    iMoveSpeed = 900,
  }
  ProjectileManager:CreateTrackingProjectile(projectile)
end