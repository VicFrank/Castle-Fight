dragonhawk_rider_solar_strike = class({})

function dragonhawk_rider_solar_strike:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local radius = ability:GetSpecialValueFor("radius")
  local damage = ability:GetSpecialValueFor("damage")
  local stun_duration = ability:GetSpecialValueFor("stun_duration")

  local enemies = FindEnemiesInRadius(caster, radius)

  local flyingEnemies = {}

  for _,enemy in pairs(enemies) do
    if enemy:HasFlyMovementCapability() then
      table.insert(flyingEnemies, enemy)
    end

    if #flyingEnemies == 4 then
      break
    end
  end

  caster:EmitSound("Hero_SkywrathMage.MysticFlare.Target")

  local particleName = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_mystic_flare_ambient.vpcf"

  for _,target in pairs(flyingEnemies) do
    target:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun_duration})
    ApplyDamage({
      victim = target,
      damage = damage,
      damage_type = DAMAGE_TYPE_MAGICAL,
      attacker = caster,
      ability = ability
    })

    particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, nil)        
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(100, 1, 0))            
    ParticleManager:ReleaseParticleIndex(particle)
  end
end