LinkLuaModifier("modifier_azure_drake_attack", "abilities/north/azure_drake_attack.lua", LUA_MODIFIER_MOTION_NONE)

azure_drake_attack_sound = class({})
function azure_drake_attack_sound:GetIntrinsicModifierName() return "modifier_azure_drake_attack" end

modifier_azure_drake_attack = class({})

function modifier_azure_drake_attack:IsHidden() return true end

function modifier_azure_drake_attack:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_azure_drake_attack:GetAttackSound()
  return "Hero_DragonKnight.ElderDragonShoot3.Attack"
end
