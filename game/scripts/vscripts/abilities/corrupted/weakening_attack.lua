LinkLuaModifier("modifier_weakening_attack", "abilities/corrupted/weakening_attack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_weakening_attack_debuff", "abilities/corrupted/weakening_attack.lua", LUA_MODIFIER_MOTION_NONE)

corrupted_weakening_attack = class({})
function corrupted_weakening_attack:GetIntrinsicModifierName() return "modifier_weakening_attack" end

modifier_weakening_attack = class({})

function modifier_weakening_attack:IsHidden() return true end

function modifier_weakening_attack:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()
end

function modifier_weakening_attack:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_weakening_attack:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster and not IsCustomBuilding(target) then
    local debuffName = "modifier_weakening_attack_debuff"
    self.duration = self.ability:GetSpecialValueFor("duration")
    target:AddNewModifier(self.caster, self.ability, debuffName, {duration = self.duration})
  end
end

modifier_weakening_attack_debuff = class({})

function modifier_weakening_attack_debuff:IsDebuff()
  return true
end

function modifier_weakening_attack_debuff:GetTexture()
  return "bane_enfeeble"
end 

function modifier_weakening_attack_debuff:DeclareFunctions()
  local decFuns =
    {
      MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
    }
  return decFuns
end

function modifier_weakening_attack_debuff:OnCreated()
  self.damage = self:GetAbility():GetSpecialValueFor("damage")
end


function modifier_weakening_attack_debuff:GetModifierDamageOutgoing_Percentage()
  return self.damage
end

function modifier_weakening_attack_debuff:GetEffectName()
  return "particles/units/heroes/hero_bane/bane_enfeeble.vpcf"
end

function modifier_weakening_attack_debuff:GetEffectAttachType()
  return PATTACH_POINT_FOLLOW
end