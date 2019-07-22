-- Deals damage based on the attacker around a position, with full/medium/small factors based on distance from the impact
function SplashAttackGround(attacker, position)
  SplashAttackUnit(attacker, position)
  
  -- Hit ground particle. This could be each particle endcap instead
  local hit = ParticleManager:CreateParticle("particles/units/heroes/hero_magnataur/magnus_dust_hit.vpcf", PATTACH_CUSTOMORIGIN, attacker)
  ParticleManager:SetParticleControl(hit, 0, position)
end

function SplashAttackUnit(attacker, position)
  local full_damage_radius = attacker:GetKeyValue("SplashFullRadius") or 0
  local medium_damage_radius = attacker:GetKeyValue("SplashMediumRadius") or 0
  local small_damage_radius = attacker:GetKeyValue("SplashSmallRadius") or 0

  local full_damage = attacker:GetAttackDamage()
  local medium_damage = full_damage * attacker:GetKeyValue("SplashMediumDamage") or 0
  local small_damage = full_damage * attacker:GetKeyValue("SplashSmallDamage") or 0
  medium_damage = medium_damage + small_damage -- Small damage gets added to the mid aoe

  local splash_targets = FindAllUnitsAroundPoint(attacker, position, small_damage_radius)
  if DEBUG then
    DebugDrawCircle(position, Vector(255,0,0), 50, full_damage_radius, true, 3)
    DebugDrawCircle(position, Vector(255,0,0), 50, medium_damage_radius, true, 3)
    DebugDrawCircle(position, Vector(255,0,0), 50, small_damage_radius, true, 3)
  end

  local canHitFlying = true
  if attacker:GetKeyValue("AttacksDisallowed") == "flying" then
    canHitFlying = false
  end

  for _,unit in pairs(splash_targets) do
    local isValidTarget = true

    if not canHitFlying and unit:HasFlyMovementCapability() then
      isValidTarget = false
    end

    if unit:GetTeam() == attacker:GetTeam() then
      isValidTarget = false
    end
    
    if isValidTarget then
      local distance_from_impact = (unit:GetAbsOrigin() - position):Length2D()
      if distance_from_impact <= full_damage_radius then
        ApplyDamage({ victim = unit, attacker = attacker, damage = full_damage, ability = GameRules.Applier, damage_type = DAMAGE_TYPE_PHYSICAL})
      elseif distance_from_impact <= medium_damage_radius then
        ApplyDamage({ victim = unit, attacker = attacker, damage = medium_damage, ability = GameRules.Applier, damage_type = DAMAGE_TYPE_PHYSICAL})
      else
        ApplyDamage({ victim = unit, attacker = attacker, damage = small_damage, ability = GameRules.Applier, damage_type = DAMAGE_TYPE_PHYSICAL})
      end
    end
  end
end