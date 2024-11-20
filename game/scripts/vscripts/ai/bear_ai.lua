require("ai/general_ai")

function Spawn(keys)
  -- Wait one frame to do logic on a spawned unit
  Timers:CreateTimer(.1, function()
    local goal

    if thisEntity:GetTeam() == DOTA_TEAM_GOODGUYS then
      goal = GameRules.rightCastlePosition
    elseif thisEntity:GetTeam() == DOTA_TEAM_BADGUYS then
      goal = GameRules.leftCastlePosition - Vector(300,128,0)
    end

    local canHitFlying = true
    local canHitGround = true

    -- melee units can't hit flying
    if thisEntity:GetAttackCapability() == 1 then
      canHitFlying = false
    end

    local attacksDisallowed = thisEntity:GetKeyValue("AttacksDisallowed")
    if attacksDisallowed then
      if attacksDisallowed == "ground" then
        canHitGround = false
      elseif attacksDisallowed == "flying" then
        canHitFlying = false
      else
        print("Bad KV AttacksDisallowed = " .. attacksDisallowed .. " for " .. thisEntity:GetUnitName())
      end
    end

    local attackRange = thisEntity:GetKeyValue("AttackRange") or 0
    if attackRange == 0 then print(thisEntity:GetUnitName() .. " has no attack range") end
    local acquisitionRange = math.max(900, attackRange + 200)

    thisEntity.aiState = {
      aggroTarget = nil,
      targetAcquisitionRange = acquisitionRange,
      stopPursuitRange = 1600,
      goal = goal,
      canHitFlying = canHitFlying,
      canHitGround = canHitGround,
      spawnLocation = thisEntity:GetAbsOrigin(),
      retreatTime = 5,
    }

    thisEntity.slumberAbility = thisEntity:FindAbilityByName("bear_slumber")

    Timers:CreateTimer(function() return thisEntity:AIThink() end)
  end)
end

function thisEntity:AIThink()
  if self:IsNull() then return end
  if not self:IsAlive() then return end

  if GameRules:IsGamePaused() then
    return 0.1
  end

  -- Don't do anything while sleeping
  if self:HasModifier("modifier_bear_slumber") then
    return 0.1
  end

  if self.readyToSleep then
    if (self:GetAbsOrigin() - self.aiState.spawnLocation):Length2D() < 200 then
      -- If we're back to the spawn, just go to sleep now
      return self:CastSlumber()
    elseif GameRules:GetGameTime() > self.sleepTime then
      -- If we're done retreating
      return self:CastSlumber()
    else
      return 0.3
    end
  end

  if self.slumberAbility:IsFullyCastable() and self:GetHealthPercent() < 50 then
    -- if we're weak, retreat and cast slumber
    self:MoveToPosition(self.aiState.spawnLocation)
    self.readyToSleep = true
    self.sleepTime = GameRules:GetGameTime() + self.aiState.retreatTime
    return 1
  end

  if FindAggro(self) then
    AttackTarget(self)
    return .3
  end

  MoveTowardsGoal(self)
  return .3
end

function thisEntity:CastSlumber()
  self:CastAbilityNoTarget(self.slumberAbility, -1)
  self.readyToSleep = false

  return 1
end