LinkLuaModifier("modifier_dryad_natures_touch", "abilities/nature/natures_touch.lua", LUA_MODIFIER_MOTION_NONE)

dryad_natures_touch = class({})
function dryad_natures_touch:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorTarget()

  caster:EmitSound("Hero_Treant.LivingArmor.Cast")

  target:AddNewModifier(caster, ability, "modifier_dryad_natures_touch", {})
end

modifier_dryad_natures_touch = class({})

function modifier_dryad_natures_touch:IsPurgable()
  return true
end

function modifier_dryad_natures_touch:IsDebuff()
  return false
end

function modifier_dryad_natures_touch:OnCreated()
  self.health_bonus = self:GetAbility():GetSpecialValueFor("health")
  self.armor = self:GetAbility():GetSpecialValueFor("armor")

  if not IsServer() then return end

  local parent = self:GetParent()

  local particleName = "particles/econ/items/treant_protector/ti7_shoulder/treant_ti7_crimson_livingarmor.vpcf"

  parent.NaturesTouchParticle = ParticleManager:CreateParticle(particleName, PATTACH_POINT_FOLLOW, parent)
  ParticleManager:SetParticleControlEnt(parent.NaturesTouchParticle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
  ParticleManager:SetParticleControlEnt(parent.NaturesTouchParticle, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
end

function modifier_dryad_natures_touch:OnDestroy()
  if not IsServer() then return end
  ParticleManager:DestroyParticle(self:GetParent().NaturesTouchParticle, true)
end

function modifier_dryad_natures_touch:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
  return funcs
end

function modifier_dryad_natures_touch:GetModifierExtraHealthBonus(keys)
  return self.health_bonus
end

function modifier_dryad_natures_touch:GetModifierPhysicalArmorBonus(keys)
  return self.armor
end

function modifier_dryad_natures_touch:GetTexture()
  return "enchantress_untouchable"
end