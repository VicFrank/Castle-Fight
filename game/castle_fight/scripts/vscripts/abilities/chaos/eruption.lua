volcano_eruption = class({})

function volcano_eruption:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local target = GetRandomVisibleEnemy(caster:GetTeam())
  if not target then return end

  local position = target:GetAbsOrigin()

  local tick_rate = 1.0
  local dps = ability:GetSpecialValueFor("dps")
  local max_duration = ability:GetSpecialValueFor("duration")
  local max_targets = ability:GetSpecialValueFor("max_targets")
  local radius = ability:GetSpecialValueFor("radius")

  local duration = 0

  local particleName = "particles/econ/items/sand_king/sandking_barren_crown/sandking_rubyspire_burrowstrike_eruption.vpcf"
  local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(particle, 0, position)
  ParticleManager:SetParticleControl(particle, 1, position)
  ParticleManager:ReleaseParticleIndex(particle)

  Timers:CreateTimer(function()
    local enemies = FindEnemiesInRadius(caster, radius, position)

    particleName = "particles/econ/items/sand_king/sandking_barren_crown/sandking_rubyspire_burrowstrike_eruption.vpcf"
    particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(particle, 0, position)
    ParticleManager:SetParticleControl(particle, 1, position)
    ParticleManager:ReleaseParticleIndex(particle)

    -- Only damage the first 6 enemies
    local numHit = 0
    for _,enemy in pairs(enemies) do
      if not enemy:IsRealHero() then
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