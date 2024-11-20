tentacle_prison = class({})

function tentacle_prison:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local enemies = FindAllVisibleEnemies(caster:GetTeam())
  local target = FindFirstUnit(enemies, function(target) 
    return not target:HasFlyMovementCapability()
  end)

  if not target then return end

  for _,modifier in pairs(target:FindAllModifiers()) do
    if modifier.OnBuildingTarget and modifier:OnBuildingTarget() then
      return
    end
  end

  local unitName = "tentacle_prison_tentacle"
  local team = caster:GetTeam()
  local playerID = caster:GetPlayerOwnerID()
  local position = target:GetAbsOrigin()
  local angle = math.pi/4
  local radius = 60

  Timers:CreateTimer(function() 
    for i=1,6 do
      local position = Vector(position.x+radius*math.sin(angle), position.y+radius*math.cos(angle), position.z)
      local tentacle = CreateLaneUnit(unitName, position, team, playerID)
      tentacle:AddNewModifier(caster, ability, "modifier_kill", {duration = 10})
      tentacle.isLegendary = true
      tentacle:SetNoCorpse()

      angle = angle + math.pi/3
    end
  end)
end