dryad_abolish_magic = class({})
LinkLuaModifier("modifier_dryad_abolish_magic", "abilities/nature/abolish_magic.lua", LUA_MODIFIER_MOTION_NONE)

function dryad_abolish_magic:GetIntrinsicModifierName() return modifier_furbolg_mana_burn end

modifier_dryad_abolish_magic = class({})

function modifier_dryad_abolish_magic:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_dryad_abolish_magic:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  local chance = self:GetAbility():GetSpecialValueFor("chance")

  if attacker == self:GetParent() and not IsCustomBuilding(target) and target:GetMana() > 0 then
    if chance >= RandomInt(1,100) then
      target:Purge(true, false, false, false, false)
    end
  end
end
