assemble_gobbo_mechanist = class({})

function assemble_gobbo_mechanist:OnSpellStart()
  local ability = self
  local caster = self:GetCaster()

  local duration = ability:GetSpecialValueFor("duration")

  local gobbo = CreateUnitByName("gobbo_mechanist", caster:GetAbsOrigin(), true, nil, nil, caster:GetTeam())

  gobbo:AddNewModifier(caster, ability, "modifier_invulnerable", {})
  gobbo:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
end