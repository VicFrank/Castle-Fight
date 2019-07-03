modifier_under_construction = class({})

function modifier_under_construction:IsHidden() return true end

function modifier_under_construction:CheckState() 
  return { 
    [MODIFIER_STATE_PASSIVES_DISABLED] = true,
    [MODIFIER_STATE_SILENCED] = true,
    [MODIFIER_STATE_DISARMED] = true,
  }
end

function modifier_under_construction:DeclareFunctions()
  return {MODIFIER_PROPERTY_MANA_REGEN_CONSTANT}
end

function modifier_under_construction:GetModifierConstantManaRegen()
  return -1
end