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

function CDOTA_BaseNPC:CheckSecondaryAttackAgainst(target)
  local secondaryAttackTable = self:GetSecondaryAttackTable()
  if secondaryAttackTable then
    local used_against = secondaryAttackTable["UsedAgainst"]
    if used_against == "building" and IsCustomBuilding(target) then
      self:SwapToSecondaryAttack()
      return
    end
    local target_type = target:GetMovementCapability()
    if used_against == target_type then
      self:SwapToSecondaryAttack()
      return
    end
    self:SwapToPrimaryAttack()
  end
end

AttackCapabilities = {
  ["DOTA_UNIT_CAP_NO_ATTACK"] = 0,
  ["DOTA_UNIT_CAP_MELEE_ATTACK"] = 1,
  ["DOTA_UNIT_CAP_RANGED_ATTACK"] = 2,
}

function CDOTA_BaseNPC:SwapToSecondaryAttack()
  if self.usingSecondaryAttack then return end
  local secondaryAttackTable = self:GetSecondaryAttackTable()
  self:SetAttackCapability(AttackCapabilities[secondaryAttackTable.AttackCapabilities])
  self:SetAttackType(secondaryAttackTable.AttackType)
  self:SetBaseDamageMin(secondaryAttackTable.AttackDamageMin)
  self:SetBaseDamageMax(secondaryAttackTable.AttackDamageMax)
  self:SetBaseAttackTime(secondaryAttackTable.AttackRate)
  self:SetAttackRange(secondaryAttackTable.AttackRange)
  if secondaryAttackTable.ProjectileModel then
    self:SetRangedProjectileName(secondaryAttackTable.ProjectileModel)
  end
  self.usingSecondaryAttack = true
end

function CDOTA_BaseNPC:SwapToPrimaryAttack()
  if not self.usingSecondaryAttack then return end
  self:SetAttackCapability(AttackCapabilities[self:GetKeyValue("AttackCapabilities")])
  self:SetAttackType(self:GetKeyValue("AttackType"))
  self:SetBaseDamageMin(self:GetKeyValue("AttackDamageMin"))
  self:SetBaseDamageMax(self:GetKeyValue("AttackDamageMax"))
  self:SetBaseAttackTime(self:GetKeyValue("AttackRate"))
  self:SetAttackRange(self:GetKeyValue("AttackRange"))
  if self:GetKeyValue("ProjectileModel") then
    self:SetRangedProjectileName(self:GetKeyValue("ProjectileModel"))
  end
  self.usingSecondaryAttack = false
end

function CDOTA_BaseNPC:SetSecondaryAttackTable(attackTable)
  self.secondaryAttackTable = attackTable
end

function CDOTA_BaseNPC:GetSecondaryAttackTable()
  return self.secondaryAttackTable or self:GetKeyValue("SecondaryAttack")
end