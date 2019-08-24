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

    local attacksAllowed = thisEntity:GetKeyValue("AttacksAllowed")
    if attacksAllowed then
      if attacksAllowed == "ground" then
        canHitGround = true
      elseif attacksAllowed == "flying" then
        canHitFlying = true
      else
        print("Bad KV AttacksAllowed = " .. attacksAllowed .. " for " .. thisEntity:GetUnitName())
      end
    end

    local attackRange = thisEntity:GetKeyValue("AttackRange") or 0
    if attackRange == 0 then print(thisEntity:GetUnitName() .. " has no attack range") end
    local acquisitionRange = math.max(900, attackRange)

    thisEntity.aiState = {
      aggroTarget = nil,
      targetAcquisitionRange = acquisitionRange,
      stopPursuitRange = 1600,
      goal = goal,
      canHitFlying = canHitFlying,
      canHitGround = canHitGround,
      canUseMine = false,
    }

    -- wait 3 seconds before we can use the mine
    Timers:CreateTimer(3, function() thisEntity.aiState.canUseMine = true end)

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

  if self.aiState.canUseMine and UseAbility(self) then return 1.5 end

  if FindAggro(self) then
    -- print(self:GetUnitName() .. " is aggro'd onto " .. self.aiState.aggroTarget:GetUnitName())
    AttackTarget(self)
    return GetAggroThinkTime()
  end

  MoveTowardsGoal(self)
  return GetMoveToGoalThinkTime()
end