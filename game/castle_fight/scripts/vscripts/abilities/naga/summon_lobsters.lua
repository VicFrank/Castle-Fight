naga_siren_summon_lobsters = class({})

function naga_siren_summon_lobsters:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local unitName = "naga_lobster"
  local position = caster:GetAbsOrigin()
  local hero = caster:GetOwner()

  local duration = self:GetTalentSpecialValueFor("duration")

  for i=1,2 do
    local lobster = CreateUnitByName(unitName, position, true, hero, hero, hero:GetTeamNumber())
    lobster:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
  end
end
