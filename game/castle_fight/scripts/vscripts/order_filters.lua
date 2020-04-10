require('abilities/buildings/upgrades')

function GameMode:OrderFilter(filterTable)
  -- for k, v in pairs( filterTable ) do
  --  print("Order: " .. k .. " " .. tostring(v) )
  -- end

  local playerID = filterTable["issuer_player_id_const"]
  local units = filterTable["units"]
  local orderType = filterTable["order_type"]
  local entindex_ability = filterTable["entindex_ability"]
  local ability = nil

  if entindex_ability ~= nil then
    ability = EntIndexToHScript(entindex_ability)
  end

  local selectedEntities = PlayerResource:GetSelectedEntities(playerID)
  local mainSelectedEntity = PlayerResource:GetMainSelectedEntity(playerID)
  local firstUnit = nil

  if mainSelectedEntity ~= nil then
    firstUnit = EntIndexToHScript(mainSelectedEntity)
  end

  -- Record the time of the order
  GameRules.PlayerOrderTime[playerID] = GameRules:GetGameTime()

  -- Get the source of the command so we can properly use leavers to build buildings
  for _,entindex in pairs(units) do
    local unit = EntIndexToHScript(entindex)

    if playerID < 0 then
      unit.issuer_player_id = nil
    else
      unit.issuer_player_id = playerID
    end

    -- Handle group commands

    if orderType == DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO then
      -- toggle all selected buildings to match the main one
      local autoCastState = not ability:GetAutoCastState()

      for _,selectedUnitEntindex in pairs(selectedEntities) do
        local selectedUnit = EntIndexToHScript(selectedUnitEntindex)
        local abilityToToggle = selectedUnit:GetAbilityByIndex(ability:GetAbilityIndex())

        if abilityToToggle:GetAutoCastState() ~= autoCastState then
          abilityToToggle:ToggleAutoCast()
        end
      end

      -- We did the toggle above, return here so we don't double toggle
      return false
    elseif orderType == DOTA_UNIT_ORDER_CAST_NO_TARGET then
      -- if the ability is an upgrade ability
      -- upgrade as many buildings of the same type as possible
      local abilityName = ability:GetAbilityName()
      local isUpgradeAbility = startsWith(abilityName, "upgrade_")

      if isUpgradeAbility then
        for i,selectedUnitEntindex in pairs(selectedEntities) do
          local selectedUnit = EntIndexToHScript(selectedUnitEntindex)
          local abilityToCast = selectedUnit:GetAbilityByIndex(ability:GetAbilityIndex())
          -- Skip the main unit (we're already issuing this order)
          if not i ~= "0" and selectedUnit:GetUnitName() == unit:GetUnitName() then
            selectedUnit:CastAbilityNoTarget(abilityToCast, playerID)
          end
        end
      end
    end
  end

  return true
end

-- Lifted from DotaCraft
function GameMode:FilterDamage( filterTable )
  -- for k, v in pairs( filterTable ) do
  --  print("Damage: " .. k .. " " .. tostring(v) )
  -- end

  local victim_index = filterTable["entindex_victim_const"]
  local attacker_index = filterTable["entindex_attacker_const"]
  if not victim_index or not attacker_index then
    return true
  end

  local victim = EntIndexToHScript( victim_index )
  local attacker = EntIndexToHScript( attacker_index )
  local damagetype = filterTable["damagetype_const"]
  local inflictor = filterTable["entindex_inflictor_const"]

  local value = filterTable["damage"] --Post reduction
  local damage, reduction = GameMode:GetPreMitigationDamage(value, victim, attacker, damagetype) --Pre reduction

  -- Filter out cleave attacks on air units
  if inflictor then
    local ability = EntIndexToHScript(inflictor)
    if ability.GetAbilityName then
      local abilityName = ability:GetAbilityName()
      local ending = "cleave"
      local isCleave = abilityName:sub(-#ending) == ending
      local dontCleave = victim:HasFlyMovementCapability() or IsCustomBuilding(victim)

      if isCleave and dontCleave then
        return false
      end
    end
  end

  -- Physical attack damage filtering
  if damagetype == DAMAGE_TYPE_PHYSICAL then
    if victim == attacker and not inflictor then return end -- Self attack, for fake attack ground

    if attacker:HasSplashAttack() and not inflictor then
      SplashAttackUnit(attacker, victim:GetAbsOrigin())
      return false
    end

    -- Apply custom armor reduction
    local attack_damage = damage
    local attack_type  = attacker:GetAttackType()
    local armor_type = victim:GetArmorType()
    local multiplier = attacker:GetAttackFactorAgainstTarget(victim)
    local armor = victim:GetPhysicalArmorValue(false)
    local wc3Reduction = (armor * 0.06) / (1 + (armor * 0.06))

    damage = (attack_damage * (1 - wc3Reduction)) * multiplier

    -- print(string.format("Damage (%s attack vs %.f %s armor): (%.f * %.2f) * %.2f = %.f", attack_type, armor, armor_type, attack_damage, 1-wc3Reduction, multiplier, damage))

    -- Reassign the new damage
    filterTable["damage"] = damage
  end

  return true
end

function GameMode:GetPreMitigationDamage(value, victim, attacker, damagetype)
  if damagetype == DAMAGE_TYPE_PHYSICAL then
    local armor = victim:GetPhysicalArmorValue(false)
    -- 1 - ((0.052 × armor) ÷ (0.9 + 0.048 × |armor|))
    local reduction = ((0.052 * armor) / (0.9 + 0.048 * math.abs(armor)))
    local damage = value / (1 - reduction)

    return damage, reduction

  elseif damagetype == DAMAGE_TYPE_MAGICAL then
    local reduction = victim:GetMagicalArmorValue() * 0.01
    local damage = value / (1 - reduction)

    return damage, reduction
  else
    return value, 0
  end
end