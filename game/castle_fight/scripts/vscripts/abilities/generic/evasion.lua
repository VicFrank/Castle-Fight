LinkLuaModifier("modifier_custom_evasion", "abilities/generic/evasion.lua", LUA_MODIFIER_MOTION_NONE)

defender_evasion = class({})
function defender_evasion:GetIntrinsicModifierName() return "modifier_custom_evasion" end
murloc_evasion = class({})
function murloc_evasion:GetIntrinsicModifierName() return "modifier_custom_evasion" end
hunter_evasion = class({})
function hunter_evasion:GetIntrinsicModifierName() return "modifier_custom_evasion" end
assassin_evasion = class({})
function assassin_evasion:GetIntrinsicModifierName() return "modifier_custom_evasion" end
avenging_spirit_evasion = class({})
function avenging_spirit_evasion:GetIntrinsicModifierName() return "modifier_custom_evasion" end
keeper_incorporeal = class({})
function keeper_incorporeal:GetIntrinsicModifierName() return "modifier_custom_evasion" end
tribal_blessing_evasion = class({})
function tribal_blessing_evasion:GetIntrinsicModifierName() return "modifier_custom_evasion" end
archer_evasion = class({})
function archer_evasion:GetIntrinsicModifierName() return "modifier_custom_evasion" end
blademaster_evasion = class({})
function blademaster_evasion:GetIntrinsicModifierName() return "modifier_custom_evasion" end
skeleton_evasion = class({})
function skeleton_evasion:GetIntrinsicModifierName() return "modifier_custom_evasion" end
liquid_body = class({})
function liquid_body:GetIntrinsicModifierName() return "modifier_custom_evasion" end

modifier_custom_evasion = class({})

function modifier_custom_evasion:IsHidden() return true end

function modifier_custom_evasion:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_EVASION_CONSTANT,
    MODIFIER_EVENT_ON_ATTACK_FAIL,
  }
  return funcs
end

function modifier_custom_evasion:GetModifierEvasion_Constant()
  return self:GetAbility():GetSpecialValueFor("evasion")
end

function modifier_custom_evasion:OnAttackFail(keys)
  local fail_type = keys.fail_type
  local target = keys.target
  local attacker = keys.attacker

  if target == self:GetParent() then
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MISS, attacker, 0, nil)
  end
end