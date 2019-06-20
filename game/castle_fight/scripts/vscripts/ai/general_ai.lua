--------------------------------------------------------------------------------
-- FindAggro
-- Search for nearby valid targets to aggro onto
--------------------------------------------------------------------------------
function FindAggro(self)
  local currentTarget = self.aiState.aggroTarget

  local searchRange = self.aiState.targetAcquisitionRange

  -- expand the search range if we're currently aggro'd
  if currentTarget and not currentTarget:IsNull() and 
    currentTarget:IsAlive() and not IsCustomBuilding(currentTarget) then
    searchRange = self.aiState.stopPursuitRange
  end

  local aggroTargets = FindEnemiesInRadius(self, searchRange)

  local target
  for _,potentialTarget in pairs(aggroTargets) do
    -- print(potentialTarget:GetUnitName(), self:CanAttackTarget(potentialTarget))
    if CanAttackTarget(self, potentialTarget) then
      if not target then
        target = potentialTarget
      else
        target = GetHigherPriorityTarget(self, target, potentialTarget)
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
function CanAttackTarget(self, target)
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
-- 3 - Target is a unit
-- 2 - Target is a building that can attack
-- 1 - Target is a building
--------------------------------------------------------------------------------
function GetTargetPriority(target)
  if IsCustomBuilding(target) then
    if target:HasAttackCapability() then
      -- Is a building that can attack
      return 2
    else
      -- Is a regular building
      return 1
    end
  else
    -- Is a regular unit
    return 3
  end
end

--------------------------------------------------------------------------------
-- GetHigherPriorityTarget
-- Compares two units and returns the unit with higher priority
-- Ties are broken using distance
--------------------------------------------------------------------------------
function GetHigherPriorityTarget(self, unit1, unit2)
  local priority1 = GetTargetPriority(unit1)
  local priority2 = GetTargetPriority(unit2)

  if priority1 > priority2 then return unit1 end
  if priority2 > priority1 then return unit2 end

  local distance1 = GetDistanceBetweenTwoUnits(self, unit1)
  local distance2 = GetDistanceBetweenTwoUnits(self, unit2)

  -- The castle is a big fat boy, so the distance from the origin is misleading
  if unit1:GetUnitName() == "castle" then
    distance1 = distance1 - 200
  elseif unit2:GetUnitName() == "castle" then
    distance2 = distance2 - 200
  end

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
function MoveToAggroTarget(self)
	self:MoveToPosition(self.aiState.aggroTarget:GetAbsOrigin())
end

--------------------------------------------------------------------------------
-- MoveTowardsGoal
-- Move towards the current position of the Aggro Target
--------------------------------------------------------------------------------
function MoveTowardsGoal(self)
  self:MoveToPosition(self.aiState.goal)
end

--------------------------------------------------------------------------------
-- AttackTarget
-- Attack the current aggro target
--------------------------------------------------------------------------------
function AttackTarget(self)
  self:MoveToTargetToAttack(self.aiState.aggroTarget)
end

--------------------------------------------------------------------------------
-- CastSpellOnTarget
-- Attempt to use a random ability
-- Returns true if the ability is cast
--------------------------------------------------------------------------------
function UseAbility(self)
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

  if string.sub(getBinaryValues(ability:GetBehavior()),3,3) == "1" then
    --DOTA_ABILITY_BEHAVIOR_NO_TARGET
    self:CastAbilityNoTarget(ability, -1)
    return true
  end

  local target
  local castRange = ability:GetCastRange(self:GetAbsOrigin(), self)

  if castRange and castRange > 0 then
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
      return not IsCustomBuilding(target)
    end)

    if not target then return false end
  else
    target = self.aiState.aggroTarget
  end

  if string.sub(getBinaryValues(ability:GetBehavior()),4,4) == "1" then
  --DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
    self:CastAbilityOnTarget(target, ability, -1)
  elseif string.sub(getBinaryValues(ability:GetBehavior()),5,5) == "1" then
  --DOTA_ABILITY_BEHAVIOR_POINT
    self:CastAbilityOnPosition(target:GetAbsOrigin(), ability, -1)
  elseif string.sub(getBinaryValues(ability:GetBehavior()),6,6) == "1" then
  --DOTA_ABILITY_BEHAVIOR_AOE
    self:CastAbilityOnPosition(target:GetAbsOrigin(), ability, -1)
  end

  print("Casting: " .. ability:GetAbilityName())

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