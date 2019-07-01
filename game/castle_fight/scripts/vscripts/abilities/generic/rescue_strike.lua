item_rescue_strike = class({})

function item_rescue_strike:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorPosition()
  local playerID = caster:GetPlayerOwnerID()
  local particleName = "particles/abilities/generic/rescue_strike/rescue_strike.vpcf"
  local sound = "Hero_Techies.BlastOff.Cast"

  -- making the radius a bit bigger than it shows
  local radius = ability:GetSpecialValueFor("radius") + 100

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
    damageDone = damageDone + enemy:GetHealth()
    
    enemy:Kill(ability, caster)

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

  local message
  local username = PlayerResource:GetPlayerName(playerID)

  if enemiesKilled == 0 then
    message = "EPIC FAIL! " .. username .. " WASTED their Rescue Strike, killing no enemies and dealing 0 damage!"
  elseif enemiesKilled < 5 then
    message = username .. " WASTED their Rescue Strike, killing only " .. enemiesKilled ..
      " enemies, and dealing " .. damageDone .. " damage!"
  else
    message = username .. " killed " .. enemiesKilled .. " enemies with their Rescue Strike, dealing " ..
      damageDone .. " damage!"
  end

  Notifications:TopToAll({text=message, duration=5.0})

  -- Consume Rescue Strike
  caster:RemoveItem(ability)
end

function item_rescue_strike:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end