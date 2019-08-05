sudden_death = class({})

function sudden_death:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local filter = function(target) return not target:IsLegendary() end
  local target = GetRandomVisibleEnemyWithFilter(caster:GetTeam(), filter)

  if not target then return end

  ParticleManager:ReleaseParticleIndex(
    ParticleManager:CreateParticle(
      "particles/units/heroes/hero_life_stealer/life_stealer_infest_emerge_bloody.vpcf",
      PATTACH_ABSORIGIN_FOLLOW,
      target 
    ) 
  )

  for _,modifier in pairs(target:FindAllModifiers()) do
    if modifier.OnBuildingTarget and modifier:OnBuildingTarget() then
      return
    end
  end

  target:Kill(ability, caster)
end