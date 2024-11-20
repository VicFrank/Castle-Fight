fire_breath = class({})

LinkLuaModifier("modifier_fire_breath", "abilities/elemental/fire_breath.lua", LUA_MODIFIER_MOTION_NONE)

function fire_breath:GetIntrinsicModifierName() return "modifier_fire_breath" end

function fire_breath:OnProjectileHit(target, location)
  if target and not IsCustomBuilding(target) then
    local damage = self:GetSpecialValueFor("damage")

    ApplyDamage({
      victim = target,
      attacker = self:GetCaster(),
      damage = damage,
      damage_type = DAMAGE_TYPE_MAGICAL,
      ability = self,
    })
  end
end

-----------------------------

modifier_fire_breath = class({})

function modifier_fire_breath:IsHidden() return true end

function modifier_fire_breath:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.chance = self.ability:GetSpecialValueFor("chance")
  self.start_radius = self.ability:GetSpecialValueFor("start_radius")
  self.end_radius = self.ability:GetSpecialValueFor("end_radius")
  self.range = self.ability:GetSpecialValueFor("range")
  self.speed = self.ability:GetSpecialValueFor("speed")
end

function modifier_fire_breath:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_fire_breath:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.parent then
    if RollPercentage(self.chance) then
      -- breathe fire
      self.parent:EmitSound("Hero_DragonKnight.BreathFire")

      local particleName = "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf"

      local direction = ((target:GetAbsOrigin() - attacker:GetAbsOrigin()) * Vector(1, 1, 0)):Normalized()

      ProjectileManager:CreateLinearProjectile({
        Source = attacker,
        Ability = self.ability,
        vSpawnOrigin = self.parent:GetAbsOrigin(),    
        bDeleteOnHit = false,        
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType = DOTA_UNIT_TARGET_BASIC,        
        EffectName = particleName,
        fDistance = self.range,
        fStartRadius = self.start_radius,
        fEndRadius = self.end_radius,
        vVelocity = direction * self.speed,
      })
    end
  end
end
