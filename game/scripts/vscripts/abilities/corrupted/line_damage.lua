LinkLuaModifier("modifier_infernal_line_damage", "abilities/corrupted/line_damage.lua", LUA_MODIFIER_MOTION_NONE)

infernal_line_damage = class({})
function infernal_line_damage:GetIntrinsicModifierName() return "modifier_infernal_line_damage" end

function infernal_line_damage:OnProjectileHit_ExtraData(target, location, extraData)
  if not target then return end
  if IsCustomBuilding(target) or target:HasFlyMovementCapability() then return end

  local damage = self:GetSpecialValueFor("damage")
  local attackTarget = extraData.attackTarget

  if target:GetEntityIndex() == attackTarget then return end

  ApplyDamage({
    victim = target,
    damage = damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    attacker = self:GetCaster(),
    ability = self
  })
end

modifier_infernal_line_damage = class({})

function modifier_infernal_line_damage:IsHidden() return true end

function modifier_infernal_line_damage:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.damage = self.ability:GetSpecialValueFor("damage")
  self.radius = self.ability:GetSpecialValueFor("radius")
end

function modifier_infernal_line_damage:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_START,
  }
  return funcs
end

function modifier_infernal_line_damage:OnAttackStart(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.parent then
    -- Fire Projectile
    local particle = "particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale.vpcf"
    local speed = self.parent:GetProjectileSpeed()

    local direction = ((target:GetAbsOrigin() - attacker:GetAbsOrigin()) * Vector(1, 1, 0)):Normalized()
    local velocity = direction * speed

    local projectile = {
      Ability = self:GetAbility(),
      EffectName = particle,
      vSpawnOrigin = attacker:GetAbsOrigin(),
      fDistance = self.parent:Script_GetAttackRange(),
      fStartRadius = self.radius,
      fEndRadius = self.radius,
      Source = attacker,
      bHasFrontalCone = false,
      bReplaceExisting = false,
      iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
      iUnitTargetType = DOTA_UNIT_TARGET_ALL,
      bDeleteOnHit = false,
      vVelocity = velocity,
      bProvidesVision = false,
      ExtraData = {
        attackTarget = target:GetEntityIndex()
      },
    }

    ProjectileManager:CreateLinearProjectile(projectile)
  end
end