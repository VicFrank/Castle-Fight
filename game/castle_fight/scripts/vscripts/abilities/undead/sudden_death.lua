sudden_death = class({})

function sudden_death:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local target = GetRandomVisibleEnemy(caster:GetTeam())
  if not target then return end

  target:Kill(ability, caster)
end