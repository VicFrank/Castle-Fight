magnataur_stomp = class({})

function magnataur_stomp:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local duration = ability:GetSpecialValueFor("duration")
  local damage = ability:GetSpecialValueFor("damage")
  local radius = ability:GetSpecialValueFor("radius")

  local enemies = FindEnemiesInRadius(caster, radius)

  caster:EmitSound("Hero_Centaur.HoofStomp")

  local particleName = "particles/units/heroes/hero_centaur/centaur_warstomp.vpcf"

  local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, caster)
  ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle, 1, Vector(radius, 1, 1))
  ParticleManager:SetParticleControl(particle, 2, caster:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle)

  for _,enemy in pairs(enemies) do
    if not IsCustomBuilding(enemy) and not enemy:IsRealHero() and not enemy:HasFlyMovementCapability() then
      enemy:AddNewModifier(caster, ability, "modifier_stunned", {duration = duration})

      ApplyDamage({
        attacker = caster,
        victim = enemy,
        ability = ability,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
      })
    end
  end
end