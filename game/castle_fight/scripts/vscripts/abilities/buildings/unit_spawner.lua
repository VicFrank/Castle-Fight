function StartSpawningUnits(keys)
  local caster = keys.caster
  local ability = keys.ability
  local parent = keys.target

  local cooldown = ability:GetCooldown(ability:GetLevel())
  -- Wait for the building to build before starting to spawn units
  Timers:CreateTimer(1, function()
    if parent:IsNull() then return end
    
    if not parent:IsSilenced() and not caster:HasModifier("modifier_out_of_world") then
      ability:StartCooldown(cooldown)
      
      -- Spawn units every interval, starting now until the caster dies / is upgraded
      Timers:CreateTimer(cooldown, function()
        if parent:IsNull() or not parent:IsAlive() then return end

        SpawnUnit(keys)

        return cooldown
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
    print("has call to arms buff")
    if 24 > RandomInt(1,100) then
      numUnits = numUnits * 2
      print("Call to arms double spawn")
    end
  end

  for i=1,numUnits do
    CreateLaneUnit(unitName, parent:GetAbsOrigin(), parent:GetTeam(), playerID)
    GameRules.numUnitsTrained[playerID] = GameRules.numUnitsTrained[playerID] + 1
  end
end