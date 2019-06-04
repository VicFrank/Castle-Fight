function StartSpawningUnits(keys)
  local caster = keys.caster
  local ability = keys.ability

  -- If this unit is the ghost from building helper, just return
  if caster:GetTeam() == DOTA_TEAM_NEUTRALS then return end

  local cooldown = ability:GetCooldown(ability:GetLevel())
  -- Wait for the building to build before starting to spawn units
  Timers:CreateTimer(1, function()
    if not caster:IsSilenced() then
      ability:StartCooldown(cooldown)

      -- Spawn units every interval, starting now until the caster dies / is upgraded
      Timers:CreateTimer(cooldown, function()
        if caster:IsNull() or not caster:IsAlive() then return end

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
  local unitName = keys.UnitName
  local numUnits = keys.NumUnits

  if caster:IsNull() or not caster:IsAlive() then return end

  local cooldown = ability:GetCooldown(ability:GetLevel())
  ability:StartCooldown(cooldown)

  if caster:HasModifier("modifier_call_to_arms_aura_buff") then
    if 24 > RandomInt(1,100) then
      numUnits = numUnits * 2
      print("Call to arms double spawn")
    end
  end

  for i=1,numUnits do
    local unit = CreateUnitByName(unitName, caster:GetAbsOrigin(), true, caster, caster, 0)
    unit:SetTeam(caster:GetTeam())
  end
end