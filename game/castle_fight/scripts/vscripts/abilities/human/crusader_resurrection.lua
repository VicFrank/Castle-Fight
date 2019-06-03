crusader_resurrection = class({})

function crusader_resurrection:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  -- point target at a ground point
end