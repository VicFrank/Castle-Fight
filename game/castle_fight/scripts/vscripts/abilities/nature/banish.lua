ancient_guardian_banish = class({})

function ancient_guardian_banish:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local target = GetRandomVisibleEnemy(caster:GetTeam())
  if not target then return end

  local duration = self:GetSpecialValueFor("duration")

  target:AddNewModifier(caster, ability, "modifier_item_ethereal_blade_ethereal", {duration = duration})
end