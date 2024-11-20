faerie_dragon_heal = class({})

function faerie_dragon_heal:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  local heal = ability:GetSpecialValueFor("heal")

  caster:EmitSound("Hero_Omniknight.Purification")

  local particleName = "particles/units/heroes/hero_omniknight/omniknight_purification_d_glow.vpcf"

  local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, target)
  ParticleManager:ReleaseParticleIndex(particle)

  target:Heal(heal, target)
  SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, heal, nil)   
end
