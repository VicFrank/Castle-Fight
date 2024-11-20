function GetAggroThinkTime()
  if GameRules.numUnits < 100 then
    return 0.3
  elseif GameRules.numUnits < 125 then
    return 0.4
  elseif GameRules.numUnits < 150 then
    return 0.5
  elseif GameRules.numUnits < 175 then
    return 0.55
  elseif GameRules.numUnits < 200 then
    return 0.6
  elseif GameRules.numUnits < 225 then
    return 0.65
  elseif GameRules.numUnits < 250 then
    return 0.7
  elseif GameRules.numUnits < 275 then
    return 0.75
  elseif GameRules.numUnits < 300 then
    return 1
  else
    return 2
  end
end

function GetMoveToGoalThinkTime()
   if GameRules.numUnits < 100 then
    return 0.3
  elseif GameRules.numUnits < 125 then
    return 0.4
  elseif GameRules.numUnits < 150 then
    return 0.5
  elseif GameRules.numUnits < 175 then
    return 0.55
  elseif GameRules.numUnits < 200 then
    return 0.6
  elseif GameRules.numUnits < 225 then
    return 0.65
  elseif GameRules.numUnits < 250 then
    return 0.7
  elseif GameRules.numUnits < 275 then
    return 0.75
  elseif GameRules.numUnits < 300 then
    return 1
  else
    return 2
  end
end