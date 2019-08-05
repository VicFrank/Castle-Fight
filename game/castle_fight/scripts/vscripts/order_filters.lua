function GameMode:OrderFilter(filterTable)
  -- for k, v in pairs( filterTable ) do
  --  print("Order: " .. k .. " " .. tostring(v) )
  -- end

  local issuer_player_id_const = filterTable["issuer_player_id_const"]
  local units = filterTable["units"]

  for _,entindex in pairs(units) do
    local unit = EntIndexToHScript(entindex)
    if issuer_player_id_const < 0 then
      unit.issuer_player_id = nil
    else
      unit.issuer_player_id = issuer_player_id_const
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