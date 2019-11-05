sudden_death = class({})

function sudden_death:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local filter = function(target) return not target:IsLegendary() end
  local target = GetRandomVisibleEnemyWithFilter(caster:GetTeam(), filter)

  if not target then return end

  if target:IsMechanical() then
    target:EmitSound("Hero_Techies.RemoteMine.Detonate")
    local particleName = "particles/units/heroes/hero_techies/techies_remote_mines_detonate.vpcf"
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:ReleaseParticleIndex(particle)
  else
    -- Should have used bloodrite per-target spilled blood effect probably, and spawned random number
    -- of them in random places of some area. But this looks nice too.
    target:EmitSound("hero_bloodseeker.bloodRite.silence")

    local impactSource = "particles/units/heroes/hero_axe/axe_culling_blade_kill_warp_b.vpcf"
    local impact = ParticleManager:CreateParticle(impactSource, PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControl(impact, 4, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(impact)

    local splatterSource = "particles/custom/undead/death_pit/blood_splatter.vpcf"
    local splatter = ParticleManager:CreateParticle(splatterSource, PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControl(splatter, 4, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(splatter)
    for i=1,RandomInt(3, 7) do
      local bloodWaveSource = "particles/units/heroes/hero_axe/axe_culling_blade_kill_wave_1.vpcf"
      local bloodWave = ParticleManager:CreateParticle(bloodWaveSource, PATTACH_ABSORIGIN, target)
      ParticleManager:SetParticleControl(bloodWave, 4, target:GetAbsOrigin())
      ParticleManager:SetParticleControlForward(bloodWave, 3, RandomVector(1))
      ParticleManager:ReleaseParticleIndex(bloodWave)
    end
    -- for i=1,RandomInt(2, 4) do
    --   local bloodSource = "particles/units/heroes/hero_axe/axe_culling_blade_pool.vpcf"
    --   local blood = ParticleManager:CreateParticle(bloodSource, PATTACH_WORLDORIGIN, target)
    --   ParticleManager:SetParticleControl(blood, 4, target:GetAbsOrigin())
    --   ParticleManager:SetParticleControlForward(blood, 3, RandomVector(1))
    --   ParticleManager:ReleaseParticleIndex(blood)
    -- end
    -- for i=1,RandomInt(5, 15) do
    --   local bloodSource = "particles/blood_splatter.vpcf"
    --   local blood = ParticleManager:CreateParticle(bloodSource, PATTACH_WORLDORIGIN, target)
    --   ParticleManager:SetParticleControl(blood, 0, target:GetAbsOrigin() + RandomVector(RandomInt(10, 200)))
    --   -- ParticleManager:SetParticleControlEnt(blood, 1, target, PATTACH_WORLDORIGIN, "", target:GetAbsOrigin() + RandomVector(200), true)
    --   -- ParticleManager:SetParticleControlEnt(blood, 2, target, PATTACH_WORLDORIGIN, "", target:GetAbsOrigin() + RandomVector(200), true)
    --   -- ParticleManager:SetParticleControlEnt(blood, 3, target, PATTACH_WORLDORIGIN, "", target:GetAbsOrigin() + RandomVector(200), true)
    --   ParticleManager:ReleaseParticleIndex(blood)
    -- end
  end

  for _,modifier in pairs(target:FindAllModifiers()) do
    if modifier.OnBuildingTarget and modifier:OnBuildingTarget() then
      return
    end
  end

  target:Kill(ability, caster)
end