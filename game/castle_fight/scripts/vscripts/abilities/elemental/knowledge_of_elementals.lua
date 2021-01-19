knowledge_of_elementals = class({})

function knowledge_of_elementals:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  caster:EmitSound("Hero_Invoker.Invoke")

  if ability.current_ability then
    caster:RemoveAbilityByHandle(ability.current_ability)
  end

  if not self.bucket then
    self.bucket = {}
  end

  local abilityNames = {
    "power_of_earth",
    "fire_breath",
    "lightning_attack",
  }

  local abilityToAdd = PickRandomShuffle(abilityNames, self.bucket)

  local addedAbility = caster:AddAbility(abilityToAdd)
  addedAbility:SetLevel(2)

  ability.current_ability = addedAbility
end