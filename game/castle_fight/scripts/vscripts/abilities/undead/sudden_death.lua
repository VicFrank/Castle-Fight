sudden_death = class({})

function sudden_death:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local target = GetRandomVisibleEnemy(caster:GetTeam())
  if not target then return end

  ParticleManager:ReleaseParticleIndex(
    ParticleManager:CreateParticle(
      "particles/units/heroes/hero_life_stealer/life_stealer_infest_emerge_bloody.vpcf",
      PATTACH_ABSORIGIN_FOLLOW,
      target 
    ) 
  )

  target:Kill(ability, caster)
end