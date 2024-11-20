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

  return self:RepairBuildings()
end

function thisEntity:RepairBuildings()
  if self.currentRepair and not self.currentRepair:IsNull() and self.currentRepair:IsAlive() and self.currentRepair:GetHealthPercent() < 100 then
    return 0.3
  end

  local repairTarget = self:GetUnitToRepair()

  if self.currentRepair and self.currentRepair == repairTarget then
    return 0.3
  end

  self.currentRepair = repairTarget

  if repairTarget == nil then
    return 0.5
  end

  BuildingHelper:AddRepairToQueue(self, repairTarget, false)

  return 2
end

function thisEntity:GetUnitToRepair()
  local allies = FindAlliesInRadius(self, FIND_UNITS_EVERYWHERE)

  local lowestHealthAlly
  local minHealthPercent = 100

  for _,ally in pairs(allies) do
    if IsCustomBuilding(ally) or ally:IsMechanical() then
      local distance = GetDistanceBetweenTwoUnits(self, ally)
      local healthPercentage = ally:GetHealthPercent()
      local underConstruction = not ally:GetUnitName() == "castle" and ally:IsUnderConstruction()
      local hasTakenDamage = false
      if underConstruction then
        local constructionHealth = ally.initialHealth + ally.addedHealth
        if ally:GetHealth() < constructionHealth then
          hasTakenDamage = true
        end
      else
        hasTakenDamage = healthPercentage < minHealthPercent
      end

      if distance < 4000 and hasTakenDamage then
        minHealthPercent = healthPercentage
        lowestHealthAlly = ally
      end
    end
  end

  return lowestHealthAlly
end