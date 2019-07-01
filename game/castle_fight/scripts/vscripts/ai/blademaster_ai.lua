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

  if FindAggro(self) then
    if self:CastSpellSteal() then return 0.6 end
    AttackTarget(self)
    return .3
  end

  MoveTowardsGoal(self)
  return .3
end

function thisEntity:CastSpellSteal()
  local ability = self:FindAbilityByName("blademaster_spell_steal")

  if not ability or not ability:IsFullyCastable() then return false end
  
  local castRange = ability:GetCastRange(self:GetAbsOrigin(), self)
  local units = FindAllVisibleUnitsInRadius(self:GetTeam(), castRange, self:GetAbsOrigin())

  for _,unit in pairs(units) do
    if HasModifierToSteal(unit) then
      self:CastAbilityOnTarget(unit, ability, -1)
      return true
    end
  end

  return false
end

function HasModifierToSteal(unit)
  local targetIsFriendly = unit:GetTeam() == unit:GetTeam()
  local modifiers = unit:FindAllModifiers()

  -- Get the modifier to remove
  local modifier

  for _,buff in pairs(modifiers) do
    -- if it's an ally, get a debuff
    if buff.IsDebuff then
      if targetIsFriendly then
        if buff:IsDebuff() and buff:IsPurgable() then
          modifier = buff
          return true
        end
      -- if it's an enemy, get a buff
      elseif not buff:IsDebuff() and buff:IsPurgable() then
        modifier = buff
        return true
      end
    end
  end

  return false
end