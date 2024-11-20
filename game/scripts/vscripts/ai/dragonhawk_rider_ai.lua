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
    }

    -- Get all of the unit's abilities
    thisEntity.abilityList = {}
    for i=0,15 do
      local ability = thisEntity:GetAbilityByIndex(i)
      if ability and not ability:IsPassive() then
        table.insert(thisEntity.abilityList, ability)
      end
    end

    Timers:CreateTimer(function() return thisEntity:AIThink() end)
  end)
end

function thisEntity:AIThink()
  if self:IsNull() then return end
  if not self:IsAlive() then return end

  if GameRules:IsGamePaused() then
    return 0.1
  end

  if FindAggro(self) then
    if not self.aiState.foundTargetTime then
      self:FindSolarStrikeTarget()
    else
      -- if it's been 2 seconds, and there's still a target, cast solar strike
      if GameRules:GetGameTime() - self.aiState.foundTargetTime > 2 and
        self:FindSolarStrikeTarget() then
        if self:CastSolarStrike() then return 0.5 end
      end
    end
    AttackTarget(self)
    return .3
  end

  MoveTowardsGoal(self)
  return .3
end

function thisEntity:FindSolarStrikeTarget()
  local ability = self:FindAbilityByName("dragonhawk_rider_solar_strike")

  if not ability or not ability:IsFullyCastable() then return false end
  
  -- see if there's a target for web
  local castRange = ability:GetCastRange(self:GetAbsOrigin(), self)
  local target

  if castRange then
    local targets = FindUnitsInRadius(
      self:GetTeam(),
      self:GetAbsOrigin(),
      nil, 
      castRange,
      ability:GetAbilityTargetTeam(),
      ability:GetAbilityTargetType(),
      ability:GetAbilityTargetFlags(),
      FIND_ANY_ORDER,
      false)

    target = FindFirstUnit(targets, function(target) 
      return target:HasFlyMovementCapability()
    end)
  end

  if target and not self.aiState.foundTargetTime then
    self.aiState.foundTargetTime = GameRules:GetGameTime()
    return target
  elseif not target then
    self.aiState.foundTargetTime = nil
    return nil
  end

  return target
end

function thisEntity:CastSolarStrike()
  local ability = self:FindAbilityByName("dragonhawk_rider_solar_strike")

  target = self:FindSolarStrikeTarget()

  if target then
      self:CastAbilityNoTarget(ability, -1)
      self.aiState.foundTargetTime = nil
    return true
  end

  return false
end