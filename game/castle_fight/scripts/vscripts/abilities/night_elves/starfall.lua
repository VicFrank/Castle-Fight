starfall = class({})

function starfall:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local target = GetRandomVisibleEnemy(caster:GetTeam())
  if not target then return end

  local wave_interval = ability:GetSpecialValueFor("wave_interval")
  local duration = ability:GetSpecialValueFor("duration")

  local targetParticle = "particles/units/heroes/hero_mirana/mirana_moonlight_owner.vpcf"
  local targetFireParticle = "particles/units/heroes/hero_mirana/mirana_starfall_moonray.vpcf"

  local targetParticleIndex = ParticleManager:CreateParticle(targetParticle, PATTACH_ABSORIGIN, target)

  local position = target:GetAbsOrigin()

  local timeSpent = 0
  Timers:CreateTimer(function()
    if timeSpent >= duration then
      ParticleManager:DestroyParticle(targetParticleIndex, true)
      return
    end

    if target:IsAlive() then
      local fireParticleIndex = ParticleManager:CreateParticle(targetFireParticle, PATTACH_ABSORIGIN, target)
      position = target:GetAbsOrigin()
    end

    StarfallDamage(ability, target:GetAbsOrigin())

    timeSpent = timeSpent + wave_interval
    return wave_interval
  end)
end

function StarfallDamage(ability, position)
  local caster = ability:GetCaster()
  local radius = ability:GetSpecialValueFor("radius")
  local dps = ability:GetSpecialValueFor("damage")
  local wave_interval = ability:GetSpecialValueFor("damage")
  local damage = dps * wave_interval

  local targets = FindEnemiesInRadius(caster, radius, caster:GetAbsOrigin())

  for _,target in pairs(targets) do
    local particle = ParticleManager:CreateParticle("particles/custom/nightelf/potm/starfall.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:ReleaseParticleIndex(particle)
  end 

  Timers:CreateTimer(0.4, function()
    for _,target in pairs(targets) do
      if IsValidEntity(target) and target:IsAlive() then
        if IsCustomBuilding(target) then
          damage = damage * 0.4
        end

        ApplyDamage({
          victim = target,
          attacker = caster,
          damage = damage,
          ability = ability,
          damage_type = DAMAGE_TYPE_MAGICAL
        })

        target:EmitSound("Ability.StarfallImpact")
      end
    end 
  end)
end