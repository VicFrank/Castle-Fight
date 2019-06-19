modifier_stunned_custom = class({})

function modifier_stunned_custom:IsHidden() return true end

function modifier_stunned_custom:CheckState()
  return { 
    [MODIFIER_STATE_STUNNED] = true,
  }
end