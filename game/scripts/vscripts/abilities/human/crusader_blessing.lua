crusader_blessing = class({})
LinkLuaModifier("modifier_crusader_blessing", "abilities/human/crusader_blessing.lua", LUA_MODIFIER_MOTION_NONE)

function crusader_blessing:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  local duration = ability:GetSpecialValueFor("duration")

  target:AddNewModifier(caster, ability, "modifier_crusader_blessing", {duration = duration})

  target:EmitSound("Hero_Chen.PenitenceImpact")
end

modifier_crusader_blessing = class({})

function modifier_crusader_blessing:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()
  self.parent = self:GetParent()

  if not self.ability then return end

  self.armor_bonus = self.ability:GetSpecialValueFor("armor_bonus")
  self.regen_bonus = self.ability:GetSpecialValueFor("regen_bonus")
  self.health_bonus = self.ability:GetSpecialValueFor("health_bonus")

  if not IsServer() then return end
  Timers:CreateTimer(function() self:GetParent():Heal(self.health_bonus, self:GetCaster()) end)
end

function modifier_crusader_blessing:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
  return funcs
end

function modifier_crusader_blessing:GetModifierExtraHealthBonus()
  return self.health_bonus
end

function modifier_crusader_blessing:GetModifierConstantHealthRegen()
  return self.regen_bonus
end

function modifier_crusader_blessing:GetModifierPhysicalArmorBonus()
  return self.armor_bonus
end

function modifier_crusader_blessing:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_crusader_blessing:GetEffectName()
  return "particles/custom/human/inner_fire.vpcf"
end