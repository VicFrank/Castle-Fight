dryad_summon_treants = class({})

function dryad_summon_treants:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local position = caster:GetAbsOrigin()

  local unitName = "keeper_treant"
  local team = caster:GetTeam()
  local playerID = caster.playerID

  for i=1,2 do
    local treant = CreateLaneUnit(unitName, position, team, playerID)
    treant:AddNewModifier(caster, ability, "modifier_kill", {duration = 30})
  end
end