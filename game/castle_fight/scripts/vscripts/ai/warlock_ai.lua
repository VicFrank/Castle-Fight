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
    local acquisitionRange = 1200

    thisEntity.aiState = {
      aggroTarget = nil,
      targetAcquisitionRange = acquisitionRange,
      stopPursuitRange = 1600,
      goal = goal,
      canHitFlying = canHitFlying,
      canHitGround = canHitGround,
      spawnLocation = thisEntity:GetAbsOrigin(),
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

  if self:AbilityOnCooldown() then
    return self:Retreat()
  end

  if FindAggro(self) then
    if self:UseAbility() then
      return self:FindAbilityByName("chamber_of_darkness"):GetCastPoint() + 0.3
    end
    AttackTarget(self)
  end

  MoveTowardsGoal(self)
  return .3
end

function thisEntity:UseAbility()
  local ability = self:FindAbilityByName("chamber_of_darkness")
  local castRange = ability:GetCastRange(self:GetAbsOrigin(), self)

  if GetDistanceBetweenTwoUnits(self, self.aiState.aggroTarget) < castRange then
    local position = self.aiState.aggroTarget:GetAbsOrigin()
    self:CastAbilityOnPosition(position, ability, -1)
    self.aiState.aggroTarget = nil
    return true
  end

  return false
end

function thisEntity:AbilityOnCooldown()
  local ability = self:FindAbilityByName("chamber_of_darkness")

  return not ability:IsFullyCastable()
end

function thisEntity:Retreat()
  self.aiState.aggroTarget = nil

  local ability = self:FindAbilityByName("chamber_of_darkness")

  -- if it's been long enough, feel free to attack units that are close to us
  if ability:GetCooldownTimeRemaining() < 5 then
    if FindAggro(self) then
      AttackTarget(self)
      return .3
    end
  end

  if (self:GetAbsOrigin() - self.aiState.spawnLocation):Length2D() < 10 then
    return .3
  end

  self:MoveToPosition(self.aiState.spawnLocation)
  return .3
end