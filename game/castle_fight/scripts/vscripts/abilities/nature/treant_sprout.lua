keeper_treant_sprout = class({})

function keeper_treant_sprout:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local point = caster:GetAbsOrigin()
  
  local trees = 8
  local radius = 150
  local angle = math.pi/4

  local duration = 5
  
  -- Creates 8 temporary trees at each 45 degree interval around the clicked point
  for i=1,trees do
    local position = Vector(point.x+radius*math.sin(angle), point.y+radius*math.cos(angle), point.z)
    CreateTempTree(position, duration)
    angle = angle + math.pi/4
  end
  -- Gives vision to the caster's team in a radius around the point for the duration
  AddFOWViewer(caster:GetTeam(), point, 450, duration, false)

  -- Spawn treants after the trees die
  local unitName = "keeper_treant"
  local team = caster:GetTeam()
  local playerID = caster.playerID
  local angle = math.pi/4

  Timers:CreateTimer(duration, function() 
    for i=1,5 do
      local position = Vector(point.x+radius*math.sin(angle), point.y+radius*math.cos(angle), point.z)
      local treant = CreateLaneUnit(unitName, position, team, playerID)
      treant:AddNewModifier(caster, ability, "modifier_kill", {duration = 30})

      angle = angle + math.pi/2
    end
  end)
end