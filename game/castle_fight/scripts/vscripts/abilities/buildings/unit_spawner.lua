function StartSpawningUnits(keys)
  local caster = keys.caster
  local ability = keys.ability
  local parent = keys.target

  local cooldown = ability:GetCooldown(ability:GetLevel())
  local particleName = "particles/econ/generic/generic_timer/generic_timer.vpcf"
  local ringPos = caster:GetAbsOrigin()
  local ringRadius = 50

  -- Wait for the building to build before starting to spawn units
  Timers:CreateTimer(1, function()
    if parent:IsNull() then return end
    
    if not parent:IsSilenced() and not caster:HasModifier("modifier_out_of_world") and not caster:PassivesDisabled() then
      -- Building has finished construction
      -- Start the first cooldown and create the progress particle
      ability:StartCooldown(cooldown)    
      ringPos.z = caster:GetAbsOrigin().z + 25
      caster.progressParticle = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, caster)
      ParticleManager:SetParticleControl(caster.progressParticle, 0, ringPos)
      ParticleManager:SetParticleControl(caster.progressParticle, 1, Vector(ringRadius, 1 / cooldown, 1))
      
      -- Spawn units every interval, starting now until the caster dies / is upgraded
      Timers:CreateTimer(cooldown, function()
        if parent:IsNull() or not parent:IsAlive() then return end      

        if parent:HasModifier("modifier_frost_bolt_freeze") then
          return 1
        end

        -- Recreate the progress particle
        ParticleManager:DestroyParticle(caster.progressParticle, true)
        ParticleManager:ReleaseParticleIndex(caster.progressParticle)

        caster.progressParticle = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, caster)
        ParticleManager:SetParticleControl(caster.progressParticle, 0, ringPos)
        ParticleManager:SetParticleControl(caster.progressParticle, 1, Vector(ringRadius, 1 / cooldown, 1))

        -- Spawn the next unit
        SpawnUnit(keys)

        return cooldown
      end)

      -- Check to see if the parent is dead to remove particle
      Timers:CreateTimer(function()
        if not parent:IsAlive() then
          ParticleManager:DestroyParticle(caster.progressParticle, true)
          ParticleManager:ReleaseParticleIndex(caster.progressParticle)
          return 
        end
        return 0.1
      end)
      return
    end
    return 1/30
  end)
end

function SpawnUnit(keys)
  local caster = keys.caster
  local ability = keys.ability
  local parent = keys.target
  local unitName = keys.UnitName
  local numUnits = keys.NumUnits
  local playerID = parent:GetPlayerOwnerID()

  if parent:IsNull() or not parent:IsAlive() then return end

  local cooldown = ability:GetCooldown(ability:GetLevel())
  ability:StartCooldown(cooldown)

  if parent:HasModifier("modifier_call_to_arms_aura_buff") then
    if 24 > RandomInt(1,100) then
      numUnits = numUnits * 2
    end
  end

  for i=1,numUnits do
    local spawned = CreateLaneUnit(unitName, parent:GetAbsOrigin(), parent:GetTeam(), playerID)
    GameRules.numUnitsTrained[playerID] = GameRules.numUnitsTrained[playerID] + 1

    if caster:IsLegendary() then
      spawned.isLegendary = true
    end
  end
end