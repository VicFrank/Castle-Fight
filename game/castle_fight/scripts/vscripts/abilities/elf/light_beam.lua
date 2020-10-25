obelisk_of_light_light_beam = class({})

function obelisk_of_light_light_beam:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local target = GetRandomVisibleEnemy(caster:GetTeam())
  if not target then return end

  caster:EmitSound("Hero_Tinker.Laser")

  caster:AddNewModifier(caster, ability, "modifier_provide_vision", {duration = 0.1})

  local particleName = "particles/units/heroes/hero_tinker/tinker_laser.vpcf"
  local particle = ParticleManager:CreateParticle(particleName, PATTACH_POINT_FOLLOW, caster)

  ParticleManager:SetParticleControlEnt(particle, 9, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
  ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
  
  ParticleManager:ReleaseParticleIndex(particle)

  local damage = ability:GetSpecialValueFor("damage")

  ApplyDamage({
    victim = target,
    damage = damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    attacker = caster,
    ability = ability
  })
end