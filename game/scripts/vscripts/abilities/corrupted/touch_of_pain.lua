touch_of_pain = class({})

function touch_of_pain:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local target = GetRandomVisibleEnemy(caster:GetTeam())
  if not target then return end

  local particle_finger = "particles/units/heroes/hero_lion/lion_spell_finger_of_death.vpcf"

  local particle_finger_fx = ParticleManager:CreateParticle(particle_finger, PATTACH_ABSORIGIN_FOLLOW, caster)

  --ParticleManager:SetParticleControl(particle_finger_fx, 0, caster:GetAbsOrigin())
  ParticleManager:SetParticleControlEnt(particle_finger_fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack2", caster:GetAbsOrigin(), true)
  ParticleManager:SetParticleControl(particle_finger_fx, 1, target:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle_finger_fx, 2, target:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle_finger_fx)  

  caster:AddNewModifier(caster, ability, "modifier_provide_vision", {duration = 1})

  for _,modifier in pairs(target:FindAllModifiers()) do
    if modifier.OnBuildingTarget and modifier:OnBuildingTarget() then
      return
    end
  end 

  ApplyDamage({
    victim = target,
    damage = 200,
    damage_type = DAMAGE_TYPE_MAGICAL,
    attacker = caster,
    ability = ability
  })
end