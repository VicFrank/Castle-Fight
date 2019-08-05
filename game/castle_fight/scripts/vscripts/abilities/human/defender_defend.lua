defender_defend = class({})
LinkLuaModifier("modifier_defender_defend", "abilities/human/defender_defend.lua", LUA_MODIFIER_MOTION_NONE)

function defender_defend:GetIntrinsicModifierName()
  return "modifier_defender_defend"
end

function defender_defend:OnProjectileHit_ExtraData(target, position, extraData)
  if not IsServer() then return end

  if target then
    local parent = self:GetCaster()
    local ability = self
    
    local damage = tonumber(extraData.damage)


    ApplyDamage({
      victim = target,
      damage = damage,
      damage_type = DAMAGE_TYPE_PHYSICAL,
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
      attacker = parent,
      ability = ability
    })
  end
end

modifier_defender_defend = class({})

function modifier_defender_defend:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.ranged_repel_chance = self.ability:GetSpecialValueFor("ranged_repel_chance")
  self.ranged_damage_reduction = self.ability:GetSpecialValueFor("ranged_damage_reduction")
  self.spell_damage_reduction = self.ability:GetSpecialValueFor("spell_damage_reduction")
end

function modifier_defender_defend:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_defender_defend:OnAttackLanded(keys)
  if not IsServer() then return end

  local parent = keys.target
  local attacker = keys.attacker
  local damage = keys.damage
  local originalDamage = keys.original_damage
  local rangedAttack = keys.ranged_attack

  local sound = "Hero_Mars.Shield.Block"
  local soundSmall = "Hero_Mars.Shield.BlockSmall"
  local particleName = "particles/units/heroes/hero_mars/mars_shield_of_mars.vpcf"
  local particleNameSmall = "particles/units/heroes/hero_mars/mars_shield_of_mars_small.vpcf"

  if parent == self:GetParent() and attacker:IsAlive() and rangedAttack and attacker:HasModifier("modifier_attack_pierce") then
    local multiplier = attacker:GetAttackFactorAgainstTarget(parent)
    local armor = parent:GetPhysicalArmorValue(false)
    local wc3Reduction = (armor * 0.06) / (1 + (armor * 0.06))

    local actualDamage = (damage * (1 - wc3Reduction)) * multiplier
    -- if it was a ranged attack, chance to repel it completely
    if self.ranged_repel_chance >= RandomInt(1,100) then
      local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, self.parent)
      ParticleManager:ReleaseParticleIndex(particle)

      self.parent:EmitSound(soundSmall)

      -- Reflect the attack back
      self.parent:Heal(actualDamage, self.parent)

      local projectile = {
        Target = attacker,
        Source = parent,
        Ability = self:GetAbility(), 
        EffectName = attacker:GetRangedProjectileName(),
        iMoveSpeed = attacker:GetProjectileSpeed(),
        vSourceLoc= parent:GetAbsOrigin(),
        bDrawsOnMinimap = false,
        bDodgeable = false,
        bIsAttack = true,
        bVisibleToEnemies = true,
        bReplaceExisting = false,
        bProvidesVision = false,
        iVisionTeamNumber = parent:GetTeamNumber(),
        iSourceAttachment = 0,
        ExtraData = {
          damage = originalDamage
        }
      }

      ProjectileManager:CreateTrackingProjectile(projectile)
    else
      local particle = ParticleManager:CreateParticle(particleNameSmall, PATTACH_ABSORIGIN_FOLLOW, self.parent)
      ParticleManager:ReleaseParticleIndex(particle)

      self.parent:EmitSound(soundSmall)

      self.parent:Heal(actualDamage * self.ranged_damage_reduction * 0.01, self.parent)
    end
  end
end

function modifier_defender_defend:GetModifierMagicalResistanceBonus()
  return self.spell_damage_reduction
end