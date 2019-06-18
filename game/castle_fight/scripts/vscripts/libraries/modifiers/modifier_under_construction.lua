modifier_under_construction = class({})

function modifier_under_construction:CheckState() 
    return { [MODIFIER_STATE_PASSIVES_DISABLED] = true,
             [MODIFIER_STATE_SILENCED] = true, }
end
