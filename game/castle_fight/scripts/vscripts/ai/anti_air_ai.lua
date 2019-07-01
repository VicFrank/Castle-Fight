require("ai/general_ai")

function Spawn(keys)
  -- Wait one frame to do logic on a spawned unit
  Timers:CreateTimer(.1, function()   
    -- vs Air: Normal, (900 range), DPS 175 (60-80)
    -- vs Ground: Normal, (700 range), DPS 37 (20-25)

    thisEntity.aiState = {
      flySearchRange = 900,
      groundSearchRange = 700,

      airMinDamage = 60,
      airMaxDamage = 80,
      airAttackRate = 0.4,

      groundMinDamage = 20,
      groundMaxDamage = 25,
      groundAttackRate = 0.6,

    }

    Timers:CreateTimer(function() return thisEntity:AIThink() end)
  end)
end

function thisEntity:AIThink()
  if self:IsNull() then return end
  if not self:IsAlive() then return end

  if GameRules:IsGamePaused() then
    return 0.1
  end

  if self:FindAggro() then
    self:SetDamage()
    return .1
  end

  return .1
end

function thisEntity:FindAggro()
  local currentTarget = self.aiState.aggroTarget

  local flySearchRange = self.aiState.flySearchRange
  local groundSearchRange = self.aiState.groundSearchRange

  local flyTargets = FindEnemiesInRadius(self, flySearchRange)
  local target = FindFirstUnit(flyTargets, function(target) return target:HasFlyMovementCapability() end)

  if not target then
    local groundTargets = FindEnemiesInRadius(self, groundSearchRange)
    target = FindFirstUnit(groundTargets, function() return true end)
  end

  if target then
    self:SetAggroTarget(target)
    return true
  else
    return false
  end
end

function thisEntity:SetDamage()
  local target = self:GetAggroTarget()

  if target:HasFlyMovementCapability() then
    self:SetBaseDamageMin(self.aiState.airMinDamage) 
    self:SetBaseDamageMax(self.aiState.airMaxDamage) 
    self:SetBaseAttackTime(self.aiState.airAttackRate)
  else
    self:SetBaseDamageMin(self.aiState.groundMinDamage) 
    self:SetBaseDamageMax(self.aiState.groundMaxDamage) 
    self:SetBaseAttackTime(self.aiState.groundAttackRate)
  end
end