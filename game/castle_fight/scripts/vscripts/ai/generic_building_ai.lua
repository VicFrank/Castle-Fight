require("ai/general_ai")

function Spawn(keys)
  -- Wait one frame to do logic on a spawned unit
  Timers:CreateTimer(.1, function()   
    thisEntity.finishedConstruction = false

    -- Get all of the unit's abilities
    thisEntity.abilityList = {}
    for i=0,15 do
      local ability = thisEntity:GetAbilityByIndex(i)
      if ability and not ability:IsPassive() then
        table.insert(thisEntity.abilityList, ability)
        -- Toggle auto cast on
        if hasbit(ability:GetBehavior(), DOTA_ABILITY_BEHAVIOR_AUTOCAST) then
          ability:ToggleAutoCast()
          local cooldown = ability:GetCooldown(ability:GetLevel())
          ability:StartCooldown(cooldown)
        end
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

  -- Keep abilities on cooldown until they're done building
  if not self.finishedConstruction then
    if self.IsUnderConstruction and self:IsUnderConstruction() then
      for _,ability in pairs(self.abilityList) do
        local cooldown = ability:GetCooldown(ability:GetLevel())
        ability:StartCooldown(cooldown)
      end

      return 0.1
    else
      self.finishedConstruction = true

      -- Create the timer particle for the initial countdown
      for _,ability in pairs(self.abilityList) do
        local cooldown = ability:GetCooldown(ability:GetLevel())

        if startsWith(ability:GetAbilityName(), "train_") then
          local particleName = "particles/econ/generic/generic_timer/generic_timer.vpcf"
          local ringRadius = 50

          self.progressParticle = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, self)
          ParticleManager:SetParticleControl(self.progressParticle, 1, Vector(ringRadius, 1 / cooldown, 1))
        end
      end
    end
  end

  return self:UseAutoCastAbility()
end

function thisEntity:UseAutoCastAbility()
  local ability = GetRandomTableElement(self.abilityList)

  if ability:IsFullyCastable() and ability:GetAutoCastState() and
    not self:IsChanneling() and hasbit(ability:GetBehavior(), DOTA_ABILITY_BEHAVIOR_AUTOCAST) then
    self:CastAbilityNoTarget(ability, -1)
  end

  return 0.1
end

function hasbit(x, p)
  return x % (p + p) >= p       
end