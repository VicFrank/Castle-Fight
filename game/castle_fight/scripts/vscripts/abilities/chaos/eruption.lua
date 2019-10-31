volcano_eruption = class({})

function volcano_eruption:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local filter = function(target) return not target:HasFlyMovementCapability() end
  local target = GetRandomVisibleEnemyWithFilter(caster:GetTeam(), filter)

  if not target then return end

  local position = target:GetAbsOrigin()

  local tick_rate = 1.0
  local dps = ability:GetSpecialValueFor("dps")
  local max_duration = ability:GetSpecialValueFor("duration")
  local max_targets = ability:GetSpecialValueFor("max_targets")
  local radius = ability:GetSpecialValueFor("radius")

  local duration = 0

  local particleName = "particles/econ/items/earthshaker/egteam_set/hero_earthshaker_egset/earthshaker_echoslam_start_egset.vpcf"
  local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(particle, 0, position)
  ParticleManager:ReleaseParticleIndex(particle)
  EmitSoundOnLocationWithCaster(position,"Hero_EarthShaker.EchoSlamSmall",caster)

  Timers:CreateTimer(function()
    local enemies = FindEnemiesInRadius(caster, radius, position)

    particleName = "particles/econ/items/earthshaker/egteam_set/hero_earthshaker_egset/earthshaker_echoslam_start_egset.vpcf"
    particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(particle, 0, position)
    ParticleManager:ReleaseParticleIndex(particle)
    EmitSoundOnLocationWithCaster(position,"Hero_EarthShaker.EchoSlamSmall",caster)

    -- Only damage the first 6 enemies
    local numHit = 0
    for _,enemy in pairs(enemies) do
      if not enemy:IsRealHero() and not enemy:HasFlyMovementCapability() then
        local damage = dps * tick_rate
        if IsCustomBuilding(enemy) then
          damage = damage * 0.4
        end

        ApplyDamage({
          victim = enemy,
          damage = damage,
          damage_type = DAMAGE_TYPE_MAGICAL,
          attacker = caster,
          ability = ability
        })

        numHit = numHit + 1
        if numHit >= max_targets then
          break
        end
      end
    end

    duration = duration + tick_rate
    if duration >= max_duration then return end

    return tick_rate
  end)
end