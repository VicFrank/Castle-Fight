naga_siren_summon_big_lobsters = class({})

function naga_siren_summon_big_lobsters:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local unitName = "naga_big_lobster"
  local position = caster:GetAbsOrigin()
  local hero = caster:GetOwner()
  local team = caster:GetTeam()
  local playerID = caster.playerID

  local duration = ability:GetSpecialValueFor("duration")

  for i=1,2 do
    local lobster = CreateLaneUnit(unitName, position, team, playerID)
    lobster:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
  end
end
