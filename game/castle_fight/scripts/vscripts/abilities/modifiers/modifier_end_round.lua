modifier_end_round = class({})

function modifier_end_round:IsHidden() return true end

function modifier_end_round:CheckState()
  return { 
    [MODIFIER_STATE_STUNNED] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_PASSIVES_DISABLED] = true,
  }
end