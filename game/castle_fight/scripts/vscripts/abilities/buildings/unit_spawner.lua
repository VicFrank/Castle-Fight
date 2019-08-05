LinkLuaModifier("modifier_power_buildings_creep_buff", "abilities/mech/power_buildings.lua", LUA_MODIFIER_MOTION_NONE)

function SpawnUnits(keys)
  local caster = keys.caster
  local ability = keys.ability
  local unitName = keys.UnitName
  local numUnits = keys.NumUnits
  local playerID = caster:GetPlayerOwnerID()

  if caster:IsNull() or not caster:IsAlive() then return end

  local cooldown = ability:GetCooldown(ability:GetLevel())
  local increased_cooldown = math.floor(GameRules.roundSeconds / 150)
  ability:StartCooldown(cooldown + increased_cooldown)

  local particleName = "particles/econ/generic/generic_timer/generic_timer.vpcf"
  local ringRadius = 50

  if caster.progressParticle then
    ParticleManager:DestroyParticle(caster.progressParticle, true)
    ParticleManager:ReleaseParticleIndex(caster.progressParticle)
  end

  caster.progressParticle = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, caster)
  ParticleManager:SetParticleControl(caster.progressParticle, 1, Vector(ringRadius, 1 / cooldown, 1))

  if caster:HasModifier("modifier_call_to_arms_aura_buff") then
    if 24 >= RandomInt(1,100) then
      numUnits = numUnits * 2
    end
  end

  for i=1,numUnits do
    local spawned = CreateLaneUnit(unitName, caster:GetAbsOrigin(), caster:GetTeam(), playerID)
    GameRules.numUnitsTrained[playerID] = GameRules.numUnitsTrained[playerID] + 1

    if caster:IsLegendary() then
      spawned.isLegendary = true
    end

    if caster:HasModifier("modifier_power_buildings_aura_buff") then
      -- buff the spawned unit
      local powerBuildingsModifier = caster:FindModifierByName("modifier_power_buildings_aura_buff")
      local powerBuildingsAbility = powerBuildingsModifier:GetAbility()
      spawned:AddNewModifier(caster, powerBuildingsAbility, "modifier_power_buildings_creep_buff", {})
    end
  end
end