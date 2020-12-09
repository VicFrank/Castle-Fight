if not Units then
  Units = class({})
end

-- Initializes one unit with all its required modifiers and functions
function Units:Init( unit )
  if unit.bFirstSpawned and not unit:IsRealHero() then return
  else unit.bFirstSpawned = true end

  if unit:IsRealHero() then
    ApplyModifier(unit, "builder_invulnerable_modifier")
  end

  -- Apply armor and damage modifier (for visuals)
  local attack_type = unit:GetAttackType()
  if attack_type and unit:GetAttackDamage() > 0 then
    ApplyModifier(unit, "modifier_attack_".. attack_type)
  end

  local armor_type = unit:GetArmorType()
  if armor_type then
    ApplyModifier(unit, "modifier_armor_".. armor_type)
  end

  if unit:HasSplashAttack() then
    ApplyModifier(unit, "modifier_splash_attack")
  end

  local bBuilding = IsCustomBuilding(unit)

  -- Adjust Hull
  unit:AddNewModifier(nil,nil,"modifier_phased",{duration=0.1})
  local collision_size = unit:GetCollisionSize()
  if not bBuilding and collision_size then
    unit:SetHullRadius(collision_size)
  end
end

function CDOTA_BaseNPC:_GetMainControllingPlayer()
  return self.issuer_player_id or self:GetMainControllingPlayer()
end

-- Returns Int
function GetGoldCost( unit )
  if unit and IsValidEntity(unit) and unit.gold_cost then
    return unit.gold_cost
  end
  return 0
end

function ApplyModifier(unit, modifier_name)
  GameRules.Applier:ApplyDataDrivenModifier(unit, unit, modifier_name, {})
end

HULL_SIZES = {
  ["DOTA_HULL_SIZE_BARRACKS"]=144,
  ["DOTA_HULL_SIZE_BUILDING"]=81,
  ["DOTA_HULL_SIZE_FILLER"]=96,
  ["DOTA_HULL_SIZE_HERO"]=24,
  ["DOTA_HULL_SIZE_HUGE"]=80,
  ["DOTA_HULL_SIZE_REGULAR"]=16,
  ["DOTA_HULL_SIZE_SIEGE"]=16,
  ["DOTA_HULL_SIZE_SMALL"]=8,
  ["DOTA_HULL_SIZE_TOWER"]=144,
}

function CDOTA_BaseNPC:GetCollisionSize()
  local collision_size = self:GetKeyValue("CollisionSize")
  return collision_size
end

function GetOriginalModelScale( unit )
  return GameRules.UnitKV[unit:GetUnitName()]["ModelScale"] or unit:GetModelScale()
end

function SetRangedProjectileName( unit, pProjectileName )
  unit:SetRangedProjectileName(pProjectileName)
  unit.projectileName = pProjectileName
end

function GetOriginalRangedProjectileName( unit )
  return unit:GetKeyValue("ProjectileModel") or ""
end

function GetRangedProjectileName( unit )
  return unit.projectileName or unit:GetKeyValue("ProjectileModel") or ""
end

function IsCustomBuilding(unit)
  return unit:HasModifier("modifier_building")
end

function CDOTA_BaseNPC:GetMovementCapability()
  return self:HasFlyMovementCapability() and "air" or "ground"
end

function CDOTA_BaseNPC:HasSecondaryAttack()
  return self:GetSecondaryAttackTable()
end

function CDOTA_BaseNPC:IsFlyingUnit()
  return self:GetKeyValue("MovementCapabilities") == "DOTA_UNIT_CAP_MOVE_FLY"
end

function CDOTA_BaseNPC:SetAttackRange(value)
  if self:HasModifier("modifier_attack_range") then
    self:RemoveModifierByName("modifier_attack_range")
  end

  self:AddNewModifier(self, nil, "modifier_attack_range", {range = value})
end

-- Shortcut for a very common check
function IsValidAlive(unit)
  return (IsValidEntity(unit) and unit:IsAlive())
end

-- Auxiliary function that goes through every ability and item, checking for any
-- ability being channelled
function IsChanneling (unit)
  for abilitySlot=0,15 do
    local ability = unit:GetAbilityByIndex(abilitySlot)
    if ability and ability:IsChanneling() then 
      return ability
    end
  end

  for itemSlot=0,5 do
    local item = unit:GetItemInSlot(itemSlot)
    if item and item:IsChanneling() then
      return ability
    end
  end

  return false
end

-- Returns all visible enemies in radius of the unit/point
function FindEnemiesInRadius( unit, radius, point )
  local team = unit:GetTeamNumber()
  local position = point or unit:GetAbsOrigin()
  local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
  return FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_CLOSEST, false)
end

function FindEnemiesInRadiusFromTeam( team, radius, point )
  local position = point
  local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
  return FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_CLOSEST, false)
end

-- Includes enemies that aren't visible
function FindAllEnemiesInRadius( unit, radius, point )
  local team = unit:GetTeamNumber()
  local position = point or unit:GetAbsOrigin()
  local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
  return FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_CLOSEST, false)
end

-- Returns all units (friendly and enemy) in radius of the unit/point
function FindAllUnitsInRadius( radius, point )
  local position = point
  local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
  return FindUnitsInRadius(DOTA_TEAM_NEUTRALS, position, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, target_type, flags, FIND_ANY_ORDER, false)
end

function FindAllUnits()
  local position = Vector(0,0,0)
  local target_type = DOTA_UNIT_TARGET_ALL
  local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE
  return FindUnitsInRadius(DOTA_TEAM_NEUTRALS, position, nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_BOTH, target_type, flags, FIND_ANY_ORDER, false)
end

function FindAllVisibleUnitsInRadius( team, radius, point )
  local position = point
  local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
  return FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, target_type, flags, FIND_ANY_ORDER, false)
end

-- Returns all units in radius of a point
function FindAllUnitsAroundPoint( unit, point, radius )
  local team = unit:GetTeamNumber()
  local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
  return FindUnitsInRadius(team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, target_type, flags, FIND_ANY_ORDER, false)
end

function FindAlliesInRadius( unit, radius, point )
  local team = unit:GetTeamNumber()
  local position = point or unit:GetAbsOrigin()
  local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = DOTA_UNIT_TARGET_FLAG_NONE
  return FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, target_type, flags, FIND_ANY_ORDER, false)
end

-- Filters buildings and mechanical units
function FindOrganicAlliesInRadius( unit, radius, point )
  local team = unit:GetTeamNumber()
  local position = point or unit:GetAbsOrigin()
  local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = DOTA_UNIT_TARGET_FLAG_NONE
  local allies = FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, target_type, flags, FIND_CLOSEST, false)
  local organic_allies = {}
  for _,ally in pairs(allies) do
    if not IsCustomBuilding(ally) and not ally:IsMechanical() then
      table.insert(organic_allies, ally)
    end
  end
  return organic_allies
end

-- Returns the first unit that passes the filter
function FindFirstUnit(list, filter)
  for _,unit in ipairs(list) do
    if filter(unit) then
      return unit
    end
  end
end

-- Returns all visible enemy units  (not buildings or tentacles)
function FindAllVisibleEnemies(team)
  local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
  local enemies = FindUnitsInRadius(team, Vector(0,0,0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags, FIND_ANY_ORDER, false)
  local notBuildings = {}  
  for _,enemy in pairs(enemies) do
    if not IsCustomBuilding(enemy) and not (enemy:GetUnitName() == "tentacle_prison_tentacle") then
      table.insert(notBuildings, enemy)
    end
  end
  return notBuildings
end

-- Same as Find All Visible Enemies, but includes those in fog
function FindAllEnemies(team)
  local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS
  local enemies = FindUnitsInRadius(team, Vector(0,0,0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags, FIND_ANY_ORDER, false)
  local notBuildings = {}  
  for _,enemy in pairs(enemies) do
    if not IsCustomBuilding(enemy) and not (enemy:GetUnitName() == "tentacle_prison_tentacle") then
      table.insert(notBuildings, enemy)
    end
  end
  return notBuildings
end

function GetRandomVisibleEnemy(team)
  local enemies = FindAllVisibleEnemies(team)
  return GetRandomTableElement(enemies)
end

function GetRandomEnemy(team)
  local enemies = FindAllEnemies(team)
  return GetRandomTableElement(enemies)
end

function GetRandomVisibleEnemyWithFilter(team, filter)
  local enemies = FindAllVisibleEnemies(team)
  local filteredEnemies = {}
  for _,enemy in pairs(enemies) do
    if filter(enemy) then
      table.insert(filteredEnemies, enemy)
    end
  end  
  return GetRandomTableElement(filteredEnemies)
end

function CreateLaneUnit(unitname, position, team, playerID)
  local unit = CreateUnitByName(unitname, position, true, nil, nil, team)
  unit.playerID = playerID
  if not playerID then
    print(unitname .. " created without playerID")
  end
  -- local playerName = PlayerResource:GetPlayerName(playerID)
  -- unit:SetCustomHealthLabel(playerName, 255, 255, 255)
  return unit
end

function ReplaceUnit( unit, new_unit_name )
  --print("Replacing "..unit:GetUnitName().." with "..new_unit_name)

  local hero = unit:GetOwner()
  local playerID = hero:GetPlayerOwnerID()

  local position = unit:GetAbsOrigin()
  local relative_health = unit:GetHealthPercent() * 0.01
  local fv = unit:GetForwardVector()
  local new_unit = CreateUnitByName(new_unit_name, position, true, hero, hero, hero:GetTeamNumber())
  new_unit:SetOwner(hero)
  new_unit:SetControllableByPlayer(playerID, true)
  new_unit:SetHealth(new_unit:GetMaxHealth() * relative_health)
  new_unit:SetForwardVector(fv)
  FindClearSpaceForUnit(new_unit, position, true)

  if PlayerResource:IsUnitSelected(playerID, unit) then
    PlayerResource:AddToSelection(playerID, new_unit)
  end

  -- Add the new unit to the player units
  Players:AddUnit(playerID, new_unit)

  -- Remove replaced unit from the game
  Players:RemoveUnit(playerID, unit)
  unit:CustomRemoveSelf()

  return new_unit
end

function IsAlliedUnit( unit, target )
  return (unit:GetTeamNumber() == target:GetTeamNumber())
end

function CDOTA_BaseNPC:HasArtilleryAttack()
  return self:GetKeyValue("Artillery")
end

function CDOTA_BaseNPC:HasSplashAttack()
  return self:GetKeyValue("SplashAttack")
end

function CDOTA_BaseNPC:HasDeathAnimation()
  return self:GetKeyValue("HasDeathAnimation")
end

function CDOTA_BaseNPC:IsDummy()
  return self:GetUnitName():match("dummy_") or self:GetUnitLabel():match("dummy")
end

function CDOTA_BaseNPC:GetBuildingType()
  return self:GetKeyValue("BuildingType")
end

-- All units should have DOTA_COMBAT_CLASS_ATTACK_HERO and DOTA_COMBAT_CLASS_DEFEND_HERO, or no CombatClassAttack/ArmorType defined
-- Returns a string with the wc3 damage name
function CDOTA_BaseNPC:GetAttackType()
  return self.AttackType or self:GetKeyValue("AttackType")
end

-- Returns a string with the wc3 armor name
function CDOTA_BaseNPC:GetArmorType()
  return self.ArmorType or self:GetKeyValue("ArmorType")
end

-- Changes the AttackType and current visual tooltip of the unit
function CDOTA_BaseNPC:SetAttackType( attack_type )
  local current_attack_type = self:GetAttackType()
  self:RemoveModifierByName("modifier_attack_"..current_attack_type)
  self.AttackType = attack_type
  ApplyModifier(self, "modifier_attack_"..attack_type)
end

function CDOTA_BaseNPC:IsMechanical()
  return self:GetUnitLabel():match("mechanical")
end

function CDOTA_BaseNPC:IsElemental()
  return self:GetUnitLabel():match("elemental")
end

function CDOTA_BaseNPC:IsElementalBuilding()
  return self:GetUnitLabel():match("elemental_building")
end

function CDOTA_BaseNPC:IsLegendary()
  return self.isLegendary
end

-- Changes the ArmorType and current visual tooltip of the unit
function CDOTA_BaseNPC:SetArmorType( armor_type )
  local current_armor_type = self:GetArmorType()
  if current_armor_type then
    self:RemoveModifierByName("modifier_armor_"..current_armor_type)
  end
  self.ArmorType = armor_type
  ApplyModifier(self, "modifier_armor_"..armor_type)
end

-- Returns the damage factor this unit does against another
function CDOTA_BaseNPC:GetAttackFactorAgainstTarget( unit )
  local attack_type = self:GetAttackType()
  local armor_type = unit:GetArmorType()
  local damageTable = GameRules.Damage
  return damageTable[attack_type] and damageTable[attack_type][armor_type] or 1
end

-- Calls remove self and also decrements the unit counter
function CDOTA_BaseNPC:CustomRemoveSelf()
  self:RemoveSelf()
  GameRules.numUnits = GameRules.numUnits - 1
  CustomGameEventManager:Send_ServerToAllClients("num_units_changed",
    {numUnits = GameRules.numUnits})
end

function CDOTA_BaseNPC:CustomGetPlayerOwnerID()
  return self.playerID or self:GetPlayerOwnerID()
end

function CDOTA_BaseNPC:GetPlayerHero()
  local playerID = self:CustomGetPlayerOwnerID()

  if playerID < 0 then playerID = 0 end
  if not playerID then return nil end

  return GameRules.heroList[playerID]
end

-- MODIFIER_PROPERTY_HEALTH_BONUS doesn't work on npc_dota_creature
function CDOTA_BaseNPC_Creature:IncreaseMaxHealth(bonus)
  local newHP = self:GetMaxHealth() + bonus
  local relativeHP = self:GetHealthPercent() * 0.01
  if relativeHP == 0 then return end
  self:SetMaxHealth(newHP)
  self:SetBaseMaxHealth(newHP)
  self:SetHealth(newHP * relativeHP)
end