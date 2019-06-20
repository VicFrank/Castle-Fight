LinkLuaModifier("modifier_avenging_spirit_corrosive_attack", "abilities/night_elves/corrosive_attack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_avenging_spirit_corrosive_attack_debuff", "abilities/night_elves/corrosive_attack.lua", LUA_MODIFIER_MOTION_NONE)

avenging_spirit_corrosive_attack = class({})
function avenging_spirit_corrosive_attack:GetIntrinsicModifierName() return "modifier_avenging_spirit_corrosive_attack" end

modifier_avenging_spirit_corrosive_attack = class({})

function modifier_avenging_spirit_corrosive_attack:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.duration = self.ability:GetSpecialValueFor("duration")
end

function modifier_avenging_spirit_corrosive_attack:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_avenging_spirit_corrosive_attack:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster then
    local debuffName = "modifier_avenging_spirit_corrosive_attack_debuff"
    target:AddNewModifier(self.caster, self.ability, debuffName, {duration = self.duration})
  end
end

modifier_avenging_spirit_corrosive_attack_debuff = class({})

function modifier_avenging_spirit_corrosive_attack_debuff:IsDebuff()
  return true
end

function modifier_avenging_spirit_corrosive_attack_debuff:DeclareFunctions()
  local decFuns =
    {
      MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
  return decFuns
end

function modifier_avenging_spirit_corrosive_attack_debuff:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.armor_reduction = self.ability:GetSpecialValueFor("armor_reduction")
end

function modifier_avenging_spirit_corrosive_attack_debuff:GetModifierPhysicalArmorBonus()
  return self.armor_reduction
end

function modifier_avenging_spirit_corrosive_attack_debuff:GetEffectName()
  return "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo_debuff.vpcf"
end