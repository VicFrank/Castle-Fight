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

  --While invisible, seek out and kill a mage, or wait for one to appear
  if self:IsInvisible() then
    return self:FindAndAttackMage()
  end

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

  if ability:IsFullyCastable() and not self:IsInvisible() then
    self:CastAbilityNoTarget(ability, -1)
    return true
  end

  return false
end

function thisEntity:GetInvisTargetPriority(enemy)
  -- units with mana and light armor
  if enemy:GetMana() > 0 and enemy:HasModifier("modifier_armor_light") then
    return 0
  end
  -- units with mana unarmored
  if enemy:GetMana() > 0 and enemy:HasModifier("modifier_armor_unarmored") then
    return 1
  end
  -- units with less than some hp amount (350)
  if enemy:GetHealth() < 350 then
    return 2
  end
  -- units with mana another armor type
  if enemy:GetMana() > 0 then
    return 3
  end
  -- units with light armor
  if enemy:HasModifier("modifier_armor_light") then
    return 4
  end
  -- units unarmored
  if enemy:HasModifier("modifier_armor_unarmored") then
    return 5
  end
  -- units with other armor type and lot of hp
  return 6
end

function thisEntity:FindTarget()
  local enemies = FindEnemiesInRadius(self, FIND_UNITS_EVERYWHERE)

  -- filter out buildings
  local notBuildings = {}
  for _,enemy in ipairs(enemies) do
    if not IsCustomBuilding(enemy) and not enemy:HasFlyMovementCapability() then
      table.insert(notBuildings, enemy)
    end
  end
  enemies = notBuildings

  local target
  local currentTargetPriority = 999

  for _,enemy in ipairs(enemies) do
    local priority = self:GetInvisTargetPriority(enemy)
    if priority == 0 then
      return enemy
    end
    if priority < currentTargetPriority then
      target = enemy
      currentTargetPriority = priority
    end
  end

  return target
end

function thisEntity:FindAndAttackMage()
  local target = self:FindTarget()

  if target then
    self.aiState.aggroTarget = target
    AttackTarget(self)
    return 0.3
  end

  return 0.5
end