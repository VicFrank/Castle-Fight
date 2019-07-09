furbolg_rejuvenation = class({})
LinkLuaModifier("modifier_rejuvenation", "abilities/nature/rejuvenation.lua", LUA_MODIFIER_MOTION_NONE)

function furbolg_rejuvenation:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  caster:EmitSound("DOTA_Item.HealingSalve.Activate")

  local duration = ability:GetSpecialValueFor("duration")

  target:AddNewModifier(caster, ability, "modifier_rejuvenation", {duration = duration})
end

modifier_rejuvenation = class({})

function modifier_rejuvenation:OnCreated()
  if not self:GetAbility() then return end
  
  self.health = self:GetAbility():GetSpecialValueFor("health")
  self.duration = self:GetAbility():GetSpecialValueFor("duration")
  self.healthRegen = self.health / self.duration
end

function modifier_rejuvenation:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
  }
end

function modifier_rejuvenation:GetModifierConstantHealthRegen()
  return self.healthRegen
end

function modifier_rejuvenation:GetEffectName()
  return "particles/items_fx/healing_flask.vpcf"
end