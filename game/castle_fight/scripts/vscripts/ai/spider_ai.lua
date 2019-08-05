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

  if self:CastWeb() then return 0.6 end

  if FindAggro(self) then
    if self:CastInfest() then return 0.6 end
    AttackTarget(self)
    return .3
  end

  MoveTowardsGoal(self)
  return .3
end

function thisEntity:CastWeb()
  local ability = self:FindAbilityByName("spider_web")

  if not ability or not ability:IsFullyCastable() then return false end
  
  -- see if there's a target for web
  local castRange = ability:GetCastRange(self:GetAbsOrigin(), self)
  local target

  if castRange then
    local targets = FindEnemiesInRadius(self, castRange)

    target = FindFirstUnit(targets, function(target) 
      return not IsCustomBuilding(target) and target:HasFlyMovementCapability()
    end)
  end

  if target then
    self:CastAbilityOnTarget(target, ability, -1)
    return true
  end

  return false
end

function thisEntity:CastInfest()
  local ability = self:FindAbilityByName("brood_mother_infest")

  if not ability or not ability:IsFullyCastable() then return false end
  
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
      return not IsCustomBuilding(target)
    end)
  end

  if target then
    self:CastAbilityOnTarget(target, ability, -1)
    return true
  end

  return false
end