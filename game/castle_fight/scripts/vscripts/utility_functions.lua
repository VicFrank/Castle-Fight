function hasbit(x, p)
  if type(x) == "userdata" then x = tonumber(tostring(x)) end
  return x % (p + p) >= p
end

function GetOpposingTeam(team)
  if team == DOTA_TEAM_GOODGUYS then
    return DOTA_TEAM_BADGUYS
  elseif team == DOTA_TEAM_BADGUYS then
    return DOTA_TEAM_GOODGUYS
  end

  return DOTA_TEAM_NEUTRALS
end

function ForceKill(unit)
  unit:Kill(nil, nil)
end

function heroToRace(heroname)
  if heroname == "npc_dota_hero_kunkka" then
    return "Human"
  elseif heroname == "npc_dota_hero_slark" then
    return "Naga"
  elseif heroname == "npc_dota_hero_treant" then
    return "Nature"
  elseif heroname == "npc_dota_hero_vengefulspirit" then
    return "Night Elf"
  elseif heroname == "npc_dota_hero_abaddon" then
    return "Undead"
  elseif heroname == "npc_dota_hero_juggernaut" then
    return "Orc"
  elseif heroname == "npc_dota_hero_tusk" then
    return "North"
  elseif heroname == "npc_dota_hero_invoker" then
    return "High Elf"
  elseif heroname == "npc_dota_hero_wisp" then
    return "Elemental"
  elseif heroname == "npc_dota_hero_grimstroke" then
    return "Corrupted"
  elseif heroname == "npc_dota_hero_chaos_knight" then
    return "Chaos"
  elseif heroname == "npc_dota_hero_tinker" then
    return "Mech"
  elseif heroname == "npc_dota_hero_zuus" then
    return "Random"
  else
    return "Invalid Hero"
  end
end

function startsWith(str, start)
  return str:sub(1, #start) == start
end

function PickRandomShuffle(reference_list, bucket)
  if (TableCount(reference_list) == 0) then
    return nil
  end
  if (#bucket == 0) then
    -- ran out of options, refill the bucket from the reference
    local i = 1
    for k, v in pairs(reference_list) do
      bucket[i] = v
      i = i + 1
    end
  end
  -- pick a value from the bucket and remove it
  local pick_index = RandomInt(1, #bucket)
  local result = bucket[pick_index]
  table.remove(bucket, pick_index)
  return result
end

function GetRandomTableElement( table )
  if #table == 0 then return nil end
  local nRandomIndex = RandomInt( 1, #table )
  local randomElement = table[ nRandomIndex ]
  return randomElement
end

function GetRandomTableElements(inputTable, amount)
  if #inputTable == 0 then return nil end
  
  local indexes = {}
  local elements = {}
  
  while TableCount(indexes) < amount do
    local nRandomIndex = RandomInt(1, #inputTable)
    if not TableContainsValue(indexes, nRandomIndex) then
      table.insert(indexes, nRandomIndex)
    end
    if TableCount(indexes) >= TableCount(inputTable) then break end
  end

  for _,i in pairs(indexes) do
    local randomElement = inputTable[ i ]
    table.insert(elements, randomElement)
  end
  
  return elements
end

function FilterTable(inputTable, filter)
  local newTable = {}
  for _,v in pairs(inputTable) do
    if filter(v) then
      table.insert(newTable, v)
    end
  end
  return newTable
end

function TableContainsValue( t, value )
  for _, v in pairs( t ) do
    if v == value then
      return true
    end
  end

  return false
end

function TableCount( t )
  local n = 0
  for _ in pairs( t ) do
    n = n + 1
  end
  return n
end

function DeepTableCompare(t1,t2,ignore_mt)
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then return false end
  -- non-table types can be directly compared
  if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
  -- as well as tables which have the metamethod __eq
  local mt = getmetatable(t1)
  if not ignore_mt and mt and mt.__eq then return t1 == t2 end
  for k1,v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil or not DeepTableCompare(v1,v2) then return false end
  end
  for k2,v2 in pairs(t2) do
    local v1 = t1[k2]
    if v1 == nil or not DeepTableCompare(v1,v2) then return false end
  end
  return true
end

function RandomPositionBetweenBounds(min, max)
  local positionX = RandomFloat(min.x, max.x)
  local positionY = RandomFloat(min.y, max.y)
  return GetGroundPosition(Vector(positionX, positionY, 128), nil)
end

function GetDistanceBetweenTwoUnits(unit1, unit2)
  return (unit1:GetAbsOrigin() - unit2:GetAbsOrigin()):Length2D()
end

function ConvertTimeToTable(t)
  local minutes = math.floor(t / 60)
  local seconds = t - (minutes * 60)
  local m10 = math.floor(minutes / 10)
  local m01 = minutes - (m10 * 10)
  local s10 = math.floor(seconds / 10)
  local s01 = seconds - (s10 * 10)
  local broadcast_gametimer = 
    {
      timer_minute_10 = m10,
      timer_minute_01 = m01,
      timer_second_10 = s10,
      timer_second_01 = s01,
    }
  return broadcast_gametimer
end

-- 1st, 2nd, 3rd, 4th, ..., nth
function getNumberSuffix(number)
  if number == 1 then
    return "st"
  elseif number == 2 then
    return "nd"
  elseif number == 3 then
    return "rd"
  else
    return "th"
  end
end

function GetTableMax(t)
  local max
  for _,v in pairs(t) do
    if not max then max = v end
    max = math.max(max,v)
  end
  return max
end