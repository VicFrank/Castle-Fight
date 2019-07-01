sorceress_healing_wave = class({})

function sorceress_healing_wave:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  local heal = ability:GetSpecialValueFor("heal")
  local bounces = ability:GetSpecialValueFor("bounces")
  local health_loss = ability:GetSpecialValueFor("health_loss")
  local bounce_range = 450
  local jump_delay = 0.25

  local hit = {}
  hit[target] = true

  local lastBounce = caster
  local nextBounce = target

  Timers:CreateTimer(function()
    if not nextBounce or bounces <= 0 then return end

    -- Apply the lightning
    nextBounce:EmitSound("Hero_Dazzle.Shadow_Wave")

    local particleName = "particles/units/heroes/hero_dazzle/dazzle_shadow_wave.vpcf"
    local waveParticle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, lastBounce)
    ParticleManager:SetParticleControlEnt(waveParticle, 0, lastBounce, PATTACH_POINT_FOLLOW, "attach_hitloc", lastBounce:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(waveParticle, 1, nextBounce, PATTACH_POINT_FOLLOW, "attach_hitloc", nextBounce:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(waveParticle)

    nextBounce:Heal(heal, caster)

    heal = heal - (heal * health_loss * 0.01)

    -- Find the next bounce target
    lastBounce = nextBounce
    nextBounce = nil

    local nearbyAllies = FindAlliesInRadius(caster, bounce_range, lastBounce:GetAbsOrigin())
    for _,ally in pairs(nearbyAllies) do
      if not hit[ally] and not IsCustomBuilding(ally) and not ally:IsRealHero() then
        nextBounce = ally
      end
    end

    if nextBounce then
      hit[nextBounce] = true
    end

    bounces = bounces - 1

    return jump_delay
  end)
end