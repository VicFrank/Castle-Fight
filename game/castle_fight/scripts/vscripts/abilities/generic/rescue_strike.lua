item_rescue_strike = class({})

function item_rescue_strike:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorPosition()
  local playerID = caster:GetPlayerOwnerID()
  local particleName = "particles/abilities/generic/rescue_strike/rescue_strike.vpcf"
  local sound = "Hero_Techies.BlastOff.Cast"

  local radius = ability:GetSpecialValueFor("radius")

  -- Can't use rescue strike before the first round starts
  if not GameRules.rescueStrikeDamage then
    return
  end

  EmitSoundOnLocationWithCaster(target, sound, caster)

  local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(particle, 0, target)
  ParticleManager:ReleaseParticleIndex(particle)

  local damageDone = 0
  local enemiesKilled = 0

  local enemies = FindEnemiesInRadius(caster, radius)

  for _,enemy in pairs(enemies) do
    enemy:Kill(ability, caster)

    damageDone = damageDone + enemy:GetHealth()
    enemiesKilled = enemiesKilled + 1
  end

  GameRules.rescueStrikeDamage[playerID] = damageDone
  GameRules.rescueStrikeKills[playerID] = enemiesKilled

  -- Send event to clients
  CustomGameEventManager:Send_ServerToAllClients("rescue_strike_used", {
    playerID = playerID,
    damageDone = damageDone,
    enemiesKilled = enemiesKilled
  })

  -- Consume Rescue Strike
  caster:RemoveItem(ability)
end

function item_rescue_strike:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end