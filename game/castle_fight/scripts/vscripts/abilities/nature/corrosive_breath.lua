LinkLuaModifier("modifier_emerald_dragon_corrosive_breath", "abilities/nature/corrosive_breath.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_emerald_dragon_corrosive_breath_debuff", "abilities/nature/corrosive_breath.lua", LUA_MODIFIER_MOTION_NONE)

emerald_dragon_corrosive_breath = class({})
function emerald_dragon_corrosive_breath:GetIntrinsicModifierName() return "modifier_emerald_dragon_corrosive_breath" end

modifier_emerald_dragon_corrosive_breath = class({})

function modifier_emerald_dragon_corrosive_breath:IsHidden()
  return true
end

function modifier_emerald_dragon_corrosive_breath:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.duration = self.ability:GetSpecialValueFor("duration")
end

function modifier_emerald_dragon_corrosive_breath:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND
  }
  return funcs
end

function modifier_emerald_dragon_corrosive_breath:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster then
    local modifierName = "modifier_emerald_dragon_corrosive_breath_debuff"
    local modifier = target:AddNewModifier(self.caster, self.ability, modifierName, {duration = self.duration})

    local max_stacks = self.ability:GetSpecialValueFor("max_stacks")

    local stackCount = target:GetModifierStackCount(modifierName, self.caster)
    modifier:SetStackCount(math.min(stackCount + 1, max_stacks))
  end
end

function modifier_emerald_dragon_corrosive_breath:GetAttackSound()
  return "Hero_DragonKnight.ElderDragonShoot3.Attack"
end

modifier_emerald_dragon_corrosive_breath_debuff = class({})

function modifier_emerald_dragon_corrosive_breath_debuff:IsDebuff()
  return true
end

function modifier_emerald_dragon_corrosive_breath_debuff:DeclareFunctions()
  local decFuns =
    {
      MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
  return decFuns
end

function modifier_emerald_dragon_corrosive_breath_debuff:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  self.armor_reduction = self.ability:GetSpecialValueFor("armor_reduction")
end

function modifier_emerald_dragon_corrosive_breath_debuff:GetModifierPhysicalArmorBonus()
  return self:GetStackCount() * self.armor_reduction
end

function modifier_emerald_dragon_corrosive_breath_debuff:GetEffectName()
  return "particles/units/heroes/hero_dragon_knight/dragon_knight_corrosion_debuff.vpcf"
end