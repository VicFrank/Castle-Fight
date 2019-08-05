function GetAggroThinkTime()
  if GameRules.numUnits < 150 then
    return 0.3
  elseif GameRules.numUnits < 200 then
    return 0.5
  elseif GameRules.numUnits < 300 then
    return 0.75
  elseif GameRules.numUnits < 400 then
    return 1
  elseif GameRules.numUnits < 500 then
    return 1.25
  elseif GameRules.numUnits < 600 then
    return 1.5
  else
    return 2
  end
end

function GetMoveToGoalThinkTime()
  if GameRules.numUnits < 150 then
    return 0.3
  elseif GameRules.numUnits < 200 then
    return 0.5
  elseif GameRules.numUnits < 300 then
    return 0.75
  elseif GameRules.numUnits < 400 then
    return 1
  elseif GameRules.numUnits < 500 then
    return 1.25
  elseif GameRules.numUnits < 600 then
    return 1.5
  else
    return 2
  end
end