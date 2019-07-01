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

    thisEntity.aiState = {
      aggroTarget = nil,
      targetAcquisitionRange = 1200,
      stopPursuitRange = 1600,
      goal = goal,
      canHitFlying = canHitFlying,
      canHitGround = canHitGround,
      spawnLocation = thisEntity:GetAbsOrigin(),
      retreating = true,
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

  -- While invisible, seek out and kill a mage, or wait for one to appear
  -- if self:IsInvisible() then
  --   self:FindAndAttackMage()
  --   return .3
  -- end

  if self:GoInvisible() then
    return 0.5
  end

  if FindAggro(self) then
    -- print(self:GetUnitName() .. " is aggro'd onto " .. self.aiState.aggroTarget:GetUnitName())
    AttackTarget(self)
    return .3
  end

  MoveTowardsGoal(self)
  return .3
end

function thisEntity:GoInvisible()
  local ability = self:FindAbilityByName("assassin_backstab")

  if ability:IsFullyCastable() then
    self:CastAbilityNoTarget(ability, -1)
    return true
  end

  return false
end

function thisEntity:FindAndAttackMage()
  local enemies = FindEnemiesInRadius(self, FIND_UNITS_EVERYWHERE)

  for _,enemy in ipairs(enemies) do
    if enemy:GetMana() > 0 then
      self.aiState.aggroTarget = enemy
      AttackTarget(self)
      return true
    end
  end

  return false
end