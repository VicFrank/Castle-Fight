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
    if self:UseAbility() then return 1.5 end
    AttackTarget(self)
    return .3
  end

  MoveTowardsGoal(self)
  return .3
end

function thisEntity:UseAbility()
  local resurrection = self:FindAbilityByName("crusader_resurrection")
  local blessing = self:FindAbilityByName("crusader_blessing")

  -- Try and cast resurrection if we can
  local radius = resurrection:GetCastRange(self:GetAbsOrigin(), self)
  radius = 900
  local corpses = Corpses:FindAlliedInRadius(self:GetTeam(), self:GetAbsOrigin(), radius)

  if resurrection:IsFullyCastable() and #corpses > 0 then
    local corpseToRevive = GetRandomTableElement(corpses)
    self:CastResurrection(corpseToRevive)
    return true
  elseif blessing:IsFullyCastable() then 
    return self:TryCastBlessing()
  end

  return false
end

function thisEntity:CastResurrection(corpse)
  local ability = self:FindAbilityByName("crusader_resurrection")
  local position = corpse:GetAbsOrigin()

  self:CastAbilityOnPosition(position, ability, -1)

  -- do the revive unit logic here, instead of in the ability
  Timers:CreateTimer(.5, function()
    local owner = self:GetOwner()
    local team = self:GetTeam()

    local resurrected = CreateUnitByName(corpse.unit_name, position, true, owner, owner, team)

    resurrected:SetForwardVector(corpse:GetForwardVector())
    FindClearSpaceForUnit(resurrected, position, true)

    resurrected:EmitSound("Hero_Omniknight.GuardianAngel.Cast")
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf", PATTACH_ABSORIGIN_FOLLOW, corpse)
    Timers:CreateTimer(1.5, function()
      ParticleManager:DestroyParticle(particle, false)
    end)

    resurrected:SetNoCorpse()
    corpse:RemoveCorpse()
  end)
end

function thisEntity:TryCastBlessing()
  local ability = self:FindAbilityByName("crusader_blessing")

  -- see if there's a target for blessing
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