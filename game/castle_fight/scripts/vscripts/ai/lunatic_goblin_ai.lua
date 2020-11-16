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

    local attackRange = thisEntity:GetKeyValue("AttackRange") or 0
    if attackRange == 0 then print(thisEntity:GetUnitName() .. " has no attack range") end
    local acquisitionRange = math.max(900, attackRange)

    thisEntity.aiState = {
      aggroTarget = nil,
      targetAcquisitionRange = acquisitionRange,
      stopPursuitRange = 1600,
      goal = goal,
      canHitFlying = false,
      canHitGround = true,
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
    MoveToAggroTarget(self)
    if GetDistanceBetweenTwoUnits(self, self.aiState.aggroTarget) < 150 then
      local ability = self:FindAbilityByName("lunatic_goblin_suicide")

      if ability:IsFullyCastable() and not ability:IsInAbilityPhase() then
        self:CastAbilityNoTarget(ability, -1)
        return 0.6
      end
    end
    return GetAggroThinkTime()
  end

  MoveTowardsGoal(self)
  return GetMoveToGoalThinkTime()
end