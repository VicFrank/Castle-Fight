wizard_firebolt = class({})
LinkLuaModifier("modifier_wizard_firebolt", "abilities/elf/firebolt.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wizard_firebolt_debuff", "abilities/elf/firebolt.lua", LUA_MODIFIER_MOTION_NONE)

function wizard_firebolt:GetIntrinsicModifierName()
  return "modifier_wizard_firebolt"
end

function wizard_firebolt:OnProjectileHit(target, location)
  local damage = self:GetSpecialValueFor("damage")
  local duration = self:GetSpecialValueFor("duration")

  ApplyDamage({
    attacker = self:GetCaster(), 
    victim = target,
    ability = self,
    damage = damage, 
    damage_type = DAMAGE_TYPE_MAGICAL
  })

  target:AddNewModifier(self:GetCaster(), self, "modifier_wizard_firebolt_debuff", {duration = duration})
end

modifier_wizard_firebolt = class({})

function modifier_wizard_firebolt:IsHidden() return true end

function modifier_wizard_firebolt:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.fire_interval = self.ability:GetSpecialValueFor("fire_interval")
  self.radius = self.ability:GetSpecialValueFor("radius")

  self:StartIntervalThink(self.fire_interval)
end

function modifier_wizard_firebolt:OnIntervalThink()
  if not IsServer() then return end
  -- if there's an enemy in range, fire a projectile
  local enemies = FindEnemiesInRadius(self.caster, self.radius)

  if #enemies == 0 then return end

  local enemy = GetRandomTableElement(enemies)

  local particleName = "particles/units/heroes/hero_lina/lina_base_attack.vpcf"

  local projectile = {
    Target = enemy,
    Source = self.caster,
    Ability = self.ability,
    EffectName = particleName,
    iMoveSpeed = 900,
    bDodgeable = false,
    bVisibleToEnemies = true,
    bReplaceExisting = false,
  }

  ProjectileManager:CreateTrackingProjectile(projectile)

  self.ability:StartCooldown(self.fire_interval)
end

modifier_wizard_firebolt_debuff = class({})

function modifier_wizard_firebolt_debuff:IsDebuff() return true end
function modifier_wizard_firebolt_debuff:IsPurgable() return true end

function modifier_wizard_firebolt_debuff:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.fire_interval = self.ability:GetSpecialValueFor("fire_interval")
  self.damage = self.ability:GetSpecialValueFor("damage")
  self.dps = self.ability:GetSpecialValueFor("dps")
  self.duration = self.ability:GetSpecialValueFor("duration")
  self.radius = self.ability:GetSpecialValueFor("radius")

  self:StartIntervalThink(1)
end

function modifier_wizard_firebolt_debuff:OnIntervalThink()
  if not IsServer() then return end

  ApplyDamage({
    attacker = self:GetCaster(), 
    victim = self:GetParent(),
    ability = self:GetAbility(),
    damage = self.dps, 
    damage_type = DAMAGE_TYPE_MAGICAL
  })
end

function modifier_wizard_firebolt_debuff:GetEffectName()
  return "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite_debuff.vpcf"
end

function modifier_wizard_firebolt_debuff:GetStatusEffectName()
  return "particles/status_fx/status_effect_burn.vpcf"
end