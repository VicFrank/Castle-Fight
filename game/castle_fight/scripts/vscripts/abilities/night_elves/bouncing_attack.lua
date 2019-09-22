LinkLuaModifier("modifier_glaive_thrower_bouncing_attack", "abilities/night_elves/bouncing_attack.lua", LUA_MODIFIER_MOTION_NONE)

glaive_thrower_bouncing_attack = class({})
function glaive_thrower_bouncing_attack:GetIntrinsicModifierName() return "modifier_glaive_thrower_bouncing_attack" end

function glaive_thrower_bouncing_attack:BounceAttack(target, source, extraData)
  local caster = self:GetCaster()
  local hSource = source or caster

  extraData[tostring(target:GetEntityIndex())] = 1

  local projectile = {
    Target = target,
    Source = hSource,
    Ability = self, 
    EffectName = caster:GetRangedProjectileName(),
    iMoveSpeed = caster:GetProjectileSpeed(),
    vSourceLoc= hSource:GetAbsOrigin(),
    bDrawsOnMinimap = false,
    bDodgeable = false,
    bIsAttack = true,
    bVisibleToEnemies = true,
    bReplaceExisting = false,
    -- flExpireTime = internalData.duration,
    bProvidesVision = false,
    iVisionTeamNumber = caster:GetTeamNumber(),
    iSourceAttachment =  0,
    ExtraData = extraData
  }

  ProjectileManager:CreateTrackingProjectile(projectile)
end

function glaive_thrower_bouncing_attack:OnProjectileHit_ExtraData(target, position, extraData)
  if not IsServer() then return end

  if target then
    local caster = self:GetCaster()
    local ability = self
    
    local damage = tonumber(extraData.damage)
    local bounces = tonumber(extraData.bounces) or 0
    local targets = extraData.targets

    local damageTable = {
      victim = target,
      damage = damage,
      damage_type = DAMAGE_TYPE_PHYSICAL,
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
      attacker = caster,
      ability = ability
    }

    ApplyDamage(damageTable)
    
    if bounces > 0 then
      local radius = ability:GetSpecialValueFor("range")
      local damage_reduction_percent = ability:GetSpecialValueFor("damage_reduction_percent")

      local reduction = (100 - damage_reduction_percent) / 100
      local enemies = FindEnemiesInRadius(caster, radius, target:GetAbsOrigin())

      for _,enemy in pairs(enemies) do
        if not extraData[tostring(target:GetEntityIndex())] then
          local extraData = {
            damage =  damage * reduction,
            bounces = bounces - 1
          }

          self:BounceAttack(enemy, target, extraData)
          break
        end
      end
    end
  end
end


modifier_glaive_thrower_bouncing_attack = class({})

function modifier_glaive_thrower_bouncing_attack:IsHidden()
  return true
end

function modifier_glaive_thrower_bouncing_attack:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.range = self.ability:GetSpecialValueFor("range")
  self.bounces = self.ability:GetSpecialValueFor("bounces")
  self.range = self.ability:GetSpecialValueFor("range")
  self.damage_reduction_percent = self.ability:GetSpecialValueFor("damage_reduction_percent")
end

function modifier_glaive_thrower_bouncing_attack:DeclareFunctions()
  return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_glaive_thrower_bouncing_attack:OnTakeDamage(params)
  local attacker = params.attacker
  local target = params.unit

  if attacker == self.parent and 
    params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK and 
    self.parent:GetHealth() > 0 and 
    not params.inflictor then

    local enemies = FindEnemiesInRadius(self.parent, self.range, target:GetAbsOrigin())
    for _, enemy in ipairs(enemies) do
      if enemy ~= target then
        local extraData = {
          damage =  params.damage,
          bounces = self.bounces - 1
        }

        extraData[tostring(target:GetEntityIndex())] = 1

        self.ability:BounceAttack(enemy, target, extraData)
        break
      end
    end
  end
end