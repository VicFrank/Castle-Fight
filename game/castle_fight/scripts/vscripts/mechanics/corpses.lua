if not Corpses then
  Corpses = class({})
end

function Corpses:CreateFromUnit(killed)
  if LeavesCorpse( killed ) then
    local name = killed:GetUnitName()
    local position = killed:GetAbsOrigin()
    local fv = killed:GetForwardVector()
    local team = killed:GetTeamNumber()
    local corpse = Corpses:CreateByNameOnPosition(name, position, team)
    corpse.playerID = killed:GetPlayerOwnerID()
    corpse.isLegendary = killed.isLegendary
    corpse:SetForwardVector(fv)
    corpse:AddNoDraw()
    Timers:CreateTimer(CORPSE_APPEAR_DELAY, function()
      if IsValidEntity(corpse) then
        UTIL_Remove(killed)
        -- corpse:RemoveNoDraw()
      end
    end)
  end
end

function Corpses:CreateByNameOnPosition(name, position, team)
  local corpse = CreateUnitByName("dotacraft_corpse", position, false, nil, nil, team)
  corpse.unit_name = name -- Keep a reference to its name

  -- Remove the corpse from the game at any point
  function corpse:RemoveCorpse()
    corpse:StopExpiration()
    if corpse.meat_wagon then
      corpse.meat_wagon:RemoveCorpse(corpse)
    end 
    -- Remove the entity
    UTIL_Remove(corpse)
  end

  -- Removes the removal timer
  function corpse:StopExpiration()
    if corpse.removal_timer then Timers:RemoveTimer(corpse.removal_timer) end
  end

  -- Remove itself after the corpse duration
  function corpse:StartExpiration()
    corpse.corpse_expiration = GameRules:GetGameTime() + CORPSE_DURATION

    corpse.removal_timer = Timers:CreateTimer(CORPSE_DURATION, function()
      if corpse and IsValidEntity(corpse) and not corpse.meat_wagon then
        UTIL_Remove(corpse)
      end
    end)
  end

  corpse:StartExpiration()
  
  return corpse
end

function Corpses:AreAnyInRadius(team, origin, radius)
  return self:FindClosestInRadius(team, origin, radius) ~= nil
end

function Corpses:AreAnyAlliedInRadius(team, origin, radius)
  return self:FindAlliedInRadius(team, origin, radius)[1] ~= nil
end

function Corpses:AreAnyOutsideInRadius(team, origin, radius)
  return self:FindInRadiusOutside(team, origin, radius)[1] ~= nil
end

function Corpses:FindClosestInRadius(team, origin, radius)
  return self:FindInRadius(team, origin, radius)[1]
end

function Corpses:FindInRadius(team, origin, radius)
  local targets = FindUnitsInRadius(team, origin, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_CLOSEST, false)
  local corpses = {}
  for _,target in pairs(targets) do
    if IsCorpse(target) then
      table.insert(corpses, target)
    end
  end
  return corpses
end

function Corpses:FindVisibleInRadius(team, origin, radius)
  local targets = FindUnitsInRadius(team, origin, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_CLOSEST, false)
  local corpses = {}
  for _,target in pairs(targets) do
    if IsCorpse(target) and not target.meat_wagon then -- Ignore meat wagon corpses as first targets
      table.insert(corpses, target)
    end
  end
  return corpses
end

-- Only Friendly corpses
function Corpses:FindAlliedInRadius(team, origin, radius)
  local targets = FindUnitsInRadius(team, origin, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_CLOSEST, false)
  local corpses = {}
  local teamNumber = PlayerResource:GetTeam(team)
  for _,target in pairs(targets) do
    if IsCorpse(target) and not target.meat_wagon then -- Ignore meat wagon corpses
      table.insert(corpses, target)
    end
  end
  return corpses
end

-- I don't care about meat wagons
-- -- Only corpses outside meat wagon
-- function Corpses:FindInRadiusOutside(playerID, origin, radius)
--   local targets = FindUnitsInRadius(PlayerResource:GetTeam(playerID), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_CLOSEST, false)
--   local corpses = {}
--   for _,target in pairs(targets) do
--     if IsCorpse(target) and not target.meat_wagon then -- Ignore meat wagon corpses
--       table.insert(corpses, target)
--     end
--   end
--   return corpses
-- end

function CDOTA_BaseNPC:SetNoCorpse()
  self.no_corpse = true
end

function SetNoCorpse(event)
  event.target:SetNoCorpse()
end

-- Needs a corpse_expiration and not being eaten by cannibalize
function IsCorpse(unit)
  return unit.corpse_expiration and not unit.being_eaten
end

-- Custom Corpse Mechanic
function LeavesCorpse(unit)
  if not unit or not IsValidEntity(unit) then
    return false

  -- Heroes don't leave corpses (includes illusions)
  elseif unit:IsHero() then
    return false

  -- Ignore buildings 
  elseif unit.GetInvulnCount ~= nil then
    return false

  -- Ignore custom buildings
  elseif IsCustomBuilding(unit) then
    return false

  -- Ignore units that start with dummy keyword   
  elseif unit:IsDummy() then
    return false

  -- Ignore units that were specifically set to leave no corpse
  elseif unit.no_corpse then
    return false

  -- Air units
  elseif unit:GetKeyValue("MovementCapabilities") == "DOTA_UNIT_CAP_MOVE_FLY" then
    return false

  -- Summoned units via permanent modifier
  elseif unit:IsSummoned() then
    return false

  -- Mines
  elseif unit:GetUnitName() == "npc_dota_techies_land_mine" then
    return false

  -- Read the LeavesCorpse KV
  else
    -- local leavesCorpse = unit:GetKeyValue("LeavesCorpse")
    -- if leavesCorpse and leavesCorpse == 0 then
    --   return false
    -- else
    --   -- Leave corpse     
    --   return true
    -- end
    return true
  end
end