frost_bolt = class({})
greater_frost_bolt = class({})

LinkLuaModifier("modifier_frost_bolt_freeze", "abilities/north/frost_bolt.lua", LUA_MODIFIER_MOTION_NONE)

function frost_bolt:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local team = caster:GetTeamNumber()
  local position = point or caster:GetAbsOrigin()
  local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
  local enemies =  FindUnitsInRadius(team, position, nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_ANY_ORDER, false)

  local enemyBuildings = {}

  for _,enemy in pairs(enemies) do
    if IsCustomBuilding(enemy) then
      table.insert(enemyBuildings, enemy)
    end
  end

  local target = GetRandomTableElement(enemyBuildings)

  caster:EmitSound("Hero_Crystal.CrystalNovaCast")

  local particleName = "particles/units/heroes/hero_crystalmaiden/maiden_base_attack.vpcf"

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

function greater_frost_bolt:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local team = caster:GetTeamNumber()
  local position = point or caster:GetAbsOrigin()
  local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
  local enemies = FindUnitsInRadius(team, position, nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_ANY_ORDER, false)

  local enemyBuildings = {}

  for _,enemy in pairs(enemies) do
    if IsCustomBuilding(enemy) then
      table.insert(enemyBuildings, enemy)
    end
  end

  local target = GetRandomTableElement(enemyBuildings)

  caster:EmitSound("Hero_Crystal.CrystalNova")

  local particleName = "particles/units/heroes/hero_winter_wyvern/winter_wyvern_arctic_attack.vpcf"

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

function greater_frost_bolt:OnProjectileHit(target, locationn)
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("duration")

  if target then
    target:EmitSound("hero_Crystal.projectileImpact")

    local damage = self:GetSpecialValueFor("damage")
    local radius = self:GetSpecialValueFor("radius")

    local enemies = FindEnemiesInRadius(caster, radius, target:GetAbsOrigin())

    for _,enemy in pairs(enemies) do
      enemy:AddNewModifier(caster, self, "modifier_frost_bolt_freeze", {duration = duration})
      FreezeCooldowns(enemy, duration)

      ApplyDamage({
        victim = enemy,
        attacker = caster,
        damage = damage,
        damage_type = DAMAGE_TYPE_PURE,
        ability = self,
      })
    end
  end
end

function FreezeCooldowns(unit, duration)
  for i = 0, 23 do
    local ability = unit:GetAbilityByIndex(i)
    if ability and not ability:IsCooldownReady() then
      ability:StartCooldown(ability:GetCooldownTimeRemaining() + duration)

      if startsWith(ability:GetAbilityName(), "train_") and unit.progressParticle then
      -- Recreate the progress particle
        ParticleManager:DestroyParticle(unit.progressParticle, true)
        ParticleManager:ReleaseParticleIndex(unit.progressParticle)

        unit.progressParticle = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, unit)
        ParticleManager:SetParticleControl(unit.progressParticle, 1, Vector(50, 1 / ability:GetCooldown(ability:GetLevel()), 1))
      end
    end
  end
end

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
    --Play sound
    self:GetParent():EmitSound("Hero_Crystal.Frostbite")
  end
end

function modifier_frost_bolt_freeze:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
  }
  return funcs
end

function modifier_frost_bolt_freeze:GetModifierProvidesFOWVision()
  return 1
end

function modifier_frost_bolt_freeze:GetEffectName() return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf" end
function modifier_frost_bolt_freeze:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end