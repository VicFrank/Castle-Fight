require("ai/general_ai")
require("ai/ai_multipliers")

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

  if self:CastHealAbility() then return 1.0 end
  
  if FindAggro(self) then
    AttackTarget(self)
    return GetAggroThinkTime()
  end

  MoveTowardsGoal(self)
  return GetMoveToGoalThinkTime()
end

function thisEntity:CastHealAbility()
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
  if not ability:IsFullyCastable() then return false end
  
  -- see if there's an ally to heal
  local castRange = ability:GetCastRange(self:GetAbsOrigin(), self)
  local target

  if castRange then
    local targets = FindAlliesInRadius(self, castRange)

    target = FindFirstUnit(targets, function(target) 
      return not IsCustomBuilding(target) and target:GetHealth() < target:GetMaxHealth() * 0.75 and not target.wasHealed
    end)
  end

  if target then
    self:CastAbilityOnTarget(target, ability, -1)
    target.wasHealed = true
    Timers:CreateTimer(2, function()
      if not target:IsNull() and target and target:IsAlive() then
        target.wasHealed = false
      end
    end)
    return true
  end

  return false
end