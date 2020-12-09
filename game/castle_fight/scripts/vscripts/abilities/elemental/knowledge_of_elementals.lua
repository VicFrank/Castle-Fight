knowledge_of_elementals = class({})

function knowledge_of_elementals:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  caster:EmitSound("Hero_Invoker.Invoke")

  if ability.current_ability then
    caster:RemoveAbilityByHandle(ability.current_ability)
  end

  local abilityNames = {
    "power_of_earth",
    "fire_breath",
    "lightning_attack",
  }

  local abilityToAdd = GetRandomTableElement(abilityNames)

  local addedAbility = caster:AddAbility(abilityToAdd)
  addedAbility:SetLevel(addedAbility:GetMaxLevel())

  ability.current_ability = addedAbility
end