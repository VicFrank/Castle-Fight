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
    target:EmitSound("hero_bloodseeker.bloodRite.silence")

    local particle = ParticleManager:CreateParticle("particles/custom/undead/death_pit/sudden_death.vpcf", PATTACH_WORLDORIGIN, target)
    ParticleManager:SetParticleControl(particle, 4, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(particle)
  end

  for _,modifier in pairs(target:FindAllModifiers()) do
    if modifier.OnBuildingTarget and modifier:OnBuildingTarget() then
      return
    end
  end

  target:Kill(ability, caster)
end