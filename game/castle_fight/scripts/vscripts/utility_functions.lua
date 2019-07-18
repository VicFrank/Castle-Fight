function GetOpposingTeam(team)
  if team == DOTA_TEAM_GOODGUYS then
    return DOTA_TEAM_BADGUYS
  elseif team == DOTA_TEAM_BADGUYS then
    return DOTA_TEAM_GOODGUYS
  end

  return DOTA_TEAM_NEUTRALS
end

function startsWith(str, start)
  return str:sub(1, #start) == start
end

function GetRandomTableElement( table )
  local nRandomIndex = RandomInt( 1, #table )
    local randomElement = table[ nRandomIndex ]
    return randomElement
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