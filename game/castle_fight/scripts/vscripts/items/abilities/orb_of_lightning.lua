orb_of_lightning = class({})

function orb_of_lightning:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  local initial_damage = ability:GetSpecialValueFor("initial_damage")
  local max_targets = ability:GetSpecialValueFor("max_targets")
  local jump_damage_reduction = ability:GetSpecialValueFor("jump_damage_reduction")
  local jump_range = ability:GetSpecialValueFor("jump_range")
  local jump_delay = ability:GetSpecialValueFor("jump_delay")

  caster:EmitSound("Hero_Zuus.ArcLightning.Cast")

  local hit = {}
  hit[target] = true

  local lastBounce = caster
  local nextBounce = target
  local bounces = 1
  local damage = initial_damage

  Timers:CreateTimer(function()
    if not nextBounce or bounces >= max_targets then return end

    -- Apply the lightning
    nextBounce:EmitSound("Hero_Zuus.ArcLightning.Target")

    local particleName = "particles/units/heroes/hero_zuus/zuus_arc_lightning_.vpcf"
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, nextBounce)
    ParticleManager:SetParticleControlEnt(particle, 0, lastBounce, PATTACH_POINT_FOLLOW, "attach_hitloc", lastBounce:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, nextBounce, PATTACH_POINT_FOLLOW, "attach_hitloc", nextBounce:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(particle, 2, Vector(1, 1, 1))
    ParticleManager:ReleaseParticleIndex(particle)

    if not IsCustomBuilding(nextBounce) then
      ApplyDamage({
        attacker = caster, 
        victim = nextBounce,
        ability = ability,
        damage = damage, 
        damage_type = DAMAGE_TYPE_MAGICAL
      })
    end

    damage = damage - (damage * jump_damage_reduction)

    -- Find the next bounce target
    lastBounce = nextBounce
    nextBounce = nil

    local nearbyEnemies = FindEnemiesInRadius(caster, jump_range, lastBounce:GetAbsOrigin())
    for _,enemy in pairs(nearbyEnemies) do
      if not hit[enemy] and not enemy:IsMagicImmune() and not IsCustomBuilding(enemy) then
        nextBounce = enemy
      end
    end

    if nextBounce then
      hit[nextBounce] = true
    end

    bounces = bounces + 1

    return jump_delay
  end)
end

