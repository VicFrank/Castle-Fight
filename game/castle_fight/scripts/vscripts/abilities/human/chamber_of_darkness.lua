chamber_of_darkness = class({})

function chamber_of_darkness:OnSpellStart()
  -- Ability properties
  local caster = self:GetCaster()
  local ability = self
  local position = self:GetCursorPosition()

  local sound = "Hero_Pugna.NetherBlast"
  local soundPreCast = "Hero_Pugna.NetherBlastPreCast"
  local preCastParticleName = "particles/units/heroes/hero_pugna/pugna_netherblast_pre.vpcf"
  local particleName = "particles/units/heroes/hero_pugna/pugna_netherblast.vpcf"

  local radius = ability:GetSpecialValueFor("radius")
  local delay = ability:GetSpecialValueFor("delay")
  local damage = ability:GetSpecialValueFor("damage")

  caster:EmitSound(sound)

  local particlePre = ParticleManager:CreateParticle(preCastParticleName, PATTACH_CUSTOMORIGIN, nil)
  ParticleManager:SetParticleControl(particlePre, 0, position)
  ParticleManager:SetParticleControl(particlePre, 1, Vector(radius, delay, 1))
  ParticleManager:ReleaseParticleIndex(particlePre)

  EmitSoundOnLocationForAllies(position, soundPreCast, caster)

  Timers:CreateTimer(delay, function()
    local particleBlast = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(particleBlast, 0, position)
    ParticleManager:SetParticleControl(particleBlast, 1, Vector(radius, 0, 0))
    ParticleManager:ReleaseParticleIndex(particleBlast)

    local targets = FindEnemiesInRadius(caster, radius, position)

    for _,unit in pairs(targets) do
      if not IsCustomBuilding(unit) then
        local damageTable = {
          victim = unit,
          damage = damage,
          damage_type = DAMAGE_TYPE_MAGICAL,
          attacker = caster,
          ability = ability
        }

        ApplyDamage(damageTable)
      end
    end
  end)
end