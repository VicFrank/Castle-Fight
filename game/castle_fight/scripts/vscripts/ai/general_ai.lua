--------------------------------------------------------------------------------
-- FindAggro
-- Search for nearby valid targets to aggro onto
--------------------------------------------------------------------------------
function FindAggro(self)
  local currentTarget = self.aiState.aggroTarget

  local searchRange = self.aiState.targetAcquisitionRange

  -- Handle if we're taunted
  if self:HasModifier("mountain_giant_taunt") then
    local tauntTarget = self.tauntTarget

    if not tauntTarget:IsAlive() then
      self:RemoveModifierByName("mountain_giant_taunt")
    else
      if CanAttackTarget(self, tauntTarget) then
        self.aiState.aggroTarget = tauntTarget
        return true
      end
    end
  end

  -- expand the search range if we're currently aggro'd
  if currentTarget and not currentTarget:IsNull() and 
    currentTarget:IsAlive() and not IsCustomBuilding(currentTarget) then
    searchRange = self.aiState.stopPursuitRange
  end

  local aggroTargets = FindEnemiesInRadius(self, searchRange)

  local maxTargets = 7

  local target
  for _,potentialTarget in ipairs(aggroTargets) do
    -- print(potentialTarget:GetUnitName(), self:CanAttackTarget(potentialTarget))
    if CanAttackTarget(self, potentialTarget) then
      if not target then
        target = potentialTarget
      else
        target = GetHigherPriorityTarget(self, target, potentialTarget)
      end

      -- This is the closest unit of the highest priority, so we'll always return it
      if GetTargetPriority(self, target) == 3 then
        break
      end
    end

    maxTargets = maxTargets - 1
    if maxTargets <= 0 then break end
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

  if target:IsAttackImmune() then return false end

  if target:IsRealHero() then
   return false
  elseif target:HasFlyMovementCapability() and not self.aiState.canHitFlying then
    return false
  elseif target:HasGroundMovementCapability() and not self.aiState.canHitGround then
    return false
  end

  if target:HasModifier("modifier_ancient_guardian_banish") and
   not self:HasModifier("modifier_attack_magic") then
    return false
  end

  -- If we can't reach the target
  -- Note that we can never find path to a building
  if self:GetAttackCapability() == DOTA_UNIT_CAP_MELEE_ATTACK and not IsCustomBuilding(target) then
    local pathLength = GridNav:FindPathLength(self:GetAbsOrigin(), target:GetAbsOrigin())
    if pathLength == -1 or pathLength > self.aiState.stopPursuitRange then
      return false
    end
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
function GetTargetPriority(self, target)
  if IsCustomBuilding(target) then
    if target:HasAttackCapability() then
      -- Is a building that can attack
      if self:HasModifier("modifier_attack_siege") then
        return 3
      else
        return 2
      end
    else
      -- Is a regular building
      return 1
    end
  else
    -- Is a regular unit
    if target:HasModifier("modifier_frost_attack_freeze") then
      -- Don't attack units that are already frozen
      return 2.9
    else
      return 3
    end
  end
end

--------------------------------------------------------------------------------
-- GetHigherPriorityTarget
-- Compares two units and returns the unit with higher priority
-- Ties are broken using distance
--------------------------------------------------------------------------------
function GetHigherPriorityTarget(self, unit1, unit2)
  local priority1 = GetTargetPriority(self, unit1)
  local priority2 = GetTargetPriority(self, unit2)

  if priority1 > priority2 then return unit1 end
  if priority2 > priority1 then return unit2 end

  local distance1 = GridNav:FindPathLength(self:GetAbsOrigin(), unit1:GetAbsOrigin())
  local distance2 = GridNav:FindPathLength(self:GetAbsOrigin(), unit2:GetAbsOrigin())

  -- Stick to the currently aggro'd target
  if (unit1 == self.aiState.aggroTarget) then
    distance1 = distance1 - 200
  elseif (unit2 == self.aiState.aggroTarget) then
    distance2 = distance2 - 200
  end
  
  -- print(unit1:GetUnitName(), unit1:GetUnitName(), unit2:GetUnitName())
  -- print(priority1, priority2)
  -- print(distance1, distance2)

  if distance1 < distance2 then return unit1
  -- Because we search in order from closest to farthest, unit1 will always
  -- be closer than unit2 (in absolute terms)
  elseif distance1 == distance2 then
    local currentTarget = self.aiState.aggroTarget
    if currentTarget and not currentTarget:IsNull() and IsCustomBuilding(currentTarget) then
      return currentTarget
    end
    return unit1
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
-- UseAbility
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

  local target
  local castRange = ability:GetCastRange(self:GetAbsOrigin(), self)
  local behavior = ability:GetBehavior()

  if castRange and castRange > 0 then
    -- We should wait a bit before casting an aoe no-target ability
    if hasbit(behavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) then
      if self.aiState.waitToCast then
        return false
      end

      if not self.aiState.canCast then
        self.aiState.waitToCast = true

        Timers:CreateTimer(2, function()
          self.aiState.waitToCast = false
          self.aiState.canCast = true
        end)

        return false
      end
    end

    local targets = FindUnitsInRadius(
      self:GetTeam(),
      self:GetAbsOrigin(),
      nil, 
      castRange,
      ability:GetAbilityTargetTeam(),
      ability:GetAbilityTargetType(),
      ability:GetAbilityTargetFlags() + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
      FIND_ANY_ORDER,
      false)

    -- Don't cast an ability that applies the modifier we're going to apply anyway
    local modifierBlackList = g_AI_Modifier_Table[self:GetUnitName()]

    target = FindFirstUnit(targets, function(potentialTarget) 
      local isValidTarget = not IsCustomBuilding(potentialTarget)

      if modifierBlackList then
        if potentialTarget:HasModifier(modifierBlackList) then
          isValidTarget = false
        end
      end

      -- Don't buff summons or lunatic goblins
      if self:GetTeam() == potentialTarget:GetTeam() then
        if potentialTarget:HasModifier("modifier_kill") then
          isValidTarget = false
        end

        if potentialTarget:GetUnitName() == "lunatic_goblin" then
          isValidTarget = false
        end
      end

      -- if the ability can't hit flying units, don't use it
      if self:GetUnitName() == "corrupted_annihilator" then
        if potentialTarget:HasFlyMovementCapability() then
          isValidTarget = false
        end
      end

      return isValidTarget
    end)

    if not target then return false end
  else
    target = self.aiState.aggroTarget
  end

  if hasbit(behavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) then
    self:CastAbilityNoTarget(ability, -1)
    if self.aiState.canCast then
      self.aiState.canCast = false
    end
  elseif hasbit(behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then
    self:CastAbilityOnTarget(target, ability, -1)
  elseif hasbit(behavior, DOTA_ABILITY_BEHAVIOR_POINT) then
      self:CastAbilityOnPosition(target:GetAbsOrigin(), ability, -1)
  elseif hasbit(behavior, DOTA_ABILITY_BEHAVIOR_AOE) then
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