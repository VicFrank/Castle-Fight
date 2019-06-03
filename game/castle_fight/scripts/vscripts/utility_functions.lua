function GetRandomTableElement( table )
  local nRandomIndex = RandomInt( 1, #table )
    local randomElement = table[ nRandomIndex ]
    return randomElement
end

function RandomPositionBetweenBounds(min, max)
  local positionX = RandomFloat(min.x, max.x)
  local positionY = RandomFloat(min.y, max.y)
  return GetGroundPosition(Vector(positionX, positionY, 128), nil)
end

function GetDistanceBetweenTwoUnits(unit1, unit2)
  return (unit1:GetAbsOrigin() - unit2:GetAbsOrigin()):Length2D()
end