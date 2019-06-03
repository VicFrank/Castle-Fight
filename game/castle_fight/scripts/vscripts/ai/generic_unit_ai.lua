function Spawn(keys)
  -- Wait one frame to do logic on a spawned unit
  Timers:CreateTimer(.1, function()
    local goal

    if thisEntity:GetTeam() == DOTA_TEAM_GOODGUYS then
      goal = GameRules.rightCastlePosition
    elseif thisEntity:GetTeam() == DOTA_TEAM_BADGUYS then
      goal = GameRules.leftCastlePosition
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
      buildingAcquisitionRange = 600, -- TODO: Make units only aggro on buildings if they're close to them
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

  if self:FindAggro() then
    -- print(self:GetUnitName() .. " is aggro'd onto " .. self.aiState.aggroTarget:GetUnitName())
    if self:UseAbility() then return 1.5 end
    self:AttackTarget()
    return .3
    -- self:MoveToAggroTarget()
    -- return .3
  end

  self:MoveTowardsGoal()
  return .3
end

--------------------------------------------------------------------------------
-- FindAggro
-- Search for nearby valid targets to aggro onto
--------------------------------------------------------------------------------
function thisEntity:FindAggro()
  local aggroTargets = FindEnemiesInRadius(self, self.aiState.targetAcquisitionRange)

  local target
  for _,potentialTarget in pairs(aggroTargets) do
    -- print(potentialTarget:GetUnitName(), self:CanAttackTarget(potentialTarget))
    if self:CanAttackTarget(potentialTarget) then
      if not target then
        target = potentialTarget
      else
        target = self:GetHigherPriorityTarget(target, potentialTarget)
      end
    end
  end

  if target then
    self.aiState.aggroTarget = target
    return true
  else
    self.aiState.aggroTarget = nil
    return false
  end
end

--------------------------------------------------------------------------------
-- CanAttackTarget
-- Check to see if the target is attackable
--------------------------------------------------------------------------------
function thisEntity:CanAttackTarget(target)
  -- all units can attack the castle
  if target:GetUnitName() == "castle" then
    return true
  end

  if target:IsRealHero() then
   return false
  elseif target:HasFlyMovementCapability() and not self.aiState.canHitFlying then
    return false
  elseif target:HasGroundMovementCapability() and not self.aiState.canHitGround then
    return false
  end

  return true
end

--------------------------------------------------------------------------------
-- GetTargetPriority
-- Returns the level of priority the unit has when calculating what to aggro onto
-- Higher Number = Higher Priority
-- 4 - Target is a unit
-- 3 - Target is a building that can attack
-- 2 - Target is the castle
-- 1 - Target is a building
--------------------------------------------------------------------------------
function thisEntity:GetTargetPriority(target)
  if IsCustomBuilding(target) then
    if target:HasAttackCapability() then
      -- Is a building that can attack
      return 3
    elseif target:GetUnitName() == "castle" then
      -- Is the castle
      return 2
    else
      -- Is a regular building
      return 1
    end
  else
    -- Is a regular unit
    return 4
  end
end

--------------------------------------------------------------------------------
-- GetHigherPriorityTarget
-- Compares two units and returns the unit with higher priority
-- Ties are broken using distance
--------------------------------------------------------------------------------
function thisEntity:GetHigherPriorityTarget(unit1, unit2)
  local priority1 = self:GetTargetPriority(unit1)
  local priority2 = self:GetTargetPriority(unit2)

  if priority1 > priority2 then return unit1 end
  if priority2 > priority1 then return unit2 end

  local distance1 = GetDistanceBetweenTwoUnits(self, unit1)
  local distance2 = GetDistanceBetweenTwoUnits(self, unit2)

  -- print(unit1:GetUnitName(), unit1:GetUnitName(), unit2:GetUnitName())
  -- print(priority1, priority2)
  -- print(distance1, distance2)

  if distance1 < distance2 then return unit1
  else return unit2
  end
end

--------------------------------------------------------------------------------
-- MoveToAggroTarget
-- Move towards the current position of the Aggro Target
--------------------------------------------------------------------------------
function thisEntity:MoveToAggroTarget()
	self:MoveToPosition(self.aiState.aggroTarget:GetAbsOrigin())
end

--------------------------------------------------------------------------------
-- MoveTowardsGoal
-- Move towards the current position of the Aggro Target
--------------------------------------------------------------------------------
function thisEntity:MoveTowardsGoal()
  self:MoveToPosition(self.aiState.goal)
end

--------------------------------------------------------------------------------
-- AttackTarget
-- Attack the current aggro target
--------------------------------------------------------------------------------
function thisEntity:AttackTarget()
  self:MoveToTargetToAttack(self.aiState.aggroTarget)
end

--------------------------------------------------------------------------------
-- CastSpellOnTarget
-- Attempt to use a random ability
-- Returns true if the ability is cast
--------------------------------------------------------------------------------
function thisEntity:UseAbility()
  local abilityList = self.abilityList
  if not abilityList then return false end
  local ability

  for _,potentialAbility in pairs(abilityList) do
    if potentialAbility:IsFullyCastable() then 
      ability = potentialAbility
      break
    end
  end

  if not ability then return false end

  local target
  local castRange = ability:GetCastRange(self:GetAbsOrigin(), self)

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

    target = GetRandomTableElement(targets)
  else
    target = self.aiState.aggroTarget
  end

  if string.sub(getBinaryValues(ability:GetBehavior()),3,3) == "1" then
  --DOTA_ABILITY_BEHAVIOR_NO_TARGET
    self:CastAbilityNoTarget(ability, -1)
  elseif string.sub(getBinaryValues(ability:GetBehavior()),4,4) == "1" then
  --DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
    self:CastAbilityOnTarget(target, ability, -1)
  elseif string.sub(getBinaryValues(ability:GetBehavior()),5,5) == "1" then
  --DOTA_ABILITY_BEHAVIOR_POINT
    self:CastAbilityOnPosition(target:GetAbsOrigin(), ability, -1)
  elseif string.sub(getBinaryValues(ability:GetBehavior()),6,6) == "1" then
  --DOTA_ABILITY_BEHAVIOR_AOE
    self:CastAbilityOnPosition(target:GetAbsOrigin(), ability, -1)
  end

  return true
end

-----------------------------
-- Helper Functions
-----------------------------

--------------------------------------------------------------------------------
-- Helper Function for CastSpellOnTarget
--------------------------------------------------------------------------------
function getBinaryValues( decNumber )
  local backwards = ""

  while decNumber > 0 do
    local rem = decNumber % 2
    backwards = backwards .. rem
    decNumber = math.floor(decNumber / 2)
  end
  --return string.reverse(backwards)
  return backwards
end