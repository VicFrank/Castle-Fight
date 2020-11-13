frost_bolt = class({})
greater_frost_bolt = class({})

LinkLuaModifier("modifier_frost_bolt_freeze", "abilities/north/frost_bolt.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_frost_bolt_freeze_fx", "abilities/north/frost_bolt.lua", LUA_MODIFIER_MOTION_NONE)

function frost_bolt:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local team = caster:GetTeamNumber()
  local position = point or caster:GetAbsOrigin()
  local num_targets = ability:GetSpecialValueFor("targets")

  local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
  local enemies =  FindUnitsInRadius(team, position, nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_ANY_ORDER, false)

  local enemyBuildings = {}

  for _,enemy in pairs(enemies) do
    if IsCustomBuilding(enemy) then
      table.insert(enemyBuildings, enemy)
    end
  end

  local targets = GetRandomTableElements(enemyBuildings, num_targets)

  caster:EmitSound("Hero_Crystal.CrystalNovaCast")

  local particleName = "particles/units/heroes/hero_crystalmaiden/maiden_base_attack.vpcf"

  for _,target in pairs(targets) do
    local projectile = {
      Target = target,
      Source = caster,
      Ability = ability,
      EffectName = particleName,
      iMoveSpeed = 2000,
      bDodgeable = false,
      bVisibleToEnemies = true,
      bReplaceExisting = false,
    }
  
    ProjectileManager:CreateTrackingProjectile(projectile)
  end
end

function frost_bolt:OnProjectileHit(target, locationn)
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("duration")

  if target then
    target:EmitSound("hero_Crystal.projectileImpact")
    target:AddNewModifier(caster, self, "modifier_frost_bolt_freeze", {duration = duration})
    FreezeCooldowns(target, duration)

    local damage = self:GetSpecialValueFor("damage")

    ApplyDamage({
      victim = target,
      attacker = caster,
      damage = damage,
      damage_type = DAMAGE_TYPE_PURE,
      ability = self,
    })
  end
end

----------------------------------------------------------------------------------------------------

function greater_frost_bolt:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local team = caster:GetTeamNumber()
  local position = point or caster:GetAbsOrigin()
  local num_targets = ability:GetSpecialValueFor("targets")

  local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
  local enemies = FindUnitsInRadius(team, position, nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_ANY_ORDER, false)

  local enemyBuildings = {}

  for _,enemy in pairs(enemies) do
    if IsCustomBuilding(enemy) then
      table.insert(enemyBuildings, enemy)
    end
  end

  local targets = GetRandomTableElements(enemyBuildings, num_targets)

  caster:EmitSound("Hero_Crystal.CrystalNova")

  local particleName = "particles/units/heroes/hero_winter_wyvern/winter_wyvern_arctic_attack.vpcf"

  for _,target in pairs(targets) do
    local projectile = {
      Target = target,
      Source = caster,
      Ability = ability,
      EffectName = particleName,
      iMoveSpeed = 2000,
      bDodgeable = false,
      bVisibleToEnemies = true,
      bReplaceExisting = false,
    }
  
    ProjectileManager:CreateTrackingProjectile(projectile)
  end
end

function greater_frost_bolt:OnProjectileHit(target, location)
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("duration")

  if target then
      target:EmitSound("hero_Crystal.projectileImpact")
      target:AddNewModifier(caster, self, "modifier_frost_bolt_freeze", {duration = duration})
      FreezeCooldowns(target, duration)

      local damage = self:GetSpecialValueFor("damage")

      ApplyDamage({
      victim = target,
      attacker = caster,
      damage = damage,
      damage_type = DAMAGE_TYPE_PURE,
      ability = self,
      })
  end
end

function FreezeCooldowns(unit, duration)
  local abilityList = {}

  for i = 0, 23 do
    local ability = unit:GetAbilityByIndex(i)
    if ability and not ability:IsCooldownReady() then
      local abilityInfo = {
        ability = ability,
        cooldown = ability:GetCooldownTimeRemaining()
      }
      table.insert(abilityList, abilityInfo)

      if startsWith(ability:GetAbilityName(), "train_") and unit.progressParticle then
      -- Recreate the progress particle
        ParticleManager:DestroyParticle(unit.progressParticle, true)
        ParticleManager:ReleaseParticleIndex(unit.progressParticle)
      end
    end
  end

  Timers:CreateTimer(function()
    if duration <= 0 then
      for _,abilityInfo in pairs(abilityList) do
        local ability = abilityInfo.ability
        local cooldown = abilityInfo.cooldown

        if startsWith(ability:GetAbilityName(), "train_") and not unit.progressParticle then
          -- Recreate the progress particle
          unit.progressParticle = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, unit)
          ParticleManager:SetParticleControl(unit.progressParticle, 1, Vector(50, 1 / cooldown, 1))
        end
      end
      return
    end

    for _,abilityInfo in pairs(abilityList) do
      local ability = abilityInfo.ability
      local cooldown = abilityInfo.cooldown

      ability:StartCooldown(cooldown)
    end

    duration = duration - .1

    return .1
  end)
end

----------------------------------------------------------------------------------------------------

modifier_frost_bolt_freeze = class({})

function modifier_frost_bolt_freeze:IsDebuff()
  return true
end

function modifier_frost_bolt_freeze:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true,
    [MODIFIER_STATE_DISARMED] = true,
  }
end

function modifier_frost_bolt_freeze:OnCreated( kv )
  if IsServer() then
    local parent = self:GetParent()
    self.mana_modifier = self:GetAbility():GetSpecialValueFor("mana_regen")
    parent:EmitSound("Hero_Crystal.Frostbite")
    local particleNameA = "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf"
    local particleNameB = "particles/generic_gameplay/generic_slowed_cold.vpcf"
    self.particleA = ParticleManager:CreateParticle(particleNameA, PATTACH_ABSORIGIN_FOLLOW, parent)
    self.particleB = ParticleManager:CreateParticle(particleNameB, PATTACH_POINT_FOLLOW, parent)
    parent:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_frost_bolt_freeze_fx", {duration = self:GetDuration()})
  end
end

function modifier_frost_bolt_freeze:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE
  }
  return funcs
end

function modifier_frost_bolt_freeze:GetModifierProvidesFOWVision()
  return 1
end

function modifier_frost_bolt_freeze:GetModifierTotalPercentageManaRegen()
  return self.mana_modifier
end

function modifier_frost_bolt_freeze:OnDestroy()
  if IsServer() then
    self:GetParent():RemoveModifierByName("modifier_frost_bolt_freeze_fx")
    ParticleManager:DestroyParticle(self.particleA, false)
    ParticleManager:DestroyParticle(self.particleB, false)
    ParticleManager:ReleaseParticleIndex(self.particleA)
    ParticleManager:ReleaseParticleIndex(self.particleB)
  end
end

----------------------------------------------------------------------------------------------------

modifier_frost_bolt_freeze_fx = class ({})

function modifier_frost_bolt_freeze_fx:DeclareFunctions()
  return {}
end

function modifier_frost_bolt_freeze_fx:GetStatusEffectName()
  return "particles/status_fx/status_effect_frost.vpcf"
end

function modifier_frost_bolt_freeze_fx:StatusEffectPriority()
  return FX_PRIORITY_CHILLED
end

function modifier_frost_bolt_freeze_fx:IsHidden()
  return true
end

function modifier_frost_bolt_freeze_fx:IsDebuff()
  return false
end

function modifier_frost_bolt_freeze_fx:IsPurgable()
  return false
end