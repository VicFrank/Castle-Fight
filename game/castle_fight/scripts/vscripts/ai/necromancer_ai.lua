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

    thisEntity.aiState = {
      aggroTarget = nil,
      targetAcquisitionRange = 900,
      stopPursuitRange = 1600,
      goal = goal,
      canHitFlying = true,
      canHitGround = true,
    }

    local raiseDeadAbilities = {
      necromancer_raise_dead = true,
      necromancer_greater_raise_dead = true,
      lich_ultimate_raise_dead = true,
    }

    for i=0,15 do
      local ability = thisEntity:GetAbilityByIndex(i)
      if ability and raiseDeadAbilities[ability:GetAbilityName()] then
        thisEntity.raisDeadAbility = ability
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

  if self:UseAbility() then return 1.0 end

  if FindAggro(self) then
    AttackTarget(self)
    return .3
  end

  MoveTowardsGoal(self)
  return .3
end

function thisEntity:UseAbility()
  local radius = self.raisDeadAbility:GetCastRange(self:GetAbsOrigin(), self)
  local corpses = Corpses:FindInRadius(self:GetTeam(), self:GetAbsOrigin(), radius)

  if self.raisDeadAbility:IsFullyCastable() and #corpses > 0 then
    self:CastRaiseDead()
    return true
  end

  return false
end

function thisEntity:CastRaiseDead()
  local ability = self.raisDeadAbility

  self:CastAbilityNoTarget(ability, -1)
end