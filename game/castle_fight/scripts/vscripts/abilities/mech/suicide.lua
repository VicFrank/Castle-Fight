lunatic_goblin_suicide = class({})

function lunatic_goblin_suicide:OnSpellStart()
  local ability = self
  local caster = self:GetCaster()

  local full_damage = self:GetSpecialValueFor("full_damage")
  local far_damage = self:GetSpecialValueFor("far_damage")
  local close_radius = self:GetSpecialValueFor("close_radius")
  local far_radius = self:GetSpecialValueFor("far_radius")
  
  local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_suicide.vpcf", PATTACH_POINT, caster)
  ParticleManager:SetParticleControl(nfx, 0, caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(nfx, 1, Vector(close_radius,0,0))
  ParticleManager:SetParticleControl(nfx, 2, Vector(far_radius,far_radius,1))
  ParticleManager:ReleaseParticleIndex(nfx)

  caster:EmitSound("Hero_Techies.Suicide")

  local enemies = FindEnemiesInRadius(caster, far_radius)
  for _,enemy in pairs(enemies) do
    if not enemy:HasFlyMovementCapability() then
      local damage = far_damage

      if IsCustomBuilding(enemy) then
        damage = damage * 0.35
      end

      ApplyDamage({
        victim = enemy,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        attacker = caster,
        ability = ability
      })
    end
  end

  local close_enemies = FindEnemiesInRadius(caster, close_radius)
  for _,enemy in pairs(close_enemies) do
    if not enemy:HasFlyMovementCapability() then
      local damage = full_damage - far_damage

      if IsCustomBuilding(enemy) then
        damage = damage * 0.35
      end

      ApplyDamage({
        victim = enemy,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        attacker = caster,
        ability = ability
      })
    end
  end

  caster:Kill(ability, caster)
end
